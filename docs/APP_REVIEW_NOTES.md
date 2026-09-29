# App Review notes and privacy label (paste into App Store Connect)

Updated 2026-09-29 for the first build after 1.0.3 (22). Walked through on a
fresh install of the Release configuration.

## 0. App Store Connect fields to set before submitting

As of 2026-09-29, 1.0.3 (22) went to review with these gaps. They are locked
while a version is in review, so fix them on the next submission:

- **Notes** was empty. Paste section 1 below.
- **Sign-in required** was ticked with a demo account. FeelGood needs no
  sign-in, so untick it. If you keep the demo account, sign in with it on a
  device first; a reviewer who tries dead credentials rejects under 2.1.
- **Age rating**: "Health or Wellness Topics" was answered No. FeelGood is a
  wellness app, so answer Yes. Re-read the "Messaging and Chat" definition
  against the AI Chat tab and answer that one to match.
- **Description (en-US)** says the free trial is on the yearly plan. Both
  plans have a 1-week free trial in App Store Connect.

## 1. App Review Information → Notes

```
No account or sign-in is needed to review FeelGood. Everything works from first
launch. Signing in (Apple, Google or email) is optional and only syncs saved
routines and the subscription to a new phone.

To reach the main flows:
- Onboarding: four short questions and a quick tour, then today's menu.
- Check-in: on the Today tab, tap "How are you feeling today?", pick how you
  want to feel and how long you have (or "Resting today"). The menu updates as
  you answer.
- Swap: tap Swap on any menu item. The first swap each day is free.
- Chat: the Chat tab answers on the device by default ("Replies from your
  phone"). Before any message is sent to an AI model, a consent screen names the
  provider (Google Gemini, through our server) and offers "Keep replies on this
  device". Free users get one AI reply; subscribers get unlimited. It can be
  turned off any time: You tab > gear icon > My account > AI replies in Chat.
- Paywall: FeelGood Pro is an auto-renewable subscription, monthly or yearly,
  with a 1-week free trial for eligible accounts. To open it:
  1. Today tab > tap Swap a second time on the same day.
  2. You tab > gear icon > My account > Free plan > See FeelGood Pro plans.
  3. You tab > gear icon > My account > Calendar planning.
  The screen shows the billed price, trial length, renewal terms, Terms of Use,
  Privacy Policy and Restore. Please use a Sandbox Apple Account to purchase or
  restore; nothing else is required.
- Account deletion: You tab > gear icon > My account > Delete account.

Health note: FeelGood offers general wellness and movement suggestions only
and makes no medical claims. Optional work-arounds (for example low back, knees
or pregnancy) are stored only on the device and used on the device to filter
suggestions. They are never sent to a server, an analytics provider or an AI
provider, and are not part of account sync.

Calendar access is optional, read-only and part of Pro. Event times (and event
names, only if the person turns on movement recognition) are read on the device
to plan around the day. Notifications are optional and asked for in context.
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
