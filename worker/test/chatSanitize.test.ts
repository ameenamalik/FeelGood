import { test } from "node:test";
import assert from "node:assert/strict";
import { correctPlace, sanitizeQuickReplies } from "../src/chatSanitize.ts";
import type { QuickReplyAction } from "../src/chat.ts";

test("a pool prompt the model called atTheGym becomes happyToGoOut", () => {
  assert.equal(correctPlace("atTheGym", "I am at the pool, I want an easy swim"), "happyToGoOut");
  assert.equal(correctPlace("atTheGym", "I am heading outside for an easy jog"), "happyToGoOut");
});

test("an actual gym prompt keeps atTheGym", () => {
  assert.equal(correctPlace("atTheGym", "I am at the gym with dumbbells"), "atTheGym");
  assert.equal(correctPlace("atTheGym", "gym then a run on the treadmill"), "atTheGym");
  assert.equal(correctPlace("atTheGym", "something quick"), "atTheGym");
});

test("other places are left alone", () => {
  assert.equal(correctPlace("stayingIn", "swim at the pool"), "stayingIn");
  assert.equal(correctPlace(undefined, "swim at the pool"), undefined);
});

test("every non-custom chip gets a known symbol and no payload", () => {
  const replies: QuickReplyAction[] = [
    { id: "a", label: "Sounds good", action_type: "commit_to_today", symbol: "✅", payload: "Sounds good" },
    { id: "b", label: "Why", action_type: "ask_why", symbol: "<svg width=\"24\"></svg>", payload: "why_this_one" },
    { id: "c", label: "Else", action_type: "swap_routine", symbol: "arrow_cycle" },
    { id: "d", label: "Shorter", action_type: "filter_shorter", payload: "shorter" },
  ];
  const clean = sanitizeQuickReplies(replies);
  assert.deepEqual(clean.map((r) => r.symbol), [
    "plus",
    "questionmark.circle",
    "arrow.triangle.2.circlepath",
    "clock.arrow.circlepath",
  ]);
  assert.ok(clean.every((r) => r.payload === undefined));
});

test("a custom prompt keeps its payload, and its symbol only if known", () => {
  const clean = sanitizeQuickReplies([
    { id: "a", label: "Breath reset", action_type: "custom_prompt", symbol: "wind", payload: "a short breath reset" },
    { id: "b", label: "Floor stretch", action_type: "custom_prompt", symbol: "floor_stretch_icon", payload: "a quiet floor stretch" },
  ]);
  assert.equal(clean[0].symbol, "wind");
  assert.equal(clean[0].payload, "a short breath reset");
  assert.equal(clean[1].symbol, undefined);
  assert.equal(clean[1].payload, "a quiet floor stretch");
});

test("sanitizing does not change ids, labels or action types", () => {
  const [r] = sanitizeQuickReplies([{ id: "x", label: "Add to today", action_type: "commit_to_today" }]);
  assert.equal(r.id, "x");
  assert.equal(r.label, "Add to today");
  assert.equal(r.action_type, "commit_to_today");
});
