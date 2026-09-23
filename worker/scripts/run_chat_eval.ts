// Runs the synthetic chat cases against a deployed Worker and reports the pass
// rate. Prompts are made up; nothing real is sent.
//
//   CHAT_EVAL_SUBSCRIBER_ID=<RevenueCat app user id of a Pro sandbox account> \
//   npm run eval:chat
//
// CHAT_EVAL_URL   Worker base URL (default: production)
// CHAT_EVAL_MIN   minimum pass rate, 0 to 1 (default 0.9)
// CHAT_EVAL_ONLY  run only case ids containing this text
// CHAT_EVAL_RUNS  run each case this many times (default 1). A case passes only if
//                 every run does; some-but-not-all is reported as flaky.
// CHAT_EVAL_SHOW  set to 1 to print each reply, for reading yourself. The replies are
//                 to made-up prompts, so nothing personal is printed.
//
// One run of every case takes about six minutes because of the Worker's rate limit,
// and CHAT_EVAL_RUNS=3 about eighteen.

import { CHAT_CASES } from "../eval/chat_cases.ts";
import { checkReply, summarizeRuns, type EvalReply } from "../eval/chatEval.ts";

const baseURL = process.env.CHAT_EVAL_URL ?? "https://feelgood-copy-production.ameenazara3.workers.dev";
const subscriberID = process.env.CHAT_EVAL_SUBSCRIBER_ID;
const minRate = Number(process.env.CHAT_EVAL_MIN ?? "0.9");
const only = process.env.CHAT_EVAL_ONLY;

if (!subscriberID) {
  console.error("Set CHAT_EVAL_SUBSCRIBER_ID to a Pro sandbox account's id. The Worker only answers subscribers.");
  process.exit(2);
}

const runsPerCase = Math.max(1, Number(process.env.CHAT_EVAL_RUNS ?? "1"));
const show = process.env.CHAT_EVAL_SHOW === "1";
const cases = only ? CHAT_CASES.filter((c) => c.id.includes(only)) : CHAT_CASES;

let stable = 0;
const flaky: string[] = [];
const failing: string[] = [];

async function runOnce(testCase: (typeof CHAT_CASES)[number]): Promise<string[]> {
  try {
    const res = await fetch(`${baseURL}/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        prompt: testCase.prompt,
        subscriberID,
        history: testCase.history,
        userContext: testCase.userContext,
        todaysMenu: testCase.todaysMenu,
        activeSessionID: testCase.activeSessionID,
      }),
    });
    if (!res.ok) return [`HTTP ${res.status}`];
    const reply = (await res.json()) as EvalReply;
    if (show) {
      const card = reply.recommendation ? ` [card: ${reply.recommendation.session_id}, ${reply.recommendation.duration_min} min]` : "";
      console.log(`        > ${testCase.prompt}\n        < ${reply.message ?? ""}${card}`);
    }
    return checkReply(testCase, reply);
  } catch (error) {
    return [`request failed: ${error instanceof Error ? error.message : "unknown"}`];
  }
}

for (const testCase of cases) {
  const runs: string[][] = [];
  for (let i = 0; i < runsPerCase; i += 1) {
    runs.push(await runOnce(testCase));
    // The Worker allows 10 requests a minute per subscriber; 7s keeps under it.
    await new Promise((resolve) => setTimeout(resolve, 7000));
  }
  const { status, passes, total } = summarizeRuns(runs);
  const firstFailure = runs.find((failures) => failures.length > 0)?.join("; ");
  if (status === "stable") {
    stable += 1;
    console.log(`  ok     ${testCase.id}`);
  } else if (status === "flaky") {
    flaky.push(testCase.id);
    console.log(`  FLAKY  ${testCase.id} (${passes}/${total}): ${firstFailure}`);
  } else {
    failing.push(testCase.id);
    console.log(`  FAIL   ${testCase.id}: ${firstFailure}`);
  }
}

const rate = cases.length === 0 ? 0 : stable / cases.length;
console.log(
  `\n${stable}/${cases.length} stable (${(rate * 100).toFixed(0)}%), ${flaky.length} flaky, ${failing.length} failing, ` +
    `${runsPerCase} run${runsPerCase === 1 ? "" : "s"} each, minimum ${(minRate * 100).toFixed(0)}%`
);
process.exit(rate >= minRate ? 0 : 1);
