#!/usr/bin/env python3
"""Turn the curation CSV into catalog entries.

Usage:
    python3 scripts/import_videos.py docs/video-curation.csv [--dry-run]

Validates every value against the app's schema, rounds durations up to the next
bucket, skips rows marked not embeddable, and merges into the bundled catalog.
Reports problems by row and column rather than guessing.
"""

import csv
import sys
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "FeelGood" / "Content" / "catalog.json"

# Kept in step with FeelGood/Content/ContentTypes.swift.
ENUMS = {
    "activity": {"pilates", "yoga", "qigong", "strength", "stretching", "walking",
                 "biking", "swimming", "skating", "dance", "jumpRope", "agility",
                 "carries", "racquet", "climbing", "martialArts", "breathwork"},
    "qualities": {"strength", "mobility", "endurance", "impact", "agility",
                  "coordination", "grip", "balance", "downRegulation"},
    "energy_fit": {"low", "steady", "strong"},
    "equipment": {"none", "mat", "weights", "band", "rope", "bike", "pool",
                  "skates", "outdoor", "reformer"},
    "places": {"home", "outdoors", "gym", "studio", "pool"},
    "body_focus": {"full", "core", "lowerBody", "upperBody", "back", "hips",
                   "neckShoulders"},
    "contraindications": {"pregnancy", "postpartum", "pelvicFloor", "knees",
                          "wrists", "lowBack"},
    "intents": {"energize", "strengthen", "calm", "mobilize", "joy"},
    "course": {"main", "special"},
}
BUCKETS = [2, 5, 10, 15, 20, 30, 45, 60]


def bucket(minutes):
    """Round up, always. Never promise 20 minutes for a 23-minute video."""
    for size in BUCKETS:
        if minutes <= size:
            return size
    return BUCKETS[-1]


def split(value):
    return [part.strip() for part in (value or "").split(";") if part.strip()]


def convert(row, line, problems):
    def check(column, values, required=True):
        allowed = ENUMS[column]
        bad = [v for v in values if v not in allowed]
        for value in bad:
            problems.append(f"row {line}: {column} — '{value}' is not a valid value")
        if required and not values:
            problems.append(f"row {line}: {column} is required")
        return [v for v in values if v in allowed]

    # Collect everything wrong with this row before giving up on it — fixing
    # one field per run through 40 rows is nobody's idea of a good evening.
    before = len(problems)

    video = (row.get("video_id") or "").strip()
    if not video:
        problems.append(f"row {line}: video_id is required")

    minutes = 0
    try:
        minutes = int((row.get("duration_min") or "").strip())
    except ValueError:
        problems.append(f"row {line}: duration_min must be a whole number of minutes")

    intensity = 3
    try:
        intensity = int((row.get("intensity") or "").strip())
        if not 1 <= intensity <= 5:
            problems.append(f"row {line}: intensity must be 1 to 5, got {intensity}")
    except ValueError:
        problems.append(f"row {line}: intensity must be a number from 1 to 5")

    activity = check("activity", split(row.get("activity")))
    course = check("course", split(row.get("course")))

    title = (row.get("title") or "").strip()
    channel = (row.get("channel") or "").strip()
    if not title:
        problems.append(f"row {line}: title is required")
    if not channel:
        # Required by YouTube's terms — every embedded video credits its source.
        problems.append(f"row {line}: channel is required for attribution")

    qualities = check("qualities", split(row.get("qualities")))
    energy = check("energy_fit", split(row.get("energy_fit")))
    equipment = check("equipment", split(row.get("equipment")) or ["none"])
    places = check("places", split(row.get("places")))
    focus = check("body_focus", split(row.get("body_focus")))
    contra = check("contraindications", split(row.get("contraindications")), required=False)
    intents = check("intents", split(row.get("intents")))

    if len(problems) > before:
        return None

    return {
        "id": f"yt-{video}",
        "title": title,
        "subtitle": (row.get("subtitle") or "").strip(),
        "activity": activity[0],
        "qualities": qualities,
        "durationMin": bucket(minutes),
        "intensity": intensity,
        "energyFit": energy,
        "equipment": equipment,
        "places": places,
        "bodyFocus": focus,
        "contraindications": contra,
        "intents": intents,
        "course": course[0],
        "source": {"type": "youtube", "videoID": video, "channel": channel},
        # Stays absent: "this is their video" is not "they wrote this for us".
    }


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry_run = "--dry-run" in sys.argv
    if not args:
        print(__doc__)
        return 1

    problems, sessions, skipped = [], [], 0
    with open(args[0], newline="", encoding="utf-8") as handle:
        for line, row in enumerate(csv.DictReader(handle), start=2):
            if (row.get("embeddable") or "").strip().lower() not in ("yes", "y", "true"):
                skipped += 1
                continue
            if "EXAMPLE ROW" in (row.get("notes") or ""):
                skipped += 1
                continue
            session = convert(row, line, problems)
            if session:
                sessions.append(session)

    if problems:
        print(f"{len(problems)} problem(s) — nothing was written:\n")
        for problem in problems:
            print(f"  {problem}")
        return 1

    print(f"{len(sessions)} session(s) ready, {skipped} skipped (not embeddable or example rows).")
    durations = sorted(s["durationMin"] for s in sessions)
    gentle = sum(1 for s in sessions if s["intensity"] <= 2)
    unflagged = sum(1 for s in sessions if not s["contraindications"])
    print(f"  durations: {durations}")
    print(f"  gentle (intensity 1–2): {gentle}")
    print(f"  no contraindications at all: {unflagged}")
    if gentle < 8:
        print("  ! fewer than 8 gentle sessions — low-energy days will be thin")
    if unflagged < 15:
        print("  ! fewer than 15 unflagged — someone with several work-arounds sees very little")

    if dry_run:
        print("\nDry run: catalog not modified.")
        return 0

    catalog = json.loads(CATALOG.read_text())
    existing = {s["id"] for s in catalog["sessions"]}
    added = [s for s in sessions if s["id"] not in existing]
    catalog["sessions"] = [s for s in catalog["sessions"] if s["id"] not in {n["id"] for n in sessions}]
    catalog["sessions"].extend(sessions)
    catalog["version"] = catalog.get("version", 1) + 1
    CATALOG.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n")
    print(f"\nWrote {CATALOG.relative_to(ROOT)} — {len(added)} new, "
          f"{len(sessions) - len(added)} updated, version {catalog['version']}.")
    print("Run the tests: they check the catalog invariants this script does not.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
