# App Review notes and privacy label (paste into App Store Connect)

Updated for Version 1.0.3 (Build 22).

## 1. App Review Information → Notes

```
No account or sign-in is needed to review FeelGood. Everything works from first
launch; signing in (Apple, Google or email) is optional and only syncs saved
routines to a new phone.

To reach the main flows:
- Check-in: open the app, tap the check-in banner on the Today tab, pick a
  goal (e.g. Energised, Strong, Calm), choose how you want to feel, and select how
  much time you have (or "Resting today"). The menu on Today updates progressively.
- Chat: the Chat tab lets people describe their day in their own words. Free
  users get one AI reply, subscribers get unlimited; each AI reply is labelled
  with its source ("Replies written by AI" / "Replies from your phone"), and the
  person explicitly agrees to the privacy consent before any message leaves the device.
  Messages are scrubbed of emails, phone numbers, and links before being sent to
  the language model (disclosed in the privacy policy).
- Paywall: FeelGood Pro is an auto-renewable subscription.
  Entry points:
  1. Primary: You tab → "Your plan" button.
  2. In-flow: Today tab → tap "Adjust" or tap "Swap" on any session after using the free daily swap.
  Price, billing period, introductory trial terms, auto-renewal disclosures, Terms of Use,
  Privacy Policy, and Restore Purchases are all presented on that screen.
- Pro subscription testing: Please use a standard Apple Sandbox Apple ID to purchase or restore
  FeelGood Pro; no promo codes or external logins are required.
- Account deletion: You tab → gear icon (top right) → My account → Delete account.

Health note: FeelGood offers general wellness, stretching, and movement suggestions only. It
makes no medical claims. Optional "work-arounds" (e.g. low back, knees) and custom notes are
stored strictly on the device and used only to filter local suggestions; they are never
sent to a server, analytics provider, or AI provider, and are not part of account sync.
Calendar access is optional and read-only, used strictly to plan movement around today's calendar openings.

Contact: Ameena Malik (Email: ameenazara3@gmail.com; Phone provided in App Store Connect contact field).
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
