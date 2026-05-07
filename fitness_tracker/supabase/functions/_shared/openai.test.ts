import { assertEquals, assertRejects } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import {
  transcribeAudio,
  completeChat,
  synthesizeSpeech,
  _setFetch,
} from './openai.ts';
import { ErrorCodes, VoiceError } from './errors.ts';

// Ensure the API-key env var is set for the bulk of tests below.
// `getApiKey()` now fails fast when the env var is missing, so without this
// shim every existing test would error before reaching the mocked fetch.
// The dedicated "missing key" test deletes and restores this value.
if (!Deno.env.get('OPENAI_API_KEY')) {
  Deno.env.set('OPENAI_API_KEY', 'sk-test-dummy-key');
}

// Restore real fetch after each test group.
const realFetch = globalThis.fetch;

function mockFetch(response: Response | (() => Response)): void {
  _setFetch(() => Promise.resolve(typeof response === 'function' ? response() : response));
}

function mockFetchReject(err: Error): void {
  _setFetch(() => Promise.reject(err));
}

function restoreFetch(): void {
  _setFetch(realFetch);
}

// ---------------------------------------------------------------------------
// transcribeAudio
// ---------------------------------------------------------------------------

Deno.test('transcribeAudio: successful response is parsed correctly', async () => {
  mockFetch(
    new Response(
      JSON.stringify({ text: 'hello world', duration: 3.5, language: 'en' }),
      { status: 200 },
    ),
  );
  try {
    const result = await transcribeAudio(new Blob(['audio'], { type: 'audio/m4a' }));
    assertEquals(result.text, 'hello world');
    assertEquals(result.durationSeconds, 3.5);
    assertEquals(result.language, 'en');
  } finally {
    restoreFetch();
  }
});

Deno.test('transcribeAudio: Authorization header is present', async () => {
  let capturedHeaders: Headers | null = null;
  _setFetch((url, opts) => {
    capturedHeaders = new Headers(opts?.headers as HeadersInit);
    return Promise.resolve(
      new Response(JSON.stringify({ text: '', duration: 0, language: 'en' }), { status: 200 }),
    );
  });
  try {
    await transcribeAudio(new Blob([]));
    assertEquals(capturedHeaders?.has('Authorization'), true);
  } finally {
    restoreFetch();
  }
});

Deno.test('transcribeAudio: HTTP 429 → RATE_LIMITED', async () => {
  mockFetch(new Response('', { status: 429 }));
  try {
    const err = await assertRejects(() => transcribeAudio(new Blob([])), VoiceError);
    assertEquals(err.code, ErrorCodes.RATE_LIMITED);
  } finally {
    restoreFetch();
  }
});

Deno.test('transcribeAudio: HTTP 500 → OPENAI_UNAVAILABLE', async () => {
  mockFetch(new Response('', { status: 500 }));
  try {
    const err = await assertRejects(() => transcribeAudio(new Blob([])), VoiceError);
    assertEquals(err.code, ErrorCodes.OPENAI_UNAVAILABLE);
  } finally {
    restoreFetch();
  }
});

Deno.test('transcribeAudio: AbortError → TIMEOUT', async () => {
  mockFetchReject(Object.assign(new Error('aborted'), { name: 'AbortError' }));
  try {
    const err = await assertRejects(() => transcribeAudio(new Blob([])), VoiceError);
    assertEquals(err.code, ErrorCodes.TIMEOUT);
  } finally {
    restoreFetch();
  }
});

// ---------------------------------------------------------------------------
// completeChat
// ---------------------------------------------------------------------------

const chatReq = {
  history: [
    { role: 'user' as const, content: 'log bench press 80kg 10 reps' },
  ],
  tools: [],
};

Deno.test('completeChat: message response is parsed correctly', async () => {
  mockFetch(
    new Response(
      JSON.stringify({
        model: 'gpt-4o-mini-2024-07-18',
        choices: [{ message: { content: 'Got it!', tool_calls: null } }],
        usage: { prompt_tokens: 50, completion_tokens: 10 },
      }),
      { status: 200 },
    ),
  );
  try {
    const result = await completeChat(chatReq);
    assertEquals(result.message, 'Got it!');
    assertEquals(result.inputTokens, 50);
    assertEquals(result.outputTokens, 10);
    assertEquals(result.toolCall, undefined);
  } finally {
    restoreFetch();
  }
});

