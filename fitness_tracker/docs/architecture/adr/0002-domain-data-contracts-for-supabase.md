# ADR 0002: Domain and data contracts for Supabase-backed storage

## Status

Accepted

## Date

2026-03-18

## Context

The domain entities for workouts, meals, nutrition logs, and targets already use stable string IDs, timestamps, and sync metadata.

However, the current data layer still has an architectural leak:
local persistence models are also being used as broad serialization shapes, and the project does not yet have a dedicated cloud DTO layer for Supabase-backed records.

That creates two risks:

1. domain entities can drift toward backend row shapes
2. future Supabase code may couple directly to widgets, blocs, or repositories without a dedicated transport boundary

## Decision

### 1. Domain entities stay domain-first

User-owned domain entities must express business meaning first.

They may include:

- stable app-facing ID
- ownerUserId
- business fields
- createdAt
- updatedAt
- syncMetadata

They must not become direct table-row definitions.

### 2. User ownership is explicit

The following domain entities are user-owned and therefore include `ownerUserId`:

- WorkoutSet
- Meal
- NutritionLog
- Target

This field is nullable so existing local-only flows remain compatible during transition.

Authenticated Supabase-backed flows should treat it as required.

### 3. Local models are storage adapters, not the cloud contract

SQLite/local models remain local persistence adapters.

They may serialize local fields and sync metadata, but they are not the canonical representation of Supabase rows.

### 4. Supabase DTOs are separate from domain entities

Supabase-backed transport must use dedicated DTOs.

Those DTOs are responsible for:

- snake_case backend field mapping
- user_id ownership mapping
- converting backend timestamps
- translating between server IDs and domain sync metadata

### 5. Repository contracts stay business-oriented

Repositories should continue to expose business operations.

They should not expose raw table CRUD or Supabase query details directly to the app layer.

## Consequences

### Positive

- domain entities are clearer and more future-safe
- user scoping is now part of the model contract
- Supabase mapping has an explicit home
- later remote datasource work can build on DTOs instead of leaking backend rows upward

### Trade-offs

- there is temporary overlap between local model serializers and new Supabase DTOs
- existing local storage still needs migration work before ownership becomes fully enforced in storage

## Follow-up

This ADR prepares Milestone 4.

The next implementation step is to:
- wire Supabase client/auth
- add remote datasource implementations that use the new DTOs
- incrementally add owner-user handling to local persistence and migration flows