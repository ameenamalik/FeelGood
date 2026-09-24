import { buildChatOutcome, logChatOutcome, type ChatFailure, type ChatOutcomeInput } from "./chatOutcome";
import { Env } from "./types";
import { CATALOG_SESSIONS, findSessionById, matchBestSession, CatalogSessionItem, searchGlossary } from "./catalog_index";
import { queryAISearch } from "./ai_search";
import { traceAgentTurn, traceChatModel, traceToolExecution } from "./tracing";
import { excludedSessionIDs, isRejection, normalizeReply } from "./repeats";
import { bodyFocusLabel } from "./labels";
import { aliasSnakeCaseFields } from "./payloadKeys";
import { isSessionAvailable, parseAvailability, type Availability, type AvailabilityFields } from "./availability";

export type ChatRole = "user" | "assistant" | "model";

export interface ChatMessage {
  role: ChatRole;
  content?: string;
  text?: string;
}

export interface ChatTurnPayload {
  role: ChatRole;
  text: string;
}

export interface UserPreferencesContext extends AvailabilityFields {
  likedActivities?: string[];
  lastFeel?: "lovedIt" | "fine" | "tooMuch";
  recentCompletions?: number;
  recoveryOwed?: boolean;
  hiddenSessionIDs?: string[];
  hidden_session_ids?: string[];
  // Every session the client has rendered as a card in this conversation.
  shownSessionIDs?: string[];
  shown_session_ids?: string[];
  preferredIntensityTier?: "gentle" | "moderate" | "dynamic";
  preferred_intensity_tier?: "gentle" | "moderate" | "dynamic";
  topExploredActivities?: string[];
  top_explored_activities?: string[];
  fatigueSensitivity?: number;
  fatigue_sensitivity?: number;
}

export interface ChatPayload {
  prompt: string;
  subscriberID: string;
  history?: ChatMessage[];
  currentTimeBudget?: string;
  activeSessionID?: string;
  userContext?: UserPreferencesContext;
  todaysMenu?: StructuredRecommendation[];
}

export interface ExtractedCheckIn {
  energy?: "low" | "steady" | "strong";
  timeBudget?:
    | "fiveMinutes"
    | "aLittle"
    | "fifteenMinutes"
    | "twentyMinutes"
    | "twentyFiveMinutes"
    | "some"
    | "thirtyFiveMinutes"
    | "fortyMinutes"
    | "plenty";
  place?: "stayingIn" | "happyToGoOut" | "atTheGym";
  body?: "sore" | "stiff" | "stressed" | "cramping" | "good";
  intent?: "energize" | "strengthen" | "calm" | "mobilize" | "joy";
  quickFilter?: "shorter" | "gentler" | "moreEnergizing" | "canNotLeave";
}

export interface QuickReplyAction {
  id: string;
  label: string;
  symbol?: string;
  action_type:
    | "commit_to_today"
    | "ask_why"
    | "swap_routine"
    | "filter_gentler"
    | "filter_shorter"
    | "filter_more_energizing"
    | "filter_staying_in"
    | "start_session"
    | "custom_prompt";
  payload?: string;
}

export interface StructuredRecommendation {
  session_id: string;
  title: string;
  subtitle: string;
  duration_min: number;
  intensity: "gentle" | "moderate" | "dynamic";
  course: "appetizer" | "main" | "side" | "dessert" | "special";
  reason: string;
  tags: string[];
  equipment?: string[];
  target_area?: string;
}

export type ChatMode = "clarifying" | "banter" | "recommendation";

export interface ChatResponseData {
  message: string;
  mode: ChatMode;
  intent:
    | "new_routine_request"
    | "inquiry"
    | "acknowledgment"
    | "refinement"
    | "action_trigger"
    | "general_check_in";
  phase:
    | "greeting"
    | "needs_discovery"
    | "recommendation_active"
    | "routine_committed"
    | "inquiry_active";
  recommendation?: StructuredRecommendation | null;
  quick_replies: QuickReplyAction[];
  extracted_check_in?: ExtractedCheckIn | null;
}

