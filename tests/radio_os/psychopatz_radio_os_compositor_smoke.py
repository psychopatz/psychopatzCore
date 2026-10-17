"""Offline contract test for the canonical Radio OS compositor.

The runtime manifest and device-local PNGs are the only source of truth. This
test deliberately does not load the retired source-catalog atlas or a second
Lua manifest.
"""

from pathlib import Path
import json
import math

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[2]
COMMON = ROOT / "Contents/mods/PsychopatzCore/common"
MANIFEST = COMMON / "media/ui/Radio/DeviceManifest.json"
RENDERER = ROOT / (
    "Contents/mods/PsychopatzCore/42.20/media/lua/client/"
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOSWindow_Renderer.lua"
)


def number(value):
    return float(value)


def rect(value):
    assert isinstance(value, (list, tuple)) and len(value) == 4
    x, y, width, height = (int(number) for number in value)
    assert width > 0 and height > 0
    return x, y, width, height


def inside(inner, outer):
    ix, iy, iw, ih = inner
    ox, oy, ow, oh = outer
    return (ix >= ox and iy >= oy
            and ix + iw <= ox + ow
            and iy + ih <= oy + oh)


def overlap(left, right):
    lx, ly, lw, lh = left
    rx, ry, rw, rh = right
    return (lx < rx + rw and rx < lx + lw
            and ly < ry + rh and ry < ly + lh)


def scaled(value, scale):
    x, y, width, height = rect(value)
    return (math.floor(x * scale + 0.5),
            math.floor(y * scale + 0.5),
            max(1, math.floor(width * scale + 0.5)),
            max(1, math.floor(height * scale + 0.5)))


def image_path(relative):
    assert isinstance(relative, str) and relative.startswith("media/")
    path = COMMON / relative
    assert path.is_file(), f"missing runtime asset: {relative}"
    return path


def load_manifest():
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    assert data["manifest_kind"] == "psychopatz_radio_runtime"
    assert data["schema_version"] >= 2
    assert len(data["devices"]) == 10
    return data


def assert_device_contract(device):
    canvas = device["canvas"]
    canvas_rect = (0, 0, int(canvas["width"]), int(canvas["height"]))
    assert canvas_rect[2] > 0 and canvas_rect[3] > 0

    shell_images = []
    for variant in ("pristine", "worn"):
        shell = device["shell"][variant]
        image = Image.open(image_path(shell["image"])).convert("RGBA")
        assert image.size == (canvas_rect[2], canvas_rect[3]), device["id"]
        shell_images.append(image)
    assert (ImageChops.difference(shell_images[0], shell_images[1])
            .getbbox() is not None), f"{device['id']}: worn shell is unchanged"

    for variant in ("pristine", "worn"):
        chassis = device["chassis"].get(variant)
        if chassis:
            image = Image.open(image_path(chassis["image"])).convert("RGBA")
            assert image.size == (canvas_rect[2], canvas_rect[3])

    lcd = device["lcd"]
    aperture = rect(lcd["aperture"])
    content = rect(lcd["content"])
    backing = rect(lcd["backing"])
    assert inside(content, aperture), f"{device['id']}: LCD content escapes aperture"
    assert inside(backing, aperture), f"{device['id']}: LCD backing escapes aperture"
    assert inside(aperture, canvas_rect), f"{device['id']}: LCD escapes canvas"

    interactive = []
    for component in device["components"]:
        hitbox = rect(component["hitbox"])
        assert inside(hitbox, canvas_rect), (
            f"{device['id']}/{component['id']}: hitbox escapes canvas"
        )
        for state in component.get("states", {}).values():
            image_path(state["image"])
        if component.get("interactive"):
            for prior_id, prior_hitbox in interactive:
                assert not overlap(hitbox, prior_hitbox), (
                    f"{device['id']}: interactive hitboxes overlap "
                    f"{prior_id}/{component['id']}"
                )
            interactive.append((component["id"], hitbox))

    for layer in device.get("lcd_layers", {}).values():
        image_path(layer["image"])

    # The same local coordinates must remain valid at the supported scale
    # range used by the responsive geometry policy.
    for width, height in ((1280, 720), (1920, 1080), (2560, 1440),
                          (3840, 2160)):
        maximum = max(0.2, min(width * 0.90 / canvas_rect[2],
                               height * 0.82 / canvas_rect[3]))
        minimum = max(0.2, min(0.75, maximum * 0.5))
        preferred = max(minimum, min(maximum,
                                     height * 0.78 / canvas_rect[3]))
        for scale in (minimum, preferred, maximum):
            scaled_canvas = scaled(canvas_rect, scale)
            assert inside(scaled(content, scale), scaled(aperture, scale))
            for _, hitbox in interactive:
                assert inside(scaled(hitbox, scale), scaled_canvas)


def assert_draw_order_contract():
    source = RENDERER.read_text(encoding="utf-8")
    shell = source.index("self:drawShell()")
    screen = source.index("self:drawScreen()")
    assert shell < screen, "full shell must render before dynamic LCD content"
    assert "self:setStencilRect(screen.x, screen.y, screen.w, screen.h)" in source
    assert "self:clearStencilRect()" in source
    assert "pcall(self.drawScreenContent, self)" in source
    assert "pcall(ISPanel.render, self)" in source
    # Presentation placement must never reintroduce a shell crop.
    assert "self:beginPresentationStencil()" not in source
    assert "local shellClip" not in source


def main():
    data = load_manifest()
    for device in data["devices"]:
        assert_device_contract(device)
    assert_draw_order_contract()
    print(json.dumps({
        "status": "PASS",
        "devices": len(data["devices"]),
        "manifest": str(MANIFEST),
        "renderer": str(RENDERER),
    }, sort_keys=True))


if __name__ == "__main__":
    main()
