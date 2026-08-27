# FeelGood copy proxy

The Worker behind PRD §11 / `docs/PRD.md`'s "Claude proxy" section. The only
place the Anthropic key lives — the app never sees it. See `CLAUDE.md`'s
security rules and `FeelGood/Services/CopyPayload.swift` for the payload it
receives (the six-key allow-list, locked down by `CopyPayloadTests`).

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
project's `COPY_WORKER_BASE_URL` build setting for the matching configuration
(`FeelGood.xcodeproj/project.pbxproj` — Debug gets the dev URL, Release gets
the production one), then append `/copy` to match what
`FeelGood/Support/CopyServiceConstants.swift` expects to POST to.

If the setting is absent or invalid, the app keeps its deterministic headline
and skips the optional copy upgrade. An unconfigured Worker must never prevent
the app from launching.

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

## Local development

```bash
npm run dev
```

Runs the Worker locally against local KV; point a Debug build's
`COPY_WORKER_BASE_URL` at the printed `localhost` URL to test end-to-end
without deploying.