// Compact catalog summary embedded for high model accuracy
const CATALOG_PLACEHOLDER = "{{CATALOG}}";

// Only sessions this person can do today are shown to the model, so it cannot
// pick a gym routine for someone with no gym.
function buildCatalogSummary(availability: Availability | null): string {
  return CATALOG_SESSIONS.filter((s) => isSessionAvailable(s, availability))
    .map(
      (s) =>
        `[${s.id}] "${s.title}" (${s.durationMin}m, ${s.intensity}, ${s.course}, focus: ${s.bodyFocus.join("/") || "full"}, places: ${s.places.join("/")}, intents: ${s.intents.join("/")})`
    )
    .join("\n");
}

const CHAT_SYSTEM_PROMPT = `You are FeelGood, a warm, calm, unhurried daily wellness companion.
Your user is conversing with you about their movement, how they feel today, adjusting routines, or asking questions about workouts and yoga.

CORE PRINCIPLES:
1. Speak warmly and calmly, like an empathetic friend who knows their week. Notice how they feel and reflect it back briefly before suggesting anything. Keep responses short (1-2 sentences).
1a. REGISTER: Plain, natural, and a little understated, never theatrical or old-fashioned. Address the person as "you" only. NEVER use terms of endearment or pet names of any kind ("my dear", "dear", "honey", "sweetheart", "darling", "love", "friend", "girl", "sis", "hun"), and do not open with a stage-y interjection like "Ah," or "Oh, my". Never assume the person's gender.
2. Never make medical or diagnostic claims. Never mention streaks, calories, numbers, or guilt. Describe what a session involves (how it moves, how gentle it is, what it needs, how long it takes), never what it will do to the body or mind. Do not say a session will relieve, release, ease, treat, heal, fix, reset, calm, or reduce anything (tension, pain, stress, anxiety, tightness, a racing heart), and do not explain bodily or physiological effects.
3. GROUNDING: You MUST recommend ONLY real routines from the catalog below using their exact session ID:
${CATALOG_PLACEHOLDER}

3a. BODY AREA: When the user names an area (arms, legs, core, back, shoulders), only recommend a session whose focus includes it. If nothing in the list above targets that area, do not offer an unrelated session: say plainly that you don't have one for it right now, and offer the closest thing (e.g. upper body or back work) as a question with no session_id.

4. TIME BUDGET CEILING: When the user specifies a time limit or available duration (e.g., "10 minutes", "5 min", "2 min"), treat it as a strict upper bound. NEVER recommend a routine longer than their requested duration! Always pick a routine where durationMin <= requested time (e.g. if they say "10 min", pick a 3, 5, or 10 min routine, NEVER 15+ min).

5. UNDERSTAND CONVERSATION FLOW:
   - Routine request ("tired, 15 min", "tight hips", "quick reset"): Classify as 'new_routine_request', pick the best session_id from catalog, explain why warmly in 1 sentence, and provide relevant quick replies.
   - Why inquiry ("Why this?", "Why today's plan?"): Classify as 'inquiry', explain in 1-2 plain sentences why it fits what they told you: their time, their energy, and what the session involves (e.g., "You said you're wiped and short on time, so this is a gentle three minutes you can do sitting down, nothing to set up."). Never explain it in terms of what it will do to their body, and maintain the recommendation.
   - Refinement ("shorter", "gentler", "staying in"): Classify as 'refinement', pick a newly adjusted session_id from catalog, and confirm calmly.
   - Acknowledgment ("ok", "sounds good", "perfect"): Classify as 'acknowledgment' and confirm warmly.
   - Action trigger ("add to today", "let's do it", "start"): Classify as 'action_trigger'.
   - Vague / Incomplete / Ambiguous ("no", "nah", "it feels okay", "feels fine", "not sure", "meh", "maybe"): DO NOT return an exercise recommendation card! Classify as phase: 'needs_discovery' and intent: 'general_check_in'. Do not return a session_id. Ask a gentle clarifying question (e.g. "Got it. Would you prefer a short breath reset, a gentle floor stretch, or something to build a little energy?") and provide 3-4 discovery quick replies.`;

