-- Migration: drop the targets table
--
-- The Targets feature has been removed from the application.
-- Drop all dependent objects (policies, trigger, indexes) before the table
-- so the migration is safe to re-run (all statements use IF EXISTS).

-- Policies must be dropped first — they depend on the table.
drop policy if exists "targets: owner select" on public.targets;
drop policy if exists "targets: owner insert" on public.targets;
drop policy if exists "targets: owner update" on public.targets;
drop policy if exists "targets: owner delete" on public.targets;

-- Trigger (the function is shared; only the per-table trigger is dropped).
drop trigger if exists trg_targets_updated_at on public.targets;

-- Indexes are dropped implicitly with the table, but listed for clarity.
-- drop index if exists public.idx_targets_user_id;
-- drop index if exists public.idx_targets_updated_at;

-- Drop the table itself.
drop table if exists public.targets;
