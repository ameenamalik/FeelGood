# App Review notes and privacy label (paste into App Store Connect)

Draft prepared 2026-09-20. Items marked TODO need a value only the owner has.

## 1. App Review Information → Notes

```
No account or sign-in is needed to review FeelGood. Everything works from first
launch; signing in (Apple, Google or email) is optional and only syncs saved
routines to a new phone.

To reach the main flows:
- Check-in: open the app, tap the check-in banner on the Today tab, pick an
  energy level, a time budget and how you feel. The menu on Today updates.
- Chat (Pro): the Chat tab lets subscribers describe their day in their own
  words. Messages are scrubbed of emails, phone numbers and links, then sent to
  a third-party language model (disclosed in the privacy policy).
- Paywall: FeelGood Pro is a subscription. Open the You tab → Your plan to see
  the paywall. TODO: confirm this is the shortest path a reviewer can take, and
  list any in-app entry point (e.g. a gated session) once verified. Price, billing period,
  any free trial, auto-renewal terms, Terms of Use, Privacy Policy and Restore
  Purchases are all on that screen.
- Pro content: Pro sessions and the AI framing line are behind the
  subscription. Please use a sandbox Apple ID to purchase; nothing else is
  required. TODO: if you prefer, add a promo code here.
- Account deletion: You tab → gear icon → My account → Delete account.

Health note: FeelGood offers general wellness and movement suggestions only. It
makes no medical claims. Optional "work-arounds" (e.g. low back, pregnancy) are
stored only on the device and are used to filter suggestions; they are never
sent to a server, an analytics provider, or an AI provider, and are not part of
account sync.
Calendar access is optional and read-only, used to plan around today's events.

Contact: TODO support email / phone
```

## 2. App Privacy (nutrition label): must match `FeelGood/PrivacyInfo.xcprivacy`

Every type below is **linked to the user** and **not used for tracking**.

| Data type (ASC) | Manifest key | Purpose(s) |
|---|---|---|
| Purchases | PurchaseHistory | App Functionality |
| Usage Data → Product Interaction | ProductInteraction | Analytics |
| Contact Info → Email Address | EmailAddress | App Functionality |
| Health & Fitness → Fitness | Fitness | App Functionality |
| Identifiers → User ID | UserID | App Functionality |
| Contact Info → Name | Name | App Functionality |
| Identifiers → Device ID | DeviceID | App Functionality, Analytics |
| Diagnostics → Crash Data | CrashData | App Functionality, Analytics |
| User Content → Other User Content | OtherUserContent | App Functionality |

Notes:
- Chat text, and the coarse energy/time/days-since-last values sent for the
  framing line, fall under **Other User Content** and **Product Interaction**.
  If you decide any of it is health data, add **Health** (App Functionality)
  here and in the manifest.
- "Do you or your third-party partners use data for tracking?" → **No**.
- Privacy Policy URL: https://feelgood-web.vercel.app/privacy (the live copy,
  it lives in the separate web repo).