export function isValidChatPayload(body: unknown): body is ChatPayload {
  if (typeof body !== "object" || body === null) return false;
  const record = body as Record<string, unknown>;
  if (typeof record.prompt !== "string" || record.prompt.trim().length === 0) return false;
  if (typeof record.subscriberID !== "string" || record.subscriberID.length === 0) return false;
  if (record.history !== undefined) {
    if (!Array.isArray(record.history)) return false;
    for (const msg of record.history) {
      if (typeof msg !== "object" || msg === null) return false;
      const m = msg as Record<string, unknown>;
      if (m.role !== "user" && m.role !== "assistant" && m.role !== "model") return false;
      const textVal = typeof m.text === "string" ? m.text : typeof m.content === "string" ? m.content : undefined;
      if (textVal === undefined) return false;
    }
  }
  aliasSnakeCaseFields(record);
  return true;
}

export async function handleChat(payload: ChatPayload, env: Env): Promise<Response> {
  return traceAgentTurn(
    {
      agentName: "feelgood-chat-agent",
      agentId: "feelgood-companion",
      conversationId: payload.subscriberID,
    },
    async () => {
      try {
        let knowledgeContext = await traceToolExecution(
          "ai_search",
          { query: payload.prompt },
          async () => queryAISearch(payload.prompt, env)
        );

        const matchedExercise = searchGlossary(payload.prompt);
        if (matchedExercise) {
          const exerciseGuide = `EXERCISE GUIDE (${matchedExercise.name}):
- Movement ID: ${matchedExercise.id}
- Target muscles/focus: ${matchedExercise.muscles.join(", ")}
- Form cues & instructions:
${matchedExercise.instructions.map((inst) => `  * ${inst}`).join("\n")}`;
          knowledgeContext = knowledgeContext ? `${knowledgeContext}\n\n${exerciseGuide}` : exerciseGuide;
        }

        // Gemini is the only provider chat text is ever sent to, which is what
        // the privacy policy and the consent sheet say. Resilience comes from
        // trying other Gemini models (inside handleGeminiChat), never from a
        // second vendor.
        if (!env.GEMINI_API_KEY) {
          return new Response("upstream error: GEMINI_API_KEY is not configured", { status: 500 });
        }
        return await handleGeminiChat(payload, env.GEMINI_API_KEY, knowledgeContext);
      } catch (error) {
        console.error("handleChat error:", error);
        return new Response(`upstream error: ${error instanceof Error ? error.message : "unknown"}`, { status: 500 });
      }
    }
  );
}

