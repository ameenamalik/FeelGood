// Pure checking logic for the chat eval. No network, so it is unit-tested.
// Cases assert properties of a reply (mode, card validity, length limits, tone
// rules), never exact wording, so a prompt or model change is judged on
// behavior and not on phrasing.

import { CATALOG_SESSIONS } from "../src/catalog_index.ts";

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
}

export interface EvalCase {
  id: string;
  prompt: string;
  history?: { role: "user" | "model"; text: string }[];
  userContext?: Record<string, unknown>;
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
  }
  const message = reply.message ?? "";
  if (message.trim().length === 0) failures.push("empty message");
  if (MEDICAL_CLAIM.test(message)) failures.push("message makes a medical claim");
  if (ENDEARMENT.test(message)) failures.push("message uses a term of endearment");
  return failures;
}
