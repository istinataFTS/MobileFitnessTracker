export type FunctionName = 'voice-chat';

export interface AuthedUser {
  readonly id: string;  // auth.users.id (uuid)
  readonly jwt: string; // raw JWT, used for user-scoped DB reads
}

export interface UsageMetrics {
  readonly inputTokens?: number;
  readonly outputTokens?: number;
}

export interface UsageLogInput extends UsageMetrics {
  readonly userId: string;
  readonly functionName: FunctionName;
  readonly model: string;
  readonly latencyMs: number;
  readonly sessionId?: string;
  readonly status: string; // 'OK' or structured error code
}

export type Turn =
  | { role: 'user'; content: string }
  | { role: 'assistant'; content: string; toolCall?: ToolCall }
  | { role: 'tool'; content: string; toolCallId: string };

export interface ToolCall {
  readonly id: string;
  readonly name: string;
  readonly arguments: Record<string, unknown>;
}

export interface VoiceContext {
  readonly currentDate: string;                       // ISO yyyy-mm-dd
  readonly weightUnit: 'kg' | 'lb';
  readonly recentExerciseIds?: readonly string[];
}