function buildSystemPrompt(
  userContext?: UserPreferencesContext,
  knowledgeContext?: string | null,
  todaysMenu?: StructuredRecommendation[],
  activeSessionID?: string
): string {
  let prompt = CHAT_SYSTEM_PROMPT.replace(CATALOG_PLACEHOLDER, () => buildCatalogSummary(parseAvailability(userContext)));
  if (todaysMenu && todaysMenu.length > 0) {
    const menuLines = todaysMenu
      .map((item) => `- session_id: ${item.session_id} | course: ${item.course} | title: "${item.title}" | duration: ${item.duration_min} min | reason: ${item.reason}`)
      .join("\n");
    prompt += `\n\nTODAY'S MENU: this is the exact, already-decided menu the user sees on screen right now:\n${menuLines}\nIf the user's message names one of these items (by title, or by its course, e.g. "my dessert", "the side one"), your answer MUST be grounded in that exact item — return its session_id as-is and use its reason rather than inventing a new pick. Only run a fresh recommendation when the user is asking for something not on this list.`;
    if (activeSessionID) {
      const active = todaysMenu.find((item) => item.session_id === activeSessionID);
      if (active) {
        prompt += `\nThe item most recently discussed is "${active.title}" (session_id: ${active.session_id}). Treat questions like "why this?" as being about this item unless the user clearly asks about a different one. Requests to change it ("something shorter", "gentler", "not today", "nah", "something else") are NOT about keeping this item: they mean the user does not want it, so pick a different session.`;
      }
    }
  }
  if (userContext) {
    if (userContext.lastFeel === "tooMuch" || userContext.recoveryOwed) {
      prompt += "\n\nUSER RECENT FEEDBACK: The user recently found a workout too demanding ('tooMuch') or is in recovery debt. Strongly favor gentler, supported floor/mat options with lower intensity.";
    } else if (userContext.lastFeel === "lovedIt") {
      prompt += "\n\nUSER RECENT FEEDBACK: The user thoroughly enjoyed their last routine ('lovedIt'). Affirm their momentum calmly.";
    }
    if (userContext.likedActivities && userContext.likedActivities.length > 0) {
      prompt += `\nUSER PREFERENCES: Activities they especially love: ${userContext.likedActivities.join(", ")}. Prioritize these when appropriate.`;
    }
    const hidden = userContext.hiddenSessionIDs || userContext.hidden_session_ids;
    if (hidden && hidden.length > 0) {
      prompt += `\nEXCLUDED / HIDDEN EXERCISES: The user has explicitly chosen to hide these routines: ${hidden.join(", ")}. Never suggest or recommend these.`;
    }
    const shown = userContext.shownSessionIDs || userContext.shown_session_ids;
    if (shown && shown.length > 0) {
      prompt += `\nALREADY SHOWN IN THIS CONVERSATION: ${shown.join(", ")}. The user has seen these cards. Never recommend any of them again unless the user is asking about one of them ("why this?") or has said yes to it. If the user says no, nah, not today, or asks for something else, pick a session that is not on this list; if nothing clearly fits, ask a short clarifying question and return no session_id.`;
    }
    const preferredTier = userContext.preferredIntensityTier || userContext.preferred_intensity_tier;
    if (preferredTier) {
      prompt += `\nLEARNED INTENSITY PREFERENCE: The on-device recommendation engine has learned that this user currently thrives best at a '${preferredTier}' intensity tier. Favor routines aligned with this tier when not overridden by specific check-in requests.`;
    }
    const explored = userContext.topExploredActivities || userContext.top_explored_activities;
    if (explored && explored.length > 0) {
      prompt += `\nADAPTIVE AFFINITY: The user's most explored activities are: ${explored.join(", ")}. Prioritize these when appropriate.`;
    }
    const fatigue = userContext.fatigueSensitivity ?? userContext.fatigue_sensitivity;
    if (fatigue !== undefined && fatigue > 0.6) {
      prompt += `\nFATIGUE SENSITIVITY: The user is sensitive to high fatigue or cumulative strain. Ensure recovery options are offered generously.`;
    }
  }
  if (knowledgeContext) {
    prompt += `\n\n${knowledgeContext}\n\nKNOWLEDGE USAGE: If the user asks about app FAQs, subscription, pricing, exercises (e.g. box breathing, shake out, power pose, gratitude scan), or science/voice guidelines, use the relevant knowledge context above to answer accurately and warmly.`;
  }
  return prompt;
}

function isVagueInput(prompt: string): boolean {
  const p = normalizeReply(prompt);
  const vague = [
    "no",
    "nope",
    "nah",
    "it feels okay",
    "feels okay",
    "okay",
    "ok",
    "fine",
    "not sure",
    "idk",
    "maybe",
    "meh",
    "whatever",
    "don't know",
    "dont know",
    "nothing",
    "nothing really",
    "im ok",
    "i'm ok",
    "im okay",
    "i'm okay",
  ];
  return vague.includes(p);
}

