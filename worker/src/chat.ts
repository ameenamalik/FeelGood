import Anthropic from "@anthropic-ai/sdk";
import { Env } from "./types";
import { CATALOG_SESSIONS, findSessionById, matchBestSession, CatalogSessionItem } from "./catalog_index";

export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

export interface UserPreferencesContext {
  likedActivities?: string[];
  lastFeel?: "lovedIt" | "fine" | "tooMuch";
  recentCompletions?: number;
  recoveryOwed?: boolean;
}

export interface ChatPayload {
  prompt: string;
  subscriberID: string;
  history?: ChatMessage[];
  currentTimeBudget?: string;
  activeSessionID?: string;
  userContext?: UserPreferencesContext;
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

export interface ChatResponseData {
  message: string;
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
const CATALOG_PROMPT_SUMMARY = CATALOG_SESSIONS.map(
  (s) =>
    `[${s.id}] "${s.title}" (${s.durationMin}m, ${s.intensity}, ${s.course}, focus: ${s.bodyFocus.join("/") || "full"}, places: ${s.places.join("/")}, intents: ${s.intents.join("/")})`
).join("\n");

const CHAT_SYSTEM_PROMPT = `You are FeelGood, a warm, calm, unhurried daily wellness companion.
Your user is conversing with you about their movement, how they feel today, adjusting routines, or asking questions about workouts and yoga.

CORE PRINCIPLES:
1. Speak warmly and calmly, like an empathetic friend who knows their week. Keep responses short (1-2 sentences).
2. Never make medical or diagnostic claims. Never mention streaks, calories, numbers, or guilt.
3. GROUNDING: You MUST recommend ONLY real routines from the catalog below using their exact session ID:
${CATALOG_PROMPT_SUMMARY}

4. UNDERSTAND CONVERSATION FLOW:
   - Routine request ("tired, 15 min", "tight hips", "quick reset"): Classify as 'new_routine_request', pick the best session_id from catalog, explain why warmly in 1 sentence, and provide relevant quick replies.
   - Why inquiry ("Why this?", "Why today's plan?"): Classify as 'inquiry', explain the physiological rationale kindly (e.g., "Because your lower back is tight and you only have 15 minutes, this floor sequence releases hip and lumbar tension without any standing or wrist load."), and maintain the recommendation.
   - Refinement ("shorter", "gentler", "staying in"): Classify as 'refinement', pick a newly adjusted session_id from catalog, and confirm calmly.
   - Acknowledgment ("ok", "sounds good", "perfect"): Classify as 'acknowledgment' and confirm warmly.
   - Action trigger ("add to today", "let's do it", "start"): Classify as 'action_trigger'.
   - Vague / Incomplete / Ambiguous ("no", "nah", "it feels okay", "feels fine", "not sure", "meh", "maybe"): DO NOT return an exercise recommendation card! Classify as phase: 'needs_discovery' and intent: 'general_check_in'. Do not return a session_id. Ask a gentle clarifying question (e.g. "Got it. Would you prefer a short breath reset, a gentle floor stretch, or something to build a little energy?") and provide 3-4 discovery quick replies.`;

const ORCHESTRATE_TOOL: Anthropic.Tool = {
  name: "orchestrate_conversation_state",
  description:
    "Extract stateful conversation parameters, intent, routine recommendation, and dynamic UI quick replies.",
  input_schema: {
    type: "object",
    properties: {
      message: {
        type: "string",
        description: "Warm, calm, empathetic 1-2 sentence response.",
      },
      intent: {
        type: "string",
        enum: [
          "new_routine_request",
          "inquiry",
          "acknowledgment",
          "refinement",
          "action_trigger",
          "general_check_in",
        ],
        description: "Classified user intent.",
      },
      phase: {
        type: "string",
        enum: [
          "greeting",
          "needs_discovery",
          "recommendation_active",
          "routine_committed",
          "inquiry_active",
        ],
        description: "Current conversation state.",
      },
      session_id: {
        type: "string",
        description: "The exact session ID from the catalog that best matches the user's needs.",
      },
      reason: {
        type: "string",
        description: "Warm 1-sentence explanation of why this routine was picked.",
      },
      quick_replies: {
        type: "array",
        items: {
          type: "object",
          properties: {
            id: { type: "string" },
            label: { type: "string" },
            symbol: { type: "string" },
            action_type: {
              type: "string",
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
            payload: { type: "string" },
          },
          required: ["id", "label", "action_type"],
        },
      },
      energy: {
        type: "string",
        enum: ["low", "steady", "strong"],
      },
      timeBudget: {
        type: "string",
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
      place: {
        type: "string",
        enum: ["stayingIn", "happyToGoOut", "atTheGym"],
      },
      body: {
        type: "string",
        enum: ["sore", "stiff", "stressed", "cramping", "good"],
      },
      intentField: {
        type: "string",
        enum: ["energize", "strengthen", "calm", "mobilize", "joy"],
      },
      quickFilter: {
        type: "string",
        enum: ["shorter", "gentler", "moreEnergizing", "canNotLeave"],
      },
    },
    required: ["message", "intent", "phase", "quick_replies"],
  },
};

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
      if (m.role !== "user" && m.role !== "assistant") return false;
      if (typeof m.content !== "string") return false;
    }
  }
  return true;
}

export async function handleChat(payload: ChatPayload, env: Env): Promise<Response> {
  try {
    if (env.GEMINI_API_KEY) {
      return await handleGeminiChat(payload, env.GEMINI_API_KEY);
    }
    if (env.ANTHROPIC_API_KEY) {
      return await handleAnthropicChat(payload, env.ANTHROPIC_API_KEY);
    }
    return new Response("upstream error: Neither GEMINI_API_KEY nor ANTHROPIC_API_KEY is configured", { status: 500 });
  } catch (error) {
    console.error("handleChat error:", error);
    return new Response(`upstream error: ${error instanceof Error ? error.message : "unknown"}`, { status: 500 });
  }
}

function buildSystemPrompt(userContext?: UserPreferencesContext): string {
  let prompt = CHAT_SYSTEM_PROMPT;
  if (userContext) {
    if (userContext.lastFeel === "tooMuch" || userContext.recoveryOwed) {
      prompt += "\n\nUSER RECENT FEEDBACK: The user recently found a workout too demanding ('tooMuch') or is in recovery debt. Strongly favor gentler, supported floor/mat options with lower intensity.";
    } else if (userContext.lastFeel === "lovedIt") {
      prompt += "\n\nUSER RECENT FEEDBACK: The user thoroughly enjoyed their last routine ('lovedIt'). Affirm their momentum calmly.";
    }
    if (userContext.likedActivities && userContext.likedActivities.length > 0) {
      prompt += `\nUSER PREFERENCES: Activities they especially love: ${userContext.likedActivities.join(", ")}. Prioritize these when appropriate.`;
    }
  }
  return prompt;
}

function isVagueInput(prompt: string): boolean {
  const p = prompt.trim().toLowerCase();
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
  userContext?: UserPreferencesContext
): StructuredRecommendation | null {
  // If phase is needs_discovery or user response is vague without asking for a routine, don't return an exercise
  if ((phase === "needs_discovery" || isVagueInput(prompt)) && !sessionId) {
    return null;
  }

  let matchedSession: CatalogSessionItem | undefined = findSessionById(sessionId);

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
    if (prompt.includes("back") || extractedCheckIn.body === "stiff") bodyFocus = "lowerBack";
    else if (prompt.includes("neck") || prompt.includes("shoulder")) bodyFocus = "neckShoulders";
    else if (prompt.includes("hip")) bodyFocus = "hips";

    matchedSession = matchBestSession({
      targetDuration: targetDur,
      intensity,
      bodyFocus,
      intent: extractedCheckIn.intent,
      place: extractedCheckIn.place === "stayingIn" ? "home" : undefined,
      likedActivities: userContext?.likedActivities,
      recoveryOwed: userContext?.recoveryOwed,
      lastFeel: userContext?.lastFeel,
    });
  }

