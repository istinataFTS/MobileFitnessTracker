import { authenticate } from '../_shared/auth.ts';
import { assertWithinBudget, getBudgetState } from '../_shared/budget.ts';
import { costForChat } from '../_shared/cost.ts';
import { CORS_HEADERS, preflight } from '../_shared/cors.ts';
import { ErrorCodes, VoiceError, errorResponse } from '../_shared/errors.ts';
import { completeChat } from '../_shared/openai.ts';
import { appendSessionTurn } from '../_shared/session.ts';
import { TOOL_REGISTRY } from '../_shared/tools.ts';
import type { FunctionName, Turn, VoiceContext } from '../_shared/types.ts';
import { logUsage } from '../_shared/usage.ts';
import { json, msSince, serviceClient } from '../_shared/utils.ts';

const FUNCTION_NAME: FunctionName = 'voice-chat';
const MODEL = 'gpt-4o-mini-2024-07-18';
const MAX_HISTORY_TURNS = 3;

// System prompt template. Placeholders: {{current_date}}, {{weight_unit}}.
const SYSTEM_PROMPT_TEMPLATE = `You are the voice assistant for a personal fitness-tracking app. Your ONLY responsibilities are:
1. Logging, editing, and deleting workout sets and nutrition entries.
2. Answering factual questions about the user's own logged data.

You MUST refuse, politely and briefly, any other request — fitness advice, training plans, nutrition recommendations, general knowledge.
Example refusal: "I only handle logging and your own stats."

When the user is ambiguous, ask ONE clarifying question. After the user clarifies, propose the action via a tool call and let the app confirm with the user.

Never invent data. If the user asks about something you cannot retrieve via a tool, say so plainly.

Today is {{current_date}}. Weight unit is {{weight_unit}}. Conversation language is English.`;

interface ParsedChat {
  sessionId: string;
  userMessage: string;
  history: Turn[];
  context: VoiceContext;
  sessionLoggingEnabled: boolean;
}

async function parseChat(req: Request): Promise<ParsedChat> {
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    throw new VoiceError(ErrorCodes.INVALID_REQUEST, 'Request body must be valid JSON', 400);
  }

  const sessionId = body.session_id;
  if (!sessionId || typeof sessionId !== 'string') {
    throw new VoiceError(ErrorCodes.INVALID_REQUEST, 'Missing required field: session_id', 400);
  }

  const userMessage = body.user_message;
  if (!userMessage || typeof userMessage !== 'string') {
    throw new VoiceError(ErrorCodes.INVALID_REQUEST, 'Missing required field: user_message', 400);
  }

  const rawHistory = Array.isArray(body.history) ? body.history : [];
  // Enforce maximum 3 turns server-side.
  const history = rawHistory.slice(-MAX_HISTORY_TURNS) as Turn[];

  const ctx = (body.context ?? {}) as Partial<VoiceContext>;
  const context: VoiceContext = {
    currentDate: typeof ctx.currentDate === 'string' ? ctx.currentDate : new Date().toISOString().slice(0, 10),
    weightUnit: ctx.weightUnit === 'lb' ? 'lb' : 'kg',
    recentExerciseIds: Array.isArray(ctx.recentExerciseIds) ? ctx.recentExerciseIds : [],
  };

  const sessionLoggingEnabled = body.session_logging_enabled === true;

  return { sessionId, userMessage, history, context, sessionLoggingEnabled };
}

function buildSystemPrompt(context: VoiceContext): string {
  return SYSTEM_PROMPT_TEMPLATE
    .replace('{{current_date}}', context.currentDate)
    .replace('{{weight_unit}}', context.weightUnit);
}

async function handleChat(req: Request, t0: number): Promise<Response> {
  const user = await authenticate(req);
  const parsed = await parseChat(req);
  const supabase = serviceClient();

  await assertWithinBudget(supabase, user.id);

  const systemPrompt = buildSystemPrompt(parsed.context);
  const messages = [
    { role: 'system' as const, content: systemPrompt },
    ...parsed.history.map((t) => ({
      role: t.role as 'user' | 'assistant' | 'tool',
      content: t.content,
      ...(t.role === 'tool' ? { tool_call_id: (t as Extract<Turn, { role: 'tool' }>).toolCallId } : {}),
    })),
    { role: 'user' as const, content: parsed.userMessage },
  ];

  const tools = TOOL_REGISTRY.map((td) => ({
    type: 'function' as const,
    function: { name: td.name, description: td.description, parameters: td.parameters },
  }));

  let chatResult: Awaited<ReturnType<typeof completeChat>>;
  try {
    chatResult = await completeChat({ history: messages, tools });
  } catch (err) {
    const code = err instanceof VoiceError ? err.code : ErrorCodes.INTERNAL;
    await logUsage(supabase, {
      userId: user.id, functionName: FUNCTION_NAME, model: MODEL,
      latencyMs: msSince(t0), sessionId: parsed.sessionId, status: code,
    }, 0);
    throw err;
  }

  const cost = costForChat(MODEL, chatResult.inputTokens, chatResult.outputTokens);

  await logUsage(supabase, {
    userId: user.id, functionName: FUNCTION_NAME, model: chatResult.model,
    inputTokens: chatResult.inputTokens, outputTokens: chatResult.outputTokens,
    latencyMs: msSince(t0), sessionId: parsed.sessionId, status: 'OK',
  }, cost);

  // Log the user message turn and assistant reply to the session.
  await appendSessionTurn(supabase, {
    sessionId: parsed.sessionId, userId: user.id,
    turn: { role: 'user', content: parsed.userMessage },
    costUsd: 0, enabled: parsed.sessionLoggingEnabled,
  });

  if (chatResult.toolCall) {
    await appendSessionTurn(supabase, {
      sessionId: parsed.sessionId, userId: user.id,
      turn: { role: 'assistant', content: '', toolCall: chatResult.toolCall },
      costUsd: cost, enabled: parsed.sessionLoggingEnabled,
    });
  } else if (chatResult.message !== undefined) {
    await appendSessionTurn(supabase, {
      sessionId: parsed.sessionId, userId: user.id,
      turn: { role: 'assistant', content: chatResult.message },
      costUsd: cost, enabled: parsed.sessionLoggingEnabled,
    });
  }

  // Non-throwing read: the work has been billed; a budget gate would penalise
  // a successful call when the cost crosses the cap on this very turn.
  const { remainingUsd } = await getBudgetState(supabase, user.id);

  const base = {
    model: chatResult.model,
    input_tokens: chatResult.inputTokens,
    output_tokens: chatResult.outputTokens,
    cost_usd: cost,
    remaining_budget_usd: remainingUsd,
    request_id: crypto.randomUUID(),
  };

  if (chatResult.toolCall) {
    return json(200, { kind: 'tool_call', tool_call: chatResult.toolCall, ...base });
  }
  return json(200, { kind: 'message', content: chatResult.message, ...base });
}

Deno.serve(async (req) => {
  const t0 = performance.now();
  const corsResp = preflight(req);
  if (corsResp) return corsResp;

  try {
    return await handleChat(req, t0);
  } catch (err) {
    return errorResponse(err, new Headers(CORS_HEADERS));
  }
});
