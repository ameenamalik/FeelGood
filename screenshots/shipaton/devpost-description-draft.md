# FeelGood — Devpost submission (aligned to "Demo Video Script & Submission Prep")

**Deadline: Wednesday, Sept 30, 2026, 11:45 PM PDT.**
Items in [brackets] are things only the team can supply. Anything marked
**VERIFY** is a claim I could not confirm from the repo or App Store Connect.

## Awards to select (name them in the description, answer fields, and video)

1. **Yoga & Fitness Influencer Award**
2. **#BuildInPublic Award**
3. **OneSignal — Keep Them Coming Back Award**
4. *(Secondary)* RevenueCat Design Award

Refer to the category by name. Do not name, show, or quote the influencer
anywhere (rules forbid it without written permission, and the product's own
rule is that `attribution` stays empty until sign-off exists in writing).

---

## Text description

Most wellness apps hand you more to decide. FeelGood hands you less.

It's a movement companion for anyone whose brain already has 47 tabs open.
Instead of a library of 500 videos, you get a menu: a few options already sized
to how you actually feel today.

**What should I do today?** Open FeelGood, answer a quick check-in — how's your
energy, how much time do you really have — and get today's menu. Every pick
says why it's there, in plain language.

**The menu, every day**
- **Appetizer** — a small, low-friction option that's always there
- **Main** — one real session: Pilates, yoga, qi gong, strength, a walk
- **Sides** — short add-ons that pair with what you're already doing
- **Dessert** — movement purely for joy, and it counts just as much
- **Rest** — a day off is a valid answer, with its own small win

At most a handful of choices, no scrolling, and a small option always exists
for the days that are a lot.

**Little Wins, not streaks.** Finish something and a fruit badge appears.
Come back after two weeks and FeelGood offers something small and warm. Every
day you show up counts toward something.

**Private by design.** The engine that builds your menu runs on your phone.
Body notes and check-ins never leave the device. AI only writes the short
framing line above your menu; it never chooses what you do with your body.

**Gentle re-engagement with OneSignal.** Reminders are invitations, not
alarms — see the OneSignal section below.

**RevenueCat powers FeelGood Pro**, a real auto-renewing subscription
(Yearly with a 7-day free trial, and Monthly). Entitlement `pro` is read live
from RevenueCat's `customerInfo`; purchases and restores go through the
StoreKit flow. Pro unlocks unlimited menu swaps, companion Chat, quick
adjustments, calendar-aware planning, and longer planning memory.

FeelGood is built for anyone who has downloaded four fitness apps and deleted
four fitness apps — not because they were bad, but because each one asked them
to become a different person with more free time than they have.

---

## Judge testing instructions

1. Install from the App Store: `https://apps.apple.com/app/id6806042303` **VERIFY it opens in a private window in a US storefront.**
2. Complete the short check-in; today's menu appears. Free tier covers the daily menu, check-in, and one swap.
3. To reach the paid experience, use **either**:
   - the **7-day free trial on Yearly** (Start my 1 week free on the paywall), **or**
   - promo/offer code **`SHIPATON2026`** — **[create this in App Store Connect first; it is NOT created yet]**.
4. Paywall entry points: a second menu swap, "Adjust", Chat, or You → Account & privacy → Subscription.
5. Review demo account for Apple (not for Devpost): configured in App Store Connect.

## OneSignal (Keep Them Coming Back Award)

