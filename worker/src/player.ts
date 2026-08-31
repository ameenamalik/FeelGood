// The YouTube embed refuses any request that cannot show it a credible page
// origin — Error 152-4 when the frame's origin was synthesised on the client,
// 153 when the embed is loaded top-level with no Referer at all.
//
// Three client-side attempts are recorded in the history of
// FeelGood/Features/Session/YouTubeWebView.swift and all three fail for the
// same reason: `loadHTMLString(_:baseURL:)`, a hand-set `Referer` header, and
// `loadSimulatedRequest(_:responseHTML:)` each invent an origin without ever
// fetching a page from it, so the iframe has no Referer chain to inherit.
//
// This route is the fix: a page that genuinely was fetched, over HTTPS, from a
// host that resolves. The iframe inside it is a normal same-document child, so
// it sends the real Referer and Origin the embed checks for.
//
// It deliberately requires no secret, no KV, and no entitlement — it is public,
// cacheable, and safe to serve from a Worker deployed with nothing configured.

/// YouTube video ids are exactly 11 characters of the URL-safe base64 alphabet.
/// Anything else is rejected rather than escaped: the id is interpolated into
/// both an HTML attribute and a URL, and an allow-list is the only form of
/// validation that stays correct in both contexts.
const VIDEO_ID = /^[A-Za-z0-9_-]{11}$/;

export function isValidVideoID(id: string | null): id is string {
  return id !== null && VIDEO_ID.test(id);
}

export function playerResponse(url: URL): Response {
  const videoID = url.searchParams.get("v");

  if (!isValidVideoID(videoID)) {
    return new Response("bad request", { status: 400 });
  }

  return new Response(playerHTML(videoID), {
    status: 200,
    headers: {
      "content-type": "text/html; charset=utf-8",
      // The page is a pure function of the id, so let the edge and the
      // WKWebView cache it. A day is long enough to matter on a flaky
      // connection and short enough that a fix ships within one.
      "cache-control": "public, max-age=86400",
      // Nothing here is framed by anyone else, and nothing here reads storage.
      "x-content-type-options": "nosniff",
      "referrer-policy": "strict-origin-when-cross-origin",
    },
  });
}

function playerHTML(videoID: string): string {
  // `playsinline=1` keeps playback inside the card instead of handing it to
  // the fullscreen player; `rel=0` keeps the post-roll grid on the same
  // channel, which matters because we are showing someone else's library.
  const embed = `https://www.youtube-nocookie.com/embed/${videoID}?playsinline=1&rel=0&modestbranding=1`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<title>FeelGood player</title>
<style>
  html, body { margin: 0; padding: 0; height: 100%; background: transparent; overflow: hidden; }
  iframe { display: block; width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<iframe
  src="${embed}"
  title="Session video"
  allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
  allowfullscreen></iframe>
</body>
</html>`;
}
