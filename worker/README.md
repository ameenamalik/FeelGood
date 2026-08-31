# FeelGood Worker

Two unrelated routes that happen to share a host.

| Route | Auth | Why it exists |
|---|---|---|
| `POST /copy` | Pro entitlement, rate-limited | The Claude proxy behind PRD §11. The only place the Anthropic key lives — the app never sees it. See `CLAUDE.md`'s security rules and `FeelGood/Services/CopyPayload.swift` for the payload it receives (the six-key allow-list, locked down by `CopyPayloadTests`). |
| `GET /player?v=<id>` | none — public, static, cacheable | Serves the page that frames the YouTube embed. Needs no secret, no KV, and no entitlement. |

## Why `/player` has to exist

YouTube refuses an embed whose request carries no credible page origin —
Error 152-4. No client-side trick produces one: `loadHTMLString(_:baseURL:)`,
a hand-set `Referer` header, and `loadSimulatedRequest(_:responseHTML:)` each
synthesise an origin without ever fetching a page from it, so the iframe has
no Referer chain to inherit. All three were tried and are recorded in the
history of `FeelGood/Features/Session/YouTubeWebView.swift`.

`/player` is the fix: a page that genuinely was fetched, over HTTPS, from a
host that resolves. Because it needs nothing configured, a Worker deployed
with no secrets and no KV still plays video — the copy route simply returns
403/500 until you finish the setup below.

## One-time setup

```bash
cd worker
npm install
wrangler login
```

Create a KV namespace for the soft rate limit, one per environment, and paste
the resulting ids into `wrangler.toml`:

```bash
wrangler kv:namespace create RATE_LIMIT
wrangler kv:namespace create RATE_LIMIT --env production
```

Set secrets — never committed, never in `wrangler.toml`:

```bash
wrangler secret put ANTHROPIC_API_KEY
wrangler secret put REVENUECAT_SECRET_API_KEY   # the RevenueCat *secret* v2 REST key

wrangler secret put ANTHROPIC_API_KEY --env production
wrangler secret put REVENUECAT_SECRET_API_KEY --env production
```

Use **separate Anthropic keys for dev and production** (PRD §11, "clean
dev/prod separation") — if the dev key leaks, rotating it doesn't touch
production.

## Deploy

```bash
npm run deploy              # dev
npm run deploy:production   # production
```

Each command prints the Worker's `*.workers.dev` URL. Copy it into the Xcode
project's `WORKER_BASE_URL` build setting for the matching configuration
(`FeelGood.xcodeproj/project.pbxproj` — Debug gets the dev URL, Release gets
the production one). Set it to the **origin only**, with no path: each caller
appends its own route (`FeelGood/Support/WorkerConstants.swift`).

The two routes degrade differently when the setting is absent or invalid:

- **copy** keeps the deterministic headline and skips the optional upgrade. An
  unconfigured Worker must never prevent the app from launching.
- **player** cannot degrade to a working embed, so `PlayerView` offers "Watch
  on YouTube" instead of rendering a frame that will refuse to play.

## Verifying it's up

```bash
curl -i -X POST https://<your-worker>.workers.dev/copy \
  -H 'content-type: application/json' \
  -d '{"picks":["m-pilates-30"],"reasonCodes":["lowEnergy"],"energy":"low","time":"aLittle","daysSinceLast":null,"anonInstallID":"test-install"}'
```

Expect `403` (not entitled) unless `test-install` is a real, pro-entitled
RevenueCat subscriber. A malformed body should come back `400`; more than 10
requests in a minute from the same install should come back `429` once
entitled.

The player route needs nothing configured, so it is the quickest check that a
deploy is live at all:

```bash
curl -i "https://<your-worker>.workers.dev/player?v=nZaHiSEXqrg"
```

Expect `200` and an HTML page. A `v` that is not exactly 11 characters of
`[A-Za-z0-9_-]` should come back `400` — the id is interpolated into both an
HTML attribute and a URL, so it is allow-listed rather than escaped.

## Local development

```bash
npm run dev
```

Runs the Worker locally against local KV; point a Debug build's
`WORKER_BASE_URL` at the printed `localhost` URL to test end-to-end without
deploying. `wrangler dev` needs no Cloudflare login and no KV ids, which makes
it the fastest way to confirm the player works before committing to a deploy.
