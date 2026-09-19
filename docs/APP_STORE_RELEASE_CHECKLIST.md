# FeelGood App Store release checklist

Last audited: 2026-09-19 (Build 14)

## Code verified

- [x] Release uses the production RevenueCat public SDK key (`appl_…`).
- [x] Release uses the production copy Worker URL.
- [x] RevenueCat entitlement is `pro`; the app reads the current offering's monthly and annual packages.
- [x] Purchases, restore purchases, subscription status, and Customer Center are reachable from You → Account & privacy → Subscription.
- [x] Purchase entry points use `FeelGoodPaywallView` (custom SwiftUI paywall backed by RevenueCat for products and purchases) showing localized StoreKit pricing, introductory trial terms, auto-renewal notice, Terms of Use, Privacy Policy, and Restore Purchases.
- [x] Pro gates cover full planning memory, unlimited swaps, quick adjustments, Chat, Describe Day, and Calendar context.
- [x] Onboarding completion shows the skippable paywall once; the first completed Today session may also show it once.
- [x] The free daily swap survives an app relaunch.
- [x] The Worker fails closed when its RevenueCat secret is absent and verifies `pro` server-side before an AI request.
- [x] Terms (`https://feelgood-web.vercel.app/terms`), Privacy Policy (`https://feelgood-web.vercel.app/privacy`), Support mailto, Calendar usage copy, and privacy manifests (`PrivacyInfo.xcprivacy` in app, widget, and OneSignal extension) are present and verified.
- [x] Target device family configured as iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), eliminating iPad screenshot upload blockers.
- [x] Screenshot-based PostHog session replay is disabled in Release; allow-listed analytics events remain enabled.
- [x] Swift Release build, full iOS unit suite, Worker typecheck, and backend agent tests pass.
- [x] In-app account deletion supports Apple, Google, and email reauthentication; Apple deletion revokes its token.

## Blocking before submission

- [ ] **Deploy the updated production Worker.** Confirm the production environment has `REVENUECAT_SECRET_API_KEY`, `ANTHROPIC_API_KEY`, and the expected rate-limit binding. Do not ship the older entitlement bypass.
- [ ] **Complete App Store Connect subscriptions.** Put monthly and annual in one subscription group, add prices/localizations/review screenshots, and configure the 7-day annual introductory offer.
- [ ] **Complete RevenueCat production configuration.** Attach both App Store products to entitlement `pro`, add them to the current `default` offering as monthly/annual packages, and publish the production paywall.
- [ ] **Audit the remote paywall text.** It may advertise only shipped benefits: learning from history, quick adjustments/unlimited swaps, conversational check-ins, and optional Calendar context. It must show actual duration/price, renewal terms, Terms, Privacy, and Restore.
- [ ] **Finish App Store metadata.** Privacy Policy URL, Support URL, screenshots, description, age rating, app privacy answers (including RevenueCat and PostHog), export compliance, pricing/availability, and review contact/notes.
- [ ] **Confirm Agreements, Tax, and Banking** are active for paid apps.

## Final device/TestFlight pass

- [ ] Fresh install reaches the product intro and onboarding, then shows the skippable RevenueCat paywall once.
- [ ] Free user gets one swap; the next swap and Adjust open the paywall, including after relaunch.
- [ ] Monthly purchase, annual trial purchase, cancellation, pending purchase, restore, expiration, and refund entitlement changes behave correctly using sandbox/TestFlight accounts.
- [ ] A Pro user can use Chat, Describe Day, and Calendar context; a free user cannot reach the Worker AI endpoint.
- [ ] Calendar denial, offline mode, RevenueCat outage, and Worker outage all fail gracefully.
- [ ] Subscription management and legal links work on a physical device.
- [ ] Account deletion works on a physical device for Apple, Google, and email accounts, including a stale session that requires reauthentication.
- [ ] Archive the Release configuration, run Validate App, upload to App Store Connect, and attach the first subscription group/products to the same initial app-version submission.
