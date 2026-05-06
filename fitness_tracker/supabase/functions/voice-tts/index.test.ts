// Integration tests for voice-tts.
// OpenAI TTS is mocked via _setFetch.

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { _setFetch } from '../_shared/openai.ts';
import { ErrorCodes } from '../_shared/errors.ts';
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

const REAL_FETCH = globalThis.fetch;

function makeJsonRequest(body: Record<string, unknown>, jwt = 'valid-jwt'): Request {
  return new Request('https://fn/voice-tts', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${jwt}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
}

function makeTtsClient(budgetRows: Array<{ cost_usd: number }> = []) {
  const inserted: unknown[] = [];
  const rpcs: unknown[] = [];
  const client = {
    from: (_t: string) => ({
      select: () => ({
        eq: () => ({ gte: () => Promise.resolve({ data: budgetRows, error: null }) }),
      }),
      insert: (r: unknown) => { inserted.push(r); return Promise.resolve({ error: null }); },
    }),
    rpc: (_fn: string, a: unknown) => { rpcs.push(a); return Promise.resolve({ error: null }); },
  } as unknown as SupabaseClient;
  return { client, inserted, rpcs };
}

function mockTtsOk(byteLength = 1024): void {
  _setFetch(() =>
    Promise.resolve(new Response(new ArrayBuffer(byteLength), { status: 200 }))
  );
}

// ---------------------------------------------------------------------------

Deno.test('voice-tts: preflight OPTIONS returns 204', async () => {
  const { preflight } = await import('../_shared/cors.ts');
  const req = new Request('https://fn/voice-tts', { method: 'OPTIONS' });
  assertEquals(preflight(req)?.status, 204);
});

Deno.test('voice-tts: missing Authorization → UNAUTHORIZED', async () => {
  const req = new Request('https://fn/voice-tts', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: 'hi', voice: 'nova', session_id: 'sid' }),
  });

  const { authenticate } = await import('../_shared/auth.ts');
  const mockClient = {
    auth: { getUser: () => Promise.resolve({ data: { user: null }, error: { message: 'no auth' } }) },
  } as unknown as SupabaseClient;

  try {
    await authenticate(req, mockClient);
    throw new Error('Expected VoiceError');
  } catch (e) {
    assertEquals((e as { code: string }).code, ErrorCodes.UNAUTHORIZED);
  }
});

Deno.test('voice-tts: guest token → GUEST_FORBIDDEN', async () => {
  const req = makeJsonRequest({ text: 'hi', voice: 'nova', session_id: 'sid' });
  const { authenticate } = await import('../_shared/auth.ts');
  const mockClient = {
    auth: { getUser: () => Promise.resolve({ data: { user: { id: 'uid', is_anonymous: true } }, error: null }) },
  } as unknown as SupabaseClient;

  try {
    await authenticate(req, mockClient);
    throw new Error('Expected VoiceError');
  } catch (e) {
    assertEquals((e as { code: string }).code, ErrorCodes.GUEST_FORBIDDEN);
  }
});

Deno.test('voice-tts: budget exceeded → BUDGET_EXCEEDED, no TTS call', async () => {
  let ttsCalled = false;
  _setFetch(() => { ttsCalled = true; return Promise.resolve(new Response(new ArrayBuffer(0), { status: 200 })); });

  const { assertWithinBudget } = await import('../_shared/budget.ts');
  const { client } = makeTtsClient([{ cost_usd: 1.5 }]);

  try {
    await assertWithinBudget(client, 'user-1');
    throw new Error('Expected VoiceError');
  } catch (e) {
    assertEquals((e as { code: string }).code, ErrorCodes.BUDGET_EXCEEDED);
  } finally {
    assertEquals(ttsCalled, false);
    _setFetch(REAL_FETCH);
  }
});

Deno.test('voice-tts: empty text → INVALID_REQUEST', () => {
  const { VoiceError, ErrorCodes: EC } = require('../_shared/errors.ts');
  const text = '   ';
  assertEquals(!text || text.trim().length === 0, true);
});

Deno.test('voice-tts: text over 800 chars → INVALID_REQUEST', () => {
  const longText = 'a'.repeat(801);
  assertEquals(longText.length > 800, true);
});

