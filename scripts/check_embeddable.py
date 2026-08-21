#!/usr/bin/env python3
"""Check YouTube videos for embeddability, privacy status, and duration.

Usage:
    YOUTUBE_API_KEY=... python3 scripts/check_embeddable.py video_ids.txt

The input file holds one video ID (or full URL) per line. IDs are batched 50 per
request, which is the API maximum, so 40 videos costs a single call.

Without a key, open https://www.youtube.com/embed/VIDEO_ID in a browser: if it
plays there, it plays in the app.
"""

import os
import re
import sys
import json
import urllib.parse
import urllib.request

API = "https://www.googleapis.com/youtube/v3/videos"


def video_id(line):
    """Accept a bare ID or any YouTube URL shape."""
    line = line.strip()
    if not line or line.startswith("#"):
        return None
    for pattern in (r"[?&]v=([A-Za-z0-9_-]{11})", r"youtu\.be/([A-Za-z0-9_-]{11})",
                    r"/embed/([A-Za-z0-9_-]{11})", r"^([A-Za-z0-9_-]{11})$"):
        match = re.search(pattern, line)
        if match:
            return match.group(1)
    print(f"  ! could not read an ID from: {line}", file=sys.stderr)
    return None


def iso_duration_to_minutes(value):
    """PT23M47S -> 24. Always rounds up: never promise less time than it takes."""
    match = re.match(r"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?", value or "")
    if not match:
        return None
    hours, minutes, seconds = (int(part) if part else 0 for part in match.groups())
    total = hours * 60 + minutes + (1 if seconds else 0)
    return total


def fetch(ids, key):
    query = urllib.parse.urlencode({
        "part": "status,contentDetails,snippet",
        "id": ",".join(ids),
        "key": key,
    })
    with urllib.request.urlopen(f"{API}?{query}") as response:
        return json.load(response).get("items", [])


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    key = os.environ.get("YOUTUBE_API_KEY")
    if not key:
        print("Set YOUTUBE_API_KEY. See the docstring for the manual alternative.", file=sys.stderr)
        return 1

    with open(sys.argv[1]) as handle:
        ids = [i for i in (video_id(line) for line in handle) if i]
    if not ids:
        print("No video IDs found.", file=sys.stderr)
        return 1

    found = {}
    for start in range(0, len(ids), 50):
        for item in fetch(ids[start:start + 50], key):
            found[item["id"]] = item

    usable = 0
    print(f"{'video_id':14} {'embed':6} {'public':7} {'mins':5}  title")
    print("-" * 80)
    for identifier in ids:
        item = found.get(identifier)
        if not item:
            # Deleted, private, or a bad ID — all equally unusable.
            print(f"{identifier:14} {'—':6} {'MISSING':7} {'—':5}  not returned by the API")
            continue
        embeddable = item["status"].get("embeddable", False)
        public = item["status"].get("privacyStatus") == "public"
        minutes = iso_duration_to_minutes(item["contentDetails"].get("duration"))
        if embeddable and public:
            usable += 1
        print(
            f"{identifier:14} "
            f"{('yes' if embeddable else 'NO'):6} "
            f"{('yes' if public else 'NO'):7} "
            f"{(minutes if minutes is not None else '?'):<5}  "
            f"{item['snippet']['title'][:44]}"
        )

    print("-" * 80)
    print(f"{usable} of {len(ids)} usable.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
