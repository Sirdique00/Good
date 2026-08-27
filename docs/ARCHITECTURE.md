# Sadeeq AI V2 — Architecture

## Product
**Sadeeq AI** is a private owner-controlled AI chatbot platform. V2 is a clean rebuild using the existing GitHub repository as the source of truth and the `Sadeeq bot` Supabase project as the V2 database foundation.

## High-level architecture

```text
Owner Console / Public Iframe
          |
          v
Frontend API boundary
          |
          v
Supabase Edge Functions / server-side runtime
          |
     +----+----+
     |         |
     v         v
 PostgreSQL   AI Provider adapters
 + RLS        + secure provider secrets
```

## Core boundaries
- **Presentation:** responsive HTML/CSS/JavaScript UI; never authoritative for authorization.
- **Application:** feature modules and API clients.
- **Security:** server-side owner checks, origin validation, session/ticket validation, rate limiting, input validation, and audit events.
- **Database:** PostgreSQL with foreign keys, constraints, indexes, and RLS.
- **AI runtime:** server-side provider abstraction; provider keys never reach the browser.
- **Website integration:** iframe identified by public Bot ID; website authorization is origin-bound and Secret-backed only on first authorization.
- **Observability:** usage metadata, provider health, and security audit logs.

## V2 database foundation
The initial schema contains:
`owner_profiles`, `bots`, `bot_secrets`, `bot_websites`, `bot_sessions`, `ai_providers`, `bot_usage`, and `security_audit_logs`.

## Owner authentication flow
```text
Owner Initialization (one time)
  -> Supabase Auth account
  -> email confirmation when enabled
  -> one-time bootstrap credential
  -> claim_initial_owner()
  -> owner_profiles

Normal Login
  -> Supabase Auth password session
  -> RLS-backed owner_profiles check
  -> Owner Console

Unauthorized session
  -> owner check fails
  -> local session sign-out
  -> access denied
```

The browser uses only the Supabase publishable key. Privileged authorization comes from database RLS and the owner profile, not from frontend variables or URL state.

## Public runtime intent
```text
iframe
  -> Bot ID
  -> server determines/validates requesting origin
  -> registered website check
  -> Secret verification only when required
  -> secure short-lived session/ticket
  -> chat runtime
```

Bot ID is public and never acts as a credential.

## Owner runtime intent
```text
Supabase Auth
  -> server-side owner authorization
  -> Owner Console
  -> bot/provider/website/usage/audit operations
```

## V2 development rule
Each level is gated. A level is complete only after implementation, review, tests, security review, regression review, documentation, and explicit owner approval. No later level should silently redesign an earlier security boundary.
