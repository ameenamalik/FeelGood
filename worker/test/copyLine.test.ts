import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { acceptCopyLine, MAX_LINE_CHARS } from "../src/copyLine.ts";

describe("acceptCopyLine", () => {
  it("accepts the prompt's own examples", () => {
    assert.equal(acceptCopyLine("Good to see you. Let's start small."), "Good to see you. Let's start small.");
    const long = "You've shown up a few days running — today's a lighter one on purpose.";
    assert.equal(acceptCopyLine(long), long);
  });

  it("strips wrapping quotes and whitespace", () => {
    assert.equal(acceptCopyLine('  "Good to see you."  '), "Good to see you.");
  });

  it("rejects a reply Gemini cut off, even when the text looks like a sentence", () => {
    assert.equal(acceptCopyLine("Slow morning, so we kept it soft.", "MAX_TOKENS"), null);
  });

  it("rejects a sentence with no ending, the signature of truncation", () => {
    assert.equal(acceptCopyLine("Today's picks match what"), null);
    assert.equal(acceptCopyLine("A softer start because you"), null);
  });

  it("rejects system talk about picks and menus", () => {
    assert.equal(acceptCopyLine("Today's picks match what you told us."), null);
    assert.equal(acceptCopyLine("Your picks match how you're feeling."), null);
    assert.equal(acceptCopyLine("The menu is tuned to your energy."), null);
  });

  it("rejects multi-line and over-long replies", () => {
    assert.equal(acceptCopyLine("Good to see you.\nLet's start small."), null);
    assert.equal(acceptCopyLine("a".repeat(MAX_LINE_CHARS) + "."), null);
  });

  it("rejects empty input", () => {
    assert.equal(acceptCopyLine(""), null);
    assert.equal(acceptCopyLine(undefined), null);
    assert.equal(acceptCopyLine("   "), null);
  });
});