function resolveCanonicalRecommendation(
  sessionId: string | undefined,
  reason: string | undefined,
  extractedCheckIn: ExtractedCheckIn,
  prompt: string,
  phase: string | undefined,
  userContext?: UserPreferencesContext,
  intent?: string
): StructuredRecommendation | null {
  // If phase is needs_discovery or user response is vague without asking for a routine, don't return an exercise
  if ((phase === "needs_discovery" || isVagueInput(prompt)) && !sessionId) {
    return null;
  }

  // Hidden sessions are never offered. Sessions already shown in this chat are
  // not offered again either, unless the person is asking about the one on
  // screen — a "nah" that comes back with the same card is the bug this stops.
  const hidden = excludedSessionIDs({
    hidden: userContext?.hiddenSessionIDs || userContext?.hidden_session_ids,
    shown: userContext?.shownSessionIDs || userContext?.shown_session_ids,
    intent,
    prompt,
  });
  const availability = parseAvailability(userContext);
  let matchedSession: CatalogSessionItem | undefined = findSessionById(sessionId);
  if (matchedSession && (hidden.includes(matchedSession.id) || !isSessionAvailable(matchedSession, availability))) {
    matchedSession = undefined;
  }

  // A bare rejection has no request in it to rematch against. Guessing another
  // routine would be a second thing they did not ask for, so answer without a card.
  if (!matchedSession && isRejection(prompt)) {
    return null;
  }

  if (!matchedSession) {
    // If the input was purely vague, don't guess a routine
    if (isVagueInput(prompt)) {
      return null;
    }

    // Determine approximate target duration from check-in or prompt
    let targetDur = 15;
    if (extractedCheckIn.timeBudget === "fiveMinutes" || prompt.includes("5 min") || prompt.includes("2 min")) targetDur = 5;
    else if (extractedCheckIn.timeBudget === "aLittle" || prompt.includes("10 min")) targetDur = 10;
    else if (extractedCheckIn.timeBudget === "twentyMinutes" || prompt.includes("20 min")) targetDur = 20;
    else if (extractedCheckIn.timeBudget === "some" || prompt.includes("30 min")) targetDur = 30;

    let intensity: "gentle" | "moderate" | "dynamic" = "gentle";
    if (userContext?.recoveryOwed || userContext?.lastFeel === "tooMuch") {
      intensity = "gentle";
    } else if (extractedCheckIn.energy === "strong" || extractedCheckIn.quickFilter === "moreEnergizing") {
      intensity = "dynamic";
    } else if (extractedCheckIn.energy === "steady") {
      intensity = "moderate";
    }

    let bodyFocus: string | undefined;
    if (prompt.includes("back") || extractedCheckIn.body === "stiff") bodyFocus = "back";
    else if (prompt.includes("neck") || prompt.includes("shoulder")) bodyFocus = "neckShoulders";
    else if (prompt.includes("hip")) bodyFocus = "hips";
    else if (/\b(arms?|biceps?|triceps?|upper body)\b/.test(prompt)) bodyFocus = "upperBody";

    matchedSession = matchBestSession({
      targetDuration: targetDur,
      intensity,
      bodyFocus,
      intent: extractedCheckIn.intent,
      place: extractedCheckIn.place === "stayingIn" ? "home" : undefined,
      likedActivities: userContext?.likedActivities,
      recoveryOwed: userContext?.recoveryOwed,
      lastFeel: userContext?.lastFeel,
      hiddenSessionIds: hidden,
      preferredIntensityTier: userContext?.preferredIntensityTier || userContext?.preferred_intensity_tier,
      topExploredActivities: userContext?.topExploredActivities || userContext?.top_explored_activities,
      fatigueSensitivity: userContext?.fatigueSensitivity ?? userContext?.fatigue_sensitivity,
      isAvailable: (s) => isSessionAvailable(s, availability),
    });
  }

  // matchBestSession seeds its answer with the first catalog entry, so if every
  // session is excluded it would hand one back anyway.
  if (hidden.includes(matchedSession.id) || !isSessionAvailable(matchedSession, availability)) {
    return null;
  }

  const tags: string[] = [
    matchedSession.course.charAt(0).toUpperCase() + matchedSession.course.slice(1),
    `${matchedSession.durationMin} min`,
    matchedSession.intensity.charAt(0).toUpperCase() + matchedSession.intensity.slice(1),
  ];
  if (matchedSession.bodyFocus[0] && matchedSession.bodyFocus[0] !== "full") {
    tags.push(bodyFocusLabel(matchedSession.bodyFocus[0]));
  }

  return {
    session_id: matchedSession.id,
    title: matchedSession.title,
    subtitle: matchedSession.subtitle,
    duration_min: matchedSession.durationMin,
    intensity: matchedSession.intensity,
    course: matchedSession.course,
    reason: reason || `Curated to fit your ${matchedSession.durationMin}-minute window today.`,
    tags,
    equipment: matchedSession.equipment,
    target_area: matchedSession.bodyFocus[0],
  };
}

