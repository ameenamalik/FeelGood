#!/usr/bin/env python3
"""
Minimal-constraint App Store screenshot composer for FeelGood.

Design rules (per user direction, 2026-09-10):
- One font: SF Pro Rounded Black.
- One accent: the solid background colour.
- Elements only: headline (1 line/copy block), device frame + screenshot.
  No floating zoom-in/pop-out badges — user tried those and didn't like them.
- No verb/desc two-tier split — a single line of copy.
"""

import argparse
import os
from PIL import Image, ImageDraw, ImageFont

CANVAS_W = 1290
CANVAS_H = 2796

# Real photographic iPhone mockup (from the app-store-screenshots skill),
# not the flat placeholder frame — measured cutout, scaled to DEVICE_W below.
FRAME_NATIVE_W = 1022
FRAME_NATIVE_H = 2082
CUTOUT_L, CUTOUT_T = 52, 46
CUTOUT_W, CUTOUT_H = 918, 1990
CUTOUT_R = 126

DEVICE_W = 1030
_scale = DEVICE_W / FRAME_NATIVE_W
DEVICE_H = int(FRAME_NATIVE_H * _scale)
SCREEN_L = int(CUTOUT_L * _scale)
SCREEN_T = int(CUTOUT_T * _scale)
SCREEN_W = int(CUTOUT_W * _scale)
SCREEN_CORNER_R = int(CUTOUT_R * _scale)
DEVICE_Y = 780

HEADLINE_SIZE_MAX = 190
HEADLINE_SIZE_MIN = 100
MAX_TEXT_W = int(CANVAS_W * 0.70)
TEXT_TOP = 160

FONT_PATH = "/Users/ameena/Library/Fonts/SF-Pro-Rounded-Black.otf"
FRAME_PATH = os.path.expanduser(
    "~/Projects/yoga/FeelGood/FeelGood/.claude/skills/app-store-screenshots/mockup.png"
)


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def word_wrap(draw, text, font, max_w):
    words = text.split()
    lines, cur = [], ""
    for w in words:
        test = f"{cur} {w}".strip()
        if draw.textlength(test, font=font) <= max_w:
            cur = test
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def fit_font_wrapped(draw, text, max_w, size_max, size_min, max_lines=2):
    """Largest single font size where `text` word-wraps into <= max_lines,
    each fitting max_w. One weight, one size — a single copy block that may
    span multiple lines, not a shrink-to-one-line-forever search."""
    for size in range(size_max, size_min - 1, -4):
        font = ImageFont.truetype(FONT_PATH, size)
        lines = word_wrap(draw, text, font, max_w)
        if len(lines) <= max_lines:
            return font, lines
    font = ImageFont.truetype(FONT_PATH, size_min)
    return font, word_wrap(draw, text, font, max_w)


def rounded_shadow_badge(content_img, corner_r, shadow_blur=28, shadow_alpha=90, pad=0):
    """Wrap content_img (RGBA) in a soft drop shadow on a transparent layer."""
    w, h = content_img.size
    margin = shadow_blur * 3
    layer = Image.new("RGBA", (w + margin * 2, h + margin * 2), (0, 0, 0, 0))

    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w, h], radius=corner_r, fill=255)

    shadow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    shadow_shape = Image.new("L", layer.size, 0)
    ImageDraw.Draw(shadow_shape).rounded_rectangle(
        [margin, margin + 14, margin + w, margin + h + 14], radius=corner_r, fill=shadow_alpha
    )
    shadow_shape = shadow_shape.filter(ImageFilter.GaussianBlur(shadow_blur))
    shadow.putalpha(shadow_shape)

    content_rgba = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    content_rgba.paste(content_img, (margin, margin), mask)

    out = Image.alpha_composite(shadow, content_rgba)
    return out, margin


