#!/usr/bin/env python3
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "Resources"
ICONSET = RESOURCES / "MuPlan.iconset"
ICNS = RESOURCES / "MuPlan.icns"


def rounded_rect_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/Library/Fonts/Arial Unicode.ttf",
    ]
    for candidate in candidates:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            pass
    return ImageFont.load_default()


def make_base_icon(size: int = 1024) -> Image.Image:
    scale = size / 1024
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    background = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(background)
    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(22 + 10 * t)
        g = int(118 + 55 * t)
        b = int(157 + 63 * t)
        draw.line((0, y, size, y), fill=(r, g, b, 255))
    image.alpha_composite(background, (0, 0))

    mask = rounded_rect_mask(size, int(220 * scale))
    image.putalpha(mask)

    draw = ImageDraw.Draw(image)

    # Soft desktop card.
    card = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    card_draw = ImageDraw.Draw(card)
    card_box = (
        int(150 * scale),
        int(172 * scale),
        int(874 * scale),
        int(852 * scale),
    )
    card_draw.rounded_rectangle(card_box, radius=int(120 * scale), fill=(255, 255, 255, 238))
    card_draw.rounded_rectangle(card_box, radius=int(120 * scale), outline=(255, 255, 255, 150), width=max(2, int(6 * scale)))
    image.alpha_composite(card)

    # Pet face.
    face_box = (
        int(238 * scale),
        int(250 * scale),
        int(550 * scale),
        int(562 * scale),
    )
    draw.rounded_rectangle(face_box, radius=int(92 * scale), fill=(31, 41, 55, 255))
    eye_r = int(18 * scale)
    draw.ellipse((int(330 * scale) - eye_r, int(372 * scale) - eye_r, int(330 * scale) + eye_r, int(372 * scale) + eye_r), fill=(255, 255, 255, 235))
    draw.ellipse((int(456 * scale) - eye_r, int(372 * scale) - eye_r, int(456 * scale) + eye_r, int(372 * scale) + eye_r), fill=(255, 255, 255, 235))
    draw.rounded_rectangle((int(352 * scale), int(458 * scale), int(432 * scale), int(476 * scale)), radius=int(9 * scale), fill=(255, 255, 255, 235))

    # Visible pinned task lines.
    line_x = int(606 * scale)
    for index, color in enumerate([(239, 68, 68, 255), (20, 184, 166, 255), (31, 41, 55, 255)]):
        y = int((288 + index * 92) * scale)
        draw.rounded_rectangle((line_x, y, int(790 * scale), y + int(26 * scale)), radius=int(13 * scale), fill=color)
        draw.rounded_rectangle((line_x, y + int(40 * scale), int(820 * scale), y + int(58 * scale)), radius=int(9 * scale), fill=(148, 163, 184, 190))

    # MuPlan mark.
    text_font = font(int(168 * scale))
    text = "μ"
    bbox = draw.textbbox((0, 0), text, font=text_font)
    text_x = int(258 * scale)
    text_y = int(610 * scale) - (bbox[3] - bbox[1]) // 2
    draw.text((text_x, text_y), text, font=text_font, fill=(22, 118, 157, 255))

    small_font = font(int(78 * scale))
    draw.text((int(440 * scale), int(626 * scale)), "Plan", font=small_font, fill=(31, 41, 55, 255))

    return image


def main() -> None:
    RESOURCES.mkdir(exist_ok=True)
    ICONSET.mkdir(exist_ok=True)
    base = make_base_icon(1024)

    specs = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]
    for name, size in specs:
        base.resize((size, size), Image.Resampling.LANCZOS).save(ICONSET / name)

    # iconutil is called by package_app.sh. Keeping this script pure-Python makes
    # icon PNG regeneration easy to inspect before converting to icns.
    print(ICONSET)
    print(ICNS)


if __name__ == "__main__":
    main()
