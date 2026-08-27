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
**COMPLETE — pending owner approval to begin Level 2.**

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
- Confirmed Supabase migration history was initially empty before Level 1.

### Important boundary
The `Sadeeq ai` Supabase project is treated as V1/reference and was not modified. V2 uses the clean `Sadeeq bot` project.

### Next level
Level 2 will not start until the owner explicitly authorizes it.
