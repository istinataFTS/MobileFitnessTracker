-- =============================================================================
-- One-time cleanup: collapse duplicate (user_id, name) rows on exercises and
-- meals, then add a UNIQUE constraint so duplicates can never re-accumulate.
--
-- Background
-- ----------
-- An earlier client version uploaded seeded "system" exercises with their seed
-- ids alongside user-created copies of the same name. Because the cloud schema
-- has no UNIQUE(user_id, name) constraint, both rows survived in Supabase.
-- The mobile client's local sqlite has UNIQUE(name, COALESCE(owner_user_id, '')),
-- so on every initial-cloud-migration pull the second collision row trips the
-- constraint and aborts sign-in.
--
-- Strategy
-- --------
-- For each (user_id, name) group with >1 rows:
--   1. Pick the most-recently-updated row as the survivor.
--   2. Reassign child rows (workout_sets.exercise_id, nutrition_logs.meal_id)
--      from losers → survivor. Without this the cascading FK on workout_sets
--      would silently delete history.
--   3. Delete the loser rows.
-- Then add UNIQUE(user_id, name) so the cloud rejects future duplicates.
--
-- How to run
-- ----------
-- 1. Open Supabase Dashboard → SQL Editor → New query.
-- 2. Run the DRY-RUN block first to confirm what will be touched.
-- 3. Run the CLEANUP block. It is wrapped in a transaction so any error
--    rolls everything back.
-- 4. Run the CONSTRAINT block to lock the schema against future duplicates.
-- 5. Sign in on the device — the initial cloud migration will now succeed
--    and `requiresInitialCloudMigration` flips off permanently.
-- =============================================================================


-- =============================================================================
-- STEP 1 — DRY RUN (read-only). Run this first and inspect the output.
-- =============================================================================

-- Duplicate exercises grouped by (user_id, name)
with ranked as (
  select id, user_id, name, updated_at,
         row_number() over (
           partition by user_id, name
           order by updated_at desc, id
         ) as rn
  from public.exercises
)
select user_id, name, count(*) as duplicate_count
from ranked
group by user_id, name
having count(*) > 1
order by duplicate_count desc, name;

-- Duplicate meals grouped by (user_id, name)
with ranked as (
  select id, user_id, name, updated_at,
         row_number() over (
           partition by user_id, name
           order by updated_at desc, id
         ) as rn
  from public.meals
)
select user_id, name, count(*) as duplicate_count
from ranked
group by user_id, name
having count(*) > 1
order by duplicate_count desc, name;


-- =============================================================================
-- STEP 2 — CLEANUP (writes). Run this once.
--
-- This is wrapped in a single transaction. If anything fails it all rolls
-- back. To restrict cleanup to one user, add `where user_id = '...'` to the
-- ranked CTEs below.
-- =============================================================================

begin;

-- ---- exercises ------------------------------------------------------------

with ranked as (
  select id, user_id, name, updated_at,
         row_number() over (
           partition by user_id, name
           order by updated_at desc, id
         ) as rn,
         first_value(id) over (
           partition by user_id, name
           order by updated_at desc, id
         ) as winner_id
  from public.exercises
),
losers as (
  select id as loser_id, winner_id
  from ranked
  where rn > 1
)
update public.workout_sets ws
set exercise_id = l.winner_id
from losers l
where ws.exercise_id = l.loser_id;

with ranked as (
  select id, user_id, name, updated_at,
         row_number() over (
           partition by user_id, name
           order by updated_at desc, id
         ) as rn
  from public.exercises
)
delete from public.exercises
where id in (select id from ranked where rn > 1);

-- ---- meals ----------------------------------------------------------------

with ranked as (
  select id, user_id, name, updated_at,
         row_number() over (
           partition by user_id, name
           order by updated_at desc, id
         ) as rn,
         first_value(id) over (
           partition by user_id, name
           order by updated_at desc, id
         ) as winner_id
  from public.meals
),
losers as (
  select id as loser_id, winner_id
  from ranked
  where rn > 1
)
update public.nutrition_logs nl
set meal_id = l.winner_id
from losers l
where nl.meal_id = l.loser_id;

with ranked as (
  select id, user_id, name, updated_at,
         row_number() over (
           partition by user_id, name
           order by updated_at desc, id
         ) as rn
  from public.meals
)
delete from public.meals
where id in (select id from ranked where rn > 1);

commit;


-- =============================================================================
-- STEP 3 — CONSTRAINTS. Prevent the duplicates from coming back.
--
-- Run this only after STEP 2 completes successfully. If it errors with
-- "could not create unique index" there are still duplicates — re-run STEP 1
-- to find them.
-- =============================================================================

alter table public.exercises
  add constraint exercises_user_id_name_key unique (user_id, name);

alter table public.meals
  add constraint meals_user_id_name_key unique (user_id, name);
