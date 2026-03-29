-- =============================================================================
-- Fitness Tracker — Supabase Schema
-- =============================================================================
-- Run this in the Supabase SQL editor (Dashboard → SQL → New query).
-- Tables are created in dependency order so FK constraints resolve cleanly:
--   user_profiles → exercises → meals → workout_sets → nutrition_logs → targets
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------------
-- user_profiles
-- Mirrors the username / display_name written to auth.users metadata on sign-up.
-- Authenticated users can read any profile so that social lookups work later.
-- ---------------------------------------------------------------------------
create table public.user_profiles (
  id           uuid        primary key references auth.users(id) on delete cascade,
  username     text        not null unique,
  display_name text,
  bio          text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- exercises
-- ---------------------------------------------------------------------------
create table public.exercises (
  id            uuid        primary key default uuid_generate_v4(),
  user_id       uuid        not null references auth.users(id) on delete cascade,
  name          text        not null,
  muscle_groups text[]      not null default '{}',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  -- Per-user uniqueness (global UNIQUE is too strict in a multi-tenant schema)
  unique(user_id, name)
);

-- ---------------------------------------------------------------------------
-- meals
-- ---------------------------------------------------------------------------
create table public.meals (
  id                 uuid             primary key default uuid_generate_v4(),
  user_id            uuid             not null references auth.users(id) on delete cascade,
  name               text             not null,
  serving_size_grams double precision not null default 100.0,
  carbs_per_100g     double precision not null,
  protein_per_100g   double precision not null,
  fat_per_100g       double precision not null,
  calories_per_100g  double precision not null,
  created_at         timestamptz      not null default now(),
  updated_at         timestamptz      not null default now(),
  unique(user_id, name)
);

-- ---------------------------------------------------------------------------
-- workout_sets
-- exercise_id is a hard FK — exercises must be synced before sets.
-- ---------------------------------------------------------------------------
create table public.workout_sets (
  id           uuid             primary key default uuid_generate_v4(),
  user_id      uuid             not null references auth.users(id)      on delete cascade,
  exercise_id  uuid             not null references public.exercises(id) on delete cascade,
  reps         integer          not null,
  weight       double precision not null,
  intensity    integer          not null default 5,
  performed_at timestamptz      not null,
  created_at   timestamptz      not null default now(),
  updated_at   timestamptz      not null default now()
);

-- ---------------------------------------------------------------------------
-- nutrition_logs
-- meal_id is soft (nullable). Logs denormalise meal_name so they survive meal
-- deletion — hence ON DELETE CASCADE rather than SET NULL, matching local SQLite.
-- ---------------------------------------------------------------------------
create table public.nutrition_logs (
  id             uuid             primary key default uuid_generate_v4(),
  user_id        uuid             not null references auth.users(id) on delete cascade,
  meal_id        uuid             references public.meals(id)         on delete cascade,
  meal_name      text             not null default '',
  grams_consumed double precision,
  protein_grams  double precision not null,
  carbs_grams    double precision not null,
  fat_grams      double precision not null,
  calories       double precision not null,
  logged_at      timestamptz      not null,
  created_at     timestamptz      not null default now(),
  updated_at     timestamptz      not null default now()
);

-- ---------------------------------------------------------------------------
-- targets
-- Unique per user + type + category_key + period (e.g. weekly protein goal).
-- ---------------------------------------------------------------------------
create table public.targets (
  id           uuid             primary key default uuid_generate_v4(),
  user_id      uuid             not null references auth.users(id) on delete cascade,
  type         text             not null, -- 'muscle_sets' | 'macro'
  category_key text             not null,
  target_value double precision not null,
  unit         text             not null,
  period       text             not null, -- 'daily' | 'weekly'
  created_at   timestamptz      not null default now(),
  updated_at   timestamptz      not null default now(),
  unique(user_id, type, category_key, period)
);

-- =============================================================================
-- Indexes
-- =============================================================================

-- user_profiles
create index idx_user_profiles_username   on public.user_profiles(username);
create index idx_user_profiles_updated_at on public.user_profiles(updated_at);

-- exercises
create index idx_exercises_user_id    on public.exercises(user_id);
create index idx_exercises_name       on public.exercises(name);
create index idx_exercises_updated_at on public.exercises(updated_at);

-- meals
create index idx_meals_user_id    on public.meals(user_id);
create index idx_meals_name       on public.meals(name);
create index idx_meals_updated_at on public.meals(updated_at);

-- workout_sets
create index idx_workout_sets_user_id      on public.workout_sets(user_id);
create index idx_workout_sets_exercise_id  on public.workout_sets(exercise_id);
create index idx_workout_sets_performed_at on public.workout_sets(performed_at);
create index idx_workout_sets_updated_at   on public.workout_sets(updated_at);

-- nutrition_logs
create index idx_nutrition_logs_user_id    on public.nutrition_logs(user_id);
create index idx_nutrition_logs_meal_id    on public.nutrition_logs(meal_id);
create index idx_nutrition_logs_logged_at  on public.nutrition_logs(logged_at);
create index idx_nutrition_logs_updated_at on public.nutrition_logs(updated_at);

-- targets
create index idx_targets_user_id      on public.targets(user_id);
create index idx_targets_type_period  on public.targets(type, period);
create index idx_targets_category_key on public.targets(category_key);
create index idx_targets_updated_at   on public.targets(updated_at);

-- =============================================================================
-- Row Level Security
-- =============================================================================
alter table public.user_profiles  enable row level security;
alter table public.exercises      enable row level security;
alter table public.meals          enable row level security;
alter table public.workout_sets   enable row level security;
alter table public.nutrition_logs enable row level security;
alter table public.targets        enable row level security;

-- ---------------------------------------------------------------------------
-- user_profiles policies
-- Any authenticated user can read profiles — required for social lookups.
-- Only the owner can write their own row.
-- ---------------------------------------------------------------------------
create policy "user_profiles: authenticated users can read"
  on public.user_profiles for select
  to authenticated
  using (true);

create policy "user_profiles: owner can insert"
  on public.user_profiles for insert
  to authenticated
  with check (id = auth.uid());

create policy "user_profiles: owner can update"
  on public.user_profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create policy "user_profiles: owner can delete"
  on public.user_profiles for delete
  to authenticated
  using (id = auth.uid());

-- ---------------------------------------------------------------------------
-- exercises policies
-- ---------------------------------------------------------------------------
create policy "exercises: owner can select"
  on public.exercises for select
  to authenticated
  using (user_id = auth.uid());

create policy "exercises: owner can insert"
  on public.exercises for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "exercises: owner can update"
  on public.exercises for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "exercises: owner can delete"
  on public.exercises for delete
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- meals policies
-- ---------------------------------------------------------------------------
create policy "meals: owner can select"
  on public.meals for select
  to authenticated
  using (user_id = auth.uid());

create policy "meals: owner can insert"
  on public.meals for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "meals: owner can update"
  on public.meals for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "meals: owner can delete"
  on public.meals for delete
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- workout_sets policies
-- ---------------------------------------------------------------------------
create policy "workout_sets: owner can select"
  on public.workout_sets for select
  to authenticated
  using (user_id = auth.uid());

create policy "workout_sets: owner can insert"
  on public.workout_sets for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "workout_sets: owner can update"
  on public.workout_sets for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "workout_sets: owner can delete"
  on public.workout_sets for delete
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- nutrition_logs policies
-- ---------------------------------------------------------------------------
create policy "nutrition_logs: owner can select"
  on public.nutrition_logs for select
  to authenticated
  using (user_id = auth.uid());

create policy "nutrition_logs: owner can insert"
  on public.nutrition_logs for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "nutrition_logs: owner can update"
  on public.nutrition_logs for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "nutrition_logs: owner can delete"
  on public.nutrition_logs for delete
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- targets policies
-- ---------------------------------------------------------------------------
create policy "targets: owner can select"
  on public.targets for select
  to authenticated
  using (user_id = auth.uid());

create policy "targets: owner can insert"
  on public.targets for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "targets: owner can update"
  on public.targets for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "targets: owner can delete"
  on public.targets for delete
  to authenticated
  using (user_id = auth.uid());

-- =============================================================================
-- updated_at auto-maintenance trigger
-- A single function shared by all tables keeps the schema DRY.
-- =============================================================================
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_user_profiles_updated_at
  before update on public.user_profiles
  for each row execute function public.set_updated_at();

create trigger trg_exercises_updated_at
  before update on public.exercises
  for each row execute function public.set_updated_at();

create trigger trg_meals_updated_at
  before update on public.meals
  for each row execute function public.set_updated_at();

create trigger trg_workout_sets_updated_at
  before update on public.workout_sets
  for each row execute function public.set_updated_at();

create trigger trg_nutrition_logs_updated_at
  before update on public.nutrition_logs
  for each row execute function public.set_updated_at();

create trigger trg_targets_updated_at
  before update on public.targets
  for each row execute function public.set_updated_at();
