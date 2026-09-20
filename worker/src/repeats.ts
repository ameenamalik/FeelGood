// Chat must not hand back a session the person has already been shown and
// turned down. The client sends every session id it has rendered as a card in
// this conversation (`shown_session_ids`); this module decides when those ids
// are off the table. Pure and dependency-free so it runs under `node --test`.

/** "nahhh" -> "nah", "noooo" -> "no". Any run of 3+ of a letter collapses to one. */
export function collapseRepeats(text: string): string {
  return text.replace(/(.)\1{2,}/g, "$1");
}

/** Normalised form used for matching short replies: trimmed, lowercased, elongation and trailing punctuation removed. */
export function normalizeReply(prompt: string): string {
  return collapseRepeats(prompt.trim().toLowerCase()).replace(/[\s.!?…]+$/g, "");
}

const REJECTIONS = new Set([
  "no",
  "nah",
  "naw",
  "nope",
  "pass",
  "skip",
  "not today",
  "not this",
  "not that",
  "not this one",
  "not that one",
  "not really",
  "not feeling it",
  "not feeling this",
  "something else",
  "another",
  "another one",
  "try another",
  "different one",
  "something different",
  "i don't want that",
  "i dont want that",
  "i don't want this",
  "i dont want this",
]);

/** A reply that turns down whatever was just shown. */
export function isRejection(prompt: string): boolean {
  return REJECTIONS.has(normalizeReply(prompt));
}

// Intents where showing the same card again is the right answer: the person is
// asking about it, agreeing to it, or acting on it.
const REPEAT_OK_INTENTS = new Set(["inquiry", "acknowledgment", "action_trigger"]);

/**
 * Session ids the recommendation must not use. Hidden sessions are always out.
 * Shown sessions are out unless the person is talking about the one on screen,
 * and always out after a rejection, whatever intent the model labelled it.
 */
export function excludedSessionIDs(params: {
  hidden?: string[];
  shown?: string[];
  intent?: string;
  prompt: string;
}): string[] {
  const out = new Set(params.hidden ?? []);
  const shown = params.shown ?? [];
  const wantsFresh = isRejection(params.prompt) || !REPEAT_OK_INTENTS.has(params.intent ?? "");
  if (wantsFresh) for (const id of shown) out.add(id);
  return [...out];
}
