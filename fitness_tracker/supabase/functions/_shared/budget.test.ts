import { assertEquals, assertRejects } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { assertWithinBudget } from './budget.ts';
import { ErrorCodes, VoiceError } from './errors.ts';
import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';

function makeSupabase(rows: Array<{ cost_usd: number }>, error: unknown = null) {
  return {
    from: () => ({
      select: () => ({
        eq: () => ({
          gte: () => Promise.resolve({ data: rows, error }),
        }),
      }),
    }),
  } as unknown as SupabaseClient;
}

Deno.test('assertWithinBudget: empty log → usedUsd=0, returns remaining=1.00', async () => {
  const result = await assertWithinBudget(makeSupabase([]), 'user-1');
  assertEquals(result.usedUsd, 0);
  assertEquals(result.remainingUsd, 1.0);
});

Deno.test('assertWithinBudget: under cap → returns correct remaining', async () => {
  const rows = [{ cost_usd: 0.3 }, { cost_usd: 0.2 }];
  const result = await assertWithinBudget(makeSupabase(rows), 'user-1');
  assertEquals(result.usedUsd, 0.5);
  assertEquals(result.remainingUsd, 0.5);
});

Deno.test('assertWithinBudget: exactly at cap → throws BUDGET_EXCEEDED', async () => {
  const rows = [{ cost_usd: 1.0 }];
  const err = await assertRejects(
    () => assertWithinBudget(makeSupabase(rows), 'user-1'),
    VoiceError,
  );
  assertEquals(err.code, ErrorCodes.BUDGET_EXCEEDED);
  assertEquals(err.httpStatus, 402);
});

Deno.test('assertWithinBudget: over cap → throws BUDGET_EXCEEDED', async () => {
  const rows = [{ cost_usd: 0.8 }, { cost_usd: 0.5 }];
  const err = await assertRejects(
    () => assertWithinBudget(makeSupabase(rows), 'user-1'),
    VoiceError,
  );
  assertEquals(err.code, ErrorCodes.BUDGET_EXCEEDED);
});

Deno.test('assertWithinBudget: DB error → throws INTERNAL', async () => {
  const err = await assertRejects(
    () => assertWithinBudget(makeSupabase([], { message: 'db error' }), 'user-1'),
    VoiceError,
  );
  assertEquals(err.code, ErrorCodes.INTERNAL);
});

Deno.test('assertWithinBudget: custom daily cap is respected', async () => {
  const rows = [{ cost_usd: 0.06 }];
  const err = await assertRejects(
    () => assertWithinBudget(makeSupabase(rows), 'user-1', 0.05),
    VoiceError,
  );
  assertEquals(err.code, ErrorCodes.BUDGET_EXCEEDED);
});
