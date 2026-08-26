import { Env } from "./types";

// Matches RevenueCatConstants.proEntitlementID in
// FeelGood/Support/RevenueCatConstants.swift — keep the two in sync.
const PRO_ENTITLEMENT_ID = "FeelGood Pro";

/// Free users physically cannot reach the model — cost exposure is capped by
/// paid users, not by downloads (PRD §11, "validate everything server-side").
///
/// Any RevenueCat-side error (network hiccup, unexpected shape, timeout) is
/// treated as *not entitled* — fail closed. That costs a paying user one
/// missed warm sentence on a bad request; failing open would mean a
/// RevenueCat outage turns into an open door to the Anthropic key.
export async function hasProEntitlement(anonInstallID: string, env: Env): Promise<boolean> {
  try {
    const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(anonInstallID)}`, {
      headers: { Authorization: `Bearer ${env.REVENUECAT_SECRET_API_KEY}` },
    });
    if (!response.ok) return false;

    const body = (await response.json()) as {
      subscriber?: { entitlements?: Record<string, { expires_date?: string | null }> };
    };
    const entitlement = body.subscriber?.entitlements?.[PRO_ENTITLEMENT_ID];
    if (!entitlement) return false;

    // No `expires_date` means a non-expiring (e.g. lifetime) entitlement.
    if (!entitlement.expires_date) return true;
    return new Date(entitlement.expires_date).getTime() > Date.now();
  } catch {
    return false;
  }
}
