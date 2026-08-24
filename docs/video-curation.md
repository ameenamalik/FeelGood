# Video curation — what to collect for the 40 Mains

Working doc for turning Simone's public YouTube library into catalog entries.
The schema is already built and tested, so this is data entry, not design —
everything below maps 1:1 to a field the app already reads.

**Companion files**
- `docs/video-curation-template.csv` — the sheet to fill in
- `scripts/check_embeddable.py` — verifies embeddability in bulk
- `scripts/import_videos.py` — turns the finished CSV into catalog entries

---

## Before anything else: the three disqualifiers

A video is unusable if any of these are true, so check them first and don't
waste time tagging something that can't ship.

| Check | Why it's fatal |
|---|---|
| **Not embeddable** | `status.embeddable = false` means the player refuses to load it in-app. Nothing else about the video matters. |
| **Not public** | Unlisted and private videos can't be relied on, and unlisted ones can change status without warning. |
| **Talking-head or non-followable** | A vlog about Pilates isn't a session. If someone can't put the phone down and move along with it, it isn't a Main. |

Check embeddability in bulk rather than one at a time:

```bash
YOUTUBE_API_KEY=your_key python3 scripts/check_embeddable.py video_ids.txt
```

It reads one video ID per line, batches 50 per request, and prints a table of
embeddable / public / duration. Without an API key you can spot-check manually
by opening `https://www.youtube.com/embed/VIDEO_ID` — if it plays there, it
plays in the app.

---

## What to collect per video

One row per video. Semicolon-separated where multiple values are allowed.

| Column | Allowed values | Notes |
|---|---|---|
| `video_id` | the 11 characters after `v=` | Not the whole URL. |
| `channel` | channel name | Required — every video session shows it and links back. |
| `title` | free text | **Our** title, not YouTube's. Warm, plain, no hype. "Twenty minutes, mostly floor work" beats "FULL BODY PILATES BURN 🔥". |
| `subtitle` | free text, short | One line. What it feels like, not what it claims. |
| `activity` | pilates, yoga, qigong, strength, stretching, walking, biking, swimming, skating, dance, jumpRope, agility, carries, racquet, climbing, martialArts, breathwork | One only. |
| `duration_min` | actual minutes, e.g. `23` | Record what it really is. The importer rounds **up** to the nearest bucket — never promise 20 minutes for a 23-minute video. |
| `intensity` | 1–5 | See the scale below. |
| `qualities` | strength, mobility, endurance, impact, agility, coordination, grip, balance, downRegulation | One to three. What it *develops*. |
| `energy_fit` | low, steady, strong | Which days this is right for. Most sessions are two of the three. |
| `equipment` | none, mat, weights, band, rope, bike, pool, skates, outdoor, reformer | Everything genuinely required. If she uses a cushion, that's `none`. |
| `places` | home, outdoors, gym, studio, pool | Where it can be done. Most mat videos are `home;gym;studio`. |
| `body_focus` | full, core, lowerBody, upperBody, back, hips, neckShoulders | |
| `contraindications` | pregnancy, postpartum, pelvicFloor, knees, wrists, lowBack | **Be generous here.** See below. |
| `intents` | energize, strengthen, calm, mobilize, joy | One or two. |
| `course` | main, special | Almost everything is `main`. Use `special` for anything 45+ minutes that needs planning. |
| `embeddable` | yes / no | From the checker. Only `yes` gets imported. |
| `notes` | free text | Anything for later. Ignored by the importer. |

### The intensity scale

| | Feels like |
|---|---|
| 1 | Lying down, breathing, gentle stretching. You could do it before bed. |
| 2 | Easy movement. No sweat, no breathlessness. |
| 3 | Working, but able to hold a conversation. Most mat Pilates lands here. |
| 4 | Properly hard. Breathing changes. You'd want a rest day pattern around it. |
| 5 | The hardest thing in the library. |

The engine uses this for recovery balance — two 4s or 5s in a row means it
offers something easy on day three. Tag it honestly or that protection breaks.

### Contraindications — the one to get right

The audience is women 35–54, many postpartum. Pelvic floor, joints, and
pregnancy are not edge cases here, and a wrong tag has a real cost while a
cautious one costs almost nothing.

Flag it if the video contains, at any point:

- **`pelvicFloor` / `postpartum` / `pregnancy`** — jumping, running, bouncing, plank-heavy sequences, deep loaded flexion, breath-holding under effort, intense abdominal work (hundreds, roll-ups, double leg lowers)
- **`lowBack`** — loaded spinal flexion, unsupported forward folds, heavy twisting
- **`knees`** — deep knee flexion under load, jumping, lunges on hard floors
- **`wrists`** — sustained weight through the hands: planks, four-point kneeling, push-ups

**When in doubt, flag it.** A wrongly-flagged video means someone doesn't see a
session they'd have enjoyed. A wrongly-unflagged one means someone with a
postpartum pelvic floor gets handed jump squats at 7am.

---

## What the 40 should add up to

Don't tag 40 videos that are all 30-minute mat Pilates at intensity 3 — the
variety and coverage signals will have nothing to work with, and the menu will
feel the same every day.

Rough shape to aim for:

| Dimension | Target |
|---|---|
| **Duration** | ~10 at 10–15 min, ~20 at 20–30 min, ~10 at 30–45 min. The short ones matter most: they're what a real Tuesday can absorb. |
| **Intensity** | At least 8 at intensity 1–2. Low-energy days are common and currently under-served. |
| **Contraindication-free** | At least 15 with *no* flags at all, so someone who ticked pregnancy and lower back still has a real library. |
| **Non-Pilates** | As many as exist — stretching, mobility, recovery, walking, breathwork. Pilates will dominate naturally; the engine needs alternatives to break monotony. |
| **Equipment** | At least 20 needing nothing but a mat. |

---

## Rules that aren't negotiable

- **Every video stays free, forever.** YouTube's terms forbid charging for what's
  free on YouTube. Not one video goes behind the Pro paywall, ever.
- **Channel name and link on every video session.** That's proper attribution and
  it sends traffic back to her.
- **Never imply partnership.** Not in the app, the store listing, or the demo
  video. "Built for her community" is honest; "made with" or "endorsed by" is
  not, until she says so in writing.
- **The `attribution` field stays `nil`** on our authored micro-sessions. That
  field means "this person wrote or taught this", which is a different and
  stronger claim than "this is their video".
- **No medical or outcome claims in our titles and subtitles**, even if the
  original video makes them. We rewrite the title; we don't inherit it.

---

## Working through it

Budget ~5 minutes a video: skim at 2x, note the shape, tag the row. That's about
3.5 hours total, which is worth splitting across a few sittings — tagging quality
drops fast when it gets boring, and intensity and contraindications are exactly
the fields that suffer.

Do the embeddability check **first**, in one batch. There's no sense watching a
video that can't be embedded.

When the sheet is done:

```bash
python3 scripts/import_videos.py docs/video-curation.csv   # add --dry-run to check first
```

It validates every value against the schema, rounds durations up, skips
non-embeddable rows, and merges the result into `FeelGood/Content/catalog.json`.
Anything it can't parse it reports by row and column rather than guessing.
