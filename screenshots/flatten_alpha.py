#!/usr/bin/env python3
"""Strip the alpha channel from App Store screenshots (ASC rejects alpha).

Usage: flatten_alpha.py DIR [DIR...]   (rewrites PNGs in place, recursively)
Pixels with partial transparency are composited onto white; fully opaque
images are just re-saved as RGB, so nothing visible changes.
"""
import sys
from pathlib import Path
from PIL import Image

for root in sys.argv[1:]:
    for p in sorted(Path(root).rglob("*.png")):
        im = Image.open(p)
        if im.mode in ("RGB", "L"):
            continue
        rgba = im.convert("RGBA")
        lo = rgba.getchannel("A").getextrema()[0]
        bg = Image.new("RGBA", rgba.size, (255, 255, 255, 255))
        Image.alpha_composite(bg, rgba).convert("RGB").save(p, "PNG")
        print(f"{p}: min alpha {lo} -> RGB")
