"""Offline compositor, alpha-hole and responsive-geometry smoke test.

This test intentionally stays outside Project Zomboid.  It validates the
checked-in PNGs and the device-local coordinate contract with Pillow, then
builds synthetic RGBA composites so a transparent shell never exposes the
world through its intended LCD aperture.
"""

from collections import deque
from pathlib import Path
import json
import math
import re

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
ATLAS = ROOT / (
    "Contents/mods/PsychopatzCore/42.20/media/ui/psychopatz/radio/"
    "shells/DTA_Walkie_Shells.png"
)
CORE_ATLAS = ROOT / (
    "Contents/mods/PsychopatzCore/42.20/media/ui/psychopatz/radio/ui/"
    "DTA_Walkie_UI_Core.png"
)
OVERLAY_ATLAS = ROOT / (
    "Contents/mods/PsychopatzCore/42.20/media/ui/psychopatz/radio/ui/"
    "DTA_Walkie_Overlays.png"
)
MANIFEST = ROOT / (
    "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioManifest.lua"
)
RENDERER = ROOT / (
    "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Renderer.lua"
)


SHELLS = (
    {
        "id": "walkie_toys_shell",
        "cell": (32, 32),
        "content": (90, 236, 81, 61),
        "aperture": (88, 232, 90, 81),
        "controls": ((75, 326, 31, 26), (115, 326, 31, 26), (154, 326, 31, 26)),
    },
    {
        "id": "walkie_valutech_shell",
        "cell": (320, 32),
        "content": (85, 236, 82, 61),
        "aperture": (82, 232, 96, 81),
        "controls": ((74, 326, 31, 26), (112, 326, 31, 26), (150, 326, 31, 26)),
    },
    {
        "id": "walkie_premium_shell",
        "cell": (608, 32),
        "content": (81, 236, 83, 61),
        "aperture": (80, 232, 102, 81),
        "controls": ((68, 326, 31, 26), (108, 326, 31, 26), (149, 326, 31, 26)),
    },
    {
        "id": "walkie_tactical_shell",
        "cell": (32, 496),
        "content": (99, 246, 81, 55),
        "aperture": (97, 231, 93, 81),
        "controls": ((85, 326, 31, 26), (123, 326, 31, 26), (161, 326, 31, 26)),
    },
    {
        "id": "walkie_usarmy_shell",
        "cell": (320, 496),
        "content": (107, 247, 72, 55),
        "aperture": (97, 234, 93, 81),
        "controls": ((85, 326, 31, 26), (122, 326, 31, 26), (160, 326, 31, 26)),
    },
    {
        "id": "walkie_makeshift_shell",
        "cell": (608, 496),
        "content": (86, 247, 79, 55),
        "aperture": (83, 231, 99, 81),
        "controls": ((72, 326, 31, 26), (116, 326, 31, 26), (157, 326, 31, 26)),
    },
)


def rect_box(rect):
    x, y, w, h = rect
    return (x, y, x + w, y + h)


def snap(value):
    return math.floor(float(value) + 0.5)


def scaled(rect, scale):
    x, y, w, h = rect
    return (snap(x * scale), snap(y * scale),
            max(1, snap(w * scale)), max(1, snap(h * scale)))


def connected_zero_bbox(alpha, start, threshold=0):
    width, height = alpha.size
    pixels = alpha.load()
    queue = deque([start])
    seen = {start}
    while queue:
        x, y = queue.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if not (0 <= nx < width and 0 <= ny < height):
                continue
            if (nx, ny) in seen or pixels[nx, ny] > threshold:
                continue
            seen.add((nx, ny))
            queue.append((nx, ny))
    xs = [point[0] for point in seen]
    ys = [point[1] for point in seen]
    return (min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1), seen


def overlap(left, right):
    lx, ly, lw, lh = left
    rx, ry, rw, rh = right
    return (lx < rx + rw and rx < lx + lw and
            ly < ry + rh and ry < ly + lh)


