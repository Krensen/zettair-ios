#!/usr/bin/env python3
"""
Generate the Zettair app icon at all sizes Apple wants.

Composition (per the brief):
  1. Soft diagonal gradient background using two cool tones from the brand
     palette (deep blue → purple end).
  2. The seven-colour Paul-Smith signature stripe, running diagonally across
     the centre as a wide band.
  3. A large italic-Georgia "Z" overlaid in white, slightly off-centre so it
     reads as a glyph rather than a label.

Outputs ImageKit-style AppIcon assets into
  ZettairApp/Resources/Assets.xcassets/AppIcon.appiconset/
with a Contents.json Xcode 14+ recognises (single 1024 universal entry plus
legacy multi-size for older toolchains).

Run: python3 tools/generate_icon.py
"""

import json
import math
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "ZettairApp" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Brand stripe — same seven colours as the website + iOS hero.
STRIPE = [
    (232,  34,  42),  # red
    (242, 101,  34),  # orange
    (249, 168,  37),  # yellow
    (139, 195,  74),  # green
    ( 38, 198, 218),  # cyan
    ( 21, 101, 192),  # blue
    (106,  27, 154),  # purple
]

# Background gradient — anchored at the cool end of the stripe so the
# white Z + warm stripe band both pop against it.
BG_TOP    = ( 18,  28,  68)   # deep navy
BG_BOTTOM = ( 56,  20,  92)   # plum

# ---------------------------------------------------------------------------

def gradient_background(size):
    """Linear top-left → bottom-right gradient between BG_TOP and BG_BOTTOM."""
    img = Image.new("RGB", (size, size), BG_TOP)
    px = img.load()
    diag = size * 1.414
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)  # 0..1 along diagonal
            r = int(BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t)
            g = int(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t)
            b = int(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t)
            px[x, y] = (r, g, b)
    return img


def draw_diagonal_stripe(img, band_h_frac=0.18, angle_deg=-22):
    """
    Draw the seven-colour stripe as a diagonal band across the centre.

    band_h_frac controls how tall the band is as a fraction of the canvas.
    angle_deg tilts it; ~22° feels dynamic without looking sloppy.
    """
    size = img.width
    band_h = int(size * band_h_frac)

    # Render the stripe upright on a wide canvas, then rotate + paste.
    band_w = int(size * 1.6)
    band = Image.new("RGBA", (band_w, band_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(band)
    seg_w = band_w / len(STRIPE)
    for i, color in enumerate(STRIPE):
        x0 = int(i * seg_w)
        x1 = int((i + 1) * seg_w)
        d.rectangle([x0, 0, x1, band_h], fill=color + (255,))

    rotated = band.rotate(angle_deg, resample=Image.BICUBIC, expand=True)
    # Centre on the canvas.
    cx = (size - rotated.width) // 2
    cy = (size - rotated.height) // 2 + int(size * 0.04)  # nudge down a touch
    img_rgba = img.convert("RGBA")
    img_rgba.alpha_composite(rotated, dest=(cx, cy))
    return img_rgba


def draw_glyph(img, font_path):
    """Big italic-Georgia 'Z' in white, slightly off-centre."""
    size = img.width
    # Pillow doesn't expose tracking/letter-spacing knobs that map to SwiftUI's
    # `.tracking`, but the wordmark on the site uses letter-spacing -2px at
    # 4.5rem (72px), so per-em that's roughly -0.028 em. A single letter is
    # unaffected by tracking; just pick a large font and centre.
    font_size = int(size * 0.72)
    font = ImageFont.truetype(font_path, font_size)

    d = ImageDraw.Draw(img)
    text = "Z"

    # Measure the rendered glyph (italic letterforms have side-bearings that
    # matter for centring).
    bbox = d.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]

    # Centre, then nudge up slightly so the visual centre (descender-light Z)
    # matches the geometric centre.
    x = (size - text_w) // 2 - bbox[0]
    y = (size - text_h) // 2 - bbox[1] - int(size * 0.03)

    # Soft inner glow for depth — render a slightly translucent black shadow
    # offset by 2px down/right first, then the white glyph on top.
    shadow_offset = max(2, int(size * 0.006))
    shadow_img = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow_img)
    sd.text(
        (x + shadow_offset, y + shadow_offset),
        text, font=font, fill=(0, 0, 0, 110),
    )
    img.alpha_composite(shadow_img)

    d.text((x, y), text, font=font, fill=(255, 255, 255, 255))
    return img


def render_master(size=1024):
    """Render the master icon at the requested size."""
    img = gradient_background(size)
    img = draw_diagonal_stripe(img)
    img = draw_glyph(img, "/Library/Fonts/Georgia Italic.ttf")
    return img.convert("RGB")


# ---------------------------------------------------------------------------

# Apple's required sizes for an iOS app icon. (size_pt, scale)
# We always render from the 1024 master via Lanczos downsampling so each
# size looks crisp.
SIZES = [
    # iPhone notifications
    (20, 2), (20, 3),
    # iPhone settings
    (29, 2), (29, 3),
    # iPhone spotlight
    (40, 2), (40, 3),
    # iPhone app
    (60, 2), (60, 3),
    # iPad notifications
    (20, 1), (20, 2),
    # iPad settings
    (29, 1), (29, 2),
    # iPad spotlight
    (40, 1), (40, 2),
    # iPad app
    (76, 1), (76, 2),
    # iPad Pro app
    (83.5, 2),
    # App Store marketing
    (1024, 1),
]


def filename(pt, scale):
    return f"AppIcon-{pt}@{scale}x.png"


def write_contents_json(images):
    contents = {
        "images": images,
        "info": {"author": "xcode", "version": 1},
    }
    with open(OUT_DIR / "Contents.json", "w") as f:
        json.dump(contents, f, indent=2)


def main():
    print(f"Rendering master 1024×1024 …")
    master = render_master(1024)

    images_meta = []
    rendered = set()
    for pt, scale in SIZES:
        px = int(pt * scale)
        fname = f"AppIcon-{int(pt*10)}@{scale}x.png" if pt != int(pt) else f"AppIcon-{int(pt)}@{scale}x.png"
        path = OUT_DIR / fname
        if (px, fname) not in rendered:
            scaled = master.resize((px, px), Image.LANCZOS)
            scaled.save(path, "PNG", optimize=True)
            rendered.add((px, fname))
            print(f"  {px:>4}px → {fname}")
        size_str = f"{pt}x{pt}" if pt != int(pt) else f"{int(pt)}x{int(pt)}"
        idiom = "ios-marketing" if pt == 1024 else ("ipad" if pt in (76, 83.5) else "iphone")
        # 20/29/40 are shared between iPhone and iPad — emit both idioms.
        if pt in (20, 29, 40):
            images_meta.append({
                "size": size_str, "idiom": "iphone",
                "filename": fname, "scale": f"{scale}x",
            })
            images_meta.append({
                "size": size_str, "idiom": "ipad",
                "filename": fname, "scale": f"{scale}x",
            })
        else:
            entry = {
                "size": size_str, "idiom": idiom,
                "filename": fname, "scale": f"{scale}x",
            }
            if pt == 1024:
                entry["platform"] = "ios"
            images_meta.append(entry)

    # De-dup the meta (since we emitted iPhone/iPad pairs for shared sizes).
    seen = set()
    unique = []
    for m in images_meta:
        key = (m.get("size"), m.get("idiom"), m.get("scale"))
        if key in seen: continue
        seen.add(key)
        unique.append(m)

    write_contents_json(unique)
    print(f"\nWrote {OUT_DIR}")


if __name__ == "__main__":
    main()