Deno.test('completeChat: tool_call response is parsed correctly', async () => {
  mockFetch(
    new Response(
      JSON.stringify({
        model: 'gpt-4o-mini-2024-07-18',
        choices: [{
          message: {
            content: null,
            tool_calls: [{
              id: 'call_1',
              function: { name: 'echo', arguments: '{"text":"hi"}' },
            }],
          },
        }],
        usage: { prompt_tokens: 100, completion_tokens: 20 },
      }),
      { status: 200 },
    ),
  );
  try {
    const result = await completeChat(chatReq);
    assertEquals(result.toolCall?.id, 'call_1');
    assertEquals(result.toolCall?.name, 'echo');
    assertEquals(result.toolCall?.arguments, { text: 'hi' });
    assertEquals(result.message, undefined);
  } finally {
    restoreFetch();
  }
});

Deno.test('completeChat: HTTP 503 → OPENAI_UNAVAILABLE 502', async () => {
  mockFetch(new Response('', { status: 503 }));
  try {
    const err = await assertRejects(() => completeChat(chatReq), VoiceError);
    assertEquals(err.code, ErrorCodes.OPENAI_UNAVAILABLE);
    assertEquals(err.httpStatus, 502);
  } finally {
    restoreFetch();
  }
});

// ---------------------------------------------------------------------------
// synthesizeSpeech
// ---------------------------------------------------------------------------

Deno.test('synthesizeSpeech: returns ArrayBuffer and character count', async () => {
  const mp3Bytes = new Uint8Array([1, 2, 3, 4]);
  mockFetch(new Response(mp3Bytes.buffer, { status: 200 }));
  try {
    const result = await synthesizeSpeech('hello', 'nova');
    assertEquals(result.characters, 5);
    assertEquals(result.format, 'mp3');
    assertEquals(result.audio.byteLength, 4);
  } finally {
    restoreFetch();
  }
});

Deno.test('synthesizeSpeech: request body contains correct model and voice', async () => {
  let capturedBody: Record<string, unknown> | null = null;
  _setFetch(async (_url, opts) => {
    capturedBody = JSON.parse(opts?.body as string);
    return new Response(new ArrayBuffer(0), { status: 200 });
  });
  try {
    await synthesizeSpeech('test text', 'nova');
    assertEquals(capturedBody?.model, 'tts-1');
    assertEquals(capturedBody?.voice, 'nova');
    assertEquals(capturedBody?.input, 'test text');
  } finally {
    restoreFetch();
  }
});

Deno.test('synthesizeSpeech: HTTP 401 → OPENAI_UNAVAILABLE (server misconfig, not user auth)', async () => {
  // OpenAI 401/403 means OUR key is bad — not the user's JWT. Surfacing as
  // UNAUTHORIZED would mislead the client into prompting the user to sign in.
  mockFetch(new Response('', { status: 401 }));
  try {
    const err = await assertRejects(() => synthesizeSpeech('hi', 'nova'), VoiceError);
    assertEquals(err.code, ErrorCodes.OPENAI_UNAVAILABLE);
    assertEquals(err.httpStatus, 502);
  } finally {
    restoreFetch();
  }
});

Deno.test('synthesizeSpeech: HTTP 403 → OPENAI_UNAVAILABLE', async () => {
  mockFetch(new Response('', { status: 403 }));
  try {
    const err = await assertRejects(() => synthesizeSpeech('hi', 'nova'), VoiceError);
    assertEquals(err.code, ErrorCodes.OPENAI_UNAVAILABLE);
    assertEquals(err.httpStatus, 502);
  } finally {
    restoreFetch();
  }
});

Deno.test('OPENAI_API_KEY missing → OPENAI_UNAVAILABLE before any HTTP call', async () => {
  // The key absence is a server misconfig, not a per-request issue.
  // We must fail fast with a clear error rather than send an empty bearer
  // token to OpenAI (which would 401 and confuse the client).
  const originalKey = Deno.env.get('OPENAI_API_KEY');
  Deno.env.delete('OPENAI_API_KEY');

  let fetchCalled = false;
  _setFetch(() => {
    fetchCalled = true;
    return Promise.resolve(new Response('', { status: 200 }));
  });

  try {
    const err = await assertRejects(() => synthesizeSpeech('hi', 'nova'), VoiceError);
    assertEquals(err.code, ErrorCodes.OPENAI_UNAVAILABLE);
    assertEquals(err.httpStatus, 502);
    assertEquals(fetchCalled, false, 'should not reach the network when key is missing');
  } finally {
    if (originalKey !== undefined) Deno.env.set('OPENAI_API_KEY', originalKey);
    restoreFetch();
  }
});
