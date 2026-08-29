"""Build Civ V DDS assets from the two checked-in lossless source images."""

from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Art" / "Source"
ICONS = ROOT / "Art" / "Icons"
DOM = ROOT / "Art" / "DawnOfMan"
SIZES = (256, 128, 80, 64, 45, 32)


def cover(image: Image.Image, width: int, height: int, focus=(0.5, 0.5)) -> Image.Image:
    source_ratio = image.width / image.height
    target_ratio = width / height
    if source_ratio > target_ratio:
        crop_width = int(round(image.height * target_ratio))
        left = int(round((image.width - crop_width) * focus[0]))
        left = max(0, min(left, image.width - crop_width))
        box = (left, 0, left + crop_width, image.height)
    else:
        crop_height = int(round(image.width / target_ratio))
        top = int(round((image.height - crop_height) * focus[1]))
        top = max(0, min(top, image.height - crop_height))
        box = (0, top, image.width, top + crop_height)
    return image.crop(box).resize((width, height), Image.Resampling.LANCZOS)


def polish(image: Image.Image) -> Image.Image:
    image = ImageEnhance.Contrast(image).enhance(1.05)
    image = ImageEnhance.Color(image).enhance(1.04)
    return image.filter(ImageFilter.UnsharpMask(radius=1.0, percent=75, threshold=3))


def save_dds(image: Image.Image, path: Path, alpha=False) -> None:
    mode = "RGBA" if alpha else "RGB"
    image.convert(mode).save(path, pixel_format="DXT5" if alpha else "DXT1")


def make_alpha(emblem: Image.Image, size: int) -> Image.Image:
    square = polish(cover(emblem, size, size, focus=(0.5, 0.5))).convert("RGB")
    gray = ImageOps.grayscale(square)
    # Suppress the deep navy background while retaining gold, ivory and violet marks.
    mask = gray.point(lambda value: 0 if value < 58 else min(255, (value - 58) * 4))
    mask = mask.filter(ImageFilter.GaussianBlur(max(0.35, size / 512)))
    white = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    white.putalpha(mask)
    return white


def main() -> None:
    ICONS.mkdir(parents=True, exist_ok=True)
    DOM.mkdir(parents=True, exist_ok=True)

    leader = Image.open(SOURCE / "TrentroulsLeader.png").convert("RGB")
    emblem = Image.open(SOURCE / "PossessionBrowsersEmblem.png").convert("RGB")

    # The generated leader source is landscape: keep his face above center in square crops.
    leader_square = polish(cover(leader, 1024, 1024, focus=(0.52, 0.35)))
    emblem_square = polish(cover(emblem, 1024, 1024))
    for size in SIZES:
        save_dds(emblem_square.resize((size, size), Image.Resampling.LANCZOS),
                 ICONS / f"PPB_Civ_{size}.dds")
        save_dds(leader_square.resize((size, size), Image.Resampling.LANCZOS),
                 ICONS / f"PPB_Leader_{size}.dds")
        save_dds(leader_square.resize((size, size), Image.Resampling.LANCZOS),
                 ICONS / f"PPB_Regular_{size}.dds")
        save_dds(emblem_square.resize((size, size), Image.Resampling.LANCZOS),
                 ICONS / f"PPB_Premium_{size}.dds")
        if size != 256:
            save_dds(make_alpha(emblem, size), ICONS / f"PPB_Alpha_{size}.dds", alpha=True)

    save_dds(emblem_square.resize((128, 128), Image.Resampling.LANCZOS),
             ICONS / "PPB_FeedThumbnail.dds")
    save_dds(polish(cover(leader, 1024, 768, focus=(0.5, 0.37))),
             DOM / "PPB_DawnOfMan.dds")
    # Civilization selection maps use the game's portrait-oriented 360x412 slot.
    save_dds(polish(cover(leader, 360, 412, focus=(0.55, 0.35))),
             DOM / "PPB_Map.dds")

    print(f"Built {len(list(ICONS.glob('*.dds')))} icon textures and 2 Dawn of Man textures.")


if __name__ == "__main__":
    main()
