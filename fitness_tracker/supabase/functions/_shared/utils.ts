import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { CORS_HEADERS } from './cors.ts';

export function serviceClient(): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  );
}

export function msSince(t0: number): number {
  return Math.round(performance.now() - t0);
}

export function json(
  status: number,
  body: unknown,
  extraHeaders?: Record<string, string>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...CORS_HEADERS,
      'Content-Type': 'application/json',
      ...(extraHeaders ?? {}),
    },
  });
}
