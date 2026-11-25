"""
Procedural high-craft 2D art generator for Pact Arena (血契竞技场).
Generates supersampled, anti-aliased sprites, icons, floor tiles, and VFX textures
using Pillow and NumPy. Run via: python tools/generate_art.py
"""
import math
import os
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "assets" / "art"


def ensure_dirs():
    for sub in [
        "sprites/heroes",
        "sprites/enemies",
        "sprites/weapons",
        "sprites/projectiles",
        "sprites/pickups",
        "sprites/arena",
        "ui",
    ]:
        (ART / sub).mkdir(parents=True, exist_ok=True)


def make_canvas(size: int, ss: int = 4) -> tuple[Image.Image, ImageDraw.ImageDraw, int]:
    s = size * ss
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    return img, draw, s


def add_outer_glow(img: Image.Image, glow_color: tuple[int, int, int], radius: int = 12, strength: float = 0.9) -> Image.Image:
    alpha = img.split()[3]
    glow = Image.new("RGBA", img.size, (*glow_color, 0))
    glow.putalpha(alpha.point(lambda a: min(255, int(a * strength))))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=radius))
    return Image.alpha_composite(glow, img)


def finalize(img: Image.Image, target_size: int, glow_color=None, glow_radius: int = 14) -> Image.Image:
    if glow_color is not None:
        img = add_outer_glow(img, glow_color, radius=glow_radius, strength=0.85)
    return img.resize((target_size, target_size), Image.Resampling.LANCZOS)


def draw_poly_ring(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, sides: int, rot_deg: float, fill, outline=None, width: int = 4):
    pts = []
    for i in range(sides):
        ang = math.radians(rot_deg + i * (360.0 / sides))
        pts.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
    draw.polygon(pts, fill=fill, outline=outline, width=width)


def draw_star(draw: ImageDraw.ImageDraw, cx: float, cy: float, r_outer: float, r_inner: float, points: int, rot_deg: float, fill, outline=None, width: int = 4):
    pts = []
    for i in range(points * 2):
        r = r_outer if i % 2 == 0 else r_inner
        ang = math.radians(rot_deg + i * (180.0 / points))
        pts.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
    draw.polygon(pts, fill=fill, outline=outline, width=width)


