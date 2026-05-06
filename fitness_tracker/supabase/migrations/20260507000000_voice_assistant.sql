-- Migration: voice assistant tables
--
-- Introduces voice_usage_log (always written per OpenAI call) and
-- voice_sessions (opt-in full transcripts). All writes are performed
-- by Edge Functions using the service-role key. Authenticated users
-- have SELECT only on both tables; owner DELETE on voice_sessions for
-- privacy-erasure support.
--
-- Safe to re-run: all statements use IF EXISTS / IF NOT EXISTS.

-- ---------------------------------------------------------------------------
-- voice_usage_log — per-call OpenAI cost + metadata, always written
-- ---------------------------------------------------------------------------
create table if not exists public.voice_usage_log (
  id              uuid          primary key default gen_random_uuid(),
  user_id         uuid          not null references auth.users(id) on delete cascade,

  -- Which Edge Function recorded this row.
  function_name   text          not null
                                  check (function_name in ('voice-stt', 'voice-chat', 'voice-tts')),

  -- OpenAI model identifier verbatim (e.g. 'whisper-1', 'gpt-4o-mini-2024-07-18', 'tts-1').
  model           text          not null,

  -- Pricing-unit fields; null means not applicable for this function.
  input_tokens    integer       null check (input_tokens    is null or input_tokens    >= 0),
  output_tokens   integer       null check (output_tokens   is null or output_tokens   >= 0),
  audio_seconds   numeric(10,3) null check (audio_seconds   is null or audio_seconds   >= 0),
  characters      integer       null check (characters      is null or characters      >= 0),

  -- Computed cost in USD (6-decimal precision matches OpenAI's billing unit).
  -- NEVER NULL: failed calls record 0.
  cost_usd        numeric(10,6) not null default 0 check (cost_usd >= 0),

  -- Bumped in _shared/cost.ts on every OpenAI price change so historical rows
  -- remain reconcilable.
  pricing_version text          not null,

  -- End-to-end latency observed inside the Edge Function (Deno performance.now).
  latency_ms      integer       not null check (latency_ms >= 0),

  -- Optional grouping: same session_id across stt→chat→tts triplet.
  session_id      uuid          null,

  -- 'OK' for successful calls; structured error code otherwise.
  status          text          not null default 'OK',

  created_at      timestamptz   not null default now()
);

create index if not exists idx_voice_usage_log_user_created
  on public.voice_usage_log (user_id, created_at desc);

-- Used by the budget query: sum today's spend for a user.
create index if not exists idx_voice_usage_log_user_day
  on public.voice_usage_log (user_id, (date_trunc('day', created_at)));

alter table public.voice_usage_log enable row level security;

-- Owner-only SELECT (used by the in-app remaining-budget meter).
-- NO insert/update/delete policies for authenticated — all writes are service-role.
create policy "voice_usage_log: owner select"
  on public.voice_usage_log for select
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- voice_sessions — opt-in full transcripts
-- ---------------------------------------------------------------------------
create table if not exists public.voice_sessions (
  id              uuid          primary key,   -- client-generated session UUID
  user_id         uuid          not null references auth.users(id) on delete cascade,

  started_at      timestamptz   not null default now(),
  ended_at        timestamptz   null,

  -- Append-only conversation log. Each element:
  --   { "role": "user"|"assistant"|"tool", "content": "...", "tool_call": {...} }
  transcript      jsonb         not null default '[]'::jsonb,

  turn_count      integer       not null default 0  check (turn_count     >= 0),
  total_cost_usd  numeric(10,6) not null default 0  check (total_cost_usd >= 0),

  outcome         text          null
                                  check (outcome is null
                                         or outcome in ('completed','cancelled','budget_exceeded','error')),

  created_at      timestamptz   not null default now(),
  updated_at      timestamptz   not null default now()
);

create index if not exists idx_voice_sessions_user_started
  on public.voice_sessions (user_id, started_at desc);

create trigger trg_voice_sessions_updated_at
  before update on public.voice_sessions
  for each row execute function public.set_updated_at();

alter table public.voice_sessions enable row level security;

-- Owner SELECT — for reading session history / cost totals.
create policy "voice_sessions: owner select"
  on public.voice_sessions for select
  to authenticated
  using (user_id = auth.uid());

-- Owner DELETE — lets users erase their voice history from C-2's privacy screen.
-- All writes (insert/update) are service-role only.
create policy "voice_sessions: owner delete"
  on public.voice_sessions for delete
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Helper: atomic append of one turn to a voice session.
-- Called from _shared/session.ts using the service-role client.
-- Security DEFINER so the function executes with owner (postgres) privileges
-- and can bypass RLS on voice_sessions.
-- ---------------------------------------------------------------------------
create or replace function public.voice_session_append_turn(
  p_session_id    uuid,
  p_user_id       uuid,
  p_turn          jsonb,
  p_cost_usd      numeric
) returns void
language plpgsql
security definer
as $$
begin
  insert into public.voice_sessions (id, user_id, transcript, turn_count, total_cost_usd)
  values (
    p_session_id,
    p_user_id,
    jsonb_build_array(p_turn),
    1,
    p_cost_usd
  )
  on conflict (id) do update set
    transcript     = voice_sessions.transcript || jsonb_build_array(p_turn),
    turn_count     = voice_sessions.turn_count + 1,
    total_cost_usd = voice_sessions.total_cost_usd + p_cost_usd,
    updated_at     = now();
end;
$$;
