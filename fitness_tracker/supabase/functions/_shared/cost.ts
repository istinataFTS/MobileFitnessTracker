export const PRICING_VERSION = '2026-05-11';

// USD per unit. Verify against https://openai.com/api/pricing before each release.
// STT and TTS are device-native (free). Only the LLM call incurs cost.
const PRICES = {
  'gpt-4o-mini-2024-07-18': {
    perInputToken:  0.150 / 1_000_000,
    perOutputToken: 0.600 / 1_000_000,
  },
} as const;

type PricingModel = keyof typeof PRICES;

export function costForChat(
  model: PricingModel,
  inputTokens: number,
  outputTokens: number,
): number {
  const pricing = PRICES[model];
  if (!('perInputToken' in pricing)) {
    throw new Error(`Model '${model}' does not have token-based pricing`);
  }
  return round6(
    inputTokens * pricing.perInputToken + outputTokens * pricing.perOutputToken,
  );
}

export function round6(usd: number): number {
  return Math.round(usd * 1_000_000) / 1_000_000;
}
