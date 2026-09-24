#!/usr/bin/env python3
"""
iPad App Store screenshots from the finished iPhone slides.

Why this exists: an iPhone slide is 9:19.5 and an iPad 13" screenshot is 3:4.
Cropping or stretching one to fit the other is what cuts headlines off. This
takes each finished iPhone slide (headline, device, art, all already approved)
and places it whole, uncropped, on an iPad-size canvas in the same background
colour, so nothing in it is ever clipped.

Apple's iPad 13" portrait sizes are 2064x2752 and 2048x2732; 2064x2752 is the
default. Output is RGB with no alpha channel, which App Store Connect requires.

Usage:
  python3 compose_ipad.py                      # every slide in the default set
  python3 compose_ipad.py --src DIR --out DIR  # another set
  python3 compose_ipad.py --size 2048x2732     # the other accepted size

Needs Pillow (pip install pillow).
"""

import argparse
import glob
import os
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_SRC = os.path.join(HERE, "app-store-2026-09-18", "1320x2868", "en")
# The cream every slide in the set is drawn on. Used for the side margins.
DEFAULT_BG = "#F5F1E9"


def hex_to_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def compose(src_path, out_path, canvas_size, bg):
    slide = Image.open(src_path).convert("RGB")
    canvas_w, canvas_h = canvas_size

    # Fit by height so the whole slide shows. Never crop, never stretch.
    scale = min(canvas_h / slide.height, canvas_w / slide.width)
    fitted = slide.resize((round(slide.width * scale), round(slide.height * scale)), Image.LANCZOS)

    canvas = Image.new("RGB", canvas_size, bg)
    canvas.paste(fitted, ((canvas_w - fitted.width) // 2, (canvas_h - fitted.height) // 2))
    canvas.save(out_path, "PNG")
    return fitted.size


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--src", default=DEFAULT_SRC, help="folder of finished iPhone slides (PNG)")
    parser.add_argument("--out", help="output folder (default: <set>/<size>/en next to the source set)")
    parser.add_argument("--size", default="2064x2752", help="WIDTHxHEIGHT of the iPad canvas")
    parser.add_argument("--bg", default=DEFAULT_BG, help="background colour for the side margins")
    args = parser.parse_args()

    width, height = (int(part) for part in args.size.lower().split("x"))
    sources = sorted(glob.glob(os.path.join(args.src, "*.png")))
    if not sources:
        sys.exit(f"No PNG slides found in {args.src}")

    out_dir = args.out or os.path.join(os.path.dirname(os.path.dirname(args.src.rstrip("/"))), args.size, "en")
    os.makedirs(out_dir, exist_ok=True)

    for source in sources:
        target = os.path.join(out_dir, os.path.basename(source))
        fitted = compose(source, target, (width, height), hex_to_rgb(args.bg))
        print(f"ok  {os.path.basename(source)} -> {args.size} (slide shown at {fitted[0]}x{fitted[1]})")
    print(f"\n{len(sources)} slides written to {out_dir}")


if __name__ == "__main__":
    main()