def compose(bg_hex, headline, screenshot_path, output_path, crop_box, badge_scale, badge_anchor):
    bg = hex_to_rgb(bg_hex)
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (*bg, 255))
    draw = ImageDraw.Draw(canvas)

    # ── 1. Headline: one copy block, one font/weight, wraps if needed ─
    font, lines = fit_font_wrapped(draw, headline.upper(), MAX_TEXT_W, HEADLINE_SIZE_MAX, HEADLINE_SIZE_MIN)
    y = TEXT_TOP
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=font)
        h = bbox[3] - bbox[1]
        draw.text((CANVAS_W // 2, y - bbox[1]), line, fill="white", font=font, anchor="mt")
        y += h + 24
    text_bottom = y

    # ── 2. Device frame + screenshot ─────────────────────────────────
    device_x = (CANVAS_W - DEVICE_W) // 2
    device_y = DEVICE_Y
    screen_x = device_x + SCREEN_L
    screen_y = device_y + SCREEN_T

    # Frame goes down first — its screen cutout is painted solid black, not
    # transparent (matches the template's own z-index: mockup image below,
    # screenshot layered on top of the cutout, not composited via alpha).
    frame_template = Image.open(FRAME_PATH).convert("RGBA")
    frame_template = frame_template.resize((DEVICE_W, DEVICE_H), Image.LANCZOS)
    frame_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    frame_layer.paste(frame_template, (device_x, device_y), frame_template)
    canvas = Image.alpha_composite(canvas, frame_layer)

    # Screenshot on top, clipped to the cutout's rounded rect, cropped to the
    # visible screen height only (objectFit: cover / objectPosition: top).
    shot = Image.open(screenshot_path).convert("RGBA")
    scale = SCREEN_W / shot.width
    shot = shot.resize((SCREEN_W, int(shot.height * scale)), Image.LANCZOS)
    screen_h = int(CUTOUT_H * _scale)
    shot = shot.crop((0, 0, SCREEN_W, min(screen_h, shot.height)))

    scr_mask = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(scr_mask).rounded_rectangle(
        [screen_x, screen_y, screen_x + SCREEN_W, screen_y + screen_h], radius=SCREEN_CORNER_R, fill=255
    )
    scr_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    scr_layer.paste(shot, (screen_x, screen_y))
    scr_layer.putalpha(scr_mask)
    canvas = Image.alpha_composite(canvas, scr_layer)

    # ── 3. The one attention element: a zoomed-in detail badge ──────
    crop = shot_orig = Image.open(screenshot_path).convert("RGBA").crop(crop_box)
    bw, bh = int(crop.width * badge_scale), int(crop.height * badge_scale)
    crop = crop.resize((bw, bh), Image.LANCZOS)
    badge, margin = rounded_shadow_badge(crop, corner_r=int(min(bw, bh) * 0.16))

    bx, by = badge_anchor
    bx -= margin
    by -= margin
    canvas = Image.alpha_composite(canvas, Image.new("RGBA", canvas.size, (0, 0, 0, 0)))
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    layer.paste(badge, (bx, by), badge)
    canvas = Image.alpha_composite(canvas, layer)

    canvas.convert("RGB").save(output_path, "PNG")
    print(f"✓ {output_path} ({CANVAS_W}×{CANVAS_H}) headline size={font.size}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--bg", required=True)
    p.add_argument("--headline", required=True)
    p.add_argument("--screenshot", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--crop", required=True, help="x0,y0,x1,y1 in source screenshot pixels")
    p.add_argument("--badge-scale", type=float, default=2.2)
    p.add_argument("--badge-anchor", required=True, help="x,y top-left of badge on canvas")
    args = p.parse_args()

    crop_box = tuple(int(v) for v in args.crop.split(","))
    anchor = tuple(int(v) for v in args.badge_anchor.split(","))
    compose(args.bg, args.headline, args.screenshot, args.output, crop_box, args.badge_scale, anchor)


if __name__ == "__main__":
    main()
