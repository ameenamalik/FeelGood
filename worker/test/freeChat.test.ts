import { describe, expect, it } from "vitest";
import { consumeFreeChat } from "../src/freeChat";
import type { Env } from "../src/types";

function fakeEnv(dailyLimit?: string): Env {
  const store = new Map<string, string>();
  const kv = {
    get: async (key: string) => store.get(key) ?? null,
    put: async (key: string, value: string) => {
      store.set(key, value);
    },
  } as unknown as KVNamespace;
  return { RATE_LIMIT: kv, FREE_CHAT_DAILY_LIMIT: dailyLimit };
}

const now = Date.UTC(2026, 8, 26, 12);

describe("consumeFreeChat", () => {
  it("allows one free exchange per subscriber", async () => {
    const env = fakeEnv();
    expect(await consumeFreeChat("sub-a", "1.1.1.1", env, now)).toBe(true);
    expect(await consumeFreeChat("sub-a", "1.1.1.1", env, now)).toBe(false);
  });

  it("stops invented ids from one IP after the daily cap", async () => {
    const env = fakeEnv();
    const results = [];
    for (let i = 0; i < 7; i++) {
      results.push(await consumeFreeChat(`sub-${i}`, "2.2.2.2", env, now));
    }
    expect(results.filter(Boolean)).toHaveLength(5);
    expect(await consumeFreeChat("sub-other", "3.3.3.3", env, now)).toBe(true);
  });

  it("stops everyone at the global daily ceiling", async () => {
    const env = fakeEnv("2");
    expect(await consumeFreeChat("a", "4.4.4.1", env, now)).toBe(true);
    expect(await consumeFreeChat("b", "4.4.4.2", env, now)).toBe(true);
    expect(await consumeFreeChat("c", "4.4.4.3", env, now)).toBe(false);
  });

  it("gives the IP and global caps back the next day, but not the subscriber's", async () => {
    const env = fakeEnv("1");
    expect(await consumeFreeChat("a", "5.5.5.5", env, now)).toBe(true);
    const tomorrow = now + 24 * 60 * 60 * 1000;
    expect(await consumeFreeChat("a", "5.5.5.5", env, tomorrow)).toBe(false);
    expect(await consumeFreeChat("b", "5.5.5.5", env, tomorrow)).toBe(true);
  });
});
