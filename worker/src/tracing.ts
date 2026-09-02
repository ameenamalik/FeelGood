import { tracing } from "cloudflare:workers";

export interface TraceAgentContext {
  agentName: string;
  agentId: string;
  conversationId: string;
}

export const STORE_PAYLOADS = true;

/**
 * Traces a high-level agent turn (`invoke_agent`).
 */
export async function traceAgentTurn<T>(
  ctx: TraceAgentContext,
  fn: () => Promise<T>
): Promise<T> {
  return tracing.enterSpan("invoke_agent", async (span) => {
    span.setAttribute("gen_ai.operation.name", "invoke_agent");
    span.setAttribute("gen_ai.agent.name", ctx.agentName);
    span.setAttribute("gen_ai.agent.id", ctx.agentId);
    span.setAttribute("gen_ai.conversation.id", ctx.conversationId);
    return fn();
  });
}

/**
 * Traces an LLM model call (`chat`).
 */
export async function traceChatModel<T>(
  ctx: TraceAgentContext,
  modelInfo: {
    system: "gemini" | "anthropic" | "openai" | string;
    model: string;
    systemPrompt?: string;
    inputMessages?: unknown;
  },
  fn: (setResponse: (output: unknown) => void) => Promise<T>
): Promise<T> {
  return tracing.enterSpan("chat", async (span) => {
    span.setAttribute("gen_ai.operation.name", "chat");
    span.setAttribute("gen_ai.agent.name", ctx.agentName);
    span.setAttribute("gen_ai.agent.id", ctx.agentId);
    span.setAttribute("gen_ai.conversation.id", ctx.conversationId);
    span.setAttribute("gen_ai.system", modelInfo.system);
    span.setAttribute("gen_ai.request.model", modelInfo.model);

    if (STORE_PAYLOADS) {
      if (modelInfo.systemPrompt) {
        span.setAttribute("gen_ai.system_instructions", modelInfo.systemPrompt);
      }
      if (modelInfo.inputMessages !== undefined) {
        span.setAttribute(
          "gen_ai.input.messages",
          typeof modelInfo.inputMessages === "string"
            ? modelInfo.inputMessages
            : JSON.stringify(modelInfo.inputMessages)
        );
      }
    }

    const setResponse = (output: unknown) => {
      if (STORE_PAYLOADS && output !== undefined) {
        span.setAttribute(
          "gen_ai.output.messages",
          typeof output === "string" ? output : JSON.stringify(output)
        );
      }
    };

    return fn(setResponse);
  });
}

/**
 * Traces a tool execution (`execute_tool`).
 */
export async function traceToolExecution<T>(
  toolName: string,
  toolArgs: unknown,
  fn: () => Promise<T>
): Promise<T> {
  return tracing.enterSpan("execute_tool", async (span) => {
    span.setAttribute("gen_ai.tool.name", toolName);
    if (STORE_PAYLOADS && toolArgs !== undefined) {
      span.setAttribute(
        "gen_ai.tool.call.arguments",
        typeof toolArgs === "string" ? toolArgs : JSON.stringify(toolArgs)
      );
    }
    const result = await fn();
    if (STORE_PAYLOADS && result !== undefined) {
      span.setAttribute(
        "gen_ai.tool.call.result",
        typeof result === "string" ? result : JSON.stringify(result)
      );
    }
    return result;
  });
}