# ---------------- HEROES ----------------
def gen_heroes():
    out = ART / "sprites" / "heroes"

    # 1. Crimson Blade
    img, d, s = make_canvas(128)
    c = s / 2
    # Flowing twin crimson scarf tails
    d.polygon([(c - 10, c + 20), (c - 150, c + 140), (c - 90, c + 170), (c + 10, c + 40)], fill=(190, 22, 65, 230))
    d.polygon([(c + 10, c + 20), (c + 150, c + 135), (c + 95, c + 172), (c - 10, c + 40)], fill=(235, 45, 90, 235))
    # Armored cloak body
    draw_poly_ring(d, c, c + 10, 118, 6, -90, (42, 16, 36, 255), (255, 65, 108, 255), 10)
    # Hood & sharp visor
    d.ellipse((c - 78, c - 98, c + 78, c + 55), fill=(26, 12, 28, 255), outline=(255, 80, 120, 255), width=8)
    d.polygon([(c - 58, c - 36), (c + 58, c - 36), (c + 40, c + 8), (c - 40, c + 8)], fill=(12, 6, 16, 255))
    # Glowing ruby eyes
    d.polygon([(c - 42, c - 24), (c - 10, c - 12), (c - 32, c - 4)], fill=(255, 220, 120, 255))
    d.polygon([(c + 42, c - 24), (c + 10, c - 12), (c + 32, c - 4)], fill=(255, 220, 120, 255))
    finalize(img, 128, (255, 45, 95), 14).save(out / "hero_crimson_blade.png")

    # 2. Azure Arcanist
    img, d, s = make_canvas(128)
    c = s / 2
    # Rune halo ring
    d.ellipse((c - 165, c - 165, c + 165, c + 165), outline=(56, 189, 248, 210), width=10)
    for k in range(6):
        ang = math.radians(k * 60)
        rx, ry = c + math.cos(ang) * 165, c + math.sin(ang) * 165
        d.ellipse((rx - 14, ry - 14, rx + 14, ry + 14), fill=(186, 230, 253, 255))
    # Robe + pointed mystic hat
    d.polygon([(c, c - 170), (c - 110, c + 115), (c + 110, c + 115)], fill=(17, 36, 68, 255), outline=(56, 189, 248, 255), width=10)
    d.ellipse((c - 70, c - 50, c + 70, c + 75), fill=(10, 20, 42, 255), outline=(125, 211, 252, 255), width=8)
    d.ellipse((c - 32, c - 14, c - 10, c + 8), fill=(125, 245, 255, 255))
    d.ellipse((c + 10, c - 14, c + 32, c + 8), fill=(125, 245, 255, 255))
    finalize(img, 128, (56, 189, 248), 16).save(out / "hero_azure_arcanist.png")

    # 3. Frenzied Butcher
    img, d, s = make_canvas(128)
    c = s / 2
    # Twin curved horns
    d.polygon([(c - 75, c - 50), (c - 165, c - 160), (c - 125, c - 10)], fill=(220, 210, 195, 255), outline=(140, 20, 35, 255), width=8)
    d.polygon([(c + 75, c - 50), (c + 165, c - 160), (c + 125, c - 10)], fill=(220, 210, 195, 255), outline=(140, 20, 35, 255), width=8)
    # Hulking shoulder plate octagon
    draw_poly_ring(d, c, c + 12, 138, 8, 22.5, (72, 18, 26, 255), (244, 63, 94, 255), 12)
    # Glowing furnace chest crack + fierce eyes
    draw_star(d, c, c + 32, 65, 20, 4, 45, (255, 115, 35, 255))
    d.polygon([(c - 52, c - 46), (c - 12, c - 26), (c - 48, c - 16)], fill=(255, 235, 90, 255))
    d.polygon([(c + 52, c - 46), (c + 12, c - 26), (c + 48, c - 16)], fill=(255, 235, 90, 255))
    finalize(img, 128, (249, 115, 22), 14).save(out / "hero_frenzied_butcher.png")

    # 4. One-Arm Asura
    img, d, s = make_canvas(128)
    c = s / 2
    # Blazing golden giant shoulder/arm aura on right
    draw_star(d, c + 65, c + 10, 135, 60, 6, 15, (255, 175, 40, 170))
    # Oni mask silhouette
    draw_poly_ring(d, c - 10, c, 115, 6, 30, (34, 14, 24, 255), (251, 191, 36, 255), 10)
    # Crimson scarf slash & single glowing eye
    d.polygon([(c - 95, c + 25), (c + 85, c - 40), (c + 75, c + 20), (c - 85, c + 70)], fill=(225, 29, 72, 235))
    d.ellipse((c - 44, c - 36, c - 10, c - 4), fill=(254, 240, 138, 255))
    d.line([(c + 8, c - 45), (c + 45, c + 8)], fill=(255, 80, 100, 255), width=12)
    finalize(img, 128, (251, 191, 36), 14).save(out / "hero_one_arm_asura.png")

    # 5. Gilded Pactkeeper
    img, d, s = make_canvas(128)
    c = s / 2
    # Floating golden coin halos
    for ang_deg in (-55, 55, 180):
        ang = math.radians(ang_deg - 90)
        gx, gy = c + math.cos(ang) * 150, c + math.sin(ang) * 150
        d.ellipse((gx - 28, gy - 28, gx + 28, gy + 28), fill=(250, 204, 21, 255), outline=(255, 248, 180, 255), width=6)
        d.rectangle((gx - 8, gy - 8, gx + 8, gy + 8), fill=(40, 22, 5, 255))
    # Crowned noble armor
    draw_poly_ring(d, c, c + 12, 115, 4, 45, (46, 32, 12, 255), (250, 204, 21, 255), 12)
    d.polygon([(c - 65, c - 65), (c - 40, c - 135), (c, c - 90), (c + 40, c - 135), (c + 65, c - 65)], fill=(250, 204, 21, 255))
    d.ellipse((c - 30, c - 20, c + 30, c + 40), fill=(192, 132, 252, 255), outline=(255, 255, 255, 255), width=6)
    finalize(img, 128, (250, 204, 21), 14).save(out / "hero_gilded_pactkeeper.png")

    # 6. Void Weaver
    img, d, s = make_canvas(128)
    c = s / 2
    # 4 cosmic tentacles / sigil blades
    for k in range(4):
        ang = math.radians(45 + k * 90)
        tx, ty = c + math.cos(ang) * 165, c + math.sin(ang) * 165
        d.polygon([(c, c), (tx - 24, ty), (tx, ty + 24)], fill=(126, 34, 206, 220))
    draw_poly_ring(d, c, c, 118, 5, -90, (24, 10, 44, 255), (192, 132, 252, 255), 10)
    # Triple void eyes
    for ex, ey, er in [(c - 36, c + 6, 18), (c + 36, c + 6, 18), (c, c - 34, 22)]:
        d.ellipse((ex - er, ey - er, ex + er, ey + er), fill=(240, 171, 252, 255))
        d.ellipse((ex - er * 0.4, ey - er * 0.4, ex + er * 0.4, ey + er * 0.4), fill=(20, 6, 36, 255))
    finalize(img, 128, (168, 85, 247), 16).save(out / "hero_void_weaver.png")


