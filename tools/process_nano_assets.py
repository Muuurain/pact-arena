"""
Post-processes Nano Banana generated sprite sheets and key art into transparent RGBA PNGs
with edge-flood-filled alpha matting (preserving dark interior armor/outlines!),
de-halo color un-premultiplication, tight centering, and Godot-ready dimensions.
"""
from collections import deque
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "assets" / "art"
BRAIN_DIR = Path(r"C:\Users\12405\.gemini\antigravity\brain\41cdd672-82d1-41a3-a1d9-a45eb03cb7f0")


def flood_remove_black_bg(im: Image.Image, bfs_thresh: int = 12, feather_thresh: int = 34, bridge_leaks: bool = True) -> Image.Image:
    """Removes exterior pitch-black background using flood-fill alpha matting, optionally
    applying a 3x3 morphological bridge to prevent leaks through dark armor seams."""
    rgba = im.convert("RGBA")
    arr = np.array(rgba, dtype=np.float32)
    h, w = arr.shape[:2]
    lum = np.max(arr[..., :3], axis=2)

    fg = (lum > bfs_thresh).astype(np.uint8)
    if bridge_leaks:
        # 3x3 morphological closing on foreground mask bridges 1-2px outline seams against leaks
        padded_fg = np.pad(fg, 1, mode="constant", constant_values=0)
        dilated = np.zeros_like(fg)
        for dy in range(3):
            for dx in range(3):
                dilated = np.maximum(dilated, padded_fg[dy:dy + h, dx:dx + w])
        padded_dil = np.pad(dilated, 1, mode="constant", constant_values=0)
        closed_fg = np.ones_like(fg)
        for dy in range(3):
            for dx in range(3):
                closed_fg = np.minimum(closed_fg, padded_dil[dy:dy + h, dx:dx + w])
        closed_fg[:3, :] = fg[:3, :]
        closed_fg[-3:, :] = fg[-3:, :]
        closed_fg[:, :3] = fg[:, :3]
        closed_fg[:, -3:] = fg[:, -3:]
    else:
        closed_fg = fg

    visited = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()

    for x in range(w):
        for y in (0, h - 1):
            if closed_fg[y, x] == 0 and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if closed_fg[y, x] == 0 and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))

    while q:
        cy, cx = q.popleft()
        for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                if closed_fg[ny, nx] == 0:
                    visited[ny, nx] = True
                    q.append((ny, nx))

    # Expand back into raw lum <= bfs_thresh pixels immediately touching exterior
    for _ in range(2):
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            s = np.roll(visited, shift=(dy, dx), axis=(0, 1))
            visited |= (s & (lum <= bfs_thresh))

    # Build a 2-pixel fringe mask immediately bordering exterior background
    fringe = np.zeros((h, w), dtype=bool)
    for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)):
        shifted = np.roll(visited, shift=(dy, dx), axis=(0, 1))
        fringe |= (shifted & (~visited))

    alpha01 = np.where(visited, 0.0, 1.0)
    fringe_alpha = np.clip((lum - bfs_thresh) / max(1.0, float(feather_thresh - bfs_thresh)), 0.0, 1.0)
    alpha01 = np.where(fringe & (lum <= feather_thresh), fringe_alpha, alpha01)

    rgb = arr[..., :3]
    safe_a = np.maximum(alpha01[..., None], 0.14)
    rgb = np.where(fringe[..., None] & (alpha01[..., None] < 0.99) & (alpha01[..., None] > 0.02),
                   np.clip(rgb / safe_a, 0.0, 255.0), rgb)

    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    out[..., 3] = np.clip(alpha01 * 255.0, 0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def flood_remove_white_bg(im: Image.Image, hard_dist: float = 16.0, soft_dist: float = 54.0) -> Image.Image:
    """Removes exterior white background via border flood-fill and de-halos white fringe."""
    rgba = im.convert("RGBA")
    arr = np.array(rgba, dtype=np.float32)
    h, w = arr.shape[:2]
    dist_white = np.linalg.norm(255.0 - arr[..., :3], axis=2)

    visited = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()

    for x in range(w):
        for y in (0, h - 1):
            if dist_white[y, x] <= soft_dist and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if dist_white[y, x] <= soft_dist and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))

    while q:
        cy, cx = q.popleft()
        for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                if dist_white[ny, nx] <= soft_dist:
                    visited[ny, nx] = True
                    q.append((ny, nx))

    ext_alpha = np.clip((dist_white - hard_dist) / max(1.0, float(soft_dist - hard_dist)), 0.0, 1.0)
    alpha01 = np.where(visited, ext_alpha, 1.0)

    rgb = arr[..., :3]
    safe_a = np.maximum(alpha01[..., None], 0.12)
    dehalo = (rgb - (1.0 - alpha01[..., None]) * 255.0) / safe_a
    rgb = np.where(visited[..., None] & (alpha01[..., None] < 0.99) & (alpha01[..., None] > 0.02),
                   np.clip(dehalo, 0.0, 255.0), rgb)

    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    out[..., 3] = np.clip(alpha01 * 255.0, 0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def flood_remove_light_bg(im: Image.Image, hard_dist: float = 18.0, soft_dist: float = 52.0, min_hole_area: int = 36) -> Image.Image:
    """Removes exterior light/off-white background via corner-sampled flood-fill,
    de-halos fringes, and removes enclosed neutral background holes (e.g., ring/gear bores)."""
    rgba = im.convert("RGBA")
    arr = np.array(rgba, dtype=np.float32)
    h, w = arr.shape[:2]
    corners = np.array([arr[2, 2, :3], arr[2, w - 3, :3], arr[h - 3, 2, :3], arr[h - 3, w - 3, :3]])
    bg_rgb = np.median(corners, axis=0)
    dist_bg = np.linalg.norm(arr[..., :3] - bg_rgb[None, None, :], axis=2)

    visited = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()
    for x in range(w):
        for y in (0, h - 1):
            if dist_bg[y, x] <= soft_dist and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if dist_bg[y, x] <= soft_dist and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    while q:
        cy, cx = q.popleft()
        for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and dist_bg[ny, nx] <= soft_dist:
                visited[ny, nx] = True
                q.append((ny, nx))

    # Also detect enclosed neutral background cutouts (ring/gear/chain holes) not reachable from border
    chroma = np.max(arr[..., :3], axis=2) - np.min(arr[..., :3], axis=2)
    cand_hole = (~visited) & (dist_bg <= 22.0) & (chroma <= 10.0)
    hole_seen = np.zeros((h, w), dtype=bool)
    ys, xs = np.where(cand_hole)
    for sy, sx in zip(ys.tolist(), xs.tolist()):
        if hole_seen[sy, sx]:
            continue
        comp: list[tuple[int, int]] = []
        hq: deque[tuple[int, int]] = deque([(sy, sx)])
        hole_seen[sy, sx] = True
        while hq:
            cy, cx = hq.popleft()
            comp.append((cy, cx))
            for ny, nx in ((cy - 1, cx), (cy + 1, cx), (cy, cx - 1), (cy, cx + 1)):
                if 0 <= ny < h and 0 <= nx < w and not hole_seen[ny, nx] and cand_hole[ny, nx]:
                    hole_seen[ny, nx] = True
                    hq.append((ny, nx))
        if len(comp) >= min_hole_area:
            for py, px in comp:
                visited[py, px] = True
            # Feather 1px inner ring around removed cutout
            for py, px in comp:
                for ny, nx in ((py - 1, px), (py + 1, px), (py, px - 1), (py, px + 1)):
                    if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and dist_bg[ny, nx] <= soft_dist:
                        visited[ny, nx] = True

    ext_alpha = np.clip((dist_bg - hard_dist) / max(1.0, float(soft_dist - hard_dist)), 0.0, 1.0)
    alpha01 = np.where(visited, ext_alpha, 1.0)

    rgb = arr[..., :3]
    safe_a = np.maximum(alpha01[..., None], 0.14)
    dehalo = (rgb - (1.0 - alpha01[..., None]) * bg_rgb[None, None, :]) / safe_a
    rgb = np.where(visited[..., None] & (alpha01[..., None] < 0.99) & (alpha01[..., None] > 0.02),
                   np.clip(dehalo, 0.0, 255.0), rgb)

    out = np.zeros((h, w, 4), dtype=np.uint8)
    out[..., :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    out[..., 3] = np.clip(alpha01 * 255.0, 0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def slice_grid_light(sheet_path: Path, cols: int, rows: int, names: list[str], out_dir: Path, target_size: int, pad_ratio: float = 0.07):
    im = Image.open(sheet_path).convert("RGBA")
    sw, sh = im.size
    cell_w = sw / cols
    cell_h = sh / rows
    out_dir.mkdir(parents=True, exist_ok=True)
    for idx, name in enumerate(names):
        if not name:
            continue
        r = idx // cols
        c = idx % cols
        box = (int(round(c * cell_w)) + 6, int(round(r * cell_h)) + 6, int(round((c + 1) * cell_w)) - 6, int(round((r + 1) * cell_h)) - 6)
        cell = im.crop(box)
        matted = flood_remove_light_bg(cell, hard_dist=18.0, soft_dist=50.0)
        final = center_crop_square(matted, target_size, pad_ratio=pad_ratio)
        final.save(out_dir / f"{name}.png")
        print("Saved:", out_dir / f"{name}.png")


def center_crop_square(im: Image.Image, target_size: int, pad_ratio: float = 0.07) -> Image.Image:
    bbox = im.getbbox()
    if bbox is None:
        return Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    cropped = im.crop(bbox)
    cw, ch = cropped.size
    inner = int(target_size * (1.0 - pad_ratio * 2.0))
    scale = min(inner / max(1, cw), inner / max(1, ch))
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = cropped.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    canvas.paste(resized, ((target_size - nw) // 2, (target_size - nh) // 2), resized)
    return canvas


def slice_grid_black(sheet_path: Path, cols: int, rows: int, names: list[str], out_dir: Path, target_size: int, pad_ratio: float = 0.07, bridge_leaks: bool = True):
    im = Image.open(sheet_path).convert("RGBA")
    sw, sh = im.size
    cell_w = sw / cols
    cell_h = sh / rows
    out_dir.mkdir(parents=True, exist_ok=True)
    for idx, name in enumerate(names):
        if not name:
            continue
        r = idx // cols
        c = idx % cols
        box = (int(round(c * cell_w)) + 6, int(round(r * cell_h)) + 6, int(round((c + 1) * cell_w)) - 6, int(round((r + 1) * cell_h)) - 6)
        cell = im.crop(box)
        matted = flood_remove_black_bg(cell, bfs_thresh=14, feather_thresh=34, bridge_leaks=bridge_leaks)
        final = center_crop_square(matted, target_size, pad_ratio=pad_ratio)
        final.save(out_dir / f"{name}.png")
        print("Saved:", out_dir / f"{name}.png")


def find_exact_or_latest(prefix: str) -> Path | None:
    matches = sorted(BRAIN_DIR.glob(f"{prefix}_*.jpg")) + sorted(BRAIN_DIR.glob(f"{prefix}_*.png"))
    return matches[-1] if matches else None


def make_rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def build_items_and_sinks():
    # 9. Passive Items Sheet A (3x3 on light off-white bg)
    isa = find_exact_or_latest("items_sheet_a")
    if isa:
        slice_grid_light(isa, 3, 3, [
            "itm_glass_ring",
            "itm_blood_chalice",
            "itm_frenzy_gear",
            "itm_heavy_plate",
            "itm_greed_hourglass",
            "itm_magnet_core",
            "itm_dash_thruster",
            "itm_crimson_fang",
            "itm_eagle_eye",
        ], ART / "sprites" / "items", 128, pad_ratio=0.06)

    # 10. Passive Items Sheet B (3x3 on pitch-black bg)
    isb = find_exact_or_latest("items_sheet_b")
    if isb:
        slice_grid_black(isb, 3, 3, [
            "itm_arcane_capacitor",
            "itm_phantom_cloak",
            "itm_vital_heart",
            "itm_executioner_seal",
            "itm_void_prism",
            "itm_lucky_dice",
            "itm_blood_battery",
            "itm_mirror_buckle",
            "itm_titans_belt",
        ], ART / "sprites" / "items", 128, pad_ratio=0.06, bridge_leaks=False)

    # Clean black pocket behind top-left flare on bright silver mirror buckle
    mb_path = ART / "sprites" / "items" / "itm_mirror_buckle.png"
    if mb_path.exists():
        mb_im = Image.open(mb_path).convert("RGBA")
        arr = np.array(mb_im, dtype=np.float32)
        lum = np.max(arr[..., :3], axis=2)
        chroma = lum - np.min(arr[..., :3], axis=2)
        dark_halo = (arr[..., 3] > 0) & (lum < 36.0) & (chroma < 18.0)
        arr[dark_halo, 3] = 0.0
        soft_halo = (arr[..., 3] > 0) & (lum >= 36.0) & (lum < 56.0) & (chroma < 22.0)
        arr[soft_halo, 3] = np.minimum(arr[soft_halo, 3], ((lum[soft_halo] - 36.0) / 20.0) * 255.0)
        Image.fromarray(arr.astype(np.uint8), "RGBA").save(mb_path)
        print("Refined:", mb_path)

    # 11. Black-Market Sinks Strip (3x1 on pitch-black bg)
    ss = find_exact_or_latest("sinks_sheet")
    if ss:
        slice_grid_black(ss, 3, 1, [
            "sink_temper_power",
            "sink_temper_vital",
            "sink_mystery_relic",
        ], ART / "sprites" / "items", 128, pad_ratio=0.06, bridge_leaks=False)


def main():
    import sys
    if "--items-only" in sys.argv:
        build_items_and_sinks()
        return
    # 1. Menu Background (720x1280)
    mb = find_exact_or_latest("menu_bg")
    if mb:
        im = Image.open(mb).convert("RGB").resize((720, 1280), Image.Resampling.LANCZOS)
        im.save(ART / "ui" / "menu_bg.png")
        print("Saved menu_bg.png")

    # 2. Android Launcher Icon (512x512 + 192x192 rounded squircle + full square adaptive)
    li = find_exact_or_latest("launcher_icon")
    if li:
        im = Image.open(li).convert("RGBA")
        # Crop slight dark outer frame border (~4% on each side) so emblem fills Android icon nicely
        w, h = im.size
        inset = int(w * 0.045)
        cropped = im.crop((inset, inset, w - inset, h - inset))
        sq512 = cropped.resize((512, 512), Image.Resampling.LANCZOS)
        sq512.save(ART / "ui" / "launcher_512.png")
        sq192 = cropped.resize((192, 192), Image.Resampling.LANCZOS)
        rounded = Image.new("RGBA", (192, 192), (0, 0, 0, 0))
        rounded.paste(sq192, (0, 0), make_rounded_mask(192, 42))
        rounded.save(ART / "ui" / "launcher_192.png")
        print("Saved launcher_512.png & launcher_192.png")

    # 3. Heroes (3x2)
    hs = find_exact_or_latest("heroes_sheet")
    if hs:
        slice_grid_black(hs, 3, 2, [
            "hero_crimson_blade",
            "hero_azure_arcanist",
            "hero_frenzied_butcher",
            "hero_one_arm_asura",
            "hero_gilded_pactkeeper",
            "hero_void_weaver",
        ], ART / "sprites" / "heroes", 192, pad_ratio=0.06)

    # 4. Enemies (4x2)
    es = find_exact_or_latest("enemies_sheet")
    if es:
        slice_grid_black(es, 4, 2, [
            "enemy_swarmer",
            "enemy_brute",
            "enemy_sprinter",
            "enemy_spitter",
            "enemy_splitter",
            "enemy_bomber",
            "enemy_shielder",
            "enemy_elite_warden",
        ], ART / "sprites" / "enemies", 160, pad_ratio=0.06)

    # 5. Bosses (2x1)
    bs = find_exact_or_latest("bosses_sheet")
    if bs:
        slice_grid_black(bs, 2, 1, ["boss_inquisitor", "boss_sovereign"], ART / "sprites" / "enemies", 256, pad_ratio=0.05)

    # 6. Weapons (5x3)
    ws = find_exact_or_latest("weapons_sheet")
    if ws:
        slice_grid_black(ws, 5, 3, [
            "wpn_chainsaw",
            "wpn_battleaxe",
            "wpn_twin_pistols",
            "wpn_blood_scythe",
            "wpn_blood_spear",
            "wpn_arc_staff",
            "wpn_ice_prism",
            "wpn_laser_wing",
            "wpn_ion_gun",
            "wpn_vibroblade",
            "wpn_bone_spear",
            "wpn_void_grimoire",
            "wpn_abyss_mortar",
            "wpn_calamity_totem",
            "",
        ], ART / "sprites" / "weapons", 160, pad_ratio=0.07)

    # 7. Icons & Pickups from clean white-bg sheet (skip 14px black grid lines at cell boundaries!)
    ips_white = BRAIN_DIR / "icons_pickups_sheet_1795577331165.jpg"
    if ips_white.exists():
        im = Image.open(ips_white).convert("RGBA")
        sw, sh = im.size
        cw, ch = sw / 4.0, sh / 2.0
        pad_px = 14
        targets = [
            (0, 0, ART / "sprites" / "pickups" / "pickup_crystal.png", 96),
            (1, 0, ART / "sprites" / "pickups" / "pickup_heal.png", 96),
            (2, 0, ART / "sprites" / "pickups" / "pickup_chest.png", 128),
            (3, 0, ART / "ui" / "icon_dash.png", 128),
            (0, 1, ART / "ui" / "icon_ember.png", 128),
            (1, 1, ART / "ui" / "icon_sanctuary.png", 128),
            (2, 1, ART / "ui" / "icon_codex.png", 128),
            (3, 1, ART / "ui" / "icon_settings.png", 128),
        ]
        for c, r, dest, sz in targets:
            x0 = int(round(c * cw)) + pad_px
            y0 = int(round(r * ch)) + pad_px
            x1 = int(round((c + 1) * cw)) - pad_px
            y1 = int(round((r + 1) * ch)) - pad_px
            cell = im.crop((x0, y0, x1, y1))
            matted = flood_remove_white_bg(cell, hard_dist=18.0, soft_dist=56.0)
            center_crop_square(matted, sz, pad_ratio=0.06).save(dest)
            print("Saved:", dest)

    # 8. Arena Floor & Altar Sigil (2x1)
    ars = find_exact_or_latest("arena_sheet")
    if ars:
        im = Image.open(ars).convert("RGBA")
        sw, sh = im.size
        # Left half: stone floor tile (crop center square and make softly seamless tile)
        left = im.crop((16, 16, sw // 2 - 20, sh - 16))
        side = min(left.size)
        lx = (left.size[0] - side) // 2
        ly = (left.size[1] - side) // 2
        floor = left.crop((lx, ly, lx + side, ly + side)).resize((384, 384), Image.Resampling.LANCZOS)
        # Subtle darken so bright glowing combat projectiles & pickups pop crisply
        f_arr = (np.array(floor, dtype=np.float32) * np.array([0.78, 0.76, 0.84, 1.0])).clip(0, 255).astype(np.uint8)
        Image.fromarray(f_arr, "RGBA").save(ART / "sprites" / "arena" / "arena_floor_tile.png")
        print("Saved arena_floor_tile.png")

        right = im.crop((sw // 2 + 12, 8, sw - 8, sh - 8))
        rarr = np.array(right, dtype=np.float32)
        rlum = np.max(rarr[..., :3], axis=2)
        ralpha = np.clip((rlum - 18.0) / 145.0, 0.0, 1.0) * 205.0
        rarr[..., 3] = ralpha
        sigil = Image.fromarray(rarr.astype(np.uint8), "RGBA")
        center_crop_square(sigil, 512, pad_ratio=0.04).save(ART / "sprites" / "arena" / "altar_sigil.png")
        print("Saved altar_sigil.png")

    build_items_and_sinks()


if __name__ == "__main__":
    main()
