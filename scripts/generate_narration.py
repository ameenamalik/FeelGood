#!/usr/bin/env python3
"""Generate bundled breathing-cue narration with ElevenLabs.

Usage:
    ELEVENLABS_API_KEY=... python3 scripts/generate_narration.py [--dry-run]

Reads scripts/narration_scripts.json (narration id -> spoken text, authored
separately from catalog.json so wording can be tuned without touching session
data), calls ElevenLabs' TTS API once per id, and writes
FeelGood/Content/ExerciseNarration/{id}.mp3.

This is a content-authoring tool run manually when cues change. It is not
part of the shipped app, does not run on a device, and the API key never
ships in the app or touches worker/ — see CLAUDE.md's secrets rule.
"""

import json
import os
import pathlib
import sys
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
SCRIPTS = ROOT / "scripts" / "narration_scripts.json"
OUTPUT_DIR = ROOT / "FeelGood" / "Content" / "ExerciseNarration"

# Picked from the ElevenLabs voice library for the breathing cues. Override
# by setting ELEVENLABS_VOICE_ID to any voice ID from your own ElevenLabs
# "Voices" library.
DEFAULT_VOICE_ID = "3FP8zog6uhdEdir09I9N"
API_URL = "https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"


def load_scripts():
    if not SCRIPTS.exists():
        sys.exit(f"missing {SCRIPTS} — add narration id -> spoken text entries first")
    return json.loads(SCRIPTS.read_text())


def synthesize(api_key, voice_id, text):
    url = API_URL.format(voice_id=voice_id)
    body = json.dumps({
        "text": text,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {"stability": 0.75, "similarity_boost": 0.75},
    }).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=body,
        headers={
            "xi-api-key": api_key,
            "Content-Type": "application/json",
            "Accept": "audio/mpeg",
        },
    )
    try:
        with urllib.request.urlopen(request) as response:
            return response.read()
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        sys.exit(f"ElevenLabs returned HTTP {error.code} for voice '{voice_id}':\n{detail}")


def main():
    dry_run = "--dry-run" in sys.argv
    api_key = os.environ.get("ELEVENLABS_API_KEY")
    if not api_key and not dry_run:
        sys.exit("set ELEVENLABS_API_KEY (or pass --dry-run to just validate scripts)")
    voice_id = os.environ.get("ELEVENLABS_VOICE_ID", DEFAULT_VOICE_ID)

    scripts = load_scripts()
    if not isinstance(scripts, dict) or not scripts:
        sys.exit(f"{SCRIPTS} must be a non-empty object of narration id -> text")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for narration_id, text in scripts.items():
        if not isinstance(text, str) or not text.strip():
            sys.exit(f"narration id '{narration_id}': text must be a non-empty string")

        destination = OUTPUT_DIR / f"{narration_id}.mp3"
        if dry_run:
            print(f"[dry-run] would write {destination}")
            continue

        print(f"generating {narration_id}...")
        audio = synthesize(api_key, voice_id, text)
        destination.write_bytes(audio)
        print(f"wrote {destination}")


if __name__ == "__main__":
    main()