- **OneSignal App ID:** [paste from the OneSignal dashboard — it's the `ONESIGNAL_APP_ID` build setting; it is not in source]
- **Campaign description (write only what is actually live — see blockers):**
  FeelGood re-engages with invitations, never guilt. There are no streaks to
  lose, so there is nothing to threaten. Messaging is driven by OneSignal
  Journeys and In-App Messages:
  - a gentle push for someone who has paused a session (custom events
    `session_paused` / `session_resumed`, with a reminder-eligibility window);
  - a gentle push and an In-App Message after a gap (local trigger
    `days_since_last_session >= 5`, the same threshold the engine uses to serve
    a shorter, warmer menu).
  Copy never mentions time away ("we miss you") — it offers a small next step.
  **VERIFY the Journey and the In-App Message are configured and published in
  the OneSignal dashboard before describing them as deployed.**

## #BuildInPublic Award

- X: [@feelgoodios thread URLs] · TikTok: [@ameena.dev devlog URLs]
- Story beats to cite (all must be linkable): the founder-burnout origin, the
  Day-1 prototype vs today's UI, and the paywall feedback that led to a copy
  rewrite. [Add the real post URLs and one line on what changed in the app.]
- `docs/BUILD_IN_PUBLIC_LOG.md` is **empty**. Fill it from the Sheet V2 links
  so the Devpost form and the log agree.

## Team

- Ameena Malik and Yusra — **add Yusra as a co-creator on the Devpost project.**
- One founder is the Devpost **Representative** for submission and prizes.

## Assets

| Item | Spec | Status |
|---|---|---|
| App icon | 1024×1024 PNG, no transparency | `~/Downloads/fin.png` is 1024×1024, no alpha — **confirm it's the final icon** |
| Screenshot | ≥1, exactly 1179×2556, no device frame | Real-device paywall shots `IMG_7394.PNG` / `IMG_7395.PNG` (1179×2556) qualify. Refresh `today-1179x2556.png` and `paywall-1179x2556.png` here; both are from Sep 11's build |
| App Store URL | Live, reachable in the US | 1.0 is READY_FOR_SALE |
| Demo video | ≤ 2:00, YouTube/Vimeo, Public or Unlisted | **Not recorded** |

---

## Script fixes before filming (these claims don't match the app)

The video script you sent has lines a judge could catch. Fix them before you record.

1. **"Energy = 20%, Mood = Exhausted."** The check-in has three energy levels
   (Depleted / Steady / Energized), a time slider, a place, and optional body
   notes. There's no percentage and no mood picker. Show the real controls.
2. **"Gemini AI synthesizes the check-in into a personalized plan."** The plan
   comes from an on-device engine; AI only writes the framing copy. Saying the
   AI curates the plan contradicts your privacy claim and the product's own
   rule. Suggested line: *"a small engine on your phone builds today's menu —
   AI only writes the friendly line on top."*
3. **"Kiwi badge."** The unlocked badge in the app is **First Move (strawberry)**.
4. **Push: "tailored to your energy."** The app sends `session_paused`,
   `session_resumed`, and `days_since_last_session`. It does **not** send energy
   to OneSignal, and coarse state is the only thing allowed off the device.
   Either build that, or drop "tailored to your energy". The sample line
   ("Low energy evening? 5-min floor stretch…") must be an **actually
   configured, live campaign** — the rules ask you to demonstrate one.
5. **"Mood analytics and habit history run rock-solid."** Pro gates unlimited
   swaps, Chat, quick adjustments, calendar context, and planning memory. There's
   no mood-analytics feature. Say what Pro actually unlocks.
6. **"Shoutout to Simone Sharice" / "the Simone Sharice 'What should I do
   today?' problem" (Section 6).** Cut the name. Your own Section 1 forbids it.
7. **"Streak-shaming"** is fine as a contrast, but keep the voice affirmative:
   lead with what FeelGood does (Little Wins), not what other apps do.
8. **Promo code SHIPATON2026** on the closing card is not created yet.
9. **"84 lines" rewrite.** Keep only if you can show it (the commit or diff).
10. **Music** must be royalty-free, and the video needs on-device footage (you have it).

## Blockers, in order

1. Record and upload the demo video (script above, with the fixes).
2. Create the **`SHIPATON2026` offer code** in App Store Connect (Lance can do it).
3. **Configure and publish the OneSignal Journey and In-App Message**, then
   capture the push on a real device for the video. Also
   `TODO.md` lists the dashboard side as still open.
4. Paste the OneSignal App ID; add the #BuildInPublic URLs; add Yusra on Devpost.
5. Confirm Monthly's trial status so the description and the paywall agree
   (live Monthly shows **no** trial; the description above says Yearly-only).
6. Confirm the 1.0.1 update reached "Waiting for Review" (not required for
   Shipaton — 1.0 is already live).
