#!/usr/bin/env python3
"""Rebuild PsychopatzCore's manifest-aligned 1024x1024 shell texture.

The checked-in 341x341 compact art retains six artist-approved radio designs,
downsampled from the earlier higher-resolution approved local PNG. This is a
pixel-art fidelity compromise until the full-size master is published. The
compact source and the generated production atlas are BOTH stored in GitHub.
Build time only: requires Pillow; game does not load this script.
"""
import argparse
from collections import deque
from pathlib import Path
from PIL import Image, ImageDraw

SRC_SIZE = (341, 341)
ATLAS_SIZE = (1024, 1024)
COLS = (32, 320, 608)
ROWS = (32, 496)
SCREENS = [
    ("walkie_toys_shell",       (90, 236, 81, 61)),
    ("walkie_valutech_shell",   (85, 236, 82, 61)),
    ("walkie_premium_shell",    (81, 236, 83, 61)),
    ("walkie_tactical_shell",   (99, 246, 81, 55)),
    ("walkie_usarmy_shell",    (107, 247, 72, 55)),
    ("walkie_makeshift_shell",  (86, 247, 79, 55)),
]

# Measured connected alpha-zero apertures in the checked-in compact source
# after the 1024px atlas transform.  These are intentionally larger than the
# safe content viewports above; the runtime matte must cover this complete
# opening without filling the shell's unrelated exterior transparency.
LCD_BACKDROPS = [
    (88, 232, 90, 81),
    (82, 232, 96, 81),
    (80, 232, 102, 81),
    (97, 231, 93, 81),
    (97, 234, 93, 81),
    (83, 231, 99, 81),
]


def compose(source):
    image = Image.open(source).convert("RGBA")
    if image.size != SRC_SIZE:
        raise ValueError(f"expected {SRC_SIZE} source, got {image.size}")
    full = image.resize(ATLAS_SIZE, Image.Resampling.NEAREST)
    alpha = full.getchannel("A")
    draw = ImageDraw.Draw(alpha)
    for index, (name, screen) in enumerate(SCREENS):
        cx, cy = COLS[index % 3], ROWS[index // 3]
        sx, sy, sw, sh = screen
        draw.rectangle((cx + sx, cy + sy,
                        cx + sx + sw - 1, cy + sy + sh - 1), fill=0)
    full.putalpha(alpha)
    return full


def validate(image):
    if image.mode != "RGBA" or image.size != ATLAS_SIZE:
        raise AssertionError("wrong atlas mode or dimension")
    assert image.getpixel((0, 0))[3] == 0
    for index, (name, (sx, sy, sw, sh)) in enumerate(SCREENS):
        cx, cy = COLS[index % 3], ROWS[index // 3]
        sprite = image.crop((cx, cy, cx + 256, cy + 432))
        if sprite.getchannel("A").getbbox() is None:
            raise AssertionError(f"{name}: empty shell")
        region = image.crop((cx + sx, cy + sy,
                             cx + sx + sw, cy + sy + sh))
        if region.getchannel("A").getbbox() is not None:
            raise AssertionError(f"{name}: screen is not fully transparent")
        if sx < 0 or sy < 0 or sx + sw > 256 or sy + sh > 432:
            raise AssertionError(f"{name}: screen out of cell bounds")
        aperture = LCD_BACKDROPS[index]
        pixels = sprite.getchannel("A").load()
        start = (sx + sw // 2, sy + sh // 2)
        queue = deque([start])
        seen = {start}
        while queue:
            x, y = queue.popleft()
            for nx, ny in ((x - 1, y), (x + 1, y),
                           (x, y - 1), (x, y + 1)):
                if not (0 <= nx < 256 and 0 <= ny < 432):
                    continue
                if (nx, ny) in seen or pixels[nx, ny] != 0:
                    continue
                seen.add((nx, ny))
                queue.append((nx, ny))
        xs = [point[0] for point in seen]
        ys = [point[1] for point in seen]
        measured = (min(xs), min(ys), max(xs) - min(xs) + 1,
                    max(ys) - min(ys) + 1)
        if measured != aperture:
            raise AssertionError(
                f"{name}: LCD aperture drifted: {measured} != {aperture}"
            )
    if image.crop((896, 0, 1024, 1024)).getchannel("A").getbbox():
        raise AssertionError("atlas bleeds into right reserve")
    if image.crop((0, 960, 1024, 1024)).getchannel("A").getbbox():
        raise AssertionError("atlas bleeds into bottom reserve")


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--source',
        default='Contents/mods/PsychopatzCore/42.20/media/ui/psychopatz/radio/shells/DTA_Walkie_Shells_CompactSource.png')
    p.add_argument('--output',
        default='Contents/mods/PsychopatzCore/42.20/media/ui/psychopatz/radio/shells/DTA_Walkie_Shells.png')
    p.add_argument('--preview', default=None)
    args = p.parse_args()
    atlas = compose(args.source)
    validate(atlas)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output, optimize=True)
    reopened = Image.open(output).convert('RGBA')
    validate(reopened)
    if reopened.tobytes() != atlas.tobytes():
        raise AssertionError('PNG roundtrip mismatch')
    if args.preview:
        bg = Image.new('RGBA', ATLAS_SIZE, (29, 33, 31, 255))
        bg.alpha_composite(atlas)
        bg.convert('RGB').save(args.preview, optimize=True)
    print('PASS: 1024x1024 / 6 walkie shells / alpha-zero LCD openings / valid cells')


if __name__ == '__main__':
    main()
