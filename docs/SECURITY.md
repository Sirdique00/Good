# Sadeeq AI V2 — Security Foundation

## Owner model
Sadeeq AI V2 has one platform owner. Authentication identity comes from Supabase Auth; privileged authorization is determined server-side by membership in `owner_profiles`.

Frontend state, local storage, URL parameters, hidden HTML, and client-side role checks are never authoritative.

## Authentication
- Browser authentication uses Supabase Auth with persistent sessions, automatic token refresh, and PKCE.
- The production UI exposes owner sign-in only; there is no customer/admin signup path.
- A one-time initialization flow exists only to create the first owner.
- Password recovery uses Supabase Auth's recovery flow and an exact configured redirect URL.
- The protected owner route re-checks the owner profile server-side through RLS before rendering owner content.
- Non-owner authenticated sessions are immediately signed out and denied access.

## Owner initialization
The first owner is established through a one-time high-entropy bootstrap credential. The credential is never stored in plaintext; only a SHA-256 hash is stored in the private schema. The bootstrap record has an expiry and is marked consumed after successful initialization. A transaction-level advisory lock prevents concurrent first-owner claims.

The bootstrap function is deliberately `SECURITY DEFINER` because the initial owner insert must cross the owner-profile RLS boundary. It has a fixed `search_path`, is not executable by `anon`, accepts no public management capability beyond first-owner initialization, and becomes unusable once an owner exists or the token is consumed/expired.

## Database security
- RLS is enabled on every V2 application table.
- No anonymous policy grants access to V2 application data.
- Owner policies require `private.is_platform_owner()`.
- The owner helper is `SECURITY DEFINER` and uses `set search_path = ''`.
- Provider private keys are not stored in `ai_providers`.
- Secret plaintext is not stored in `bot_secrets`.
- Session plaintext tokens are not stored in `bot_sessions`.
- The bootstrap credential table is private and has no Data API grants.

## Secret design
Registration Secret IDs are intended to be generated and verified server-side. The database stores only a cryptographic hash and safe display metadata. Secret credentials can be scoped to a website, rotated, and revoked.

## Session design
Public chat sessions are intended to use cryptographically random bearer tokens whose hashes are stored in `bot_sessions`. Each session is scoped to a bot and website, has an expiry, and supports revocation. Bot ID alone is never authorization.

## Website/origin design
Website authorization is bound to a normalized origin (`scheme + host + port` where applicable). Client-provided origin signals are not trusted as authorization by themselves; final validation will occur in server-side functions.

## AI provider design
Browsers will never call AI providers directly. Provider credentials will remain in server-side environment/secrets. The browser communicates with Sadeeq AI backend functions, which enforce bot, website, session, usage, and rate-limit checks before invoking a provider.

## Rate limiting and abuse prevention
Rate limits, message-size limits, Secret verification limits, and usage quotas must be enforced server-side. Frontend counters are informational only.

## Audit logging
Security-sensitive actions will be recorded in `security_audit_logs`. Secrets, API keys, authentication tokens, and private customer message content must not be logged.

## Error handling
Public endpoints must return safe, structured errors without SQL details, stack traces, internal file paths, provider credentials, or service-role information.

## Threat model priorities
The implementation must explicitly defend against:
- Bot ID-only authorization;
- forged/spoofed origins;
- Secret brute force;
- replay of expired/revoked tickets;
- frontend manipulation;
- rate-limit bypass;
- unauthorized provider access;
- XSS/injection;
- accidental secret disclosure;
- revoked website access;
- disabled/suspended bot access.

## Level 2 boundary
Level 2 establishes real owner authentication and authorization. Public bot/website registration, session issuance, rate limiting, and provider execution remain deferred to later levels so they can be implemented behind the complete server-side authorization boundary rather than as client-side shortcuts.
