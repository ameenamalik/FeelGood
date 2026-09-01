import Anthropic from "@anthropic-ai/sdk";
import { Env } from "./types";

export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

export interface ChatPayload {
  prompt: string;
  subscriberID: string;
  history?: ChatMessage[];
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

export interface ChatResponseData {
  message: string;
  extractedCheckIn: ExtractedCheckIn;
}

const CHAT_SYSTEM_PROMPT = `You are FeelGood, a warm, calm, unhurried daily wellness companion.
Your user is describing how they feel today, how much time they have, or what kind of movement they need.
Your goals:
1. Speak warmly and calmly, like an empathetic friend who knows their week. 1-2 sentences maximum.
2. Never make medical or diagnostic claims. Never mention streaks, calories, numbers, or guilt.
3. Use the tool 'extract_check_in_state' to structure your response and extract the user's available time, energy level, location, physical/mental feelings, or quick adjustments.
4. If the user only gives a brief description (e.g. "exhausted, tight shoulders"), infer reasonable defaults (e.g. energy: low, timeBudget: fifteenMinutes, body: stiff).`;

const EXTRACT_TOOL: Anthropic.Tool = {
  name: "extract_check_in_state",
  description:
    "Extract structured check-in constraints and supply a warm, empathetic 1-2 sentence response.",
  input_schema: {
    type: "object",
    properties: {
      message: {
        type: "string",
        description:
          "Warm, calm, empathetic 1-2 sentence response. Never clinical, no medical claims, no shame.",
      },
      energy: {
        type: "string",
        enum: ["low", "steady", "strong"],
        description: "Energy level if stated or implied.",
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
        description:
          "Available time (5m: fiveMinutes, 10m: aLittle, 15m: fifteenMinutes, 20m: twentyMinutes, 25m: twentyFiveMinutes, 30m: some, 35m: thirtyFiveMinutes, 40m: fortyMinutes, 45m+: plenty).",
      },
      place: {
        type: "string",
        enum: ["stayingIn", "happyToGoOut", "atTheGym"],
        description: "Where they can or want to move.",
      },
      body: {
        type: "string",
        enum: ["sore", "stiff", "stressed", "cramping", "good"],
        description: "Body or nervous system state.",
      },
      intent: {
        type: "string",
        enum: ["energize", "strengthen", "calm", "mobilize", "joy"],
        description: "Movement intent or direction.",
      },
      quickFilter: {
        type: "string",
        enum: ["shorter", "gentler", "moreEnergizing", "canNotLeave"],
        description: "Specific quick modification requested.",
      },
    },
    required: ["message"],
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
  const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });

  const messages: Anthropic.MessageParam[] = [];
  if (payload.history && payload.history.length > 0) {
    for (const item of payload.history.slice(-6)) {
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

  try {
    const response = await client.messages.create({
      model: "claude-opus-5",
      max_tokens: 400,
      system: [{ type: "text", text: CHAT_SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
      tools: [EXTRACT_TOOL],
      tool_choice: { type: "auto" },
      messages,
    });

    let messageText = "";
    let extractedCheckIn: ExtractedCheckIn = {};

    for (const block of response.content) {
      if (block.type === "tool_use" && block.name === "extract_check_in_state") {
        const input = block.input as Record<string, unknown>;
        if (typeof input.message === "string") {
          messageText = input.message.trim();
        }
        if (typeof input.energy === "string") {
          extractedCheckIn.energy = input.energy as ExtractedCheckIn["energy"];
        }
        if (typeof input.timeBudget === "string") {
          extractedCheckIn.timeBudget = input.timeBudget as ExtractedCheckIn["timeBudget"];
        }
        if (typeof input.place === "string") {
          extractedCheckIn.place = input.place as ExtractedCheckIn["place"];
        }
        if (typeof input.body === "string") {
          extractedCheckIn.body = input.body as ExtractedCheckIn["body"];
        }
        if (typeof input.intent === "string") {
          extractedCheckIn.intent = input.intent as ExtractedCheckIn["intent"];
        }
        if (typeof input.quickFilter === "string") {
          extractedCheckIn.quickFilter = input.quickFilter as ExtractedCheckIn["quickFilter"];
        }
      } else if (block.type === "text" && !messageText) {
        messageText = block.text.trim();
      }
    }

    if (!messageText) {
      messageText = "Here's a gentle plan that fits your day.";
    }

    const data: ChatResponseData = {
      message: messageText,
      extractedCheckIn,
    };

    return Response.json(data);
  } catch (error) {
    return new Response("upstream error", { status: 500 });
  }
}
