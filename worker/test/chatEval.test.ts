import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { checkReply, type EvalCase } from "../eval/chatEval.ts";
import { CHAT_CASES } from "../eval/chat_cases.ts";
import { CATALOG_SESSIONS } from "../src/catalog_index.ts";

const base: EvalCase = { id: "t", prompt: "p", expect: {} };
const card = { session_id: "app-box-breathing", duration_min: 2, intensity: "gentle" };

describe("chat eval checks", () => {
  it("passes a clean reply", () => {
    const c = { ...base, expect: { mode: ["recommendation"], hasCard: true, maxDurationMin: 5 } };
    assert.deepEqual(checkReply(c, { message: "Here you go.", mode: "recommendation", recommendation: card }), []);
  });

  it("catches a missing or unexpected card, wrong mode, and a too-long card", () => {
    assert.equal(checkReply({ ...base, expect: { hasCard: true } }, { message: "x", mode: "banter" }).length, 1);
    assert.equal(checkReply({ ...base, expect: { hasCard: false } }, { message: "x", recommendation: card }).length, 1);
    assert.equal(checkReply({ ...base, expect: { mode: ["clarifying"] } }, { message: "x", mode: "banter" }).length, 1);
    assert.equal(checkReply({ ...base, expect: { maxDurationMin: 1 } }, { message: "x", recommendation: card }).length, 1);
  });

  it("catches an excluded card coming back and an invented session id", () => {
    assert.equal(checkReply({ ...base, expect: { notSessionIds: [card.session_id] } }, { message: "x", recommendation: card }).length, 1);
    assert.equal(checkReply(base, { message: "x", recommendation: { ...card, session_id: "made-up" } }).length, 1);
  });

  it("applies the tone rules to every reply", () => {
    assert.equal(checkReply(base, { message: "This will cure your back pain." }).length, 1);
    assert.equal(checkReply(base, { message: "You've got this, honey." }).length, 1);
    assert.equal(checkReply(base, { message: "  " }).length, 1);
  });
});

describe("chat eval cases", () => {
  it("have unique ids", () => {
    assert.equal(new Set(CHAT_CASES.map((c) => c.id)).size, CHAT_CASES.length);
  });

  it("only reference real catalog sessions", () => {
    const ids = new Set(CATALOG_SESSIONS.map((s) => s.id));
    for (const c of CHAT_CASES) {
      const referenced = [
        ...(c.expect.notSessionIds ?? []),
        ...((c.userContext?.hiddenSessionIDs as string[] | undefined) ?? []),
        ...((c.userContext?.shownSessionIDs as string[] | undefined) ?? []),
      ];
      for (const id of referenced) assert.ok(ids.has(id), `${c.id} references unknown session ${id}`);
    }
  });
});

import { summarizeRuns } from "../eval/chatEval.ts";

describe("chat eval extras", () => {
  it("requires a message to point to a professional when asked", () => {
    const c: EvalCase = { id: "t", prompt: "p", expect: { messageMatchesAny: [/doctor|professional/i] } };
    assert.deepEqual(checkReply(c, { message: "A physio can help with that." }).length, 1);
    assert.deepEqual(checkReply(c, { message: "Worth checking with a doctor." }), []);
  });

  it("restricts a card to the allowed session ids", () => {
    const c: EvalCase = { id: "t", prompt: "p", expect: { sessionIdIn: ["app-box-breathing"] } };
    const other = { session_id: "app-hip-openers", duration_min: 5, intensity: "gentle" };
    assert.equal(checkReply(c, { message: "x", recommendation: other }).length, 1);
  });

  it("calls a case flaky when only some runs pass", () => {
    assert.equal(summarizeRuns([[], [], []]).status, "stable");
    assert.equal(summarizeRuns([[], ["x"], []]).status, "flaky");
    assert.equal(summarizeRuns([["x"], ["y"]]).status, "failing");
  });

  it("fails a card the person can't do, and a card for the wrong body area", () => {
    const homeOnly = { available_equipment: ["none", "mat"], available_places: ["home"], available_activities: ["stretching"] };
    const gymCard = { session_id: "side-gym-pull-8", duration_min: 8, intensity: "moderate" };
    assert.equal(checkReply({ ...base, userContext: homeOnly }, { message: "x", recommendation: gymCard }).length, 1);
    // No availability sent (older app build): nothing to enforce.
    assert.equal(checkReply(base, { message: "x", recommendation: gymCard }).length, 0);

    const lowerBody = { session_id: "side-skater-bounds", duration_min: 5, intensity: "moderate" };
    assert.equal(checkReply({ ...base, expect: { focusOrNoCard: "upperBody" } }, { message: "x", recommendation: lowerBody }).length, 1);
    assert.equal(checkReply({ ...base, expect: { focusOrNoCard: "upperBody" } }, { message: "No arms session right now." }).length, 0);
  });
});