  const tags: string[] = [
    matchedSession.course.charAt(0).toUpperCase() + matchedSession.course.slice(1),
    `${matchedSession.durationMin} min`,
    matchedSession.intensity.charAt(0).toUpperCase() + matchedSession.intensity.slice(1),
  ];
  if (matchedSession.bodyFocus[0] && matchedSession.bodyFocus[0] !== "full") {
    tags.push(matchedSession.bodyFocus[0]);
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

async function handleGeminiChat(payload: ChatPayload, apiKey: string): Promise<Response> {
  const contents = [];
  if (payload.history && payload.history.length > 0) {
    for (const item of payload.history.slice(-8)) {
      contents.push({
        role: item.role === "user" ? "user" : "model",
        parts: [{ text: item.content }],
      });
    }
  }
  contents.push({
    role: "user",
    parts: [{ text: payload.prompt }],
  });

  const systemPrompt = buildSystemPrompt(payload.userContext);

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
        required: ["message", "intent", "phase", "quick_replies"],
      },
    },
  };

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    }
  );

  if (!res.ok) {
    const errText = await res.text();
    console.error("Gemini API error:", res.status, errText);
    return new Response(`upstream error: gemini ${res.status}`, { status: 500 });
  }

  const json = (await res.json()) as any;
  const candidateText = json.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!candidateText) {
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
    payload.userContext
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

  const data: ChatResponseData = {
    message: parsed.message || (isVagueInput(payload.prompt) ? "Got it. What kind of support would feel best right now?" : "Here is a gentle plan tailored for your day."),
    intent: parsed.intent || "general_check_in",
    phase: parsed.phase || (isVagueInput(payload.prompt) ? "needs_discovery" : "recommendation_active"),
    recommendation,
    quick_replies: quickReplies,
    extracted_check_in: Object.keys(extractedCheckIn).length > 0 ? extractedCheckIn : null,
  };

  return Response.json(data);
}

