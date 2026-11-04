// Gemini streams the reply as a JSON document, one fragment at a time. The
// person should read the `message` field as it arrives, before the rest of the
// document (card, chips, extracted check-in) exists. This pulls the decoded
// text of that one field out of the fragments received so far.

const MESSAGE_KEY = /"message"\s*:\s*"/;

const SIMPLE_ESCAPES: Record<string, string> = {
  '"': '"',
  "\\": "\\",
  "/": "/",
  b: "\b",
  f: "\f",
  n: "\n",
  r: "\r",
  t: "\t",
};

/**
 * The decoded `message` string in a partial JSON document, as far as it has
 * arrived. Returns "" until the field starts. A trailing, incomplete escape
 * sequence is held back until its remaining characters arrive, so the result
 * only ever grows by appending.
 */
export function partialMessage(accumulated: string): string {
  const start = MESSAGE_KEY.exec(accumulated);
  if (!start) return "";

  let out = "";
  let i = start.index + start[0].length;
  while (i < accumulated.length) {
    const ch = accumulated[i];
    if (ch === '"') return out;
    if (ch !== "\\") {
      out += ch;
      i += 1;
      continue;
    }

    const next = accumulated[i + 1];
    if (next === undefined) return out;
    if (next === "u") {
      const hex = accumulated.slice(i + 2, i + 6);
      if (hex.length < 4) return out;
      const code = Number.parseInt(hex, 16);
      if (Number.isNaN(code)) return out;
      out += String.fromCharCode(code);
      i += 6;
      continue;
    }
    out += SIMPLE_ESCAPES[next] ?? next;
    i += 2;
  }
  return out;
}

/** One server-sent event frame. */
export function sseFrame(event: string, data: unknown): string {
  return `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
}

/**
 * Splits an SSE byte stream's text into complete `data:` payloads, keeping an
 * unfinished trailing event in `rest` for the next chunk.
 */
export function drainSseData(buffer: string): { payloads: string[]; rest: string } {
  const payloads: string[] = [];
  const events = buffer.split(/\r?\n\r?\n/);
  const rest = events.pop() ?? "";
  for (const event of events) {
    const data = event
      .split(/\r?\n/)
      .filter((line) => line.startsWith("data:"))
      .map((line) => line.slice(5).trimStart())
      .join("\n");
    if (data) payloads.push(data);
  }
  return { payloads, rest };
}
