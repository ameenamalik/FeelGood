// One structured log line per chat request: what happened, never what was said.
//
// The privacy policy says the server does not keep chat text, so this is how
// chat quality is measured instead: error rate, latency, how often a card comes
// back, how often the model's card is dropped. Every field is a number,
// boolean, or a value from a closed set. There is deliberately no field that
// can hold free text, and `test/chatOutcome.test.ts` fails if one is added.

export type ChatFailure = "none" | "gemini_error" | "empty_response" | "exception";

export interface ChatOutcome {
  event: "chat_outcome";
  ok: boolean;
  failure: ChatFailure;
  upstream_status: number | null;
  latency_ms: number;
  model: string | null;
  mode: string | null;
  intent: string | null;
  phase: string | null;
  has_card: boolean;
  card_dropped: boolean;
  quick_reply_count: number;
  extracted_check_in: boolean;
  history_turns: number;
  prompt_length: "short" | "medium" | "long";
}

export const CHAT_OUTCOME_KEYS: readonly (keyof ChatOutcome)[] = [
  "event",
  "ok",
  "failure",
  "upstream_status",
  "latency_ms",
  "model",
  "mode",
  "intent",
  "phase",
  "has_card",
  "card_dropped",
  "quick_reply_count",
  "extracted_check_in",
  "history_turns",
  "prompt_length",
];

const MODES = new Set(["clarifying", "banter", "recommendation"]);

// Only values the schema allows are recorded. Anything else becomes "other", so
// a model that put a sentence in one of these fields cannot smuggle it into the log.
function closed(value: unknown, allowed?: Set<string>): string | null {
  if (typeof value !== "string" || value.length === 0) return null;
  if (allowed) return allowed.has(value) ? value : "other";
  return /^[a-z_]{1,40}$/.test(value) ? value : "other";
}

function promptLength(prompt: string): ChatOutcome["prompt_length"] {
  if (prompt.length <= 40) return "short";
  if (prompt.length <= 200) return "medium";
  return "long";
}

export interface ChatOutcomeInput {
  prompt: string;
  historyTurns: number;
  startedAt: number;
  now: number;
  model?: string | null;
  upstreamStatus?: number | null;
  failure?: ChatFailure;
  mode?: unknown;
  intent?: unknown;
  phase?: unknown;
  hasCard?: boolean;
  modelProposedCard?: boolean;
  quickReplyCount?: number;
  extractedCheckIn?: boolean;
}

export function buildChatOutcome(input: ChatOutcomeInput): ChatOutcome {
  const failure = input.failure ?? "none";
  const hasCard = input.hasCard ?? false;
  return {
    event: "chat_outcome",
    ok: failure === "none",
    failure,
    upstream_status: input.upstreamStatus ?? null,
    latency_ms: Math.max(0, Math.round(input.now - input.startedAt)),
    model: closed(input.model),
    mode: closed(input.mode, MODES),
    intent: closed(input.intent),
    phase: closed(input.phase),
    has_card: hasCard,
    card_dropped: (input.modelProposedCard ?? false) && !hasCard,
    quick_reply_count: input.quickReplyCount ?? 0,
    extracted_check_in: input.extractedCheckIn ?? false,
    history_turns: input.historyTurns,
    prompt_length: promptLength(input.prompt),
  };
}

export function logChatOutcome(outcome: ChatOutcome): void {
  console.log(JSON.stringify(outcome));
}
