import { Env } from "./types";

// A free user's first chat reply is the one that decides whether the app
// seems smart, so it comes from the model too. One exchange, then the
// paywall — the same allowance the app gives (hasUsedFreeChatExchange).
//
// The subscriber id is sent by the client, so on its own it is not a
// boundary: anyone could invent a fresh one per request. Three caps bound the
// cost of that instead, all in the RATE_LIMIT namespace:
//   - one free exchange per subscriber id, ever;
//   - a few per client IP per day, so inventing ids from one place stops fast;
//   - a global daily ceiling, so the worst case is a known, small bill.
// KV is eventually consistent, so a tight burst can slip one or two past a
// cap. Accepted for the same reason as rateLimit.ts.

const FREE_EXCHANGES_PER_SUBSCRIBER = 1;
const FREE_EXCHANGES_PER_IP_PER_DAY = 5;
const DEFAULT_FREE_EXCHANGES_PER_DAY = 1000;
const DAY_SECONDS = 60 * 60 * 24;
const SUBSCRIBER_TTL_SECONDS = DAY_SECONDS * 365;

async function count(env: Env, key: string): Promise<number> {
  return Number((await env.RATE_LIMIT.get(key)) ?? "0");
}

/**
 * Whether this request may use a free exchange. When it may, the exchange is
 * counted against all three caps before returning, so a request that then
 * fails upstream still spent it — a retry loop can't turn one into many.
 */
export async function consumeFreeChat(
  subscriberID: string,
  clientIP: string | null,
  env: Env,
  now: number = Date.now()
): Promise<boolean> {
  const day = Math.floor(now / 1000 / DAY_SECONDS);
  const dailyLimit = Number(env.FREE_CHAT_DAILY_LIMIT ?? DEFAULT_FREE_EXCHANGES_PER_DAY);

  const subscriberKey = `free:sub:${subscriberID}`;
  const ipKey = clientIP ? `free:ip:${clientIP}:${day}` : null;
  const globalKey = `free:all:${day}`;

  const [bySubscriber, byIP, overall] = await Promise.all([
    count(env, subscriberKey),
    ipKey ? count(env, ipKey) : Promise.resolve(0),
    count(env, globalKey),
  ]);

  if (bySubscriber >= FREE_EXCHANGES_PER_SUBSCRIBER) return false;
  if (byIP >= FREE_EXCHANGES_PER_IP_PER_DAY) {
    console.warn("free chat: per-IP daily cap reached");
    return false;
  }
  if (overall >= dailyLimit) {
    console.warn("free chat: global daily cap reached");
    return false;
  }

  await Promise.all([
    env.RATE_LIMIT.put(subscriberKey, String(bySubscriber + 1), { expirationTtl: SUBSCRIBER_TTL_SECONDS }),
    ipKey ? env.RATE_LIMIT.put(ipKey, String(byIP + 1), { expirationTtl: DAY_SECONDS * 2 }) : Promise.resolve(),
    env.RATE_LIMIT.put(globalKey, String(overall + 1), { expirationTtl: DAY_SECONDS * 2 }),
  ]);
  return true;
}
