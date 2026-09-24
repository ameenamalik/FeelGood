// worker/src/appSiteAssociation.ts
// Apple's app-site-association file. iOS fetches it (through Apple's CDN) to
// confirm this host belongs to the app, which is what lets Password AutoFill
// offer and save the right login on the sign-in sheet. It pairs with the
// `webcredentials:` entries in FeelGood/FeelGood.entitlements.
//
// Public and static like /terms: no secret, no KV, no entitlement check.

/// Team ID + bundle ID, as Apple expects them.
export const APP_ID = "322ZGVD4Z7.com.ameenamalik.FeelGood";

export const APP_SITE_ASSOCIATION = {
  webcredentials: {
    apps: [APP_ID],
  },
};

export function appSiteAssociationResponse(): Response {
  // Must be served as JSON over HTTPS with no redirect; Apple's CDN caches it.
  return new Response(JSON.stringify(APP_SITE_ASSOCIATION), {
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=3600",
    },
  });
}
