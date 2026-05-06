import { assertEquals, assertThrows } from 'https://deno.land/std@0.224.0/assert/mod.ts';
import { costForWhisper, costForChat, costForTts, round6, PRICING_VERSION } from './cost.ts';

Deno.test('PRICING_VERSION is a non-empty string', () => {
  assertEquals(typeof PRICING_VERSION, 'string');
  assertEquals(PRICING_VERSION.length > 0, true);
});

Deno.test('costForWhisper: 60 seconds = $0.006', () => {
  assertEquals(costForWhisper(60), 0.006);
});

Deno.test('costForWhisper: 30 seconds = $0.003', () => {
  assertEquals(costForWhisper(30), 0.003);
});

Deno.test('costForWhisper: 0 seconds = $0', () => {
  assertEquals(costForWhisper(0), 0);
});

Deno.test('costForChat: known token counts produce expected cost', () => {
  // 1 000 000 input tokens @ $0.150/M + 1 000 000 output tokens @ $0.600/M = $0.75
  const cost = costForChat('gpt-4o-mini-2024-07-18', 1_000_000, 1_000_000);
  assertEquals(cost, 0.75);
});

Deno.test('costForChat: 100 input + 50 output tokens', () => {
  const cost = costForChat('gpt-4o-mini-2024-07-18', 100, 50);
  const expected = round6(100 * (0.150 / 1_000_000) + 50 * (0.600 / 1_000_000));
  assertEquals(cost, expected);
});

Deno.test('costForChat: throws on non-token-priced model', () => {
  assertThrows(
    () => costForChat('whisper-1' as never, 100, 100),
    Error,
  );
});

Deno.test('costForTts: 1 000 000 characters = $15', () => {
  assertEquals(costForTts(1_000_000), 15.0);
});

Deno.test('costForTts: 100 characters', () => {
  const cost = costForTts(100);
  assertEquals(cost, round6(100 * (15.0 / 1_000_000)));
});

Deno.test('round6: rounds to 6 decimal places', () => {
  assertEquals(round6(0.1234567), 0.123457);
  assertEquals(round6(0.123456), 0.123456);
  assertEquals(round6(0), 0);
});

Deno.test('round6: round-trip precision matches DB numeric(10,6)', () => {
  const val = 0.000432;
  assertEquals(round6(val), val);
});
