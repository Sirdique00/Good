-- Level 2 database foundation.
-- The one-time bootstrap token hash is provisioned separately from source control.

create index if not exists bots_default_provider_idx
  on public.bots(default_provider_id);

create index if not exists bot_usage_session_created_idx
  on public.bot_usage(session_id, created_at desc);

create index if not exists security_audit_logs_website_idx
  on public.security_audit_logs(website_id, created_at desc);

create index if not exists security_audit_logs_session_idx
  on public.security_audit_logs(session_id, created_at desc);

create table if not exists private.owner_bootstrap_tokens (
  id uuid primary key default gen_random_uuid(),
  token_hash text not null unique,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_at timestamptz not null default now(),
  constraint owner_bootstrap_token_hash_ck check (length(token_hash) = 64)
);

revoke all on private.owner_bootstrap_tokens from public, anon, authenticated;

create or replace function public.claim_initial_owner(p_bootstrap_token text)
returns public.owner_profiles
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_token_id uuid;
  v_owner public.owner_profiles;
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'AUTHENTICATION_REQUIRED' using errcode = 'P0001';
  end if;

  perform pg_advisory_xact_lock(hashtext('sadeeq-ai-owner-bootstrap'));

  if exists (select 1 from public.owner_profiles) then
    raise exception 'OWNER_ALREADY_INITIALIZED' using errcode = 'P0001';
  end if;

  select id into v_token_id
  from private.owner_bootstrap_tokens
  where token_hash = encode(digest(p_bootstrap_token, 'sha256'), 'hex')
    and used_at is null
    and expires_at > now()
  for update;

  if v_token_id is null then
    raise exception 'INVALID_BOOTSTRAP_TOKEN' using errcode = 'P0001';
  end if;

  update private.owner_bootstrap_tokens
  set used_at = now()
  where id = v_token_id;

  insert into public.owner_profiles (user_id, display_name)
  values (v_uid, 'Sadeeq AI Owner')
  returning * into v_owner;

  return v_owner;
end;
$$;

revoke all on function public.claim_initial_owner(text) from public, anon;
grant execute on function public.claim_initial_owner(text) to authenticated;