# ---------------- ENEMIES & BOSSES ----------------
def gen_enemies():
    out = ART / "sprites" / "enemies"

    # 1. Swarmer
    img, d, s = make_canvas(96)
    c = s / 2
    draw_poly_ring(d, c, c, 95, 3, -90, (90, 20, 60, 255), (244, 114, 182, 255), 10)
    d.polygon([(c - 50, c - 60), (c - 105, c - 125), (c - 20, c - 85)], fill=(251, 113, 133, 255))
    d.polygon([(c + 50, c - 60), (c + 105, c - 125), (c + 20, c - 85)], fill=(251, 113, 133, 255))
    d.ellipse((c - 34, c - 24, c - 10, c), fill=(255, 240, 150, 255))
    d.ellipse((c + 10, c - 24, c + 34, c), fill=(255, 240, 150, 255))
    finalize(img, 96, (244, 63, 94), 10).save(out / "enemy_swarmer.png")

    # 2. Brute
    img, d, s = make_canvas(128)
    c = s / 2
    draw_poly_ring(d, c, c, 150, 8, 22.5, (52, 58, 72, 255), (251, 146, 60, 255), 14)
    d.rectangle((c - 64, c - 50, c + 64, c + 60), fill=(30, 34, 44, 255), outline=(148, 163, 184, 255), width=8)
    d.ellipse((c - 32, c - 10, c + 32, c + 44), fill=(249, 115, 22, 255))
    d.rectangle((c - 48, c - 38, c - 14, c - 20), fill=(253, 224, 71, 255))
    d.rectangle((c + 14, c - 38, c + 48, c - 20), fill=(253, 224, 71, 255))
    finalize(img, 128, (249, 115, 22), 12).save(out / "enemy_brute.png")

    # 3. Sprinter
    img, d, s = make_canvas(96)
    c = s / 2
    d.polygon([(c, c - 135), (c + 115, c + 95), (c, c + 35), (c - 115, c + 95)], fill=(159, 18, 57, 255), outline=(255, 90, 120, 255), width=10)
    d.polygon([(c, c - 85), (c + 26, c + 10), (c - 26, c + 10)], fill=(254, 240, 138, 255))
    finalize(img, 96, (255, 60, 95), 12).save(out / "enemy_sprinter.png")

    # 4. Spitter
    img, d, s = make_canvas(112)
    c = s / 2
    d.ellipse((c - 125, c - 105, c + 125, c + 115), fill=(74, 20, 96, 255), outline=(217, 70, 239, 255), width=12)
    d.ellipse((c - 58, c - 58, c + 58, c + 58), fill=(240, 171, 252, 255))
    d.ellipse((c - 24, c - 24, c + 24, c + 24), fill=(32, 6, 48, 255))
    finalize(img, 112, (217, 70, 239), 12).save(out / "enemy_spitter.png")

    # 5. Splitter
    img, d, s = make_canvas(112)
    c = s / 2
    d.ellipse((c - 140, c - 100, c + 30, c + 100), fill=(18, 92, 68, 230), outline=(52, 211, 153, 255), width=10)
    d.ellipse((c - 30, c - 100, c + 140, c + 100), fill=(18, 92, 68, 230), outline=(52, 211, 153, 255), width=10)
    d.ellipse((c - 80, c - 30, c - 25, c + 25), fill=(167, 243, 208, 255))
    d.ellipse((c + 25, c - 30, c + 80, c + 25), fill=(167, 243, 208, 255))
    finalize(img, 112, (52, 211, 153), 12).save(out / "enemy_splitter.png")

    # 6. Bomber
    img, d, s = make_canvas(112)
    c = s / 2
    draw_star(d, c, c, 155, 88, 8, 0, (124, 45, 18, 255), (251, 146, 60, 255), 10)
    d.ellipse((c - 64, c - 64, c + 64, c + 64), fill=(254, 215, 170, 255), outline=(239, 68, 68, 255), width=12)
    d.ellipse((c - 24, c - 24, c + 24, c + 24), fill=(255, 255, 255, 255))
    finalize(img, 112, (249, 115, 22), 14).save(out / "enemy_bomber.png")

    # 7. Shielder
    img, d, s = make_canvas(112)
    c = s / 2
    draw_poly_ring(d, c, c + 12, 115, 6, 0, (30, 41, 59, 255), (56, 189, 248, 255), 10)
    # Front energy arc shield
    d.arc((c - 155, c - 155, c + 155, c + 155), start=205, end=335, fill=(34, 211, 238, 255), width=26)
    d.rectangle((c - 40, c - 22, c + 40, c + 8), fill=(125, 245, 255, 255))
    finalize(img, 112, (34, 211, 238), 12).save(out / "enemy_shielder.png")

    # 8. Elite Warden
    img, d, s = make_canvas(144)
    c = s / 2
    draw_star(d, c, c, 195, 115, 8, 22.5, (44, 24, 10, 255), (250, 204, 21, 255), 12)
    draw_poly_ring(d, c, c, 110, 4, 45, (127, 29, 29, 255), (253, 224, 71, 255), 12)
    d.polygon([(c - 50, c - 110), (c - 25, c - 175), (c, c - 130), (c + 25, c - 175), (c + 50, c - 110)], fill=(250, 204, 21, 255))
    d.ellipse((c - 30, c - 30, c + 30, c + 30), fill=(255, 255, 255, 255))
    finalize(img, 144, (250, 204, 21), 16).save(out / "enemy_elite_warden.png")

    # Boss 1: Crimson Inquisitor (256x256)
    img, d, s = make_canvas(256, ss=2)
    c = s / 2
    # Outer rotating blood halo
    d.ellipse((c - 210, c - 210, c + 210, c + 210), outline=(225, 29, 72, 200), width=10)
    draw_star(d, c, c, 220, 140, 12, 0, (48, 10, 24, 245), (255, 70, 110, 255), 8)
    # Twin side scythe horns
    d.polygon([(c - 110, c - 40), (c - 225, c - 180), (c - 155, c + 65)], fill=(244, 63, 94, 255), outline=(255, 220, 230, 255), width=6)
    d.polygon([(c + 110, c - 40), (c + 225, c - 180), (c + 155, c + 65)], fill=(244, 63, 94, 255), outline=(255, 220, 230, 255), width=6)
    draw_poly_ring(d, c, c, 115, 6, 30, (24, 8, 16, 255), (253, 224, 71, 255), 8)
    d.ellipse((c - 44, c - 44, c + 44, c + 44), fill=(255, 45, 85, 255), outline=(255, 255, 255, 255), width=6)
    finalize(img, 256, (255, 40, 90), 18).save(out / "boss_inquisitor.png")

    # Boss 2: Twin Abyss Sovereign (256x256)
    img, d, s = make_canvas(256, ss=2)
    c = s / 2
    draw_star(d, c, c, 230, 120, 8, 22.5, (30, 10, 56, 245), (192, 132, 252, 255), 8)
    # Wing blades
    d.polygon([(c - 80, c), (c - 235, c - 110), (c - 185, c + 120)], fill=(147, 51, 234, 230), outline=(232, 121, 249, 255), width=6)
    d.polygon([(c + 80, c), (c + 235, c - 110), (c + 185, c + 120)], fill=(225, 29, 72, 230), outline=(251, 113, 133, 255), width=6)
    # Interlocking twin cores
    d.ellipse((c - 105, c - 65, c + 25, c + 65), fill=(225, 29, 72, 240), outline=(255, 255, 255, 255), width=6)
    d.ellipse((c - 25, c - 65, c + 105, c + 65), fill=(126, 34, 206, 240), outline=(255, 255, 255, 255), width=6)
    d.ellipse((c - 24, c - 24, c + 24, c + 24), fill=(254, 240, 138, 255))
    finalize(img, 256, (192, 132, 252), 20).save(out / "boss_sovereign.png")


