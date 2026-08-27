# Sadeeq AI V2 — Progress

## Workflow rule
Each level must be implemented, reviewed, tested, security-checked, regression-checked, documented, and explicitly approved before the next level starts.

## Levels
- [ ] Level 0 — Repository & architecture foundation
- [x] Level 1 — Supabase + database foundation
- [ ] Level 2 — Owner authentication & authorization
- [ ] Level 3 — Owner Console shell
- [ ] Level 4 — Bot management
- [ ] Level 5 — Secret & website security foundation
- [ ] Level 6 — Secure session/ticket system
- [ ] Level 7 — Public iframe runtime
- [ ] Level 8 — AI provider runtime
- [ ] Level 9 — Production chat runtime
- [ ] Level 10 — Owner tools & real analytics
- [ ] Level 11 — Security hardening & abuse protection
- [ ] Level 12 — Full E2E, regression & production release

## Level 1 status
**COMPLETE.**

### Implemented
- Clean V2 database foundation in Supabase project `Sadeeq bot`.
- Owner, bot, website, secret, session, provider, usage, and security-audit entities.
- UUID primary keys and public Bot IDs.
- Lifecycle enums and database constraints.
- Foreign keys and performance indexes.
- Per-website active Secret uniqueness.
- Server-side owner detection helper.
- RLS enabled on all V2 application tables.
- Deliberate owner-only policies for sensitive data.
- Updated-at triggers for mutable core tables.
- No provider/API secrets stored in the database schema.

### Verification performed
- Confirmed all 8 required application tables exist.
- Confirmed RLS policies exist for all 8 tables.
- Confirmed required indexes exist.
- Confirmed all 7 lifecycle enums exist.
- Confirmed updated-at triggers exist on mutable tables.
- Confirmed anonymous database privileges cannot read `bot_secrets`.
- Confirmed an authenticated user without an owner profile sees zero V2 bot/secret rows under RLS.
- Confirmed the initial migration was reproducible.

## Level 2 status
**IN PROGRESS — implementation complete, final owner bootstrap/E2E verification pending.**

### Implemented
- Centralized Supabase browser client using the publishable key only.
- Persistent/auto-refreshing Supabase Auth sessions with PKCE.
- Owner-only sign-in page.
- Server/database-backed owner authorization check.
- Protected owner route boundary.
- Local logout.
- Password reset request flow.
- Password update flow.
- One-time owner initialization flow protected by a high-entropy bootstrap credential.
- Bootstrap credential stored only as a SHA-256 hash and consumed once.
- Owner bootstrap transaction uses an advisory lock to prevent concurrent initialization races.
- Added missing foreign-key indexes discovered during performance review.
- Sadeeq AI logo asset and private-console branding foundation.
- Hardened bootstrap RPC to return no owner row to the browser.
- Revoked the previously exposed bootstrap credential and replaced it with a fresh credential; plaintext is not stored in Supabase or GitHub.

### Security verification
- Anonymous access to owner data remains blocked.
- Non-owner authenticated sessions are denied and locally signed out.
- `claim_initial_owner` is not executable by `anon`.
- `claim_initial_owner` has a fixed `search_path` and uses a transaction-level advisory lock.
- The bootstrap RPC returns no owner record to the browser.
- The previously exposed bootstrap credential has been invalidated.
- The Supabase Security Advisor warning for the bootstrap function is intentional: it is a narrowly scoped one-time `SECURITY DEFINER` function requiring a high-entropy credential, and it is not usable by `anon`.
- Performance Advisor foreign-key findings were remediated with explicit indexes. Empty-table unused-index notices are expected until real workload exists.

### Remaining Level 2 gates
1. Configure the production Auth Site URL and exact password-reset/owner-initialization redirect URL in Supabase Auth settings.
2. Perform the first owner initialization using the fresh one-time bootstrap credential delivered out-of-band.
3. Verify owner login, non-owner denial, session persistence, logout, password recovery, and protected-route behavior on the deployed GitHub Pages site.
4. Re-run security/performance advisors after final Auth configuration.
5. Perform regression review against Level 1 and confirm Level 3 compatibility.
6. Only then mark Level 2 complete and wait for owner approval before Level 3.

### Important boundary
The `Sadeeq ai` Supabase project is treated as V1/reference and was not modified. V2 uses the clean `Sadeeq bot` project.
