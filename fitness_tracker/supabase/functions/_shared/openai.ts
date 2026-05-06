import { ErrorCodes, VoiceError } from './errors.ts';
import type { ToolCall } from './types.ts';

const OPENAI_BASE = 'https://api.openai.com/v1';
const TIMEOUT_MS = 30_000;
const USER_AGENT = 'fitness-tracker-voice/c1';

// Injectable fetch for testing.
let _fetch: typeof fetch = globalThis.fetch;
export function _setFetch(f: typeof fetch): void {
  _fetch = f;
}

function getApiKey(): string {
  return Deno.env.get('OPENAI_API_KEY') ?? '';
}

function makeHeaders(extra?: Record<string, string>): Headers {
  return new Headers({
    Authorization: `Bearer ${getApiKey()}`,
    'User-Agent': USER_AGENT,
    ...extra,
  });
}

async function withTimeout(signal: AbortSignal, fn: () => Promise<Response>): Promise<Response> {
  const timer = setTimeout(() => signal.dispatchEvent(new Event('abort')), TIMEOUT_MS);
  try {
    const res = await fn();
    clearTimeout(timer);
    return res;
  } catch (err) {
    clearTimeout(timer);
    if ((err as Error).name === 'AbortError') {
      throw new VoiceError(ErrorCodes.TIMEOUT, 'OpenAI request timed out', 504);
    }
    throw err;
  }
}

function mapOpenAiStatus(status: number): never {
  if (status === 429) throw new VoiceError(ErrorCodes.RATE_LIMITED, 'OpenAI rate limit exceeded', 429);
  if (status === 401 || status === 403) throw new VoiceError(ErrorCodes.UNAUTHORIZED, 'OpenAI auth failed', 500);
  throw new VoiceError(ErrorCodes.OPENAI_UNAVAILABLE, `OpenAI returned HTTP ${status}`, 502);
}

// ---------------------------------------------------------------------------
// Whisper STT
// ---------------------------------------------------------------------------

export interface WhisperResponse {
  text: string;
  durationSeconds: number;
  language: string;
}

export async function transcribeAudio(audio: Blob, language = 'en'): Promise<WhisperResponse> {
  const controller = new AbortController();
  const form = new FormData();
  form.append('file', audio, 'audio.m4a');
  form.append('model', 'whisper-1');
  form.append('language', language);
  form.append('response_format', 'verbose_json');

  const res = await withTimeout(controller.signal, () =>
    _fetch(`${OPENAI_BASE}/audio/transcriptions`, {
      method: 'POST',
      headers: makeHeaders(),
      body: form,
      signal: controller.signal,
    })
  );

  if (!res.ok) mapOpenAiStatus(res.status);

  const json = await res.json();
  return {
    text: json.text ?? '',
    durationSeconds: Number(json.duration ?? 0),
    language: json.language ?? language,
  };
}

// ---------------------------------------------------------------------------
// Chat completion
// ---------------------------------------------------------------------------

export interface ChatRequest {
  history: ReadonlyArray<{
    role: 'system' | 'user' | 'assistant' | 'tool';
    content: string;
    tool_call_id?: string;
  }>;
  tools: ReadonlyArray<{
    type: 'function';
    function: { name: string; description: string; parameters: object };
  }>;
}

export interface ChatResponse {
  model: string;
  inputTokens: number;
  outputTokens: number;
  message?: string;
  toolCall?: ToolCall;
}

export async function completeChat(req: ChatRequest): Promise<ChatResponse> {
  const controller = new AbortController();

  const res = await withTimeout(controller.signal, () =>
    _fetch(`${OPENAI_BASE}/chat/completions`, {
      method: 'POST',
      headers: makeHeaders({ 'Content-Type': 'application/json' }),
      body: JSON.stringify({
        model: 'gpt-4o-mini-2024-07-18',
        messages: req.history,
        tools: req.tools.length > 0 ? req.tools : undefined,
        tool_choice: req.tools.length > 0 ? 'auto' : undefined,
      }),
      signal: controller.signal,
    })
  );

  if (!res.ok) mapOpenAiStatus(res.status);

  const json = await res.json();
  const choice = json.choices?.[0];
  const msg = choice?.message;

  const result: ChatResponse = {
    model: json.model,
    inputTokens: json.usage?.prompt_tokens ?? 0,
    outputTokens: json.usage?.completion_tokens ?? 0,
  };

  if (msg?.tool_calls?.[0]) {
    const tc = msg.tool_calls[0];
    result.toolCall = {
      id: tc.id,
      name: tc.function.name,
      arguments: JSON.parse(tc.function.arguments ?? '{}'),
    };
  } else {
    result.message = msg?.content ?? '';
  }

  return result;
}

// ---------------------------------------------------------------------------
// TTS
// ---------------------------------------------------------------------------

export type TtsVoice = 'alloy' | 'echo' | 'fable' | 'nova' | 'onyx' | 'shimmer';

export interface TtsResponse {
  audio: ArrayBuffer;
  characters: number;
  format: 'mp3';
}

export async function synthesizeSpeech(text: string, voice: TtsVoice): Promise<TtsResponse> {
  const controller = new AbortController();

  const res = await withTimeout(controller.signal, () =>
    _fetch(`${OPENAI_BASE}/audio/speech`, {
      method: 'POST',
      headers: makeHeaders({ 'Content-Type': 'application/json' }),
      body: JSON.stringify({ model: 'tts-1', input: text, voice }),
      signal: controller.signal,
    })
  );

  if (!res.ok) mapOpenAiStatus(res.status);

  return {
    audio: await res.arrayBuffer(),
    characters: text.length,
    format: 'mp3',
  };
}
