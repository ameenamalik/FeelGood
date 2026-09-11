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
<p class="updated">Last updated: 10 September 2026 · FeelGood: Dopamine Menu</p>

<p>This Privacy Policy explains what information FeelGood processes, why it is used, and the choices available to you. You can use FeelGood's core experience without creating an account. Creating an account is optional and enables account-based features such as syncing supported data between devices.</p>

<h2>Information stored on your device</h2>
<p>FeelGood stores information such as onboarding preferences, check-in answers, today's menu, session progress, workout history, hidden exercises, and profile preferences on your device using Apple's local storage. This may include sensitive wellness context that you choose to provide, such as soreness, cramping, pregnancy, postpartum, or pelvic-floor considerations.</p>
<p>The core recommendation engine runs on your device. Detailed body-concern selections and profile work-arounds are not uploaded to Firebase as part of account sync. Information you voluntarily type into the companion chat is handled separately as described below.</p>

<h2>Optional accounts and authentication</h2>
<p>If you create or use an account, authentication is provided through Firebase Authentication. Depending on the method you choose, we may receive and process:</p>
<ul>
  <li>A Firebase user identifier</li>
  <li>Your email address</li>
  <li>Your display name, if your sign-in provider supplies one</li>
  <li>Your authentication provider, such as Apple, Google, or email and password</li>
</ul>
<p>Apple and Google also process information according to their own privacy policies when you use their sign-in services. FeelGood does not receive your Apple or Google account password.</p>

<h2>Workout and routine sync</h2>
<p>When you are signed in, FeelGood uses Google Firebase and Cloud Firestore to sync supported account data. Synced workout-completion records may include the session title and internal identifier, activity type, authored duration, start and end times, general place category such as home or gym, and optional post-session feedback. Custom routines may include the name you give the routine, activity type, duration, intensity, menu section, and creation date.</p>
<p>This information is linked to your account identifier and is used to maintain account-associated workout records, restore supported custom routines, personalize the experience, and provide app functionality.</p>

<h2>Companion chat and AI-generated text</h2>
<p>When you choose to use the companion chat or an AI-generated explanation, FeelGood sends information to our Cloudflare Worker and to an AI provider, currently Google Gemini or Anthropic Claude, to generate a response. Depending on the feature, this may include:</p>
<ul>
  <li>The message you type and a limited number of recent conversation turns</li>
  <li>The active or recommended session and internal session identifiers</li>
  <li>General check-in context such as energy, available time, and place</li>
  <li>Liked activity types, your most recent post-session feeling, a recent-completion count, recovery context, and hidden session identifiers</li>
  <li>Machine-readable reasons for a recommendation and the number of days since a previous completion</li>
  <li>A RevenueCat subscriber identifier used to verify access and prevent abuse</li>
</ul>
<p>Do not include medical information or other information you do not want processed by these services in a chat message. Requests and generated responses may be recorded in Cloudflare observability traces for reliability, debugging, and abuse prevention. Google and Anthropic process prompts and responses under the service arrangements and privacy terms applicable to those providers.</p>

<h2>Product analytics, diagnostics, and session replay</h2>
<p>We use PostHog to understand app usage and improve reliability. PostHog may receive a random installation identifier, interaction events, subscription events, error and diagnostic information, and coarse product context such as energy, time, place, activity type, duration, intensity, or whether a body question was answered. Some events may include a custom routine or session title.</p>
<p>Session replay is enabled to help us understand interface problems. It can capture screenshots of the app interface and interaction information. We mask screens and fields designed to contain check-in answers, profile details, chat content, and other sensitive text, but you should understand that session replay records portions of the visible interface.</p>

<h2>Purchases and subscriptions</h2>
<p>Purchases are processed by Apple's App Store. We use RevenueCat to verify purchases and manage subscription access. RevenueCat receives purchase and entitlement information together with a RevenueCat-generated subscriber identifier. If you sign in, that subscription identity may be connected to your FeelGood account identifier so access can follow you across devices.</p>

<h2>Calendar access</h2>
<p>If you grant calendar permission, FeelGood reads event times on your device to find possible openings in your day. If you separately enable movement recognition, it may also inspect event titles on your device to recognize a scheduled workout or class. Calendar events and titles are not uploaded to Firebase, PostHog, RevenueCat, or the companion-chat service by these features.</p>

<h2>Embedded video and external services</h2>
<p>Some sessions embed or open videos using YouTube. YouTube and Google may receive information such as your IP address, device information, and video interactions according to their own privacy policies and settings.</p>

<h2>How information is used</h2>
<ul>
  <li>To provide, personalize, and sync FeelGood features</li>
  <li>To authenticate accounts and restore purchases</li>
  <li>To generate companion-chat responses and recommendation explanations</li>
  <li>To measure product usage, diagnose errors, and improve the app</li>
  <li>To protect the service from abuse and enforce feature limits</li>
</ul>

<h2>Sharing and tracking</h2>
<p>We share information with service providers only as needed to operate FeelGood, including Apple, Google Firebase, Google Gemini, Google Sign-In, YouTube, Anthropic, Cloudflare, RevenueCat, and PostHog. We do not sell personal information. We do not use information for third-party advertising or cross-app or cross-website tracking.</p>

<h2>Retention and deletion</h2>
<p>Information stored only on your device remains there until you remove it through the app or delete the app. Deleting the app does not automatically delete information already held by account, purchase, analytics, AI, or infrastructure providers.</p>
<p>If you created an account, you can use Delete Account in FeelGood to delete your authentication account and associated top-level account record. To request deletion of synced workout records, custom routines, analytics data, AI traces, or other service-provider records, contact us using the address below. Some information may be retained where reasonably necessary for security, fraud prevention, legal compliance, transaction records, or dispute resolution.</p>

<h2>Your choices</h2>
<ul>
  <li>Use the core app without creating an account</li>
  <li>Decline or revoke calendar access in iOS Settings</li>
  <li>Sign out or use Delete Account from the account screen</li>
  <li>Manage or cancel subscriptions through your Apple Account</li>
  <li>Contact us to request access to or deletion of information associated with an identifier you provide</li>
</ul>

<h2>Security</h2>
<p>We use reasonable technical and organizational measures intended to protect information. No method of transmission or storage is completely secure.</p>

<h2>Children</h2>
<p>FeelGood is not directed at children under 13 and we do not knowingly collect data from them.</p>

<h2>Changes to this policy</h2>
<p>If this policy changes, the update will be posted on this page with a new "Last updated" date.</p>

<div class="contact">
  <strong>Privacy questions or deletion requests:</strong><br>
  <a href="mailto:ameenazara3@gmail.com">ameenazara3@gmail.com</a>
</div>

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
