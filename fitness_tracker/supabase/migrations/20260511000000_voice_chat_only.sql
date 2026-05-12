-- Migration: narrow voice_usage_log to voice-chat only
--
-- STT (Whisper) and TTS (OpenAI TTS-1) have been replaced by device-native
-- equivalents (Android SpeechRecognizer / iOS SFSpeechRecognizer for STT;
-- Android TextToSpeech / iOS AVSpeechSynthesizer for TTS). Only the LLM
-- call (voice-chat / GPT-4o-mini) incurs server cost and writes to this
-- table. The voice-stt and voice-tts Edge Functions have been deleted.
--
-- Safe to re-run: all statements use IF EXISTS / DO $$ blocks.

-- Drop the unused audio/character columns.
alter table public.voice_usage_log drop column if exists audio_seconds;
alter table public.voice_usage_log drop column if exists characters;

-- Replace the function_name check constraint to only allow 'voice-chat'.
-- The original constraint was auto-named by Postgres; drop it defensively
-- regardless of its exact name by re-adding the column constraint inline.
do $$
begin
  -- Remove old constraint if it exists under the standard auto-generated name.
  if exists (
    select 1 from pg_constraint
    where conrelid = 'public.voice_usage_log'::regclass
      and conname  = 'voice_usage_log_function_name_check'
  ) then
    alter table public.voice_usage_log
      drop constraint voice_usage_log_function_name_check;
  end if;
end;
$$;

alter table public.voice_usage_log
  add constraint voice_usage_log_function_name_check
  check (function_name in ('voice-chat'));