# ---------------- 14 WEAPONS ----------------
def gen_weapons():
    out = ART / "sprites" / "weapons"

    def w_canvas(glow):
        img, d, s = make_canvas(128)
        return img, d, s, glow

    # 1. Chainsaw (Crimson)
    img, d, s, g = w_canvas((244, 63, 94))
    d.rounded_rectangle((70, 195, 455, 295), radius=24, fill=(148, 24, 52, 255), outline=(255, 110, 140, 255), width=10)
    for x in range(150, 445, 42):
        d.polygon([(x, 195), (x + 18, 160), (x + 36, 195)], fill=(226, 232, 240, 255))
        d.polygon([(x, 295), (x + 18, 330), (x + 36, 295)], fill=(226, 232, 240, 255))
    d.rectangle((50, 215, 145, 295), fill=(30, 41, 59, 255), outline=(244, 63, 94, 255), width=8)
    finalize(img, 128, g, 12).save(out / "wpn_chainsaw.png")

    # 2. Crimson Battleaxe
    img, d, s, g = w_canvas((244, 63, 94))
    d.line([(95, 420), (415, 100)], fill=(120, 53, 60, 255), width=26)
    d.polygon([(260, 115), (435, 70), (465, 245), (340, 245)], fill=(225, 29, 72, 255), outline=(255, 210, 220, 255), width=10)
    finalize(img, 128, g, 12).save(out / "wpn_battleaxe.png")

    # 3. Twin Pistols
    img, d, s, g = w_canvas((251, 113, 133))
    for dy in (-75, 75):
        d.rectangle((140, 220 + dy, 380, 275 + dy), fill=(51, 65, 85, 255), outline=(251, 113, 133, 255), width=8)
        d.polygon([(140, 275 + dy), (195, 275 + dy), (170, 345 + dy), (115, 345 + dy)], fill=(159, 18, 57, 255))
        d.ellipse((370, 228 + dy, 415, 268 + dy), fill=(254, 240, 138, 255))
    finalize(img, 128, g, 12).save(out / "wpn_twin_pistols.png")

    # 4. Blood Scythe
    img, d, s, g = w_canvas((225, 29, 72))
    d.line([(120, 415), (370, 120)], fill=(71, 85, 105, 255), width=20)
    d.polygon([(140, 80), (430, 90), (410, 260), (320, 165)], fill=(225, 29, 72, 255), outline=(255, 220, 225, 255), width=10)
    finalize(img, 128, g, 12).save(out / "wpn_blood_scythe.png")

    # 5. Sacrificial Spear
    img, d, s, g = w_canvas((244, 63, 94))
    d.line([(65, 445), (340, 170)], fill=(100, 30, 50, 255), width=18)
    d.polygon([(460, 52), (380, 210), (305, 135)], fill=(255, 70, 105, 255), outline=(255, 235, 235, 255), width=10)
    finalize(img, 128, g, 12).save(out / "wpn_blood_spear.png")

    # 6. Arc Staff (Azure)
    img, d, s, g = w_canvas((56, 189, 248))
    d.line([(110, 420), (360, 165)], fill=(30, 58, 138, 255), width=20)
    draw_star(d, 375, 135, 90, 36, 4, 45, (125, 245, 255, 255), (255, 255, 255, 255), 8)
    finalize(img, 128, g, 14).save(out / "wpn_arc_staff.png")

    # 7. Ice Prism
    img, d, s, g = w_canvas((34, 211, 238))
    d.polygon([(256, 55), (390, 220), (256, 455), (122, 220)], fill=(56, 189, 248, 225), outline=(224, 242, 254, 255), width=12)
    d.polygon([(256, 125), (330, 225), (256, 375), (182, 225)], fill=(186, 230, 253, 255))
    finalize(img, 128, g, 14).save(out / "wpn_ice_prism.png")

    # 8. Laser Wing
    img, d, s, g = w_canvas((56, 189, 248))
    d.polygon([(95, 256), (340, 110), (425, 165), (250, 256), (425, 347), (340, 402)], fill=(14, 116, 144, 255), outline=(103, 232, 249, 255), width=10)
    d.ellipse((230, 220, 310, 292), fill=(224, 242, 254, 255))
    finalize(img, 128, g, 14).save(out / "wpn_laser_wing.png")

    # 9. Ricochet Ion Gun
    img, d, s, g = w_canvas((59, 130, 246))
    d.rounded_rectangle((110, 175, 420, 285), radius=28, fill=(30, 64, 175, 255), outline=(147, 197, 253, 255), width=10)
    d.polygon([(125, 285), (205, 285), (175, 390), (105, 390)], fill=(15, 23, 42, 255), outline=(96, 165, 250, 255), width=8)
    d.ellipse((355, 195, 435, 265), fill=(186, 230, 253, 255))
    finalize(img, 128, g, 12).save(out / "wpn_ion_gun.png")

    # 10. High-Freq Vibroblade
    img, d, s, g = w_canvas((103, 232, 249))
    d.polygon([(95, 415), (430, 80), (445, 135), (150, 430)], fill=(224, 242, 254, 255), outline=(34, 211, 238, 255), width=10)
    d.line([(85, 345), (175, 435)], fill=(15, 23, 42, 255), width=22)
    finalize(img, 128, g, 14).save(out / "wpn_vibroblade.png")

    # 11. Bone Spear (Void)
    img, d, s, g = w_canvas((168, 85, 247))
    d.line([(85, 425), (345, 165)], fill=(168, 85, 247, 255), width=18)
    d.polygon([(450, 62), (370, 220), (320, 180), (290, 140)], fill=(243, 232, 255, 255), outline=(192, 132, 252, 255), width=10)
    finalize(img, 128, g, 14).save(out / "wpn_bone_spear.png")

    # 12. Void Grimoire
    img, d, s, g = w_canvas((192, 132, 252))
    d.rounded_rectangle((110, 95, 402, 415), radius=20, fill=(59, 7, 100, 255), outline=(216, 180, 254, 255), width=12)
    d.line([(160, 95), (160, 415)], fill=(216, 180, 254, 255), width=8)
    d.ellipse((230, 210, 330, 300), fill=(240, 171, 252, 255))
    d.ellipse((265, 230, 295, 280), fill=(24, 8, 42, 255))
    finalize(img, 128, g, 14).save(out / "wpn_void_grimoire.png")

    # 13. Abyssal Mortar
    img, d, s, g = w_canvas((147, 51, 234))
    d.polygon([(110, 345), (315, 95), (415, 180), (210, 410)], fill=(46, 16, 101, 255), outline=(192, 132, 252, 255), width=12)
    d.ellipse((295, 85, 430, 210), fill=(240, 171, 252, 255))
    finalize(img, 128, g, 14).save(out / "wpn_abyss_mortar.png")

    # 14. Calamity Totem
    img, d, s, g = w_canvas((168, 85, 247))
    d.polygon([(170, 430), (342, 430), (310, 110), (202, 110)], fill=(59, 7, 100, 255), outline=(216, 180, 254, 255), width=12)
    draw_star(d, 256, 165, 65, 28, 4, 0, (240, 171, 252, 255))
    d.rectangle((210, 275, 302, 315), fill=(192, 132, 252, 255))
    finalize(img, 128, g, 14).save(out / "wpn_calamity_totem.png")


