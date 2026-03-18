# ADR 0001: Supabase target architecture

## Status

Accepted

## Date

2026-03-18

## Context

The codebase is no longer purely local-first in practice.

Several repository implementations already use the shape:

- local datasource
- remote datasource
- sync coordinator

This pattern is already present for workouts, meals, nutrition logs, and targets, even though the current remote implementations are still no-op placeholders.

The app also already has an application-level session boundary:

- guest session support exists
- authenticated session support exists
- initial cloud migration state exists
- cloud sync state exists

There is also already an explicit sync policy object that says:

- offline-first
- local writes are accepted
- remote is the source of truth when authenticated
- guest mode uses local storage only
- authenticated mode uses user-scoped data
- initial sign-in uploads local data
- conflict strategy is server-wins

That means the architectural direction is already partially encoded in the codebase, but it is still too easy for future work to treat Supabase as optional or hypothetical.

This ADR makes the target explicit so future milestones can implement toward a stable destination.

## Decision

### 1. Backend direction

Supabase is the primary backend target for the application.

This means:

- authenticated app data is ultimately backed by Supabase
- Supabase auth is the authentication boundary for signed-in users
- repositories remain the app-facing contract above backend details
- widgets, pages, and blocs must not depend directly on raw Supabase SDK APIs

### 2. Repository boundary

Repositories remain the only app-facing persistence contract.

Application and presentation code should depend on repository interfaces and use cases, not on:

- table names
- SQL rows
- Supabase query builders
- raw transport DTOs

Repository contracts should continue to express business operations such as:

- add workout set
- get logs for date
- update target
- load meals

and not database-shaped CRUD around backend tables.

### 3. Local storage role

Local storage is not the long-term primary source of truth for authenticated users.

Its role is:

- guest-mode primary store
- authenticated offline store / cache
- write buffer for offline-first behavior
- transitional migration layer for existing SQLite-backed installs

For authenticated users, local storage exists to support responsiveness, offline behavior, and migration safety.

For authenticated users, local storage does not define truth over Supabase.

### 4. Auth boundary

Auth and session ownership live in core app session infrastructure, not feature code.

This means:

- session state is owned centrally
- user identity is resolved before repository calls need user scope
- repositories and sync flows operate using authenticated user scope
- UI code does not decide storage ownership rules

Feature modules should not invent their own auth/session rules.

### 5. Guest mode

Guest mode remains supported for now.

Guest mode behavior:

- uses local storage only
- does not write to Supabase
- does not pretend local guest data is already cloud-owned
- may be migrated into the user account on first authenticated session

The first authenticated session should support explicit migration of local guest data into the authenticated cloud-backed account.

### 6. Source of truth after login

After login, Supabase becomes the source of truth for user-owned data.

This applies to:

- workouts
- nutrition logs
- meals
- targets

History is treated as user-scoped derived data built from user-owned records, not as an independent source of truth.

Local authenticated copies may exist, but they are cache/offline representations of cloud-owned data.

### 7. User-scoped feature ownership

The following features are user-scoped in authenticated mode:

- workouts
- nutrition logs
- meals
- targets
- history

Ownership semantics:

- workouts belong to a user
- nutrition logs belong to a user
- meals belong to a user
- targets belong to a user
- history belongs to a user logically, but should be derived from that user’s underlying records where practical

This ADR does not require every feature to migrate immediately.
It defines the ownership model that future migrations must follow.

### 8. Sync expectations

The app target is offline-first authenticated behavior with repository-managed sync.

Initial expectations:

- local writes remain allowed
- repositories coordinate local + remote behavior
- successful remote writes should update or confirm local state
- failed remote writes should leave recoverable local state
- sync retry/queue behavior is allowed behind repository and coordinator boundaries
- conflict handling defaults to server-wins unless a feature later requires more specific rules

This ADR defines the target behavior, not the full implementation detail for every feature.

### 9. Migration posture for existing local users

Existing local-only users must not be broken by the Supabase migration.

The migration posture is:

- preserve guest/local flows while Supabase rolls out
- support initial upload/migration when a user authenticates
- avoid forcing presentation code to care about migration state
- keep migration orchestration at session/repository/sync boundaries

## Consequences

### Positive

- Supabase is no longer treated as a maybe-later backend
- repository boundaries stay valuable
- future entity and DTO work can align to a known target
- sync decisions can be implemented incrementally without changing presentation architecture
- guest mode has an explicit, limited role

### Trade-offs

- maintaining guest mode increases migration complexity
- repositories will need clearer remote/local merge behavior
- local tables must stop assuming purely local identity semantics
- some current local-first assumptions will need to be tightened in later milestones

## Non-goals

This ADR does not:

- implement the Supabase client
- define final table schemas
- finalize every sync edge case
- migrate all existing features immediately

Those belong to later milestones.

## Follow-up implications

This ADR directly drives the next milestones:

- domain entities need stable IDs, timestamps, and user ownership
- DTO boundaries must stay separate from domain entities
- remote datasource implementations should replace no-op placeholders
- repository implementations should continue to hide backend details
- one vertical slice should prove the end-to-end pattern before broad migration