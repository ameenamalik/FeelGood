// The wire shape of `CopyPayload` (FeelGood/Services/CopyPayload.swift),
// mirrored exactly. `CopyPayloadTests.wireShapeIsClosed` locks down the six
// keys on the Swift side; if that test's key list ever changes, this file
// needs the same change or the two silently drift.

export const REASON_CODES = [
  "recoveryBalance",
  "lowEnergy",
  "timeConstrained",
  "varietyBreak",
  "returningAfterGap",
  "matchesIntent",
  "qualityGap",
] as const;
export type ReasonCode = (typeof REASON_CODES)[number];

export const ENERGY_VALUES = ["low", "steady", "strong"] as const;
export type EnergyValue = (typeof ENERGY_VALUES)[number];

export const TIME_BUDGET_VALUES = [
  "zeroMinutes",
  "fiveMinutes",
  "aLittle",
  "fifteenMinutes",
  "twentyMinutes",
  "twentyFiveMinutes",
  "some",
  "thirtyFiveMinutes",
  "fortyMinutes",
  "fortyFiveMinutes",
  "fiftyMinutes",
  "plenty",
] as const;
export type TimeBudgetValue = (typeof TIME_BUDGET_VALUES)[number];

export interface CopyPayload {
  picks: string[];
  reasonCodes: ReasonCode[];
  energy: EnergyValue;
  time: TimeBudgetValue;
  daysSinceLast: number | null;
  subscriberID: string;
}

export interface Env {
  RATE_LIMIT: KVNamespace;
  ANTHROPIC_API_KEY?: string;
  GEMINI_API_KEY?: string;
  REVENUECAT_SECRET_API_KEY?: string;
  CLOUDFLARE_ACCOUNT_ID?: string;
  CLOUDFLARE_API_TOKEN?: string;
  AI_SEARCH_INSTANCE_NAME?: string;
  ENVIRONMENT?: string;
}
