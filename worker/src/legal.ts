// worker/src/legal.ts
// Serves static HTML for Privacy Policy, Terms of Use, and Support.
// Required by App Store Review Guidelines 5.1.2 & 3.1.2.

const HTML_HEADERS = {
  "Content-Type": "text/html; charset=utf-8",
  "Cache-Control": "public, max-age=3600",
};

export const PRIVACY_POLICY_HTML = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Privacy Policy — FeelGood</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; max-width: 680px; margin: 0 auto; padding: 48px 24px 96px; line-height: 1.6; color: #1a1a1a; }
  h1 { font-size: 28px; margin-bottom: 4px; }
  .updated { color: #666; font-size: 14px; margin-bottom: 40px; }
  h2 { font-size: 19px; margin-top: 40px; }
  p, li { font-size: 16px; }
  ul { padding-left: 20px; }
  code { background: #f2f2f2; padding: 1px 5px; border-radius: 4px; font-size: 14px; }
  .contact { background: #f7f7f7; border-radius: 12px; padding: 20px 24px; margin-top: 40px; }
  a { color: #0066cc; }
</style>
</head>
<body>

<h1>Privacy Policy</h1>
<p class="updated">Last updated: 6 September 2026 · FeelGood: Dopamine Menu</p>

<p>Creating an account is entirely optional. Without one, FeelGood has no login and no password to remember — everything is a random identifier generated on your device, with no name, no email address, and no profile tied to a person anywhere in the system.</p>

<p>If you do create an account — to keep your subscription and saved routines with you on a new phone — you can sign in with Apple, Google, or an email address and password, using Firebase Authentication (operated by Google). Google Sign-In and email/password both require an email address; Sign in with Apple shares your email and name with us only if you choose to share them. Whichever you use, that address (and any name attached to it) identifies your account and nothing else — it is never sent to our analytics provider or used for marketing.</p>

<p>Your check-ins and your profile — including any health-related work-arounds like pregnancy, postpartum, or pelvic floor considerations — are stored only on your device using Apple's on-device storage (SwiftData), whether or not you have an account. The engine that decides what to recommend runs entirely on your phone. None of this is ever transmitted anywhere — deleting the app deletes it.</p>

<p>If you sign in, your kept custom routines and a record of each completed session — its title, duration, intensity, and how you said you felt afterward — are synced to Cloud Firestore (also operated by Google) so they are available on your other devices. Your check-in answers and your profile's health-related work-arounds are never included in this sync; those fields have no path off your device, signed in or not.</p>

<p>We use PostHog to understand how the app is used — which screens are opened, whether a workout was logged or completed, whether a subscription was purchased. Each event is tied only to a random per-install identifier, never to a name or account. Signing in does not change this: analytics is never told that a sign-in happened or who it was, regardless of which method you use. We never send your check-in answers, your profile's health-related fields, or any free-text you enter — those fields have no path off the device by design.</p>

<p>Subscription purchases are handled by Apple's App Store and processed through RevenueCat, which verifies and manages entitlement status. Before you sign in, this is tied to a random identifier RevenueCat generates. If you do sign in — with Apple, Google, or email — it is tied to your account's identifier instead, which is what lets your subscription follow you to a new phone. Neither identifier is your name or your email address.</p>

<p>For paying subscribers, FeelGood can generate a short line of framing text explaining today's menu. To do this, the following — and only the following — is sent to our server, which forwards it to a language model:</p>
<ul>
  <li>Which sessions were picked (internal ids, e.g. <code>app-box-breathing</code>)</li>
  <li>The general reason those sessions were picked (a machine-readable code, e.g. “low energy”)</li>
  <li>Your reported energy level and time budget for today</li>
  <li>How many days it's been since your last completed session (a number, never a date or the sessions themselves)</li>
  <li>The subscription identifier described above, so we can confirm you're a subscriber and prevent abuse</li>
</ul>

<p>This is deliberately narrow. Your check-in's body-focus answer and your profile's work-arounds (cramping, pregnancy, postpartum, pelvic floor) are never included — there is no field for them to travel in, so this isn't a setting that can be misconfigured. If this feature is switched off or you're not a subscriber, the app makes no network requests related to it at all.</p>

<p>Some sessions are Pilates and wellness classes embedded from YouTube's official player. Watching one of these is subject to YouTube's own Privacy Policy and Terms of Service, which are Google's, not ours.</p>

<ul>
  <li>No advertising SDKs, no ad tracking</li>
  <li>No cross-app or cross-website tracking of any kind (nothing to request App Tracking Transparency consent for)</li>
  <li>We never sell personal data or share it with third parties for their own marketing</li>
  <li>We never send your account email, synced routines, or workout history to our analytics provider</li>
</ul>

<p>If you created an account, you can permanently delete it — along with your synced routines and workout history — at any time from Profile → Account &amp; Data → Delete Account inside the app; this removes everything from our servers immediately. Deleting the app itself removes everything stored locally on your device, account or not. If you signed in with Apple, you can also revoke this app's access at any time in iOS Settings under your Apple Account. If you never created an account, we have no name, email, or account to delete — analytics and purchase records exist only under a random identifier, and we can only act on those if you provide us that identifier.</p>

<p>FeelGood is not directed at children under 13 and we do not knowingly collect data from them.</p>

<p>If this policy changes, the update will be posted on this page with a new “Last updated” date.</p>

</body>
</html>`;

export const TERMS_HTML = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Terms of Use — FeelGood</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; max-width: 680px; margin: 0 auto; padding: 48px 24px 96px; line-height: 1.6; color: #1a1a1a; }
  h1 { font-size: 28px; margin-bottom: 4px; }
  .updated { color: #666; font-size: 14px; margin-bottom: 40px; }
  h2 { font-size: 19px; margin-top: 40px; }
  p, li { font-size: 16px; }
  ul { padding-left: 20px; }
  code { background: #f2f2f2; padding: 1px 5px; border-radius: 4px; font-size: 14px; }
  .contact { background: #f7f7f7; border-radius: 12px; padding: 20px 24px; margin-top: 40px; }
  a { color: #0066cc; }
</style>
</head>
<body>

<h1>Terms of Use</h1>
<p class="updated">Last updated: 31 August 2026 · FeelGood: Dopamine Menu</p>

<p>FeelGood is licensed to you under Apple's Standard End User License Agreement, which you can read here: <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">apple.com/legal/internet-services/itunes/dev/stdeula</a>. The terms below are specific to FeelGood and sit alongside it.</p>

<h2>What FeelGood is, and what it isn't</h2>

<p>FeelGood suggests short movement and recovery sessions based on answers you give it. It is a general wellness app for healthy adults.</p>

<p>It is <strong>not</strong> a medical device or a medical service. Nothing in the app diagnoses, treats, cures, or prevents any condition, and nothing in it is a substitute for advice from a qualified healthcare professional. If you are pregnant, recently postpartum, recovering from injury or surgery, or managing a health condition, talk to a professional about what movement is appropriate for you. If something hurts, stop.</p>

<p>You are responsible for deciding whether a suggested session is right for you on a given day, and for exercising within your own limits. You take part at your own risk.</p>

<h2>Subscriptions</h2>

<p>FeelGood is free to use. An optional paid subscription unlocks additional features, which are described in the app before you buy.</p>

<ul>
  <li>The price and billing period are shown in the app at the point of purchase, and payment is charged to your Apple Account on confirmation.</li>
  <li>Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Your Apple Account is charged for renewal within 24 hours of the period ending.</li>
  <li>You can manage or cancel a subscription in Settings on your device, under your Apple Account. Deleting the app does not cancel a subscription.</li>
  <li>If a free trial is offered, any unused portion is forfeited when you buy a subscription.</li>
  <li>Purchases are made through Apple, so refunds are handled by Apple under their policies, not by us.</li>
</ul>

<h2>Content in the app</h2>

<p>Some sessions are videos published on YouTube by their creators and played through YouTube's official player. Those videos belong to the people who made them, not to us, and watching one is also subject to YouTube's own terms and privacy policy. Videos can be removed or made private by their creators at any time, which is outside our control.</p>

<p>The written sessions, the app's text, and its design are ours. You may use them within the app for your own personal use; please don't copy, redistribute, or resell them.</p>

<h2>Using the app fairly</h2>

<p>Please don't attempt to break, overload, reverse-engineer, or gain unauthorised access to the app or the services behind it, or use it in a way that breaks the law.</p>

<h2>Availability, and the limits of what we promise</h2>

<p>We work to keep FeelGood running, but we can't promise it will always be available, uninterrupted, or free of errors. Some features need an internet connection and depend on services we don't control. To the fullest extent the law allows, the app is provided "as is", and we are not liable for indirect or consequential loss arising from your use of it. Nothing here limits liability that cannot be limited by law, and you may have rights under consumer law in your country that these terms do not affect.</p>

<h2>Changes</h2>

<p>If these terms change, the updated version will be posted on this page with a new "Last updated" date. Continuing to use the app after that means you accept the change.</p>

<div class="contact">
  <strong>Questions:</strong><br>
  <a href="mailto:ameenazara3@gmail.com">ameenazara3@gmail.com</a>
</div>

</body>
</html>`;

export const SUPPORT_HTML = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Support — FeelGood</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif; max-width: 680px; margin: 0 auto; padding: 48px 24px 96px; line-height: 1.6; color: #1a1a1a; }
  h1 { font-size: 28px; margin-bottom: 40px; }
  h2 { font-size: 18px; margin-top: 36px; }
  p, li { font-size: 16px; }
  ul { padding-left: 20px; }
  .contact { background: #f7f7f7; border-radius: 12px; padding: 20px 24px; margin: 40px 0; }
  a { color: #0066cc; }
</style>
</head>
<body>

<h1>Support</h1>

<div class="contact">
  <strong>Need help?</strong> Email <a href="mailto:ameenazara3@gmail.com">ameenazara3@gmail.com</a> and we'll get back to you.
</div>

<h2>How does the menu work?</h2>
<p>Answer two quick questions — your energy and how much time you have — and FeelGood builds a short menu for today: one main session, a couple of small options, and always a two-minute one. There's no library to browse and no feed to scroll.</p>

<h2>Why didn't my streak carry over? / Where are my stats?</h2>
<p>FeelGood doesn't have streaks, rings, or completion percentages by design. Coming back after time away doesn't reset anything or show you a gap — you'll just get a short, gentle menu.</p>

<h2>Restoring a purchase</h2>
<p>Open Settings inside the app and choose "Restore Purchases." This re-checks your subscription status with the App Store — no account or login is needed since FeelGood doesn't have accounts.</p>

<h2>Do I need an internet connection?</h2>
<p>The two-minute and short sessions work fully offline. The longer class-length sessions are streamed from YouTube and need a connection to play.</p>

<h2>How do I delete my data?</h2>
<p>Deleting the app removes everything stored on your device. See the <a href="/privacy">Privacy Policy</a> for how to request deletion of anything else.</p>

<h2>Something's not working</h2>
<p>Email <a href="mailto:ameenazara3@gmail.com">ameenazara3@gmail.com</a> with what happened and, if you can, which screen you were on — that's usually enough for us to track it down.</p>

</body>
</html>`;

export function privacyPolicyResponse(): Response {
  return new Response(PRIVACY_POLICY_HTML, {
    status: 200,
    headers: HTML_HEADERS,
  });
}

export function termsResponse(): Response {
  return new Response(TERMS_HTML, {
    status: 200,
    headers: HTML_HEADERS,
  });
}

export function supportResponse(): Response {
  return new Response(SUPPORT_HTML, {
    status: 200,
    headers: HTML_HEADERS,
  });
}
