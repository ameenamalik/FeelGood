import { Env } from "./types";

interface AISearchResultItem {
  content?: string;
  text?: string;
  title?: string;
  filename?: string;
  score?: number;
}

interface AISearchResponse {
  result?: {
    results?: AISearchResultItem[];
    items?: AISearchResultItem[];
    chunks?: AISearchResultItem[];
  } | AISearchResultItem[];
  results?: AISearchResultItem[];
  items?: AISearchResultItem[];
}

/**
 * Queries Cloudflare AI Search (feelgood-knowledge) for semantic grounding.
 * Returns formatted context string or null if unavailable/unconfigured.
 */
export async function queryAISearch(
  query: string,
  env: Env
): Promise<string | null> {
  const accountId = env.CLOUDFLARE_ACCOUNT_ID;
  const apiToken = env.CLOUDFLARE_API_TOKEN;
  const instanceName = env.AI_SEARCH_INSTANCE_NAME || "nameless-feather-c645";

  if (!accountId || !apiToken) {
    return null;
  }

  const endpoint = `https://api.cloudflare.com/client/v4/accounts/${accountId}/ai/search/${instanceName}`;

  try {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 1800);

    const res = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        query,
        top_k: 3,
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!res.ok) {
      console.warn(`[AI Search] Failed with status ${res.status}: ${await res.text().catch(() => "")}`);
      return null;
    }

    const data = (await res.json()) as AISearchResponse;
    const rawItems: AISearchResultItem[] =
      (Array.isArray(data.result) ? data.result : data.result?.results || data.result?.items || data.result?.chunks) ||
      data.results ||
      data.items ||
      [];

    if (!rawItems || rawItems.length === 0) {
      return null;
    }

    const snippets = rawItems
      .slice(0, 3)
      .map((item, idx) => {
        const title = item.title || item.filename || `Reference ${idx + 1}`;
        const text = (item.content || item.text || "").trim();
        return `[Source: ${title}]\n${text}`;
      })
      .filter((s) => s.length > 20);

    if (snippets.length === 0) {
      return null;
    }

    return `RELEVANT KNOWLEDGE BASE CONTEXT (From Dopamine Menu Knowledge Base):\n${snippets.join("\n\n---\n\n")}`;
  } catch (err: any) {
    if (err?.name === "AbortError") {
      console.warn("[AI Search] Request timed out after 1800ms");
    } else {
      console.warn("[AI Search] Query failed:", err?.message || err);
    }
    return null;
  }
}
