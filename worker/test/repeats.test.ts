import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { collapseRepeats, excludedSessionIDs, isRejection, normalizeReply } from "../src/repeats.ts";

describe("normalizeReply", () => {
  it("collapses elongation and trailing punctuation", () => {
    assert.equal(normalizeReply("nahhh"), "nah");
    assert.equal(normalizeReply("  Noooo!! "), "no");
    assert.equal(normalizeReply("Not today."), "not today");
  });
  it("leaves ordinary double letters alone", () => {
    assert.equal(collapseRepeats("good feeling"), "good feeling");
  });
});

describe("isRejection", () => {
  it("catches elongated and chip rejections", () => {
    for (const p of ["nahhh", "nope", "Not today", "something else", "Try another", "noooo!"]) {
      assert.equal(isRejection(p), true, p);
    }
  });
  it("does not treat requests as rejections", () => {
    for (const p of ["nothing hurts today", "10 min walk", "why this?", "Gentler option"]) {
      assert.equal(isRejection(p), false, p);
    }
  });
});

describe("excludedSessionIDs", () => {
  const shown = ["main-qi-gong-twenty", "dessert-sauna-quiet-mat"];

  it("always excludes hidden sessions", () => {
    assert.deepEqual(excludedSessionIDs({ hidden: ["a"], intent: "inquiry", prompt: "why this?" }), ["a"]);
  });
  it("keeps the shown card available when the person asks about it", () => {
    assert.deepEqual(excludedSessionIDs({ shown, intent: "inquiry", prompt: "Why this?" }), []);
  });
  it("excludes shown cards for a refinement", () => {
    assert.deepEqual(excludedSessionIDs({ shown, intent: "refinement", prompt: "Gentler option" }).sort(), [...shown].sort());
  });
  it("excludes shown cards after a rejection even if the model called it an inquiry", () => {
    assert.deepEqual(excludedSessionIDs({ shown, intent: "inquiry", prompt: "nahhh" }).sort(), [...shown].sort());
  });
  it("excludes shown cards when the intent is missing", () => {
    assert.equal(excludedSessionIDs({ shown, prompt: "something calmer" }).length, 2);
  });
});
