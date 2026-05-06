export const PRICING_VERSION = '2026-05-06';

// USD per unit. Verify against https://openai.com/api/pricing before each release.
const PRICES = {
  'whisper-1': { perAudioSecond: 0.006 / 60 },           // $0.006 / minute
  'gpt-4o-mini-2024-07-18': {
    perInputToken: 0.150 / 1_000_000,
    perOutputToken: 0.600 / 1_000_000,
  },
  'tts-1': { perCharacter: 15.000 / 1_000_000 },
} as const;

type PricingModel = keyof typeof PRICES;

export function costForWhisper(audioSeconds: number): number {
  return round6(audioSeconds * PRICES['whisper-1'].perAudioSecond);
}

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

export function costForTts(characters: number): number {
  return round6(characters * PRICES['tts-1'].perCharacter);
}

export function round6(usd: number): number {
  return Math.round(usd * 1_000_000) / 1_000_000;
}