async function handleAnthropicChat(payload: ChatPayload, apiKey: string): Promise<Response> {
  const client = new Anthropic({ apiKey });

  const messages: Anthropic.MessageParam[] = [];
  if (payload.history && payload.history.length > 0) {
    for (const item of payload.history.slice(-8)) {
      messages.push({
        role: item.role,
        content: item.content,
      });
    }
  }
  messages.push({
    role: "user",
    content: payload.prompt,
  });

  const systemPrompt = buildSystemPrompt(payload.userContext);

  const response = await client.messages.create({
    model: "claude-3-5-haiku-20241022",
    max_tokens: 600,
    system: [{ type: "text", text: systemPrompt, cache_control: { type: "ephemeral" } }],
    tools: [ORCHESTRATE_TOOL],
    tool_choice: { type: "auto" },
    messages,
  });

  let messageText = "";
  let intent: ChatResponseData["intent"] = "general_check_in";
  let phase: ChatResponseData["phase"] = "recommendation_active";
  let sessionId: string | undefined;
  let reason: string | undefined;
  let quick_replies: QuickReplyAction[] = [];
  const extractedCheckIn: ExtractedCheckIn = {};

  for (const block of response.content) {
    if (block.type === "tool_use" && block.name === "orchestrate_conversation_state") {
      const input = block.input as Record<string, unknown>;
      if (typeof input.message === "string") messageText = input.message.trim();
      if (typeof input.intent === "string") intent = input.intent as ChatResponseData["intent"];
      if (typeof input.phase === "string") phase = input.phase as ChatResponseData["phase"];
      if (typeof input.session_id === "string") sessionId = input.session_id;
      if (typeof input.reason === "string") reason = input.reason;
      if (Array.isArray(input.quick_replies)) {
        quick_replies = input.quick_replies as QuickReplyAction[];
      }
      if (typeof input.energy === "string") extractedCheckIn.energy = input.energy as ExtractedCheckIn["energy"];
      if (typeof input.timeBudget === "string") extractedCheckIn.timeBudget = input.timeBudget as ExtractedCheckIn["timeBudget"];
      if (typeof input.place === "string") extractedCheckIn.place = input.place as ExtractedCheckIn["place"];
      if (typeof input.body === "string") extractedCheckIn.body = input.body as ExtractedCheckIn["body"];
      if (typeof input.intentField === "string") extractedCheckIn.intent = input.intentField as ExtractedCheckIn["intent"];
      if (typeof input.quickFilter === "string") extractedCheckIn.quickFilter = input.quickFilter as ExtractedCheckIn["quickFilter"];
    } else if (block.type === "text" && !messageText) {
      messageText = block.text.trim();
    }
  }

  if (!messageText) {
    messageText = isVagueInput(payload.prompt)
      ? "Got it. What kind of movement or rest would feel good right now?"
      : "Here is a gentle plan tailored for your day.";
  }

  const recommendation = resolveCanonicalRecommendation(
    sessionId,
    reason,
    extractedCheckIn,
    payload.prompt,
    phase,
    payload.userContext
  );

  if (quick_replies.length === 0) {
    if (phase === "needs_discovery" || isVagueInput(payload.prompt)) {
      quick_replies = [
        { id: "floor_stretch", label: "5 min floor stretch", symbol: "figure.mind.and.body", action_type: "custom_prompt", payload: "5 min gentle floor stretch" },
        { id: "breath_reset", label: "Breath reset", symbol: "wind", action_type: "custom_prompt", payload: "3 min breath reset" },
        { id: "gentle_mobility", label: "Gentle mobility", symbol: "figure.cooldown", action_type: "custom_prompt", payload: "10 min gentle mobility" },
        { id: "just_resting", label: "Resting today", symbol: "bed.double", action_type: "custom_prompt", payload: "I am taking a full rest day" },
      ];
    } else {
      quick_replies = [
        { id: "commit", label: "Add to today", symbol: "plus", action_type: "commit_to_today" },
        { id: "why_this", label: "Why this?", symbol: "questionmark.circle", action_type: "ask_why" },
        { id: "shorter", label: "Something shorter", symbol: "clock.arrow.circlepath", action_type: "filter_shorter" },
        { id: "gentler", label: "Gentler option", symbol: "leaf", action_type: "filter_gentler" },
      ];
    }
  }

  const data: ChatResponseData = {
    message: messageText,
    intent,
    phase,
    recommendation,
    quick_replies,
    extracted_check_in: Object.keys(extractedCheckIn).length > 0 ? extractedCheckIn : null,
  };

  return Response.json(data);
}