# ---------------- PROJECTILES / PICKUPS / ARENA / UI ----------------
def gen_misc():
    # Projectiles
    pout = ART / "sprites" / "projectiles"
    for name, col in [
        ("proj_crimson", (255, 68, 108)),
        ("proj_azure", (56, 189, 248)),
        ("proj_void", (192, 132, 252)),
        ("proj_enemy", (251, 146, 60)),
    ]:
        img, d, s = make_canvas(64)
        c = s / 2
        d.ellipse((c - 58, c - 36, c + 78, c + 36), fill=(*col, 255))
        d.ellipse((c - 22, c - 20, c + 55, c + 20), fill=(255, 255, 255, 245))
        finalize(img, 64, col, 14).save(pout / f"{name}.png")

    # Slash arc
    img, d, s = make_canvas(128)
    c = s / 2
    d.arc((40, 40, s - 40, s - 40), start=-60, end=60, fill=(255, 255, 255, 250), width=52)
    d.arc((52, 52, s - 52, s - 52), start=-50, end=50, fill=(255, 110, 140, 220), width=26)
    finalize(img, 128, (255, 70, 110), 14).save(pout / "slash_arc.png")

    # Soft radial glow (for hit flashes, singularities, telegraph circles)
    glow = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    arr = np.zeros((128, 128, 4), dtype=np.uint8)
    yy, xx = np.mgrid[0:128, 0:128]
    dist = np.sqrt((xx - 63.5) ** 2 + (yy - 63.5) ** 2) / 63.5
    alpha = np.clip((1.0 - dist), 0.0, 1.0) ** 2.2
    arr[..., 0] = 255
    arr[..., 1] = 255
    arr[..., 2] = 255
    arr[..., 3] = (alpha * 255).astype(np.uint8)
    Image.fromarray(arr, "RGBA").save(pout / "glow_soft.png")

    # Pickups
    kout = ART / "sprites" / "pickups"
    # Crystal
    img, d, s = make_canvas(64)
    c = s / 2
    d.polygon([(c, 35), (c + 64, c), (c, s - 35), (c - 64, c)], fill=(244, 63, 94, 255), outline=(255, 220, 230, 255), width=10)
    d.polygon([(c, 65), (c + 30, c), (c, s - 65), (c - 30, c)], fill=(255, 180, 200, 255))
    finalize(img, 64, (244, 63, 94), 10).save(kout / "pickup_crystal.png")

    # Heal orb
    img, d, s = make_canvas(64)
    c = s / 2
    d.ellipse((c - 75, c - 75, c + 75, c + 75), fill=(16, 185, 129, 255), outline=(167, 243, 208, 255), width=10)
    d.rectangle((c - 18, c - 48, c + 18, c + 48), fill=(255, 255, 255, 255))
    d.rectangle((c - 48, c - 18, c + 48, c + 18), fill=(255, 255, 255, 255))
    finalize(img, 64, (16, 185, 129), 10).save(kout / "pickup_heal.png")

    # Chest
    img, d, s = make_canvas(96)
    d.rounded_rectangle((65, 120, s - 65, s - 75), radius=24, fill=(146, 64, 14, 255), outline=(250, 204, 21, 255), width=14)
    d.line([(65, s * 0.5), (s - 65, s * 0.5)], fill=(250, 204, 21, 255), width=14)
    d.rectangle((s * 0.5 - 22, s * 0.5 - 28, s * 0.5 + 22, s * 0.5 + 28), fill=(254, 240, 138, 255))
    finalize(img, 96, (250, 204, 21), 12).save(kout / "pickup_chest.png")

    # Arena floor tile (256x256 dark basalt rune grid)
    aout = ART / "sprites" / "arena"
    tile = Image.new("RGBA", (256, 256), (18, 15, 28, 255))
    td = ImageDraw.Draw(tile, "RGBA")
    for x in range(0, 256, 64):
        td.line([(x, 0), (x, 256)], fill=(45, 36, 68, 90), width=1)
    for y in range(0, 256, 64):
        td.line([(0, y), (256, y)], fill=(45, 36, 68, 90), width=1)
    td.rectangle((0, 0, 255, 255), outline=(65, 44, 96, 130), width=2)
    td.ellipse((124, 124, 132, 132), fill=(110, 52, 95, 110))
    tile.save(aout / "arena_floor_tile.png")

    # Center Blood Pact Altar Sigil (512x512)
    sigil = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sigil, "RGBA")
    sd.ellipse((32, 32, 480, 480), outline=(225, 29, 72, 95), width=5)
    sd.ellipse((68, 68, 444, 444), outline=(147, 51, 234, 85), width=4)
    draw_star(sd, 256, 256, 205, 85, 6, 0, (0, 0, 0, 0), (225, 29, 72, 90), 4)
    draw_poly_ring(sd, 256, 256, 135, 3, -90, (0, 0, 0, 0), (56, 189, 248, 80), 4)
    sigil.save(aout / "altar_sigil.png")

    # UI Icons & Android Launcher Icons
    uout = ART / "ui"
    for name, col, shape in [
        ("faction_crimson", (244, 63, 94), 3),
        ("faction_azure", (56, 189, 248), 4),
        ("faction_void", (192, 132, 252), 6),
    ]:
        img, d, s = make_canvas(64)
        c = s / 2
        draw_poly_ring(d, c, c, 90, shape, -90, (*col, 255), (255, 255, 255, 230), 10)
        finalize(img, 64, col, 10).save(uout / f"{name}.png")

    # Dash Icon
    img, d, s = make_canvas(64)
    d.polygon([(55, 145), (145, 128), (110, 70), (205, 128), (110, 186), (145, 128)], fill=(255, 220, 140, 255))
    d.polygon([(45, 70), (165, 128), (45, 186), (85, 128)], fill=(244, 63, 94, 255), outline=(255, 255, 255, 230), width=8)
    finalize(img, 64, (244, 63, 94), 8).save(uout / "icon_dash.png")

    # App Launcher Icon 192x192
    img, d, s = make_canvas(192, ss=2)
    c = s / 2
    d.rounded_rectangle((12, 12, s - 12, s - 12), radius=76, fill=(14, 10, 24, 255), outline=(225, 29, 72, 255), width=12)
    d.ellipse((c - 132, c - 132, c + 132, c + 132), outline=(56, 189, 248, 200), width=8)
    draw_star(d, c, c, 148, 52, 4, 0, (244, 63, 94, 255), (255, 235, 180, 255), 8)
    d.ellipse((c - 30, c - 30, c + 30, c + 30), fill=(24, 10, 36, 255), outline=(250, 204, 21, 255), width=8)
    finalize(img, 192, (225, 29, 72), 14).save(uout / "launcher_192.png")


if __name__ == "__main__":
    ensure_dirs()
    gen_heroes()
    gen_enemies()
    gen_weapons()
    gen_misc()
    print("All art assets generated successfully in", ART)
