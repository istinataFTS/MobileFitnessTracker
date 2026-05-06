import { authenticate } from '../_shared/auth.ts';
import { assertWithinBudget } from '../_shared/budget.ts';
import { costForTts } from '../_shared/cost.ts';
import { CORS_HEADERS, preflight } from '../_shared/cors.ts';
import { ErrorCodes, VoiceError, errorResponse } from '../_shared/errors.ts';
import { synthesizeSpeech, TtsVoice } from '../_shared/openai.ts';
import { appendSessionTurn } from '../_shared/session.ts';
import type { FunctionName } from '../_shared/types.ts';
import { logUsage } from '../_shared/usage.ts';
import { msSince, serviceClient } from '../_shared/utils.ts';

const FUNCTION_NAME: FunctionName = 'voice-tts';
const MODEL = 'tts-1';
const MAX_CHARACTERS = 800;

const VALID_VOICES: ReadonlySet<string> = new Set([
  'alloy', 'echo', 'fable', 'nova', 'onyx', 'shimmer',
]);

interface ParsedTts {
  text: string;
  voice: TtsVoice;
  sessionId: string;
  sessionLoggingEnabled: boolean;
}

async function parseTts(req: Request): Promise<ParsedTts> {
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    throw new VoiceError(ErrorCodes.INVALID_REQUEST, 'Request body must be valid JSON', 400);
  }

  const text = body.text;
  if (!text || typeof text !== 'string' || text.trim().length === 0) {
    throw new VoiceError(ErrorCodes.INVALID_REQUEST, 'Missing or empty required field: text', 400);
  }

  if (text.length > MAX_CHARACTERS) {
    throw new VoiceError(
      ErrorCodes.INVALID_REQUEST,
      `text exceeds ${MAX_CHARACTERS} character limit (got ${text.length})`,
      400,
    );
  }

  const voiceInput = (body.voice as string | undefined) ?? 'nova';
  if (!VALID_VOICES.has(voiceInput)) {
    throw new VoiceError(
      ErrorCodes.INVALID_REQUEST,
      `Invalid voice '${voiceInput}'. Valid values: ${[...VALID_VOICES].join(', ')}`,
      400,
    );
  }

  const sessionId = body.session_id;
  if (!sessionId || typeof sessionId !== 'string') {
    throw new VoiceError(ErrorCodes.INVALID_REQUEST, 'Missing required field: session_id', 400);
  }

  const sessionLoggingEnabled = body.session_logging_enabled === true;

  return { text, voice: voiceInput as TtsVoice, sessionId, sessionLoggingEnabled };
}

async function handleTts(req: Request, t0: number): Promise<Response> {
  const user = await authenticate(req);
  const parsed = await parseTts(req);
  const supabase = serviceClient();

  await assertWithinBudget(supabase, user.id);

  let ttsResult: Awaited<ReturnType<typeof synthesizeSpeech>>;
  try {
    ttsResult = await synthesizeSpeech(parsed.text, parsed.voice);
  } catch (err) {
    const code = err instanceof VoiceError ? err.code : ErrorCodes.INTERNAL;
    await logUsage(supabase, {
      userId: user.id,
      functionName: FUNCTION_NAME,
      model: MODEL,
      characters: parsed.text.length,
      latencyMs: msSince(t0),
      sessionId: parsed.sessionId,
      status: code,
    }, 0);
    throw err;
  }

  const cost = costForTts(ttsResult.characters);

  await logUsage(supabase, {
    userId: user.id,
    functionName: FUNCTION_NAME,
    model: MODEL,
    characters: ttsResult.characters,
    latencyMs: msSince(t0),
    sessionId: parsed.sessionId,
    status: 'OK',
  }, cost);

  await appendSessionTurn(supabase, {
    sessionId: parsed.sessionId,
    userId: user.id,
    turn: { role: 'assistant', content: parsed.text },
    costUsd: cost,
    enabled: parsed.sessionLoggingEnabled,
  });

  const { remainingUsd } = await assertWithinBudget(supabase, user.id);

  return new Response(ttsResult.audio, {
    status: 200,
    headers: {
      ...CORS_HEADERS,
      'Content-Type': 'audio/mpeg',
      'X-Voice-Cost-Usd': String(cost),
      'X-Voice-Remaining-Budget-Usd': String(remainingUsd),
      'X-Voice-Request-Id': crypto.randomUUID(),
    },
  });
}

Deno.serve(async (req) => {
  const t0 = performance.now();
  const corsResp = preflight(req);
  if (corsResp) return corsResp;

  try {
    return await handleTts(req, t0);
  } catch (err) {
    return errorResponse(err, new Headers(CORS_HEADERS));
  }
});
