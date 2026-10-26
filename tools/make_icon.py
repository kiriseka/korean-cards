"""Draw the app icon: the syllable 한 in geometric strokes on taegeuk blue (original art, no fonts).

Usage: python tools/make_icon.py   → assets/icon/{icon,foreground,splash}.png
Then:  dart run flutter_launcher_icons && dart run flutter_native_splash:create
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "icon"
BLUE = (0, 71, 160, 255)
RED = (205, 46, 58, 255)
WHITE = (255, 255, 255, 255)
SIZE = 1024
SS = 4  # supersampling for smooth edges


def glyph(draw: ImageDraw.ImageDraw, x0: float, y0: float, scale: float, color, accent=True) -> None:
    """한 on a 100-unit grid placed at (x0, y0); one unit = scale pixels."""
    def box(x1, y1, x2, y2):
        r = 4.5 * scale
        draw.rounded_rectangle([x0 + x1 * scale, y0 + y1 * scale, x0 + x2 * scale, y0 + y2 * scale], radius=r, fill=color)

    # ㅎ: short top stroke, long bar, ring
    box(25, 4, 41, 13)
    box(9, 18, 57, 27)
    cx, cy, r_out, r_in = 33, 42.5, 13, 5
    draw.ellipse([x0 + (cx - r_out) * scale, y0 + (cy - r_out) * scale, x0 + (cx + r_out) * scale, y0 + (cy + r_out) * scale], fill=color)
    draw.ellipse([x0 + (cx - r_in) * scale, y0 + (cy - r_in) * scale, x0 + (cx + r_in) * scale, y0 + (cy + r_in) * scale], fill=(0, 0, 0, 0))
    # ㅏ: tall stroke with a tick
    box(67, 2, 76, 58)
    box(72, 25, 90, 34)
    # ㄴ: down then across
    box(15, 63, 24, 96)
    box(15, 87, 88, 96)
    if accent:
        # a small red "seal" dot
        draw.ellipse([x0 + 82 * scale, y0 + 63 * scale, x0 + 94 * scale, y0 + 75 * scale], fill=RED)


def render(size: int, background: bool, glyph_fraction: float, color=WHITE, accent=True) -> Image.Image:
    big = size * SS
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if background:
        draw.rounded_rectangle([0, 0, big, big], radius=big * 0.22, fill=BLUE)
    span = big * glyph_fraction
    glyph_layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    glyph(ImageDraw.Draw(glyph_layer), (big - span) / 2, (big - span) / 2, span / 100, color, accent)
    if background:
        # Punch the ring's hole through to the background colour.
        img.alpha_composite(glyph_layer)
    else:
        img = glyph_layer
    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    render(SIZE, background=True, glyph_fraction=0.62).save(OUT / "icon.png")
    # Adaptive icons crop to the centre ~66%; keep the glyph inside it.
    render(SIZE, background=False, glyph_fraction=0.46).save(OUT / "foreground.png")
    render(SIZE, background=False, glyph_fraction=0.46, accent=False).save(OUT / "monochrome.png")
    render(768, background=False, glyph_fraction=0.55).save(OUT / "splash.png")
    print("wrote", ", ".join(p.name for p in sorted(OUT.glob("*.png"))))


if __name__ == "__main__":
    main()
