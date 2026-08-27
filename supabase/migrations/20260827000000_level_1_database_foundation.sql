-- Sadeeq AI V2 — Level 1 database foundation
-- Applied to Supabase project: Sadeeq bot

create schema if not exists private;
create extension if not exists pgcrypto;

create type public.bot_status as enum ('ACTIVE','DISABLED','SUSPENDED');
create type public.website_status as enum ('PENDING','ACTIVE','SUSPENDED','REVOKED');
create type public.secret_status as enum ('ACTIVE','REVOKED','EXPIRED');
create type public.session_status as enum ('ACTIVE','EXPIRED','REVOKED');
create type public.provider_status as enum ('ACTIVE','DEGRADED','FAILED','DISABLED');
create type public.usage_status as enum ('SUCCESS','ERROR','RATE_LIMITED','REJECTED');
create type public.audit_severity as enum ('INFO','WARNING','CRITICAL');

create table public.owner_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  display_name text,
  singleton boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint owner_profiles_singleton_check check (singleton = true)
);
create unique index owner_profiles_singleton_uidx on public.owner_profiles (singleton);

create table public.ai_providers (
  id uuid primary key default gen_random_uuid(),
  provider_name text not null,
  model_name text not null,
  status public.provider_status not null default 'DISABLED',
  priority integer not null default 100 check (priority > 0),
  secret_name text not null,
  rate_limit_rpm integer check (rate_limit_rpm is null or rate_limit_rpm > 0),
  failure_count integer not null default 0 check (failure_count >= 0),
  last_success_at timestamptz,
  last_failure_at timestamptz,
  cooldown_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ai_providers_provider_model_uk unique (provider_name, model_name),
  constraint ai_providers_secret_name_ck check (length(trim(secret_name)) between 1 and 128)
);

