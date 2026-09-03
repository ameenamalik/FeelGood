import Anthropic from "@anthropic-ai/sdk";
import { handleChat, isValidChatPayload } from "./chat";
import { hasProEntitlement } from "./entitlement";
import { privacyPolicyResponse, supportResponse, termsResponse } from "./legal";
import { playerResponse } from "./player";
import { isRateLimited } from "./rateLimit";
import { COPY_SYSTEM_PROMPT } from "./systemPrompt";
import { traceAgentTurn, traceChatModel } from "./tracing";
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
          privacy: "GET /privacy",
          terms: "GET /terms",
          support: "GET /support",
        },
      });
    }

    // Static Legal & Policy routes (App Store Review requirement)
    if (url.pathname === "/privacy" || url.pathname === "/privacy-policy.html") {
      return privacyPolicyResponse();
    }
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

      if (!(await hasProEntitlement(body.subscriberID, env))) {
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

          // Prioritize Gemini 1.5 Flash (primary model)
          if (env.GEMINI_API_KEY) {
            line = await generateGeminiCopy(body, env.GEMINI_API_KEY);
          }

          // Fallback to Anthropic if Gemini unavailable or not configured and Anthropic key exists
          if (!line && env.ANTHROPIC_API_KEY) {
            const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
            const messages = [{ role: "user" as const, content: JSON.stringify(body) }];

            const response = await traceChatModel(
              {
                agentName: "feelgood-copy-agent",
                agentId: "feelgood-copywriter",
                conversationId: body.subscriberID || "anonymous",
              },
              {
                system: "anthropic",
                model: "claude-3-5-haiku-20241022",
                systemPrompt: COPY_SYSTEM_PROMPT,
                inputMessages: messages,
              },
              async (setResponse) => {
                const res = await client.messages.create({
                  model: "claude-3-5-haiku-20241022",
                  max_tokens: 300,
                  system: [{ type: "text", text: COPY_SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
                  messages,
                });
                setResponse(res.content);
                return res;
              }
            );
            line = firstText(response);
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

async function generateGeminiCopy(body: unknown, apiKey: string): Promise<string | null> {
  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    const resp = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        systemInstruction: {
          parts: [{ text: COPY_SYSTEM_PROMPT }],
        },
        contents: [
          {
            role: "user",
            parts: [{ text: `Here is the user context and today's picks payload: ${JSON.stringify(body)}. Write a single warm, grounded headline line.` }],
          },
        ],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: 150,
        },
      }),
    });

    if (!resp.ok) return null;
    const data = (await resp.json()) as {
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
    };
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
    return text || null;
  } catch {
    return null;
  }
}

function firstText(response: Anthropic.Message): string | null {
  const block = response.content.find((entry) => entry.type === "text");
  return block?.type === "text" ? block.text.trim() : null;
}