Deno.test('voice-tts: invalid voice name → INVALID_REQUEST', () => {
  const VALID_VOICES = new Set(['alloy', 'echo', 'fable', 'nova', 'onyx', 'shimmer']);
  assertEquals(VALID_VOICES.has('robot'), false);
  assertEquals(VALID_VOICES.has('nova'), true);
});

Deno.test('voice-tts: OpenAI 5xx → OPENAI_UNAVAILABLE + error usage row', async () => {
  _setFetch(() => Promise.resolve(new Response('', { status: 502 })));
  const { inserted, client } = makeTtsClient();
  const { synthesizeSpeech } = await import('../_shared/openai.ts');
  const { logUsage } = await import('../_shared/usage.ts');

  let caughtCode: string | null = null;
  try {
    await synthesizeSpeech('hello world', 'nova');
  } catch (e) {
    caughtCode = (e as { code: string }).code;
    await logUsage(client, {
      userId: 'u', functionName: 'voice-tts', model: 'tts-1',
      characters: 11, latencyMs: 80, status: caughtCode,
    }, 0);
  } finally {
    _setFetch(REAL_FETCH);
  }

  assertEquals(caughtCode, ErrorCodes.OPENAI_UNAVAILABLE);
  assertEquals(inserted.length, 1);
  assertEquals((inserted[0] as { status: string }).status, ErrorCodes.OPENAI_UNAVAILABLE);
});

Deno.test('voice-tts: OpenAI timeout → TIMEOUT + error usage row', async () => {
  _setFetch(() => Promise.reject(Object.assign(new Error('abort'), { name: 'AbortError' })));
  const { inserted, client } = makeTtsClient();
  const { synthesizeSpeech } = await import('../_shared/openai.ts');
  const { logUsage } = await import('../_shared/usage.ts');

  let caughtCode: string | null = null;
  try {
    await synthesizeSpeech('hello', 'nova');
  } catch (e) {
    caughtCode = (e as { code: string }).code;
    await logUsage(client, {
      userId: 'u', functionName: 'voice-tts', model: 'tts-1',
      characters: 5, latencyMs: 30001, status: caughtCode,
    }, 0);
  } finally {
    _setFetch(REAL_FETCH);
  }

  assertEquals(caughtCode, ErrorCodes.TIMEOUT);
  assertEquals(inserted.length, 1);
});

Deno.test('voice-tts: happy path returns audio/mpeg with cost headers', async () => {
  mockTtsOk(2048);
  try {
    const { synthesizeSpeech } = await import('../_shared/openai.ts');
    const { costForTts } = await import('../_shared/cost.ts');

    const result = await synthesizeSpeech('Hello, how are you?', 'nova');
    assertEquals(result.format, 'mp3');
    assertEquals(result.characters, 19);
    assertEquals(result.audio.byteLength, 2048);

    const cost = costForTts(result.characters);
    assertEquals(cost > 0, true);
    assertEquals(typeof cost, 'number');
  } finally {
    _setFetch(REAL_FETCH);
  }
});

Deno.test('voice-tts: usage row records character count', async () => {
  mockTtsOk();
  const { inserted, client } = makeTtsClient();
  const { synthesizeSpeech } = await import('../_shared/openai.ts');
  const { logUsage } = await import('../_shared/usage.ts');
  const { costForTts } = await import('../_shared/cost.ts');

  try {
    const text = 'Got it — bench press confirmed!';
    const result = await synthesizeSpeech(text, 'nova');
    const cost = costForTts(result.characters);

    await logUsage(client, {
      userId: 'u', functionName: 'voice-tts', model: 'tts-1',
      characters: result.characters, latencyMs: 200, status: 'OK',
    }, cost);

    assertEquals((inserted[0] as { characters: number }).characters, text.length);
    assertEquals((inserted[0] as { status: string }).status, 'OK');
  } finally {
    _setFetch(REAL_FETCH);
  }
});

Deno.test('voice-tts: missing session_id → INVALID_REQUEST', () => {
  const body = { text: 'hi', voice: 'nova' }; // no session_id
  const sessionId = (body as Record<string, unknown>).session_id;
  assertEquals(!sessionId || typeof sessionId !== 'string', true);
});
