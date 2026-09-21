import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { bodyFocusLabel } from "../src/labels.ts";
import { CATALOG_SESSIONS } from "../src/catalog_index.ts";

describe("bodyFocusLabel", () => {
  it("turns the raw enum into card words", () => {
    assert.equal(bodyFocusLabel("neckShoulders"), "Neck & Shoulders");
    assert.equal(bodyFocusLabel("lowerBody"), "Lower Body");
  });

  it("has a label for every bodyFocus the catalog uses", () => {
    const focuses = new Set(CATALOG_SESSIONS.flatMap((s) => s.bodyFocus));
    for (const focus of focuses) {
      assert.notEqual(bodyFocusLabel(focus), focus, `no display label for "${focus}"`);
    }
  });
});
