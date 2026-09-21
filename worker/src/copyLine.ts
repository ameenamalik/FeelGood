// The copy line sits above the menu as the Today headline, so it has to be a
// whole, short, plain sentence or nothing. Anything else returns null and the
// client keeps the deterministic template headline it already rendered.
// Pure and dependency-free so it runs under `node --test`.

/** Long enough for the register in the prompt's examples, short enough for two or three lines of display type. */
export const MAX_LINE_CHARS = 90;

// The model only ever sees session ids and reason codes, so when it has nothing
// specific to say it narrates the system. That is filler, not framing.
const SYSTEM_TALK = /\b(today'?s|your|these|the)\s+(picks?|menu|sessions?|recommendations?)\b|\b(engine|algorithm|based on your)\b/i;

/**
 * Returns the line if it is safe to show, otherwise null.
 * `finishReason` is Gemini's: anything other than STOP means the reply was cut
 * off (MAX_TOKENS), safety-blocked, or otherwise incomplete.
 */
export function acceptCopyLine(text: string | null | undefined, finishReason?: string | null): string | null {
  if (!text) return null;
  if (finishReason && finishReason !== "STOP") return null;

  const line = text.trim().replace(/^["“'‘]+|["”'’]+$/g, "").trim();
  if (line.length === 0) return null;
  if (/[\r\n]/.test(line)) return null; // one line only
  if (line.length > MAX_LINE_CHARS) return null;
  if (!/[.!?]$/.test(line)) return null; // a cut-off sentence has no ending
  if (SYSTEM_TALK.test(line)) return null;
  return line;
}
