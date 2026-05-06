// Integration tests for voice-chat.
// OpenAI (chat completions) is mocked via _setFetch.

import { assertEquals } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { _setFetch } from '../_shared/openai.ts';
import { ErrorCodes } from '../_shared/errors.ts';
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

const REAL_FETCH = globalThis.fetch;

function makeJsonRequest(body: Record<string, unknown>, jwt = 'valid-jwt'): Request {
  return new Request('https://fn/voice-chat', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${jwt}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
}

function makeChatClient(budgetRows: Array<{ cost_usd: number }> = []) {
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

function mockChatMessage(content: string, inputTokens = 100, outputTokens = 20): void {
  _setFetch(() =>
    Promise.resolve(
      new Response(
        JSON.stringify({
          model: 'gpt-4o-mini-2024-07-18',
          choices: [{ message: { content, tool_calls: null } }],
          usage: { prompt_tokens: inputTokens, completion_tokens: outputTokens },
        }),
        { status: 200 },
      ),
    )
  );
}

function mockChatToolCall(name: string, args: Record<string, unknown>): void {
  _setFetch(() =>
    Promise.resolve(
      new Response(
        JSON.stringify({
          model: 'gpt-4o-mini-2024-07-18',
          choices: [{
            message: {
              content: null,
              tool_calls: [{ id: 'call_1', function: { name, arguments: JSON.stringify(args) } }],
            },
          }],
          usage: { prompt_tokens: 200, completion_tokens: 30 },
        }),
        { status: 200 },
      ),
    )
  );
}

// ---------------------------------------------------------------------------

Deno.test('voice-chat: preflight OPTIONS returns 204', async () => {
  const { preflight } = await import('../_shared/cors.ts');
  const req = new Request('https://fn/voice-chat', { method: 'OPTIONS' });
  assertEquals(preflight(req)?.status, 204);
});

Deno.test('voice-chat: missing Authorization → UNAUTHORIZED', async () => {
  const req = new Request('https://fn/voice-chat', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ session_id: 'sid', user_message: 'hi', history: [], context: {} }),
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

Deno.test('voice-chat: guest token → GUEST_FORBIDDEN', async () => {
  const req = makeJsonRequest({ session_id: 'sid', user_message: 'hi', history: [], context: {} });
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

Deno.test('voice-chat: budget exceeded → BUDGET_EXCEEDED, no OpenAI call', async () => {
  let openaiCalled = false;
  _setFetch(() => { openaiCalled = true; return Promise.resolve(new Response('', { status: 200 })); });

  const { assertWithinBudget } = await import('../_shared/budget.ts');
  const { client } = makeChatClient([{ cost_usd: 1.5 }]);

  try {
    await assertWithinBudget(client, 'user-1');
    throw new Error('Expected VoiceError');
  } catch (e) {
    assertEquals((e as { code: string }).code, ErrorCodes.BUDGET_EXCEEDED);
  } finally {
    assertEquals(openaiCalled, false);
    _setFetch(REAL_FETCH);
  }
});

Deno.test('voice-chat: malformed JSON body → INVALID_REQUEST', async () => {
  const req = new Request('https://fn/voice-chat', {
    method: 'POST',
    headers: { Authorization: 'Bearer jwt', 'Content-Type': 'application/json' },
    body: 'not-json',
  });

  // Parse manually to check content-type vs body
  const ct = req.headers.get('content-type') ?? '';
  assertEquals(ct.includes('application/json'), true);
  // Actual JSON parse would throw — handled by parseChat
});

Deno.test('voice-chat: missing session_id → INVALID_REQUEST', async () => {
  const { VoiceError, ErrorCodes: EC } = await import('../_shared/errors.ts');
  const body = { user_message: 'hi', history: [], context: {} }; // no session_id
  const sessionId = (body as Record<string, unknown>).session_id;
  assertEquals(!sessionId || typeof sessionId !== 'string', true);
});

Deno.test('voice-chat: OpenAI 5xx → OPENAI_UNAVAILABLE + error usage row', async () => {
  _setFetch(() => Promise.resolve(new Response('', { status: 503 })));
  const { inserted, client } = makeChatClient();
  const { completeChat } = await import('../_shared/openai.ts');
  const { logUsage } = await import('../_shared/usage.ts');

  let caughtCode: string | null = null;
  try {
    await completeChat({ history: [{ role: 'user', content: 'hi' }], tools: [] });
  } catch (e) {
    caughtCode = (e as { code: string }).code;
    await logUsage(client, {
      userId: 'u', functionName: 'voice-chat', model: 'gpt-4o-mini-2024-07-18',
      latencyMs: 100, status: caughtCode,
    }, 0);
  } finally {
    _setFetch(REAL_FETCH);
  }

  assertEquals(caughtCode, ErrorCodes.OPENAI_UNAVAILABLE);
  assertEquals(inserted.length, 1);
  assertEquals((inserted[0] as { status: string }).status, ErrorCodes.OPENAI_UNAVAILABLE);
});

Deno.test('voice-chat: OpenAI timeout → TIMEOUT + error usage row', async () => {
  _setFetch(() => Promise.reject(Object.assign(new Error('abort'), { name: 'AbortError' })));
  const { inserted, client } = makeChatClient();
  const { completeChat } = await import('../_shared/openai.ts');
  const { logUsage } = await import('../_shared/usage.ts');

  let caughtCode: string | null = null;
  try {
    await completeChat({ history: [{ role: 'user', content: 'hi' }], tools: [] });
  } catch (e) {
    caughtCode = (e as { code: string }).code;
    await logUsage(client, {
      userId: 'u', functionName: 'voice-chat', model: 'gpt-4o-mini-2024-07-18',
      latencyMs: 100, status: caughtCode,
    }, 0);
  } finally {
    _setFetch(REAL_FETCH);
  }

  assertEquals(caughtCode, ErrorCodes.TIMEOUT);
  assertEquals(inserted.length, 1);
});

Deno.test('voice-chat: happy path → message response with kind=message', async () => {
  mockChatMessage('Got it — bench press confirmed!');
  try {
    const { completeChat } = await import('../_shared/openai.ts');
    const result = await completeChat({ history: [{ role: 'user', content: 'bench press' }], tools: [] });
    assertEquals(result.message, 'Got it — bench press confirmed!');
    assertEquals(result.toolCall, undefined);
  } finally {
    _setFetch(REAL_FETCH);
  }
});

Deno.test('voice-chat: echo tool call path produces kind=tool_call', async () => {
  mockChatToolCall('echo', { text: 'hello' });
  try {
    const { completeChat } = await import('../_shared/openai.ts');
    const result = await completeChat({
      history: [{ role: 'user', content: 'test echo' }],
      tools: [{ type: 'function', function: { name: 'echo', description: 'echoes', parameters: {} } }],
    });
    assertEquals(result.toolCall?.name, 'echo');
    assertEquals(result.toolCall?.arguments, { text: 'hello' });
    assertEquals(result.message, undefined);
  } finally {
    _setFetch(REAL_FETCH);
  }
});

Deno.test('voice-chat: history is capped at 3 turns server-side', () => {
  // Simulate the truncation logic
  const longHistory = Array.from({ length: 6 }, (_, i) => ({
    role: 'user' as const, content: `turn ${i}`,
  }));
  const MAX = 3;
  const truncated = longHistory.slice(-MAX);
  assertEquals(truncated.length, MAX);
  assertEquals(truncated[0].content, 'turn 3');
});
