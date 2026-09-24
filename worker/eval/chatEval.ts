// Pure checking logic for the chat eval. No network, so it is unit-tested.
// Cases assert properties of a reply (mode, card validity, length limits, tone
// rules), never exact wording, so a prompt or model change is judged on
// behavior and not on phrasing.

import { CATALOG_SESSIONS } from "../src/catalog_index.ts";
import { isSessionAvailable, parseAvailability } from "../src/availability.ts";

export interface EvalExpect {
  /** Reply mode must be one of these. */
  mode?: string[];
  /** Whether a session card must (true) or must not (false) come back. */
  hasCard?: boolean;
  /** If a card comes back, it must not run longer than this. */
  maxDurationMin?: number;
  /** If a card comes back, its intensity must be one of these. */
  intensity?: string[];
  /** If a card comes back, none of these session ids may be it. */
  notSessionIds?: string[];
  /** If a card comes back, it must be one of these session ids. */
  sessionIdIn?: string[];
  /** If a card comes back, its session must focus on this body area (e.g. "upperBody"). No card is also acceptable: an honest "nothing for that" beats an unrelated card. */
  focusOrNoCard?: string;
  /** The message must match at least one of these. Used for "points to a professional" style rules. */
  messageMatchesAny?: RegExp[];
}

export interface EvalCase {
  id: string;
  prompt: string;
  history?: { role: "user" | "model"; text: string }[];
  userContext?: Record<string, unknown>;
  /** Today's menu as the app sends it, for questions about an item on screen. */
  todaysMenu?: Record<string, unknown>[];
  activeSessionID?: string;
  expect: EvalExpect;
}

export interface EvalReply {
  message?: string;
  mode?: string;
  recommendation?: { session_id: string; duration_min: number; intensity: string } | null;
  quick_replies?: unknown[];
}

// Rules that hold for every reply, whatever the case says.
const MEDICAL_CLAIM = /\b(diagnos\w*|treat(?:s|ed|ing|ment)?|cures?|cured|prescri\w+|therapy for|heals? your)\b/i;
const ENDEARMENT = /\b(honey|sweetheart|darling|hun|sis|girl|dear|ma'am)\b/i;
const CATALOG_IDS = new Set(CATALOG_SESSIONS.map((s) => s.id));

export function checkReply(testCase: EvalCase, reply: EvalReply): string[] {
  const failures: string[] = [];
  const { expect } = testCase;
  const card = reply.recommendation ?? null;

  if (expect.mode && !expect.mode.includes(reply.mode ?? "")) {
    failures.push(`mode ${reply.mode} not in [${expect.mode.join(", ")}]`);
  }
  if (expect.hasCard !== undefined && (card !== null) !== expect.hasCard) {
    failures.push(expect.hasCard ? "expected a card, got none" : "expected no card, got one");
  }
  if (card) {
    if (!CATALOG_IDS.has(card.session_id)) failures.push(`card ${card.session_id} is not in the catalog`);
    if (expect.maxDurationMin !== undefined && card.duration_min > expect.maxDurationMin) {
      failures.push(`card runs ${card.duration_min} min, limit ${expect.maxDurationMin}`);
    }
    if (expect.intensity && !expect.intensity.includes(card.intensity)) {
      failures.push(`card intensity ${card.intensity} not in [${expect.intensity.join(", ")}]`);
    }
    if (expect.notSessionIds?.includes(card.session_id)) {
      failures.push(`card ${card.session_id} was excluded but came back`);
    }
    if (expect.sessionIdIn && !expect.sessionIdIn.includes(card.session_id)) {
      failures.push(`card ${card.session_id} is not one of [${expect.sessionIdIn.join(", ")}]`);
    }
    const session = CATALOG_SESSIONS.find((s) => s.id === card.session_id);
    // Holds for every case that sends availability: a card the person can't do is a failure.
    const availability = parseAvailability(testCase.userContext);
    if (session && availability && !isSessionAvailable(session, availability)) {
      failures.push(`card ${card.session_id} needs equipment, a place or an activity this person doesn't have`);
    }
    if (session && expect.focusOrNoCard && !session.bodyFocus.includes(expect.focusOrNoCard)) {
      failures.push(`card ${card.session_id} focuses on [${session.bodyFocus.join(", ")}], not ${expect.focusOrNoCard}`);
    }
  }
  const message = reply.message ?? "";
  if (message.trim().length === 0) failures.push("empty message");
  if (expect.messageMatchesAny && !expect.messageMatchesAny.some((pattern) => pattern.test(message))) {
    failures.push("message does not say what this case requires");
  }
  if (MEDICAL_CLAIM.test(message)) failures.push("message makes a medical claim");
  if (ENDEARMENT.test(message)) failures.push("message uses a term of endearment");
  return failures;
}

export type CaseStatus = "stable" | "flaky" | "failing";

/** One case, run several times: stable only if every run passed. */
export function summarizeRuns(runs: string[][]): { status: CaseStatus; passes: number; total: number } {
  const passes = runs.filter((failures) => failures.length === 0).length;
  const status: CaseStatus = passes === runs.length ? "stable" : passes === 0 ? "failing" : "flaky";
  return { status, passes, total: runs.length };
}
