import { CopyPayload, ENERGY_VALUES, REASON_CODES, TIME_BUDGET_VALUES } from "./types";

const ALLOWED_KEYS = new Set(["picks", "reasonCodes", "energy", "time", "daysSinceLast", "anonInstallID"]);

/// Defense in depth: the Swift-side `CopyPayload` struct can't produce
/// anything outside these six keys, but the Worker doesn't get to assume the
/// caller is that Swift struct.
export function isValidPayload(body: unknown): body is CopyPayload {
  if (typeof body !== "object" || body === null) return false;
  const record = body as Record<string, unknown>;

  const keys = Object.keys(record);
  if (keys.length !== ALLOWED_KEYS.size || !keys.every((key) => ALLOWED_KEYS.has(key))) return false;

  if (!Array.isArray(record.picks) || !record.picks.every((id) => typeof id === "string")) return false;

  if (
    !Array.isArray(record.reasonCodes) ||
    !record.reasonCodes.every((code) => REASON_CODES.includes(code as (typeof REASON_CODES)[number]))
  ) {
    return false;
  }

  if (typeof record.energy !== "string" || !ENERGY_VALUES.includes(record.energy as (typeof ENERGY_VALUES)[number])) {
    return false;
  }

  if (typeof record.time !== "string" || !TIME_BUDGET_VALUES.includes(record.time as (typeof TIME_BUDGET_VALUES)[number])) {
    return false;
  }

  if (record.daysSinceLast !== null && typeof record.daysSinceLast !== "number") return false;

  if (typeof record.anonInstallID !== "string" || record.anonInstallID.length === 0) return false;

  return true;
}