async function handleGeminiChat(
  payload: ChatPayload,
  apiKey: string,
  knowledgeContext?: string | null
): Promise<Response> {
  const startedAt = Date.now();
  let modelUsed: string | null = null;
  let upstreamStatus: number | null = null;
  const historyTurns = payload.history?.length ?? 0;
  const logOutcome = (failure: ChatFailure, extra: Partial<ChatOutcomeInput> = {}) =>
    logChatOutcome(
      buildChatOutcome({
        prompt: payload.prompt,
        historyTurns,
        startedAt,
        now: Date.now(),
        model: modelUsed,
        upstreamStatus,
        failure,
        ...extra,
      })
    );

  const contents = [];
  if (payload.history && payload.history.length > 0) {
    for (const item of payload.history.slice(-8)) {
      const text = item.text || item.content || "";
      if (text) {
        contents.push({
          role: item.role === "model" || item.role === "assistant" ? "model" : "user",
          parts: [{ text }],
        });
      }
    }
  }
  contents.push({
    role: "user",
    parts: [{ text: payload.prompt }],
  });

  const systemPrompt = buildSystemPrompt(payload.userContext, knowledgeContext, payload.todaysMenu, payload.activeSessionID);

  const body = {
    contents,
    systemInstruction: {
      parts: [{ text: systemPrompt }],
    },
    generationConfig: {
      responseMimeType: "application/json",
      responseSchema: {
        type: "OBJECT",
        properties: {
          message: { type: "STRING", description: "Warm, calm, empathetic 1-2 sentence response." },
          mode: {
            type: "STRING",
            enum: ["clarifying", "banter", "recommendation"],
            description: "Lean 3-mode conversation state: clarifying (vague/clarifying question, no card), banter (greeting/inquiry, no card), recommendation (specific routine suggested with card).",
          },
          intent: {
            type: "STRING",
            enum: [
              "new_routine_request",
              "inquiry",
              "acknowledgment",
              "refinement",
              "action_trigger",
              "general_check_in",
            ],
          },
          phase: {
            type: "STRING",
            enum: [
              "greeting",
              "needs_discovery",
              "recommendation_active",
              "routine_committed",
              "inquiry_active",
            ],
          },
          session_id: { type: "STRING", description: "Exact session_id from the catalog." },
          reason: { type: "STRING", description: "Warm 1-sentence explanation of why this routine was picked." },
          quick_replies: {
            type: "ARRAY",
            items: {
              type: "OBJECT",
              properties: {
                id: { type: "STRING" },
                label: { type: "STRING" },
                symbol: { type: "STRING" },
                action_type: {
                  type: "STRING",
                  enum: [
                    "commit_to_today",
                    "ask_why",
                    "swap_routine",
                    "filter_gentler",
                    "filter_shorter",
                    "filter_more_energizing",
                    "filter_staying_in",
                    "start_session",
                    "custom_prompt",
                  ],
                },
                payload: { type: "STRING" },
              },
              required: ["id", "label", "action_type"],
            },
          },
          energy: { type: "STRING", enum: ["low", "steady", "strong"] },
          timeBudget: {
            type: "STRING",
            enum: [
              "fiveMinutes",
              "aLittle",
              "fifteenMinutes",
              "twentyMinutes",
              "twentyFiveMinutes",
              "some",
              "thirtyFiveMinutes",
              "fortyMinutes",
              "plenty",
            ],
          },
          place: { type: "STRING", enum: ["stayingIn", "happyToGoOut", "atTheGym"] },
          body: { type: "STRING", enum: ["sore", "stiff", "stressed", "cramping", "good"] },
          intentField: { type: "STRING", enum: ["energize", "strengthen", "calm", "mobilize", "joy"] },
          quickFilter: { type: "STRING", enum: ["shorter", "gentler", "moreEnergizing", "canNotLeave"] },
        },
        required: ["message", "mode", "quick_replies"],
      },
    },
  };

  const { res, candidateText } = await traceChatModel(
    {
      agentName: "feelgood-chat-agent",
      agentId: "feelgood-companion",
      conversationId: payload.subscriberID,
    },
    {
      system: "gemini",
      model: "gemini-2.5-flash",
      systemPrompt,
      inputMessages: contents,
    },
    async (setResponse) => {
      const candidateModels = ["gemini-2.5-flash", "gemini-flash-latest", "gemini-2.5-pro"];
      let response: Response | null = null;

      for (const model of candidateModels) {
        modelUsed = model;
        response = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(body),
          }
        );
        // Move to the next model on "not found" and on transient failures
        // (rate limit, overload). Anything else is a real answer.
        const shouldTryNextModel = response.status === 404 || response.status === 429 || response.status >= 500;
        if (!shouldTryNextModel) {
          break;
        }
      }

      if (!response || !response.ok) {
        const errText = response ? await response.text() : "No response";
        // Status only. The body is the provider's error text and can echo
        // request content, which is never logged.
        console.error("Gemini API error:", response?.status);
        return { res: response || new Response("gemini 404", { status: 404 }), candidateText: null, errorDetail: errText };
      }

      const json = (await response.json()) as any;
      const text = json.candidates?.[0]?.content?.parts?.[0]?.text || null;
      if (text) {
        setResponse([{ role: "model", content: text }]);
      }
      return { res: response, candidateText: text, errorDetail: null };
    }
  );

  upstreamStatus = res.status;
  if (!res.ok) {
    logOutcome("gemini_error");
    const detail = (res as any).errorDetail || "";
    return new Response(`upstream error: gemini ${res.status} - ${detail}`, { status: 500 });
  }

  if (!candidateText) {
    logOutcome("empty_response");
    return new Response("empty response from gemini", { status: 500 });
  }

  const parsed = JSON.parse(candidateText);
  const extractedCheckIn: ExtractedCheckIn = {};
  if (parsed.energy) extractedCheckIn.energy = parsed.energy;
  if (parsed.timeBudget) extractedCheckIn.timeBudget = parsed.timeBudget;
  if (parsed.place) extractedCheckIn.place = parsed.place;
  if (parsed.body) extractedCheckIn.body = parsed.body;
  if (parsed.intentField) extractedCheckIn.intent = parsed.intentField;
  if (parsed.quickFilter) extractedCheckIn.quickFilter = parsed.quickFilter;

  const recommendation = resolveCanonicalRecommendation(
    parsed.session_id,
    parsed.reason,
    extractedCheckIn,
    payload.prompt,
    parsed.phase,
    payload.userContext,
    parsed.intent
  );

  let quickReplies: QuickReplyAction[] = parsed.quick_replies || [];
  if (quickReplies.length === 0) {
    if (parsed.phase === "needs_discovery" || isVagueInput(payload.prompt)) {
      quickReplies = [
        { id: "floor_stretch", label: "5 min floor stretch", symbol: "figure.mind.and.body", action_type: "custom_prompt", payload: "5 min gentle floor stretch" },
        { id: "breath_reset", label: "Breath reset", symbol: "wind", action_type: "custom_prompt", payload: "3 min breath reset" },
        { id: "gentle_mobility", label: "Gentle mobility", symbol: "figure.cooldown", action_type: "custom_prompt", payload: "10 min gentle mobility" },
        { id: "just_resting", label: "Resting today", symbol: "bed.double", action_type: "custom_prompt", payload: "I am taking a full rest day" },
      ];
    } else {
      quickReplies = [
        { id: "commit", label: "Add to today", symbol: "plus", action_type: "commit_to_today" },
        { id: "why_this", label: "Why this?", symbol: "questionmark.circle", action_type: "ask_why" },
        { id: "shorter", label: "Something shorter", symbol: "clock.arrow.circlepath", action_type: "filter_shorter" },
        { id: "gentler", label: "Gentler option", symbol: "leaf", action_type: "filter_gentler" },
      ];
    }
  }

  let mode: ChatMode = parsed.mode;
  if (!mode || (mode !== "clarifying" && mode !== "banter" && mode !== "recommendation")) {
    if (parsed.phase === "needs_discovery" || isVagueInput(payload.prompt)) {
      mode = "clarifying";
    } else if (recommendation) {
      mode = "recommendation";
    } else {
      mode = "banter";
    }
  }

  // Enforce lean schema invariant: clarifying and banter MUST have null recommendation
  const finalRecommendation = mode === "recommendation" ? recommendation : null;

  // The model asked for a card that was dropped (already shown, hidden, or a
  // bare "nah"). A recommendation reply with no card would show "Add to today"
  // and "Why this?" chips over nothing, so it becomes a clarifying turn.
  if (mode === "recommendation" && !finalRecommendation) {
    mode = "clarifying";
    parsed.phase = "needs_discovery";
    quickReplies = [
      { id: "floor_stretch", label: "5 min floor stretch", symbol: "figure.mind.and.body", action_type: "custom_prompt", payload: "5 min gentle floor stretch" },
      { id: "breath_reset", label: "Breath reset", symbol: "wind", action_type: "custom_prompt", payload: "3 min breath reset" },
      { id: "gentle_mobility", label: "Gentle mobility", symbol: "figure.cooldown", action_type: "custom_prompt", payload: "10 min gentle mobility" },
      { id: "just_resting", label: "Resting today", symbol: "bed.double", action_type: "custom_prompt", payload: "I am taking a full rest day" },
    ];
  }

  const data: ChatResponseData = {
    message: parsed.message || (isVagueInput(payload.prompt) ? "Got it. What kind of support would feel best right now?" : "Here is a gentle plan tailored for your day."),
    mode,
    intent: parsed.intent || "general_check_in",
    phase: parsed.phase || (mode === "clarifying" ? "needs_discovery" : "recommendation_active"),
    recommendation: finalRecommendation,
    quick_replies: quickReplies,
    extracted_check_in: Object.keys(extractedCheckIn).length > 0 ? extractedCheckIn : null,
  };

  logOutcome("none", {
    mode: data.mode,
    intent: data.intent,
    phase: data.phase,
    hasCard: finalRecommendation !== null,
    modelProposedCard: Boolean(parsed.session_id),
    quickReplyCount: quickReplies.length,
    extractedCheckIn: data.extracted_check_in !== null,
  });
  return Response.json(data);
}
