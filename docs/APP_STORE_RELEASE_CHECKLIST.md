# FeelGood App Store release checklist

Last audited: 2026-09-04

## Code verified

- [x] Release uses the production RevenueCat public SDK key (`appl_…`).
- [x] Release uses the production copy Worker URL.
- [x] RevenueCat entitlement is `pro`; the app reads the current offering's monthly and annual packages.
- [x] Purchases, restore purchases, subscription status, and Customer Center are reachable from You → Account & privacy → Subscription.
- [x] Purchase entry points use the RevenueCat paywall so trial eligibility, renewal terms, and localized pricing can be shown before purchase.
- [x] Pro gates cover full planning memory, unlimited swaps, quick adjustments, Chat, Describe Day, and Calendar context.
- [x] The first completed Today session may show the paywall once; onboarding and launch never do.
- [x] The free daily swap survives an app relaunch.
- [x] The Worker fails closed when its RevenueCat secret is absent and verifies `pro` server-side before an AI request.
- [x] Terms, Privacy Policy, Calendar usage copy, and a privacy manifest are present in the app bundle.
- [x] Swift Release build, focused entitlement regression test, Worker typecheck, and production-dependency audit pass.

## Blocking before submission

- [ ] **Resolve Sign in with Apple deletion.** Either remove optional Sign in with Apple for v1, or add an in-app Delete Account flow backed by a server endpoint that revokes the Apple token and deletes associated records. A local sign-out is not account deletion.
- [ ] **Deploy the updated production Worker.** Confirm the production environment has `REVENUECAT_SECRET_API_KEY`, `ANTHROPIC_API_KEY`, and the expected rate-limit binding. Do not ship the older entitlement bypass.
- [ ] **Complete App Store Connect subscriptions.** Put monthly and annual in one subscription group, add prices/localizations/review screenshots, and configure the 7-day annual introductory offer.
- [ ] **Complete RevenueCat production configuration.** Attach both App Store products to entitlement `pro`, add them to the current `default` offering as monthly/annual packages, and publish the production paywall.
- [ ] **Audit the remote paywall text.** It may advertise only shipped benefits: learning from history, quick adjustments/unlimited swaps, conversational check-ins, and optional Calendar context. It must show actual duration/price, renewal terms, Terms, Privacy, and Restore.
- [ ] **Finish App Store metadata.** Privacy Policy URL, Support URL, screenshots, description, age rating, app privacy answers (including RevenueCat and PostHog), export compliance, pricing/availability, and review contact/notes.
- [ ] **Confirm Agreements, Tax, and Banking** are active for paid apps.

## Final device/TestFlight pass

- [ ] Fresh install reaches the product intro and onboarding without a paywall.
- [ ] Free user gets one swap; the next swap and Adjust open the paywall, including after relaunch.
- [ ] Monthly purchase, annual trial purchase, cancellation, pending purchase, restore, expiration, and refund entitlement changes behave correctly using sandbox/TestFlight accounts.
- [ ] A Pro user can use Chat, Describe Day, and Calendar context; a free user cannot reach the Worker AI endpoint.
- [ ] Calendar denial, offline mode, RevenueCat outage, and Worker outage all fail gracefully.
- [ ] Subscription management and legal links work on a physical device.
- [ ] Archive the Release configuration, run Validate App, upload to App Store Connect, and attach the first subscription group/products to the same initial app-version submission.