def assert_manifest_geometry():
    source = MANIFEST.read_text(encoding="utf-8")
    for item in SHELLS:
        assert f'skin("{item["id"]}"' in source, item["id"]
        content = "{ " + ", ".join(str(value) for value in item["content"]) + " }"
        aperture = "{ " + ", ".join(str(value) for value in item["aperture"]) + " }"
        start = source.index(f'skin("{item["id"]}"')
        end = source.index("\n\n", start)
        block = source[start:end]
        assert content in block, f"{item['id']}: content geometry drift"
        assert aperture in block, f"{item['id']}: aperture geometry drift"
    assert "function M.LCDBounds" in source
    assert "lcdBackdrop" in source


def assert_alpha_and_uv_contract(atlas):
    assert atlas.size == (1024, 1024) and atlas.mode == "RGBA"
    cells = []
    for item in SHELLS:
        cx, cy = item["cell"]
        cell = atlas.crop((cx, cy, cx + 256, cy + 432))
        alpha = cell.getchannel("A")
        content = item["content"]
        aperture = item["aperture"]
        assert alpha.crop(rect_box(content)).getbbox() is None, (
            f"{item['id']}: content viewport is not alpha-zero"
        )
        center = (content[0] + content[2] // 2,
                  content[1] + content[3] // 2)
        actual, _ = connected_zero_bbox(alpha, center)
        assert actual == aperture, (
            f"{item['id']}: aperture={aperture} measured={actual}"
        )
        assert alpha.crop(rect_box(aperture)).getbbox() is not None
        assert 0 <= aperture[0] and 0 <= aperture[1]
        assert aperture[0] + aperture[2] <= 256
        assert aperture[1] + aperture[3] <= 432
        for control in item["controls"]:
            assert 0 <= control[0] and 0 <= control[1]
            assert control[0] + control[2] <= 256
            assert control[1] + control[3] <= 432
            assert not overlap(control, aperture), (
                f"{item['id']}: control intersects LCD aperture"
            )
        cells.append((cx, cy, alpha.getbbox()))

    # The source builder reserves the right and bottom atlas gutters.
    assert atlas.crop((896, 0, 1024, 1024)).getchannel("A").getbbox() is None
    assert atlas.crop((0, 960, 1024, 1024)).getchannel("A").getbbox() is None
    # Shell cells have deliberate 32px gutters, preventing linear filtering
    # from sampling a neighboring radio when the exact UV rect is drawn.
    for gap in ((288, 32, 32, 432), (576, 32, 32, 432),
                (864, 32, 32, 432), (288, 496, 32, 432),
                (576, 496, 32, 432), (864, 496, 32, 432),
                (32, 464, 832, 32)):
        assert atlas.crop(rect_box(gap)).getchannel("A").getbbox() is None
    return cells


def assert_background_alpha_contract():
    core = Image.open(CORE_ATLAS).convert("RGBA")
    for name, rect in (
        ("green", (16, 16, 224, 128)),
        ("amber", (256, 16, 224, 128)),
        ("dark", (496, 16, 224, 128)),
        ("noise", (736, 16, 224, 128)),
    ):
        alpha = core.crop(rect_box(rect)).getchannel("A")
        low, high = alpha.getextrema()
        assert low == 0 and high == 255, (
            f"screen_bg_{name}: expected transparent and opaque pixels"
        )
    overlays = Image.open(OVERLAY_ATLAS).convert("RGBA")
    scanlines = overlays.crop((16, 16, 176, 176)).getchannel("A")
    assert scanlines.getextrema()[0] == 0
    assert scanlines.getextrema()[1] < 255


def synthetic_composite(atlas, item):
    cx, cy = item["cell"]
    shell = atlas.crop((cx, cy, cx + 256, cy + 432))
    content = item["content"]
    aperture = item["aperture"]
    world_color = (204, 34, 17, 255)
    matte_color = (9, 42, 22, 255)
    content_color = (16, 220, 120, 255)

    result = Image.new("RGBA", shell.size, world_color)
    matte = Image.new("RGBA", shell.size, (0, 0, 0, 0))
    ImageDraw.Draw(matte).rectangle(rect_box(aperture), fill=matte_color)
    result = Image.alpha_composite(result, matte)

    # A fully transparent themed sprite must not undo the opaque matte.
    transparent_theme = Image.new("RGBA", shell.size, (0, 0, 0, 0))
    result = Image.alpha_composite(result, transparent_theme)

    dynamic = Image.new("RGBA", shell.size, (0, 0, 0, 0))
    ImageDraw.Draw(dynamic).rectangle(rect_box(content), fill=content_color)
    result = Image.alpha_composite(result, dynamic)
    result = Image.alpha_composite(result, shell)

    sample = None
    for y in range(aperture[1], aperture[1] + aperture[3]):
        for x in range(aperture[0], aperture[0] + aperture[2]):
            if (x, y) not in [(content[0], content[1])] and shell.getpixel((x, y))[3] == 0:
                if not (content[0] <= x < content[0] + content[2]
                        and content[1] <= y < content[1] + content[3]):
                    sample = (x, y)
                    break
        if sample:
            break
    assert sample is not None
    assert result.getpixel(sample) == matte_color, (
        f"{item['id']}: world leaked through aperture at {sample}"
    )
    center = (content[0] + content[2] // 2,
              content[1] + content[3] // 2)
    assert result.getpixel(center) == content_color
    assert result.getpixel((0, 0)) == world_color, (
        f"{item['id']}: exterior transparent region was filled"
    )
    return sample


def assert_scaling_and_hitboxes():
    for width, height in ((1280, 720), (1920, 1080),
                          (2560, 1440), (3840, 2160)):
        maximum = max(0.5, min(width * 0.90 / 256, height * 0.82 / 432))
        minimum = max(0.5, min(0.75, maximum * 0.5))
        assert minimum <= maximum
        assert 256 * maximum <= width * 0.90 + 0.001
        assert 432 * maximum <= height * 0.82 + 0.001
        preferred = max(minimum, min(maximum, height * 0.78 / 432))
        assert minimum <= preferred <= maximum
        for scale in (minimum, preferred, maximum, 1.333):
            if scale < minimum or scale > maximum:
                continue
            shell = scaled((0, 0, 256, 432), scale)
            assert abs(shell[2] / shell[3] - 256 / 432) < 0.02
            for item in SHELLS:
                screen = scaled(item["content"], scale)
                aperture = scaled(item["aperture"], scale)
                assert (aperture[0] <= screen[0]
                        and aperture[1] <= screen[1]
                        and aperture[0] + aperture[2] >= screen[0] + screen[2]
                        and aperture[1] + aperture[3] >= screen[1] + screen[3])
                for control in item["controls"]:
                    hitbox = scaled(control, scale)
                    assert hitbox[0] >= 0 and hitbox[1] >= 0
                    assert hitbox[0] + hitbox[2] <= shell[2]
                    assert hitbox[1] + hitbox[3] <= shell[3]


def assert_draw_order_contract():
    source = RENDERER.read_text(encoding="utf-8")
    positions = [source.index(token) for token in (
        "self:drawLCDMatte()",
        'self:drawSprite("screen_bg_" .. theme',
        "pcall(self.drawScreenContent, self)",
        'self:drawSprite("overlay_scanlines_" .. theme',
        "self:drawShell()",
    )]
    assert positions == sorted(positions), "compositor layer order drifted"
    assert "self:clearStencilRect()" in source
    assert "pcall(self.drawScreenContent, self)" in source
    assert "pcall(ISPanel.render, self)" in source


def main():
    assert_manifest_geometry()
    atlas = Image.open(ATLAS).convert("RGBA")
    assert_alpha_and_uv_contract(atlas)
    assert_background_alpha_contract()
    samples = [synthetic_composite(atlas, item) for item in SHELLS]
    assert_scaling_and_hitboxes()
    assert_draw_order_contract()
    print(json.dumps({
        "status": "PASS",
        "shells": len(SHELLS),
        "opaque_aperture_samples": samples,
        "resolutions": ["1280x720", "1920x1080", "2560x1440", "3840x2160"],
        "source": str(ATLAS),
    }, sort_keys=True))


if __name__ == "__main__":
    main()
