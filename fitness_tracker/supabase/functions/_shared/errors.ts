import { CORS_HEADERS } from './cors.ts';

export const ErrorCodes = {
  UNAUTHORIZED: 'UNAUTHORIZED',
  GUEST_FORBIDDEN: 'GUEST_FORBIDDEN',
  BUDGET_EXCEEDED: 'BUDGET_EXCEEDED',
  INVALID_REQUEST: 'INVALID_REQUEST',
  AUDIO_TOO_LARGE: 'AUDIO_TOO_LARGE',
  AUDIO_DECODE_FAIL: 'AUDIO_DECODE_FAIL',
  OPENAI_UNAVAILABLE: 'OPENAI_UNAVAILABLE',
  RATE_LIMITED: 'RATE_LIMITED',
  TIMEOUT: 'TIMEOUT',
  INTERNAL: 'INTERNAL',
} as const;

export type ErrorCode = (typeof ErrorCodes)[keyof typeof ErrorCodes];

export class VoiceError extends Error {
  constructor(
    public readonly code: ErrorCode,
    message: string,
    public readonly httpStatus: number,
  ) {
    super(message);
    this.name = 'VoiceError';
  }
}

export function errorResponse(err: unknown, headers: Headers): Response {
  const base = { ...CORS_HEADERS, ...Object.fromEntries(headers), 'Content-Type': 'application/json' };

  if (err instanceof VoiceError) {
    return new Response(
      JSON.stringify({ code: err.code, message: err.message }),
      { status: err.httpStatus, headers: base },
    );
  }

  console.error('[voice] unhandled error:', err);
  return new Response(
    JSON.stringify({ code: ErrorCodes.INTERNAL, message: 'Internal server error' }),
    { status: 500, headers: base },
  );
}
