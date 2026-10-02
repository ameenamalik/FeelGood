import type { ExtractedCheckIn, QuickReplyAction } from "./chat";

// The app draws a chip's symbol with Image(systemName:), so only a real SF
// Symbol name shows anything. The model invents emoji, SVG and made-up names,
// all of which render as blank space. Each action gets a known name instead.
const ACTION_SYMBOLS: Record<Exclude<QuickReplyAction["action_type"], "custom_prompt">, string> = {
  commit_to_today: "plus",
  ask_why: "questionmark.circle",
  swap_routine: "arrow.triangle.2.circlepath",
  filter_gentler: "leaf",
  filter_shorter: "clock.arrow.circlepath",
  filter_more_energizing: "bolt",
  filter_staying_in: "house",
  start_session: "play.fill",
};

// Names the app and the fallback chips already use. A custom prompt keeps the
// model's symbol only when it is one of these.
const CUSTOM_PROMPT_SYMBOLS = new Set([
  "figure.mind.and.body",
  "wind",
  "figure.cooldown",
  "bed.double",
  "figure.walk",
  "battery.25",
  "sun.max",
  "clock",
  "leaf",
  "house",
  "moon",
  "heart",
  "sparkles",
]);

/**
 * Makes quick replies safe for the app to render and act on.
 * - symbol: replaced by the action's known SF Symbol; a custom prompt keeps its
 *   own only when it is a known name, otherwise it has none.
 * - payload: the app reads it only for custom_prompt (what to send). For every
 *   other action it is dropped, so the label text can't pass for a session id.
 */
export function sanitizeQuickReplies(replies: QuickReplyAction[]): QuickReplyAction[] {
  return replies.map((reply) => {
    const { symbol, payload, ...rest } = reply;
    const clean: QuickReplyAction = { ...rest };

    if (reply.action_type === "custom_prompt") {
      if (symbol && CUSTOM_PROMPT_SYMBOLS.has(symbol)) clean.symbol = symbol;
      if (payload) clean.payload = payload;
    } else {
      clean.symbol = ACTION_SYMBOLS[reply.action_type];
    }
    return clean;
  });
}

// "Out" in the app means anywhere that isn't the gym or the floor at home:
// PlaceIntent.happyToGoOut covers home, outdoors, studio and pool.
const GYM_WORDS = /\b(gym|weights?|dumbbells?|barbells?|kettlebells?|cables?|machines?|treadmill|elliptical|rack)\b/;
const OUT_WORDS = /\b(pool|swim|swimming|outside|outdoors?|park|jog|jogging|run|running|walk|walking|hike|hiking|studio|bike|biking|cycling)\b/;

/**
 * The model has no value for "the pool" or "outside" in its place enum, so it
 * reaches for atTheGym. If the person never mentioned a gym and did mention
 * somewhere else, that is happyToGoOut.
 */
export function correctPlace(place: ExtractedCheckIn["place"], prompt: string): ExtractedCheckIn["place"] {
  if (place !== "atTheGym") return place;
  const text = prompt.toLowerCase();
  if (GYM_WORDS.test(text)) return place;
  return OUT_WORDS.test(text) ? "happyToGoOut" : place;
}
