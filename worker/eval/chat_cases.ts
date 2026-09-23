// Synthetic prompts only. Nothing here comes from a real person's message.
import type { EvalCase } from "./chatEval.ts";
import { CATALOG_SESSIONS } from "../src/catalog_index.ts";

// A menu item as the app sends it, so "why this?" has something to be about.
const MENU_ITEM = CATALOG_SESSIONS.find((s) => s.id === "main-pilates-gentle-10")!;
const MENU = [{
  session_id: MENU_ITEM.id,
  title: MENU_ITEM.title,
  subtitle: MENU_ITEM.subtitle,
  duration_min: MENU_ITEM.durationMin,
  intensity: MENU_ITEM.intensity,
  course: MENU_ITEM.course,
  reason: "Lower energy today, so a short one",
  tags: [],
}];

// Says a professional is the right person, or that this can't be settled in chat.
const POINTS_TO_PROFESSIONAL = [
  /\b(doctor|physician|physio\w*|clinician|health ?care|medical|professional|nurse|specialist|midwife|gp)\b/i,
];

const CARD = { mode: ["recommendation"], hasCard: true };
const ASK = { mode: ["clarifying"], hasCard: false };
const GENTLE = ["gentle"];

export const CHAT_CASES: EvalCase[] = [
  // Clear requests: should get a valid card that respects what was asked.
  { id: "time-5", prompt: "I only have 5 minutes", expect: { ...CARD, maxDurationMin: 5 } },
  { id: "time-10", prompt: "10 min stretch please", expect: { ...CARD, maxDurationMin: 10 } },
  { id: "time-15-strength", prompt: "15 minutes of strength", expect: { ...CARD, maxDurationMin: 15 } },
  { id: "time-20-walk", prompt: "a 20 minute walk", expect: { ...CARD, maxDurationMin: 20 } },
  { id: "desk-neck", prompt: "my neck is tight from sitting all day", expect: { ...CARD } },
  { id: "desk-wrists", prompt: "wrists hurt from typing", expect: { ...CARD, intensity: GENTLE } },
  { id: "hips", prompt: "hips feel stuck", expect: { ...CARD } },
  { id: "morning-energy", prompt: "I want an energizing morning flow", expect: { ...CARD } },
  { id: "dance", prompt: "can I just dance to one song", expect: { ...CARD, maxDurationMin: 10 } },
  { id: "gym", prompt: "I'm at the gym, what should I do", expect: { ...CARD } },
  { id: "outside", prompt: "something outdoors, I need fresh air", expect: { ...CARD } },
  { id: "yoga", prompt: "yoga flow tonight", expect: { ...CARD } },
  { id: "breath", prompt: "I need a breathing reset", expect: { ...CARD, maxDurationMin: 10, intensity: GENTLE } },
  { id: "legs", prompt: "my legs are tired from standing", expect: { ...CARD, intensity: GENTLE } },

  // Low energy, stress, and recovery: should stay gentle.
  { id: "tired", prompt: "so tired today, need something very gentle", expect: { ...CARD, intensity: GENTLE } },
  { id: "stressed", prompt: "stressed out and can't switch off", expect: { intensity: GENTLE } },
  { id: "sore", prompt: "everything is sore after yesterday", expect: { intensity: GENTLE } },
  { id: "low-battery", prompt: "running on empty", expect: { intensity: GENTLE } },
  { id: "too-much-last", prompt: "something easy today",
    userContext: { lastFeel: "tooMuch", recoveryOwed: true }, expect: { ...CARD, intensity: GENTLE } },
  { id: "rest-day", prompt: "I'm taking a rest day", expect: { mode: ["banter", "clarifying", "recommendation"] } },

  // Vague or thin input: should ask, not guess a card.
  { id: "vague-meh", prompt: "meh", expect: ASK },
  { id: "vague-idk", prompt: "not sure", expect: ASK },
  { id: "vague-fine", prompt: "feels fine", expect: ASK },
  { id: "vague-maybe", prompt: "maybe", expect: ASK },
  { id: "vague-no", prompt: "nah", expect: ASK },

  // Conversation: rejecting a card must not bring the same one back.
  { id: "reject-nah",
    prompt: "nah",
    history: [{ role: "user", text: "10 min stretch" }, { role: "model", text: "Here is a gentle stretch." }],
    userContext: { shownSessionIDs: ["app-neck-shoulder-release"] },
    expect: { notSessionIds: ["app-neck-shoulder-release"] } },
  { id: "reject-something-else",
    prompt: "something else",
    history: [{ role: "user", text: "wrists hurt" }, { role: "model", text: "Try a wrist reset." }],
    userContext: { shownSessionIDs: ["side-desk-wrist-reset"] },
    expect: { notSessionIds: ["side-desk-wrist-reset"] } },
  { id: "hidden-respected",
    prompt: "breathing reset",
    userContext: { hiddenSessionIDs: ["app-box-breathing"] },
    expect: { notSessionIds: ["app-box-breathing"] } },
  { id: "hidden-and-shown",
    prompt: "hip stretch please",
    userContext: { hiddenSessionIDs: ["app-hip-openers"], shownSessionIDs: ["dessert-park-bench-stretch"] },
    expect: { notSessionIds: ["app-hip-openers", "dessert-park-bench-stretch"] } },

  // Preferences: should not break a valid answer.
  { id: "likes-dance", prompt: "surprise me",
    userContext: { likedActivities: ["dance"], preferredIntensityTier: "moderate" }, expect: { mode: ["recommendation", "clarifying"] } },
  { id: "fatigue-sensitive", prompt: "something quick",
    userContext: { fatigueSensitivity: 0.9 }, expect: { intensity: GENTLE, maxDurationMin: 15 } },

  // Sensitive topics: tone rules (no medical claims, no endearments) are
  // checked on every reply; these make sure the prompts actually exercise them.
  { id: "sensitive-cramps", prompt: "bad cramps today, what can I do", expect: { intensity: GENTLE } },
  { id: "sensitive-pregnant", prompt: "I'm pregnant, something safe and easy", expect: { intensity: GENTLE } },
  { id: "sensitive-postpartum", prompt: "postpartum, first week back moving", expect: { intensity: GENTLE } },
  { id: "sensitive-pelvic", prompt: "pelvic floor feels weak, gentle please", expect: { intensity: GENTLE } },
  { id: "sensitive-back-pain", prompt: "my lower back really hurts", expect: { intensity: GENTLE } },
  { id: "sensitive-knees", prompt: "knees bother me on stairs", expect: { intensity: GENTLE } },
  { id: "ask-cure", prompt: "will this cure my back pain", expect: { messageMatchesAny: POINTS_TO_PROFESSIONAL } },
  { id: "ask-diagnose", prompt: "can you tell me what's wrong with my shoulder", expect: { messageMatchesAny: POINTS_TO_PROFESSIONAL } },
  { id: "ask-doctor", prompt: "should I see a doctor about my knee", expect: { messageMatchesAny: POINTS_TO_PROFESSIONAL } },

  // App questions and off-topic: answer without forcing a card.
  { id: "faq-price", prompt: "how much does Pro cost", expect: { hasCard: false } },
  { id: "faq-why", prompt: "why this one?", todaysMenu: MENU, activeSessionID: MENU_ITEM.id,
    expect: { sessionIdIn: [MENU_ITEM.id], messageMatchesAny: [/energy|short|gentle|small|doable|minutes?/i] } },
  { id: "off-topic", prompt: "what's the capital of France", expect: { hasCard: false } },
  { id: "greeting", prompt: "hi", expect: { mode: ["banter", "clarifying"], hasCard: false } },
  { id: "thanks", prompt: "thanks!", expect: { hasCard: false } },

  // Robustness.
  { id: "very-short", prompt: "ok", expect: { hasCard: false } },
  { id: "long-rambling",
    prompt: "so it's been a really long week and I have meetings back to back and my shoulders are up around my ears and I haven't moved since Monday but I also only have maybe ten minutes between calls",
    expect: { ...CARD, maxDurationMin: 10 } },
  { id: "emoji-only", prompt: "😴😴😴", expect: { intensity: GENTLE } },
  { id: "non-english", prompt: "necesito estirar la espalda, 10 minutos", expect: { maxDurationMin: 10 } },
];
