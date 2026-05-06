import { authenticate } from '../_shared/auth.ts';
import { assertWithinBudget } from '../_shared/budget.ts';
import { costForWhisper } from '../_shared/cost.ts';
import { CORS_HEADERS, preflight } from '../_shared/cors.ts';
import { ErrorCodes, VoiceError, errorResponse } from '../_shared/errors.ts';
import { transcribeAudio } from '../_shared/openai.ts';
import { appendSessionTurn } from '../_shared/session.ts';
import type { FunctionName } from '../_shared/types.ts';
import { logUsage } from '../_shared/usage.ts';
import { json, msSince, serviceClient } from '../_shared/utils.ts';

const FUNCTION_NAME: FunctionName = 'voice-stt';
const MODEL = 'whisper-1';
const MAX_AUDIO_BYTES = 4 * 1024 * 1024; // 4 MB

interface ParsedStt {
  audio: Blob;
  sessionId: string;
  language: string;
  sessionLoggingEnabled: boolean;
}

async function parseStt(req: Request): Promise<ParsedStt> {
  const ct = req.headers.get('content-type') ?? '';
  if (!ct.includes('multipart/form-data')) {
    throw new VoiceError(ErrorCodes.INVALID_REQUEST, 'Expected multipart/form-data', 400);
  }

  let form: FormData;
  try {
    form = await req.formData();
  } catch {
    throw new VoiceError(ErrorCodes.AUDIO_DECODE_FAIL, 'Failed to parse multipart body', 422);
  }

  const audioEntry = form.get('audio');
  if (!audioEntry || !(audioEntry instanceof File)) {
    throw new VoiceError(ErrorCodes.INVALID_REQUEST, 'Missing required field: audio', 400);
  }

  if (audioEntry.size > MAX_AUDIO_BYTES) {
    throw new VoiceError(ErrorCodes.AUDIO_TOO_LARGE, 'Audio file exceeds 4 MB limit', 413);
  }

  const sessionId = form.get('session_id');
  if (!sessionId || typeof sessionId !== 'string') {
    throw new VoiceError(ErrorCodes.INVALID_REQUEST, 'Missing required field: session_id', 400);
  }

  const language = (form.get('language') as string | null) ?? 'en';
  const sessionLoggingEnabled = form.get('session_logging_enabled') === 'true';
  const audio = new Blob([await audioEntry.arrayBuffer()], { type: audioEntry.type });

  return { audio, sessionId, language, sessionLoggingEnabled };
}

async function handleStt(req: Request, t0: number): Promise<Response> {
  const user = await authenticate(req);
  const parsed = await parseStt(req);
  const supabase = serviceClient();

  await assertWithinBudget(supabase, user.id);

  let whisper: Awaited<ReturnType<typeof transcribeAudio>>;
  try {
    whisper = await transcribeAudio(parsed.audio, parsed.language);
  } catch (err) {
    const code = err instanceof VoiceError ? err.code : ErrorCodes.INTERNAL;
    await logUsage(supabase, {
      userId: user.id,
      functionName: FUNCTION_NAME,
      model: MODEL,
      latencyMs: msSince(t0),
      sessionId: parsed.sessionId,
      status: code,
    }, 0);
    throw err;
  }

  const cost = costForWhisper(whisper.durationSeconds);

  await logUsage(supabase, {
    userId: user.id,
    functionName: FUNCTION_NAME,
    model: MODEL,
    audioSeconds: whisper.durationSeconds,
    latencyMs: msSince(t0),
    sessionId: parsed.sessionId,
    status: 'OK',
  }, cost);

  await appendSessionTurn(supabase, {
    sessionId: parsed.sessionId,
    userId: user.id,
    turn: { role: 'user', content: whisper.text },
    costUsd: cost,
    enabled: parsed.sessionLoggingEnabled,
  });

  const { remainingUsd } = await assertWithinBudget(supabase, user.id);

  return json(200, {
    transcript: whisper.text,
    language: whisper.language,
    audio_seconds: whisper.durationSeconds,
    cost_usd: cost,
    remaining_budget_usd: remainingUsd,
    request_id: crypto.randomUUID(),
  });
}

Deno.serve(async (req) => {
  const t0 = performance.now();
  const corsResp = preflight(req);
  if (corsResp) return corsResp;

  try {
    return await handleStt(req, t0);
  } catch (err) {
    return errorResponse(err, new Headers(CORS_HEADERS));
  }
});
