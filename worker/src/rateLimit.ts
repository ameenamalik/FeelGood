import { Env } from "./types";

const REQUESTS_PER_MINUTE = 10;
const WINDOW_SECONDS = 60;

/// A soft limit, not a security boundary — only paying users (already
/// entitlement-checked) ever reach this. Workers KV is eventually
/// consistent, so a burst right at a minute boundary could squeak a couple
/// of extra requests through; that's an accepted tradeoff for staying at
/// "one KV call" instead of reaching for Durable Objects over a risk this
/// small.
export async function isRateLimited(anonInstallID: string, env: Env): Promise<boolean> {
  const bucket = Math.floor(Date.now() / 1000 / WINDOW_SECONDS);
  const key = `rl:${anonInstallID}:${bucket}`;

  const current = Number((await env.RATE_LIMIT.get(key)) ?? "0");
  if (current >= REQUESTS_PER_MINUTE) return true;

  await env.RATE_LIMIT.put(key, String(current + 1), { expirationTtl: WINDOW_SECONDS * 2 });
  return false;
}
