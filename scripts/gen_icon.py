"""Generates the app launcher icon: a wallet+coin mark on a teal gradient.
Produces icon.png (full icon w/ background) and icon_foreground.png (transparent,
centered in the adaptive-icon safe zone) at 1024x1024.
"""
import math
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT_DIR = "assets/icon"


def lerp(a, b, t):
    return a + (b - a) * t


def gradient_bg(size, c1, c2):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            px[x, y] = (
                int(lerp(c1[0], c2[0], t)),
                int(lerp(c1[1], c2[1], t)),
                int(lerp(c1[2], c2[2], t)),
            )
    return img


def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def draw_glyph(canvas_size, scale):
    """Draws the wallet+coin mark centered on a transparent canvas."""
    img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

    # Draw at 4x supersampling for smooth edges, then downscale.
    ss = 4
    big = canvas_size * ss
    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    cx, cy = big / 2, big / 2
    unit = big * scale  # glyph footprint

    # --- Card / wallet (rotated rounded rect) ---
    card_w, card_h = unit * 0.78, unit * 0.5
    card = Image.new("RGBA", (int(card_w), int(card_h)), (0, 0, 0, 0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle(
        [0, 0, card_w - 1, card_h - 1],
        radius=card_h * 0.22,
        fill=(255, 255, 255, 255),
    )
    # A subtle stripe near the top of the card for detail.
    stripe_y = card_h * 0.32
    cd.rectangle([0, stripe_y, card_w, stripe_y + card_h * 0.09], fill=(15, 157, 130, 255))

    card = card.rotate(-10, expand=True, resample=Image.BICUBIC)
    card_pos = (int(cx - card.width / 2 - unit * 0.06), int(cy - card.height / 2 - unit * 0.05))
    layer.alpha_composite(card, card_pos)

    # --- Coin overlapping the bottom-right of the card ---
    coin_d = unit * 0.46
    coin_cx = cx + unit * 0.22
    coin_cy = cy + unit * 0.18
    coin_bbox = [coin_cx - coin_d / 2, coin_cy - coin_d / 2, coin_cx + coin_d / 2, coin_cy + coin_d / 2]

    # soft shadow under the coin
    shadow = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    off = coin_d * 0.04
    sd.ellipse(
        [coin_bbox[0] + off, coin_bbox[1] + off, coin_bbox[2] + off, coin_bbox[3] + off],
        fill=(0, 0, 0, 60),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(unit * 0.015))
    layer.alpha_composite(shadow)

    gold = (255, 200, 87, 255)
    gold_dark = (232, 165, 33, 255)
    d.ellipse(coin_bbox, fill=gold)
    ring_inset = coin_d * 0.12
    d.ellipse(
        [coin_bbox[0] + ring_inset, coin_bbox[1] + ring_inset, coin_bbox[2] - ring_inset, coin_bbox[3] - ring_inset],
        outline=gold_dark,
        width=max(2, int(coin_d * 0.045)),
    )

    # currency mark on the coin: a simple "$" via two arcs + a bar (kept geometric, not text,
    # so it renders identically across platforms without font dependencies)
    bar_w = coin_d * 0.09
    d.rectangle(
        [coin_cx - bar_w / 2, coin_bbox[1] + coin_d * 0.18, coin_cx + bar_w / 2, coin_bbox[3] - coin_d * 0.18],
        fill=gold_dark,
    )
    s_r = coin_d * 0.16
    d.arc([coin_cx - s_r, coin_cy - coin_d * 0.22 - s_r, coin_cx + s_r, coin_cy - coin_d * 0.22 + s_r],
          start=200, end=380, fill=gold_dark, width=max(2, int(coin_d * 0.05)))
    d.arc([coin_cx - s_r, coin_cy + coin_d * 0.22 - s_r, coin_cx + s_r, coin_cy + coin_d * 0.22 + s_r],
          start=20, end=200, fill=gold_dark, width=max(2, int(coin_d * 0.05)))

    layer.alpha_composite(layer.copy() if False else layer)  # no-op, keep structure simple

    layer = layer.resize((canvas_size, canvas_size), Image.LANCZOS)
    img.alpha_composite(layer)
    return img


def main():
    teal_light = (17, 181, 148)
    teal_dark = (8, 92, 76)

    # Full icon (legacy / fallback): gradient background + glyph.
    bg = gradient_bg(SIZE, teal_light, teal_dark).convert("RGBA")
    mask = rounded_mask(SIZE, int(SIZE * 0.22))
    rounded_bg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    rounded_bg.paste(bg, (0, 0), mask)

    glyph = draw_glyph(SIZE, scale=0.6)
    full_icon = Image.alpha_composite(rounded_bg, glyph)
    full_icon.save(f"{OUT_DIR}/icon.png")

    # Foreground-only (adaptive icon): transparent bg, glyph kept inside the safe zone.
    foreground = draw_glyph(SIZE, scale=0.42)
    foreground.save(f"{OUT_DIR}/icon_foreground.png")

    print("Wrote icon.png and icon_foreground.png")


if __name__ == "__main__":
    main()
