-- =============================================================================
-- Phase 5 — Social graph
-- =============================================================================

-- ---------------------------------------------------------------------------
-- follows
-- Composite PK prevents duplicate follows. CHECK prevents self-follows.
-- ---------------------------------------------------------------------------
create table public.follows (
  follower_id  uuid        not null references auth.users(id) on delete cascade,
  following_id uuid        not null references auth.users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

-- Indexes
create index idx_follows_follower_id  on public.follows(follower_id);
create index idx_follows_following_id on public.follows(following_id);
create index idx_follows_created_at   on public.follows(created_at);

-- RLS
alter table public.follows enable row level security;

-- Any authenticated user can read the social graph (needed for follower counts
-- and "is this person following me?" checks).
create policy "follows: authenticated users can read"
  on public.follows for select
  to authenticated
  using (true);

-- Users can only create follow relationships where they are the follower.
create policy "follows: owner can insert"
  on public.follows for insert
  to authenticated
  with check (follower_id = auth.uid());

-- Users can only remove follow relationships where they are the follower.
create policy "follows: owner can delete"
  on public.follows for delete
  to authenticated
  using (follower_id = auth.uid());

-- updated_at trigger not needed on follows (immutable after insert).
