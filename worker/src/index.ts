import { handleChat, isValidChatPayload } from "./chat";
import { acceptCopyLine } from "./copyLine";
import { hasProEntitlement } from "./entitlement";
import { consumeFreeChat } from "./freeChat";
import { supportResponse, termsResponse } from "./legal";
import { playerResponse } from "./player";
import { isRateLimited } from "./rateLimit";
import { COPY_SYSTEM_PROMPT } from "./systemPrompt";
import { traceAgentTurn } from "./tracing";
import { Env } from "./types";
import { isValidPayload } from "./validate";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Root / Health check for browser and monitoring verification
    if (url.pathname === "/" || url.pathname === "/health") {
      return Response.json({
        status: "healthy",
        service: "FeelGood Edge Worker",
        version: "1.0.0",
        endpoints: {
          chat: "POST /chat",
          copy: "POST /copy",
          player: "GET /player?v=<id>",
          terms: "GET /terms",
          support: "GET /support",
        },
      });
    }

    // Static Legal & Policy routes (App Store Review requirement)
    if (url.pathname === "/terms" || url.pathname === "/terms.html") {
      return termsResponse();
    }
    if (url.pathname === "/support" || url.pathname === "/support.html") {
      return supportResponse();
    }

    // `/player` is public and static: it holds no secret, reads no KV, and
    // checks no entitlement, so a Worker deployed with nothing configured
    // still plays video. See player.ts for why it has to exist at all.
    if (url.pathname === "/player") {
      if (request.method !== "GET") {
        return new Response("method not allowed", { status: 405 });
      }
      return playerResponse(url);
    }

    if (url.pathname === "/chat") {
      if (request.method !== "POST") {
        return new Response("method not allowed", { status: 405 });
      }

      let body: unknown;
      try {
        body = await request.json();
      } catch {
        return new Response("bad request", { status: 400 });
      }

      if (!isValidChatPayload(body)) {
        return new Response("bad request", { status: 400 });
      }

      // Subscribers get chat; everyone else gets one free exchange, so the
      // first reply a new person sees is a real one. See freeChat.ts.
      if (
        !(await hasProEntitlement(body.subscriberID, env)) &&
        !(await consumeFreeChat(body.subscriberID, request.headers.get("CF-Connecting-IP"), env))
      ) {
        return new Response("forbidden", { status: 403 });
      }

      if (await isRateLimited(body.subscriberID, env)) {
        return new Response("slow down", { status: 429 });
      }

      return handleChat(body, env);
    }

    if (url.pathname !== "/copy") {
      return new Response("not found", { status: 404 });
    }

    if (request.method !== "POST") {
      return new Response("method not allowed", { status: 405 });
    }

    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return new Response("bad request", { status: 400 });
    }

    if (!isValidPayload(body)) {
      return new Response("bad request", { status: 400 });
    }

    if (!(await hasProEntitlement(body.subscriberID, env))) {
      return new Response("forbidden", { status: 403 });
    }

    if (await isRateLimited(body.subscriberID, env)) {
      return new Response("slow down", { status: 429 });
    }

    return traceAgentTurn(
      {
        agentName: "feelgood-copy-agent",
        agentId: "feelgood-copywriter",
        conversationId: body.subscriberID || "anonymous",
      },
      async () => {
        try {
          let line: string | null = null;

          // Gemini only. If it fails the client falls back to its template headline.
          if (env.GEMINI_API_KEY) {
            line = await generateGeminiCopy(body, env.GEMINI_API_KEY);
          }

          if (!line) return new Response("empty response", { status: 500 });

          return Response.json({ line });
        } catch {
          // No detail leaked — the client's only reaction to any failure here is
          // to fall back to the deterministic template headline.
          return new Response("upstream error", { status: 500 });
        }
      }
    );
  },
};

// Ordered: the first model that answers wins. Only the 2.5 models think by
// default, and thinking tokens count against maxOutputTokens, so on those the
// budget is set to zero — otherwise the visible line can be cut off after a
// few words. (2.0 rejects a thinkingConfig, so it only goes to 2.5.)
const COPY_MODELS = ["gemini-2.0-flash", "gemini-2.5-flash"];

function copyRequestBody(model: string, body: unknown): string {
  const generationConfig: Record<string, unknown> = {
    temperature: 0.7,
    maxOutputTokens: 256,
  };
  if (model.startsWith("gemini-2.5")) {
    generationConfig.thinkingConfig = { thinkingBudget: 0 };
  }
  return JSON.stringify({
    systemInstruction: {
      parts: [{ text: COPY_SYSTEM_PROMPT }],
    },
    contents: [
      {
        role: "user",
        parts: [{ text: `Here is the user context and today's picks payload: ${JSON.stringify(body)}. Write a single warm, grounded headline line.` }],
      },
    ],
    generationConfig,
  });
}

async function generateGeminiCopy(body: unknown, apiKey: string): Promise<string | null> {
  try {
    let resp: Response | null = null;
    for (const model of COPY_MODELS) {
      resp = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: copyRequestBody(model, body),
      });
      // Next model on "not found" and transient failures; anything else is an answer.
      if (!(resp.status === 404 || resp.status === 429 || resp.status >= 500)) break;
    }

    if (!resp || !resp.ok) return null;
    const data = (await resp.json()) as {
      candidates?: Array<{ finishReason?: string; content?: { parts?: Array<{ text?: string }> } }>;
    };
    const candidate = data.candidates?.[0];
    // A cut-off, multi-line, over-long or system-talk reply is worse than the
    // template headline the client already has, so it is dropped here.
    return acceptCopyLine(candidate?.content?.parts?.[0]?.text, candidate?.finishReason);
  } catch {
    return null;
  }
}
