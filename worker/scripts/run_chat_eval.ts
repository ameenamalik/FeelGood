// Runs the synthetic chat cases against a deployed Worker and reports the pass
// rate. Prompts are made up; nothing real is sent.
//
//   CHAT_EVAL_SUBSCRIBER_ID=<RevenueCat app user id of a Pro sandbox account> \
//   npm run eval:chat
//
// CHAT_EVAL_URL   Worker base URL (default: production)
// CHAT_EVAL_MIN   minimum pass rate, 0 to 1 (default 0.9)
// CHAT_EVAL_ONLY  run only case ids containing this text
//
// A full run takes about five minutes because of the Worker's rate limit.

import { CHAT_CASES } from "../eval/chat_cases.ts";
import { checkReply, type EvalReply } from "../eval/chatEval.ts";

const baseURL = process.env.CHAT_EVAL_URL ?? "https://feelgood-copy-production.ameenazara3.workers.dev";
const subscriberID = process.env.CHAT_EVAL_SUBSCRIBER_ID;
const minRate = Number(process.env.CHAT_EVAL_MIN ?? "0.9");
const only = process.env.CHAT_EVAL_ONLY;

if (!subscriberID) {
  console.error("Set CHAT_EVAL_SUBSCRIBER_ID to a Pro sandbox account's id. The Worker only answers subscribers.");
  process.exit(2);
}

const cases = only ? CHAT_CASES.filter((c) => c.id.includes(only)) : CHAT_CASES;
let passed = 0;
const failed: string[] = [];

for (const testCase of cases) {
  let failures: string[];
  try {
    const res = await fetch(`${baseURL}/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        prompt: testCase.prompt,
        subscriberID,
        history: testCase.history,
        userContext: testCase.userContext,
      }),
    });
    failures = res.ok
      ? checkReply(testCase, (await res.json()) as EvalReply)
      : [`HTTP ${res.status}`];
  } catch (error) {
    failures = [`request failed: ${error instanceof Error ? error.message : "unknown"}`];
  }

  if (failures.length === 0) {
    passed += 1;
    console.log(`  ok    ${testCase.id}`);
  } else {
    failed.push(testCase.id);
    console.log(`  FAIL  ${testCase.id}: ${failures.join("; ")}`);
  }
  // The Worker allows 10 requests a minute per subscriber; 7s keeps under it.
  await new Promise((resolve) => setTimeout(resolve, 7000));
}

const rate = cases.length === 0 ? 0 : passed / cases.length;
console.log(`\n${passed}/${cases.length} passed (${(rate * 100).toFixed(0)}%), minimum ${(minRate * 100).toFixed(0)}%`);
process.exit(rate >= minRate ? 0 : 1);
