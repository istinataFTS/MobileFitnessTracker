import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import type { Turn } from './types.ts';
import { ErrorCodes, VoiceError } from './errors.ts';

export async function appendSessionTurn(
  serviceClient: SupabaseClient,
  args: {
    sessionId: string;
    userId: string;
    turn: Turn;
    costUsd: number;
    enabled: boolean;
  },
): Promise<void> {
  if (!args.enabled) return;

  const { error } = await serviceClient.rpc('voice_session_append_turn', {
    p_session_id: args.sessionId,
    p_user_id: args.userId,
    p_turn: args.turn,
    p_cost_usd: args.costUsd,
  });

  if (error) {
    // Swallow — session logging failure must never block the user's request.
    console.error('[voice] appendSessionTurn failed:', error);
  }
}
