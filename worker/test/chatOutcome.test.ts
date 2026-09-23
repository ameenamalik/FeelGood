import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { buildChatOutcome, CHAT_OUTCOME_KEYS } from "../src/chatOutcome.ts";

const TYPED = "my pelvic floor hurts after the baby, help";

const base = { prompt: TYPED, historyTurns: 2, startedAt: 1000, now: 1450 };

describe("chat outcome log line", () => {
  it("has exactly the permitted keys", () => {
    const outcome = buildChatOutcome({ ...base, mode: "recommendation", hasCard: true });
    assert.deepEqual(Object.keys(outcome).sort(), [...CHAT_OUTCOME_KEYS].sort());
  });

  it("never contains what the person typed", () => {
    const outcome = buildChatOutcome({ ...base, mode: "clarifying", intent: "general_check_in" });
    const line = JSON.stringify(outcome);
    for (const word of TYPED.split(" ").filter((w) => w.length > 4)) {
      assert.ok(!line.includes(word), `"${word}" reached the log line`);
    }
    assert.equal(outcome.prompt_length, "medium");
  });

  it("cannot be used to smuggle text through model-controlled fields", () => {
    const outcome = buildChatOutcome({
      ...base,
      mode: "Sure, since you mentioned pregnancy...",
      intent: "Sure, since you mentioned pregnancy...",
      phase: "x".repeat(200),
    });
    assert.equal(outcome.mode, "other");
    assert.equal(outcome.intent, "other");
    assert.equal(outcome.phase, "other");
  });

  it("records latency, failures, and dropped cards", () => {
    const ok = buildChatOutcome({ ...base, hasCard: false, modelProposedCard: true });
    assert.equal(ok.latency_ms, 450);
    assert.equal(ok.card_dropped, true);
    const failed = buildChatOutcome({ ...base, failure: "gemini_error", upstreamStatus: 429 });
    assert.equal(failed.ok, false);
    assert.equal(failed.upstream_status, 429);
    assert.equal(failed.card_dropped, false);
  });
});
