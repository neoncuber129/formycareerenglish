from __future__ import annotations

from collections import deque
import json
from pathlib import Path

from PIL import Image


ROOT = Path(r"c:\formycareer")
SRC = ROOT / "icon.png"
NO_BG = ROOT / "icon_nobg.png"
ICO = ROOT / "icon.ico"

MAC_ICON_FILES = {
    "app_icon_16.png": 16,
    "app_icon_32.png": 32,
    "app_icon_64.png": 64,
    "app_icon_128.png": 128,
    "app_icon_256.png": 256,
    "app_icon_512.png": 512,
    "app_icon_1024.png": 1024,
}

MAC_TARGETS = [
    ROOT / "apps" / "desktop" / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset",
    ROOT / "apps" / "mobile" / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset",
]

IOS_TARGETS = [
    ROOT / "apps" / "desktop" / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset",
    ROOT / "apps" / "mobile" / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset",
]

WIN_TARGETS = [
    ROOT / "apps" / "desktop" / "windows" / "runner" / "resources" / "app_icon.ico",
    ROOT / "apps" / "mobile" / "windows" / "runner" / "resources" / "app_icon.ico",
]

ANDROID_TARGETS = [
    ROOT / "apps" / "desktop" / "android" / "app" / "src" / "main" / "res",
    ROOT / "apps" / "mobile" / "android" / "app" / "src" / "main" / "res",
]

WEB_TARGETS = [
    ROOT / "apps" / "desktop" / "web",
    ROOT / "apps" / "mobile" / "web",
]

ANDROID_MIPMAP_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Global artwork scale after background removal.
# Increased to better match macOS visual weight and reused across platforms.
COMMON_CONTENT_RATIO = 1.00
MASKABLE_CONTENT_RATIO = 0.90
WINDOWS_CONTENT_RATIO = 1.12


def remove_background(image: Image.Image) -> Image.Image:
    """Remove near-white regions connected to image borders."""
    im = image.convert("RGBA")
    w, h = im.size
    pixels = im.load()

    visited = [[False] * h for _ in range(w)]
    q: deque[tuple[int, int]] = deque()

    def near_white(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        return a > 0 and r >= 238 and g >= 238 and b >= 238

    # Seed flood fill with all border pixels that look like background.
    for x in range(w):
        for y in (0, h - 1):
            if not visited[x][y] and near_white(x, y):
                visited[x][y] = True
                q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not visited[x][y] and near_white(x, y):
                visited[x][y] = True
                q.append((x, y))

    # Remove only connected outer background to avoid punching holes inside logo.
    while q:
        x, y = q.popleft()
        r, g, b, _ = pixels[x, y]
        pixels[x, y] = (r, g, b, 0)
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not visited[nx][ny] and near_white(nx, ny):
                visited[nx][ny] = True
                q.append((nx, ny))
    return im


def fit_for_macos(image: Image.Image, size: int, content_ratio: float = COMMON_CONTENT_RATIO) -> Image.Image:
    """
    Place artwork into a square icon canvas with balanced breathing room.
    content_ratio 0.90 keeps icon visually aligned with common macOS icon balance.
    """
    base = image.convert("RGBA")
    alpha_box = base.getbbox()
    if alpha_box:
        base = base.crop(alpha_box)

    target_content = max(1, int(size * content_ratio))
    scale = min(target_content / base.width, target_content / base.height)
    new_w = max(1, int(base.width * scale))
    new_h = max(1, int(base.height * scale))
    resized = base.resize((new_w, new_h), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    offset = ((size - new_w) // 2, (size - new_h) // 2)
    canvas.alpha_composite(resized, offset)
    return canvas


def fit_square(image: Image.Image, size: int, content_ratio: float) -> Image.Image:
    """Resize icon artwork into a square canvas with transparent padding."""
    base = image.convert("RGBA")
    alpha_box = base.getbbox()
    if alpha_box:
        base = base.crop(alpha_box)
    target = max(1, int(size * content_ratio))
    scale = min(target / base.width, target / base.height)
    new_w = max(1, int(base.width * scale))
    new_h = max(1, int(base.height * scale))
    resized = base.resize((new_w, new_h), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((size - new_w) // 2, (size - new_h) // 2))
    return canvas


def render_ios_from_contents(no_bg: Image.Image, target_dir: Path) -> None:
    contents = json.loads((target_dir / "Contents.json").read_text(encoding="utf-8"))
    for item in contents.get("images", []):
        filename = item.get("filename")
        size_text = item.get("size")
        scale_text = item.get("scale", "1x")
        if not filename or not size_text:
            continue
        base_pt = float(size_text.split("x")[0])
        scale = int(scale_text.replace("x", ""))
        px = int(round(base_pt * scale))
        fit_square(no_bg, px, content_ratio=COMMON_CONTENT_RATIO).save(
            target_dir / filename,
            format="PNG",
        )


def main() -> None:
    src = Image.open(SRC).convert("RGBA")
    no_bg = remove_background(src)
    no_bg.save(NO_BG)

    # Update Windows ICO from transparent source.
    no_bg.save(
        ICO,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )
    # Windows taskbar often looks visually smaller than other apps.
    # Overscale slightly and allow edge crop for stronger icon presence.
    fit_square(no_bg, 256, content_ratio=WINDOWS_CONTENT_RATIO).save(
        ICO,
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )
    for win_target in WIN_TARGETS:
        win_target.write_bytes(ICO.read_bytes())

    # Generate macOS app icon set files.
    for target_dir in MAC_TARGETS:
        for filename, px in MAC_ICON_FILES.items():
            icon = fit_for_macos(no_bg, px)
            icon.save(target_dir / filename, format="PNG")

    # Generate iOS app icon set files for all declared sizes.
    for target_dir in IOS_TARGETS:
        render_ios_from_contents(no_bg, target_dir)

    # Generate Android launcher icons.
    for res_dir in ANDROID_TARGETS:
        for folder, px in ANDROID_MIPMAP_SIZES.items():
            fit_square(no_bg, px, content_ratio=COMMON_CONTENT_RATIO).save(
                res_dir / folder / "ic_launcher.png",
                format="PNG",
            )

    # Generate Web icons and favicon.
    for web_dir in WEB_TARGETS:
        fit_square(no_bg, 32, content_ratio=COMMON_CONTENT_RATIO).save(
            web_dir / "favicon.png",
            format="PNG",
        )
        fit_square(no_bg, 192, content_ratio=COMMON_CONTENT_RATIO).save(
            web_dir / "icons" / "Icon-192.png", format="PNG"
        )
        fit_square(no_bg, 512, content_ratio=COMMON_CONTENT_RATIO).save(
            web_dir / "icons" / "Icon-512.png", format="PNG"
        )
        # Keep safe-zone for maskable icons but scale up vs previous output.
        fit_square(no_bg, 192, content_ratio=MASKABLE_CONTENT_RATIO).save(
            web_dir / "icons" / "Icon-maskable-192.png", format="PNG"
        )
        fit_square(no_bg, 512, content_ratio=MASKABLE_CONTENT_RATIO).save(
            web_dir / "icons" / "Icon-maskable-512.png", format="PNG"
        )

    print("Done: icon synced for Windows, macOS, iOS, Android, and Web.")


if __name__ == "__main__":
    main()
