# Sadeeq AI V2 — Database Design

## V2 database
Supabase project: `Sadeeq bot`

The legacy `Sadeeq ai` project is treated as V1/reference and is not modified by the V2 build.

## Core entities

### owner_profiles
Represents the single platform owner. It references `auth.users` and enforces a singleton row through a boolean uniqueness constraint.

### bots
Stores bot configuration, public Bot ID, lifecycle status, instructions, provider selection, usage limits, and message-size limits.

### bot_secrets
Stores only a cryptographic secret hash plus non-sensitive metadata. Secrets may be associated with a specific website so compromise of one website credential does not automatically authorize another website.

### bot_websites
Stores normalized website origins and their lifecycle state: `PENDING`, `ACTIVE`, `SUSPENDED`, or `REVOKED`.

### bot_sessions
Stores only a hash of a public session/ticket token. Sessions are scoped to both bot and website and have explicit expiry/revocation state.

### ai_providers
Stores provider/model configuration metadata and operational health fields. Provider API keys are intentionally not stored in this table; privileged provider secrets will remain server-side.

### bot_usage
Stores auditable usage metadata such as provider/model, token counts, latency, status, and timestamps. Customer message content is not stored by this foundation.

### security_audit_logs
Stores security-sensitive event metadata with optional owner, bot, website, and session references. Secrets and private credentials must never be placed in `metadata`.

## Level 2 private initialization entity

### private.owner_bootstrap_tokens
Stores only the SHA-256 hash of the one-time first-owner bootstrap credential, plus expiry and consumption timestamps. The table is in the private schema and has no `anon` or `authenticated` Data API grants.

The plaintext bootstrap credential is not committed to GitHub and is never stored in the database.

## Lifecycle enums
- `bot_status`: `ACTIVE`, `DISABLED`, `SUSPENDED`
- `website_status`: `PENDING`, `ACTIVE`, `SUSPENDED`, `REVOKED`
- `secret_status`: `ACTIVE`, `REVOKED`, `EXPIRED`
- `session_status`: `ACTIVE`, `EXPIRED`, `REVOKED`
- `provider_status`: `ACTIVE`, `DEGRADED`, `FAILED`, `DISABLED`
- `usage_status`: `SUCCESS`, `ERROR`, `RATE_LIMITED`, `REJECTED`
- `audit_severity`: `INFO`, `WARNING`, `CRITICAL`

## Security model
All eight V2 application tables have RLS enabled. Owner-facing policies call the server-side `private.is_platform_owner()` helper. There are no public read policies for V2 application data.

Sensitive tables (`bot_secrets`, `bot_sessions`, usage, and audit logs) are read-only through the current owner-facing client grants; mutation paths will be introduced through narrowly scoped server-side functions in later levels.

The `private` schema is not exposed to anonymous clients. The owner helper is `SECURITY DEFINER` with an empty `search_path` and only callable by authenticated users.

The first-owner claim uses `public.claim_initial_owner(text)`. It is intentionally `SECURITY DEFINER`, restricted to `authenticated`, protected by a high-entropy one-time credential, and serialized with a transaction-level advisory lock. Once an owner exists, the function cannot initialize another owner.

## Index strategy
Indexes cover:
- bot status/creation and provider selection;
- bot website lookup by bot/status and recent activity;
- active secret lookup by bot/website;
- session lookup by bot/website/expiry;
- usage history by bot/website/provider/session;
- audit history by time/event/bot/actor/website/session.

## Migration
- `level_1_database_foundation` — core V2 schema.
- `level_2_owner_auth_foundation` — owner initialization boundary and missing foreign-key indexes.

The one-time bootstrap credential hash is environment initialization state and is provisioned separately from source control.

## Future Level 1-compatible work
Public registration, secret verification, session issuance, chat authorization, and provider calls must not bypass the RLS/security design. They will use server-side Edge Functions/RPCs with narrowly scoped data access.
