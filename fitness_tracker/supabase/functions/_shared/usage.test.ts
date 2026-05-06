import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { logUsage } from './usage.ts';
import { PRICING_VERSION } from './cost.ts';
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

function makeInsertClient(onInsert: (payload: Record<string, unknown>) => { error: unknown }) {
  return {
    from: (_table: string) => ({
      insert: (payload: Record<string, unknown>) => onInsert(payload),
    }),
  } as unknown as SupabaseClient;
}

Deno.test('logUsage: inserts row with correct shape', async () => {
  let captured: Record<string, unknown> | null = null;
  const client = makeInsertClient((p) => {
    captured = p;
    return { error: null };
  });

  await logUsage(
    client,
    {
      userId: 'user-1',
      functionName: 'voice-stt',
      model: 'whisper-1',
      audioSeconds: 4.5,
      latencyMs: 320,
      sessionId: 'session-uuid',
      status: 'OK',
    },
    0.00045,
  );

  assertEquals(captured?.user_id, 'user-1');
  assertEquals(captured?.function_name, 'voice-stt');
  assertEquals(captured?.model, 'whisper-1');
  assertEquals(captured?.audio_seconds, 4.5);
  assertEquals(captured?.cost_usd, 0.00045);
  assertEquals(captured?.pricing_version, PRICING_VERSION);
  assertEquals(captured?.latency_ms, 320);
  assertEquals(captured?.session_id, 'session-uuid');
  assertEquals(captured?.status, 'OK');
  assertEquals(captured?.input_tokens, null);
  assertEquals(captured?.output_tokens, null);
  assertEquals(captured?.characters, null);
});

Deno.test('logUsage: DB error is swallowed (no throw)', async () => {
  const consoleSpy: unknown[] = [];
  const originalError = console.error;
  console.error = (...args: unknown[]) => consoleSpy.push(args);

  try {
    const client = makeInsertClient(() => ({ error: { message: 'insert failed' } }));
    // Should not throw
    await logUsage(client, {
      userId: 'u', functionName: 'voice-chat', model: 'gpt-4o-mini-2024-07-18',
      inputTokens: 100, outputTokens: 50, latencyMs: 200, status: 'INTERNAL',
    }, 0);
    assertEquals(consoleSpy.length > 0, true, 'Expected console.error to be called');
  } finally {
    console.error = originalError;
  }
});

Deno.test('logUsage: optional metrics are null when not provided', async () => {
  let captured: Record<string, unknown> | null = null;
  const client = makeInsertClient((p) => { captured = p; return { error: null }; });

  await logUsage(client, {
    userId: 'u', functionName: 'voice-tts', model: 'tts-1', latencyMs: 100, status: 'OK',
  }, 0.001);

  assertEquals(captured?.input_tokens, null);
  assertEquals(captured?.output_tokens, null);
  assertEquals(captured?.audio_seconds, null);
  assertEquals(captured?.session_id, null);
});
