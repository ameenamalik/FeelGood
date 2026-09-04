import { Env } from "./types";

// Matches RevenueCatConstants.proEntitlementID in
// FeelGood/Support/RevenueCatConstants.swift — keep the two in sync.
//
// This said "FeelGood Pro" and the app said "pro". The app's value is
// load-bearing in five places (every Pro gate, purchase, and restore), so a
// wrong id there would visibly fail to unlock a paid subscription; this one is
// used once and fails closed, so a wrong id here was invisible. That asymmetry
// is why the mismatch survived — and why the mismatch logs loudly below now.
const PRO_ENTITLEMENT_ID = "pro";

/// Free users physically cannot reach the model — cost exposure is capped by
/// paid users, not by downloads (PRD §11, "validate everything server-side").
///
/// Any RevenueCat-side error (network hiccup, unexpected shape, timeout) is
/// treated as *not entitled* — fail closed. That costs a paying user one
/// missed warm sentence on a bad request; failing open would mean a
/// RevenueCat outage turns into an open door to the Anthropic key.
///
/// Failing closed is right, but it is also indistinguishable from being
/// misconfigured, which hid three separate faults at once: a subscriber id
/// RevenueCat had never been told about, an entitlement id that didn't match
/// the app's, and a README that asked for a v2 key against this v1 endpoint.
/// Every refusal below therefore says *why* — visible with `wrangler tail`.
export async function hasProEntitlement(subscriberID: string, env: Env): Promise<boolean> {
  if (!env.REVENUECAT_SECRET_API_KEY) {
    console.warn("entitlement: REVENUECAT_SECRET_API_KEY is missing; denying access");
    return false;
  }

  try {
    const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(subscriberID)}`, {
      headers: { Authorization: `Bearer ${env.REVENUECAT_SECRET_API_KEY}` },
    });

    if (!response.ok) {
      console.warn(`entitlement: RevenueCat returned ${response.status} for subscriber lookup`);
      return false;
    }

    const body = (await response.json()) as {
      subscriber?: { entitlements?: Record<string, { expires_date?: string | null }> };
    };
    const entitlements = body.subscriber?.entitlements ?? {};
    const entitlement = entitlements[PRO_ENTITLEMENT_ID];

    if (!entitlement) {
      // Naming what the subscriber *does* have turns "wrong id" from a silent
      // 403 into one line that says exactly which id to use.
      const available = Object.keys(entitlements);
      console.warn(
        `entitlement: no "${PRO_ENTITLEMENT_ID}" for this subscriber; ` +
          (available.length ? `they hold [${available.join(", ")}]` : "they hold none"),
      );
      return false;
    }

    // No `expires_date` means a non-expiring (e.g. lifetime) entitlement.
    if (!entitlement.expires_date) return true;

    const active = new Date(entitlement.expires_date).getTime() > Date.now();
    if (!active) console.warn(`entitlement: "${PRO_ENTITLEMENT_ID}" expired at ${entitlement.expires_date}`);
    return active;
  } catch (error) {
    console.warn(`entitlement: lookup threw — ${error instanceof Error ? error.message : "unknown"}`);
    return false;
  }
}
