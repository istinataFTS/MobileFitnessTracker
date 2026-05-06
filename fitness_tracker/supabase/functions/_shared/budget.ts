import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { ErrorCodes, VoiceError } from './errors.ts';

export async function assertWithinBudget(
  supabase: SupabaseClient,
  userId: string,
  dailyCapUsd = 1.00,
): Promise<{ usedUsd: number; remainingUsd: number }> {
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);

  const { data, error } = await supabase
    .from('voice_usage_log')
    .select('cost_usd')
    .eq('user_id', userId)
    .gte('created_at', today.toISOString());

  if (error) {
    throw new VoiceError(ErrorCodes.INTERNAL, 'Budget check failed', 500);
  }

  const usedUsd = (data ?? []).reduce((sum, row) => sum + Number(row.cost_usd), 0);

  if (usedUsd >= dailyCapUsd) {
    throw new VoiceError(
      ErrorCodes.BUDGET_EXCEEDED,
      `Daily budget of $${dailyCapUsd.toFixed(2)} exceeded`,
      402,
    );
  }

  return { usedUsd, remainingUsd: dailyCapUsd - usedUsd };
}
