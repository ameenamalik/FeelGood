import { test } from "node:test";
import assert from "node:assert/strict";
import { drainSseData, partialMessage, sseFrame } from "../src/messageStream.ts";

test("nothing is shown until the message field starts", () => {
  assert.equal(partialMessage(""), "");
  assert.equal(partialMessage('{"mod'), "");
  assert.equal(partialMessage('{"message'), "");
});

test("the message grows as fragments arrive", () => {
  assert.equal(partialMessage('{"message": "Got'), "Got");
  assert.equal(partialMessage('{"message": "Got it. Rest'), "Got it. Rest");
  assert.equal(partialMessage('{"message": "Got it.", "mode": "banter"}'), "Got it.");
});

test("escapes are decoded, and a half-arrived one waits", () => {
  assert.equal(partialMessage('{"message":"Say \\"hi\\"\\nthen rest'), 'Say "hi"\nthen rest');
  assert.equal(partialMessage('{"message":"abc\\'), "abc");
  assert.equal(partialMessage('{"message":"abc\\u00'), "abc");
  assert.equal(partialMessage('{"message":"caf\\u00e9"}'), "café");
});

test("every prefix of a document yields a prefix of the final message", () => {
  const doc = JSON.stringify({ message: 'It\'s "easy" — 5 min\nno rush.', mode: "banter" });
  const final = partialMessage(doc);
  let previous = "";
  for (let i = 0; i <= doc.length; i++) {
    const text = partialMessage(doc.slice(0, i));
    assert.ok(final.startsWith(text), `prefix ${i}`);
    assert.ok(text.startsWith(previous), `grows ${i}`);
    previous = text;
  }
  assert.equal(final, 'It\'s "easy" — 5 min\nno rush.');
});

test("SSE data is split on blank lines and the tail is kept", () => {
  const first = drainSseData('data: {"a":1}\n\ndata: {"b":2}\n\ndata: {"c"');
  assert.deepEqual(first.payloads, ['{"a":1}', '{"b":2}']);
  const second = drainSseData(first.rest + ':3}\r\n\r\n');
  assert.deepEqual(second.payloads, ['{"c":3}']);
  assert.equal(second.rest, "");
});

test("a frame names its event", () => {
  assert.equal(sseFrame("delta", { text: "hi" }), 'event: delta\ndata: {"text":"hi"}\n\n');
});