create table public.bots (
  id uuid primary key default gen_random_uuid(),
  public_bot_id uuid not null unique default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 120),
  description text,
  status public.bot_status not null default 'DISABLED',
  instructions text not null default '',
  welcome_message text,
  default_provider_id uuid references public.ai_providers(id) on delete set null,
  daily_request_limit bigint check (daily_request_limit is null or daily_request_limit > 0),
  monthly_request_limit bigint check (monthly_request_limit is null or monthly_request_limit > 0),
  max_message_chars integer not null default 4000 check (max_message_chars between 1 and 20000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.bot_websites (
  id uuid primary key default gen_random_uuid(),
  bot_id uuid not null references public.bots(id) on delete cascade,
  origin text not null check (length(origin) between 1 and 2048),
  status public.website_status not null default 'PENDING',
  registered_at timestamptz,
  last_activity_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bot_websites_bot_origin_uk unique (bot_id, origin)
);

create table public.bot_secrets (
  id uuid primary key default gen_random_uuid(),
  bot_id uuid not null references public.bots(id) on delete cascade,
  website_id uuid references public.bot_websites(id) on delete set null,
  intended_origin text check (intended_origin is null or length(intended_origin) between 1 and 2048),
  secret_hash text not null,
  secret_prefix text not null check (length(secret_prefix) between 4 and 16),
  version integer not null default 1 check (version > 0),
  status public.secret_status not null default 'ACTIVE',
  created_at timestamptz not null default now(),
  used_at timestamptz,
  rotated_at timestamptz,
  revoked_at timestamptz,
  constraint bot_secrets_hash_ck check (length(secret_hash) >= 20)
);

create table public.bot_sessions (
  id uuid primary key default gen_random_uuid(),
  bot_id uuid not null references public.bots(id) on delete cascade,
  website_id uuid not null references public.bot_websites(id) on delete cascade,
  token_hash bytea not null unique,
  status public.session_status not null default 'ACTIVE',
  issued_at timestamptz not null default now(),
  expires_at timestamptz not null,
  last_seen_at timestamptz,
  revoked_at timestamptz,
  user_agent_hash bytea,
  constraint bot_sessions_expiry_ck check (expires_at > issued_at)
);

create table public.bot_usage (
  id uuid primary key default gen_random_uuid(),
  bot_id uuid not null references public.bots(id) on delete cascade,
  website_id uuid references public.bot_websites(id) on delete set null,
  session_id uuid references public.bot_sessions(id) on delete set null,
  provider_id uuid references public.ai_providers(id) on delete set null,
  model_name text,
  request_count integer not null default 1 check (request_count > 0),
  input_tokens bigint not null default 0 check (input_tokens >= 0),
  output_tokens bigint not null default 0 check (output_tokens >= 0),
  total_tokens bigint generated always as (input_tokens + output_tokens) stored,
  latency_ms integer check (latency_ms is null or latency_ms >= 0),
  status public.usage_status not null,
  error_code text,
  created_at timestamptz not null default now()
);

create table public.security_audit_logs (
  id uuid primary key default gen_random_uuid(),
  event_type text not null check (length(trim(event_type)) between 1 and 120),
  severity public.audit_severity not null default 'INFO',
  actor_user_id uuid references auth.users(id) on delete set null,
  bot_id uuid references public.bots(id) on delete set null,
  website_id uuid references public.bot_websites(id) on delete set null,
  session_id uuid references public.bot_sessions(id) on delete set null,
  request_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index bots_status_idx on public.bots(status);
create index bots_created_at_idx on public.bots(created_at desc);
create index bot_websites_bot_status_idx on public.bot_websites(bot_id, status);
create index bot_websites_last_activity_idx on public.bot_websites(last_activity_at desc);
create index bot_secrets_bot_status_idx on public.bot_secrets(bot_id, status);
create index bot_secrets_website_status_idx on public.bot_secrets(website_id, status);
create index bot_sessions_bot_status_idx on public.bot_sessions(bot_id, status);
create index bot_sessions_website_status_idx on public.bot_sessions(website_id, status);
create index bot_sessions_expires_at_idx on public.bot_sessions(expires_at);
create index bot_usage_bot_created_idx on public.bot_usage(bot_id, created_at desc);
create index bot_usage_website_created_idx on public.bot_usage(website_id, created_at desc);
create index bot_usage_provider_created_idx on public.bot_usage(provider_id, created_at desc);
create index security_audit_logs_created_idx on public.security_audit_logs(created_at desc);
create index security_audit_logs_event_idx on public.security_audit_logs(event_type, created_at desc);
create index security_audit_logs_bot_idx on public.security_audit_logs(bot_id, created_at desc);
create index security_audit_logs_actor_idx on public.security_audit_logs(actor_user_id, created_at desc);

create unique index bot_secrets_active_website_uidx on public.bot_secrets(website_id) where website_id is not null and status = 'ACTIVE';
create unique index bot_secrets_active_unbound_bot_uidx on public.bot_secrets(bot_id) where website_id is null and status = 'ACTIVE';

create or replace function private.is_platform_owner()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.owner_profiles op where op.user_id = (select auth.uid()));
$$;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
revoke all on function private.is_platform_owner() from public, anon;
grant execute on function private.is_platform_owner() to authenticated;

create or replace function public.set_updated_at()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;

create trigger owner_profiles_set_updated_at before update on public.owner_profiles for each row execute function public.set_updated_at();
create trigger ai_providers_set_updated_at before update on public.ai_providers for each row execute function public.set_updated_at();
create trigger bots_set_updated_at before update on public.bots for each row execute function public.set_updated_at();
create trigger bot_websites_set_updated_at before update on public.bot_websites for each row execute function public.set_updated_at();
revoke all on function public.set_updated_at() from public, anon, authenticated;

alter table public.owner_profiles enable row level security;
alter table public.ai_providers enable row level security;
alter table public.bots enable row level security;
alter table public.bot_websites enable row level security;
alter table public.bot_secrets enable row level security;
alter table public.bot_sessions enable row level security;
alter table public.bot_usage enable row level security;
alter table public.security_audit_logs enable row level security;

create policy owner_profiles_owner_select on public.owner_profiles for select to authenticated using ((select private.is_platform_owner()));
create policy owner_profiles_owner_update on public.owner_profiles for update to authenticated using ((select private.is_platform_owner())) with check ((select private.is_platform_owner()));
create policy ai_providers_owner_all on public.ai_providers for all to authenticated using ((select private.is_platform_owner())) with check ((select private.is_platform_owner()));
create policy bots_owner_all on public.bots for all to authenticated using ((select private.is_platform_owner())) with check ((select private.is_platform_owner()));
create policy bot_websites_owner_all on public.bot_websites for all to authenticated using ((select private.is_platform_owner())) with check ((select private.is_platform_owner()));
create policy bot_secrets_owner_select on public.bot_secrets for select to authenticated using ((select private.is_platform_owner()));
create policy bot_sessions_owner_select on public.bot_sessions for select to authenticated using ((select private.is_platform_owner()));
create policy bot_usage_owner_select on public.bot_usage for select to authenticated using ((select private.is_platform_owner()));
create policy security_audit_logs_owner_select on public.security_audit_logs for select to authenticated using ((select private.is_platform_owner()));

revoke all on public.owner_profiles from anon, authenticated;
revoke all on public.ai_providers from anon, authenticated;
revoke all on public.bots from anon, authenticated;
revoke all on public.bot_websites from anon, authenticated;
revoke all on public.bot_secrets from anon, authenticated;
revoke all on public.bot_sessions from anon, authenticated;
revoke all on public.bot_usage from anon, authenticated;
revoke all on public.security_audit_logs from anon, authenticated;

grant select, update on public.owner_profiles to authenticated;
grant select, insert, update, delete on public.ai_providers to authenticated;
grant select, insert, update, delete on public.bots to authenticated;
grant select, insert, update, delete on public.bot_websites to authenticated;
grant select on public.bot_secrets to authenticated;
grant select on public.bot_sessions to authenticated;
grant select on public.bot_usage to authenticated;
grant select on public.security_audit_logs to authenticated;
grant usage on schema public to authenticated;
