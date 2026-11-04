"""Blocky Tales face set v2 (reel 02 on): bigger, bolder cartoon faces that fill the head, original art.
Thick black outlines, big white eyes, mouths with teeth + tongue. Transparent 512 PNGs for a classic-head Decal.
usage: python tools/draw_faces_v2.py <out_dir>        (then upload, ids go in assets/faces/face_ids_v2.json)
"""
import math, os, sys
from PIL import Image, ImageDraw

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
S = 4
W = 512 * S
INK = (22, 16, 16, 255)
WHITE = (255, 255, 255, 255)
MOUTH = (110, 20, 35, 255)
TONGUE = (240, 95, 110, 255)
BLUSH = (255, 110, 100, 120)
TEAR = (95, 185, 255, 235)
SWEAT = (120, 200, 255, 240)
RED = (220, 30, 40, 255)
GOLD = (255, 205, 40, 255)
LW = 13 * S


def p(x, y):
    return (x * S, y * S)


def ell(d, cx, cy, rx, ry, fill=None, outline=INK, w=LW):
    d.ellipse([p(cx - rx, cy - ry), p(cx + rx, cy + ry)], fill=fill, outline=outline, width=w if outline else 0)


def eye(d, cx, cy, rx=54, ry=64, pupil=26, look=(0, 6), shine=True):
    ell(d, cx, cy, rx, ry, fill=WHITE)
    px, py = cx + look[0], cy + look[1]
    if pupil:
        ell(d, px, py, pupil, pupil * 1.12, fill=INK, outline=None)
        if shine:
            ell(d, px + pupil * 0.35, py - pupil * 0.45, pupil * 0.32, pupil * 0.32, fill=WHITE, outline=None)


def lid(d, cx, cy, rx, ry, frac, tilt=0):
    """cover the top `frac` of an eye with skin-coloured nothing (transparent) and draw the lid line."""
    top = cy - ry - 12
    cut = cy - ry + 2 * ry * frac
    d.polygon([p(cx - rx - 10, top), p(cx + rx + 10, top), p(cx + rx + 10, cut - tilt), p(cx - rx - 10, cut + tilt)], fill=(0, 0, 0, 0))
    d.line([p(cx - rx - 4, cut + tilt), p(cx + rx + 4, cut - tilt)], fill=INK, width=LW)


def brow(d, x1, y1, x2, y2, w=1.3):
    d.line([p(x1, y1), p(x2, y2)], fill=INK, width=int(LW * w))
    for x, y in ((x1, y1), (x2, y2)):
        ell(d, x, y, 9 * w, 9 * w, fill=INK, outline=None)


def poly(d, pts, fill=None, outline=INK, w=LW):
    pts = [p(x, y) for x, y in pts]
    if fill:
        d.polygon(pts, fill=fill)
    if outline:
        d.line(pts + [pts[0]], fill=outline, width=w, joint="curve")


def big_mouth(d, cx, top, w, h, teeth_top=True, teeth_bot=False, tongue=True, curve=0.45):
    """D-shaped open mouth: flat-ish top, round bottom. curve = how round the bottom is."""
    pts = []
    for i in range(41):
        a = math.pi * i / 40
        pts.append((cx - w * math.cos(a), top + h * math.sin(a) ** curve * 1.0))
    outline = [(cx - w, top)] + pts + [(cx + w, top)]
    poly(d, outline, fill=MOUTH, outline=None)
    if tongue:
        d.chord([p(cx - w * 0.55, top + h * 0.45), p(cx + w * 0.55, top + h * 1.35)], 180, 360, fill=TONGUE)
    if teeth_top:
        d.rectangle([p(cx - w * 0.92, top), p(cx + w * 0.92, top + h * 0.26)], fill=WHITE)
        for k in range(1, 4):
            x = cx - w * 0.92 + 2 * w * 0.92 * k / 4
            d.line([p(x, top), p(x, top + h * 0.26)], fill=INK, width=4 * S)
    if teeth_bot:
        d.rectangle([p(cx - w * 0.6, top + h * 0.78), p(cx + w * 0.6, top + h * 0.98)], fill=WHITE)
    # clean the outline over everything
    d.line([p(x, y) for x, y in outline] + [p(cx - w, top)], fill=INK, width=LW, joint="curve")


def scream_mouth(d, cx, cy, w, h):
    """tall rounded-rectangle scream: top + bottom teeth rows."""
    box = [p(cx - w, cy - h), p(cx + w, cy + h)]
    d.rounded_rectangle(box, radius=int(w * 0.7 * S), fill=MOUTH)
    d.chord([p(cx - w * 0.7, cy + h * 0.15), p(cx + w * 0.7, cy + h * 1.2)], 180, 360, fill=TONGUE)
    d.rounded_rectangle([p(cx - w * 0.82, cy - h * 0.92), p(cx + w * 0.82, cy - h * 0.55)], radius=8 * S, fill=WHITE)
    d.rounded_rectangle([p(cx - w * 0.7, cy + h * 0.6), p(cx + w * 0.7, cy + h * 0.9)], radius=8 * S, fill=WHITE)
    for k in range(1, 4):
        x = cx - w * 0.82 + 2 * w * 0.82 * k / 4
        d.line([p(x, cy - h * 0.92), p(x, cy - h * 0.55)], fill=INK, width=4 * S)
    d.rounded_rectangle(box, radius=int(w * 0.7 * S), outline=INK, width=LW)


def drop(d, x, y, s=1.0, col=SWEAT):
    poly(d, [(x, y - 26 * s), (x - 14 * s, y), (x + 14 * s, y)], fill=col, outline=None)
    ell(d, x, y + 4 * s, 15 * s, 15 * s, fill=col, outline=INK, w=5 * S)
    d.polygon([p(x - 12 * s, y - 2 * s), p(x, y - 26 * s), p(x + 12 * s, y - 2 * s)], fill=col)
    d.line([p(x - 14 * s, y), p(x, y - 26 * s), p(x + 14 * s, y)], fill=INK, width=5 * S)


def blush(d):
    ell(d, 92, 330, 34, 20, fill=BLUSH, outline=None)
    ell(d, 420, 330, 34, 20, fill=BLUSH, outline=None)


def spiral(d, cx, cy, r):
    pts = []
    for i in range(160):
        a = i / 160 * 3.2 * 2 * math.pi
        rr = r * i / 160
        pts.append(p(cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.line(pts, fill=INK, width=9 * S, joint="curve")


def star(cx, cy, r, n=5, inner=0.45, rot=-90):
    pts = []
    for i in range(n * 2):
        a = math.radians(rot + i * 180 / n)
        rr = r if i % 2 == 0 else r * inner
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return pts


def vein(d, x, y, s=1.0):
    """the cartoon 'angry vein' mark: four curved brackets bulging toward a centre."""
    for qx, qy in ((1, 1), (-1, 1), (-1, -1), (1, -1)):
        cx, cy = x + qx * 34 * s, y + qy * 34 * s
        a0 = math.degrees(math.atan2(-qy, -qx))
        d.arc([p(cx - 26 * s, cy - 26 * s), p(cx + 26 * s, cy + 26 * s)], a0 - 50, a0 + 50, fill=RED, width=int(11 * S * s))


L, R, EY = 168, 344, 215  # eye centres


def happy(d):
    eye(d, L, EY); eye(d, R, EY)
    brow(d, 120, 120, 205, 112); brow(d, 307, 112, 392, 120)
    big_mouth(d, 256, 300, 105, 120)
    blush(d)


def laugh(d):
    for cx, s in ((L, 1), (R, -1)):  # > < squeezed eyes
        d.line([p(cx - 45 * s, EY - 38), p(cx + 30 * s, EY), p(cx - 45 * s, EY + 38)], fill=INK, width=int(LW * 1.3), joint="curve")
    brow(d, 118, 128, 205, 140); brow(d, 307, 140, 394, 128)
    big_mouth(d, 256, 290, 130, 150)
    for x in (80, 432):
        drop(d, x, 270, 0.9, TEAR)
    blush(d)


def scream(d):
    eye(d, L, 195, 58, 70, 13, (0, 0), shine=False); eye(d, R, 195, 58, 70, 13, (0, 0), shine=False)
    brow(d, 112, 96, 200, 70); brow(d, 312, 70, 400, 96)
    scream_mouth(d, 256, 370, 95, 105)
    for x in (70, 442):  # stress lines down the cheeks
        for k in range(3):
            d.line([p(x - 14 + k * 14, 280), p(x - 14 + k * 14, 340)], fill=INK, width=6 * S)


def shocked(d):
    eye(d, L, 205, 62, 74, 12, (0, 0), shine=False); eye(d, R, 205, 62, 74, 12, (0, 0), shine=False)
    brow(d, 110, 100, 200, 84); brow(d, 312, 84, 402, 100)
    ell(d, 256, 380, 40, 55, fill=MOUTH)


def scared(d):
    eye(d, L, 210, 56, 66, 16, (-8, 4)); eye(d, R, 210, 56, 66, 16, (-8, 4))
    brow(d, 118, 140, 205, 104); brow(d, 307, 104, 394, 140)
    pts = [p(170 + i * 17, 372 + (14 if i % 2 else -14)) for i in range(11)]
    d.line(pts, fill=INK, width=LW, joint="curve")
    drop(d, 428, 140, 1.3)


def dizzy(d):
    for cx in (L, R):
        ell(d, cx, EY, 58, 64, fill=WHITE)
        spiral(d, cx, EY, 46)
    d.arc([p(176, 310), p(336, 420)], 200, 340, fill=INK, width=LW)
    # wobbly open mouth with tongue out to the side
    ell(d, 256, 380, 70, 38, fill=MOUTH)
    ell(d, 300, 412, 34, 30, fill=TONGUE)
    d.line([p(300, 390), p(300, 430)], fill=(200, 60, 80, 255), width=4 * S)
    for s in [star(430, 110, 26), star(86, 120, 20)]:
        poly(d, s, fill=GOLD, w=5 * S)


def angry(d):
    eye(d, L, 230, 54, 58, 22, (8, 6)); eye(d, R, 230, 54, 58, 22, (-8, 6))
    lid(d, L, 230, 54, 58, 0.38, 16); lid(d, R, 230, 54, 58, 0.38, -16)
    brow(d, 104, 140, 210, 182, 1.6); brow(d, 302, 182, 408, 140, 1.6)
    d.rounded_rectangle([p(150, 330), p(362, 410)], radius=18 * S, fill=WHITE, outline=INK, width=LW)
    d.line([p(156, 370), p(356, 370)], fill=INK, width=6 * S)
    for x in (203, 256, 309):
        d.line([p(x, 334), p(x, 406)], fill=INK, width=6 * S)
    vein(d, 410, 80, 1.2)


def smug(d):
    eye(d, L, 225, 54, 58, 24, (20, 10)); eye(d, R, 225, 54, 58, 24, (20, 10))
    lid(d, L, 225, 54, 58, 0.5, -4); lid(d, R, 225, 54, 58, 0.5, 4)
    brow(d, 112, 150, 210, 150); brow(d, 302, 120, 400, 104)
    d.arc([p(190, 290), p(360, 380)], 15, 110, fill=INK, width=LW)
    d.line([p(350, 320), p(372, 306)], fill=INK, width=LW)


def creepy(d):
    """unblinking round eyes, pin-prick pupils, a cheek-to-cheek grin with too many teeth."""
    eye(d, L, 200, 52, 52, 8, (0, 0), shine=False); eye(d, R, 200, 52, 52, 8, (0, 0), shine=False)
    top, cx, w, h = 300, 256, 205, 120
    pts = []
    for i in range(41):  # crescent grin
        a = math.pi * i / 40
        pts.append((cx - w * math.cos(a), top - 30 * math.sin(a) + h * math.sin(a)))
    upper = [(cx - w, top)] + [(cx - w * math.cos(math.pi * i / 40), top + 12 * math.sin(math.pi * i / 40)) for i in range(41)]
    shape = upper + pts[::-1]
    poly(d, shape, fill=WHITE, outline=None)
    for k in range(1, 14):  # teeth lines
        x = cx - w + 2 * w * k / 14
        d.line([p(x, top + 4), p(x, top + 95 * math.sin(math.pi * k / 14))], fill=INK, width=4 * S)
    mid = [(cx - w * math.cos(math.pi * i / 40), top + 6 + 46 * math.sin(math.pi * i / 40)) for i in range(41)]
    d.line([p(x, y) for x, y in mid], fill=INK, width=5 * S, joint="curve")
    poly(d, shape, outline=INK)


def cry(d):
    eye(d, L, 215, 56, 64, 30, (0, 8)); eye(d, R, 215, 56, 64, 30, (0, 8))
    brow(d, 118, 150, 205, 120); brow(d, 307, 120, 394, 150)
    for x in (L, R):  # tear rivers
        d.rounded_rectangle([p(x - 16, 270), p(x + 16, 512)], radius=16 * S, fill=TEAR)
    d.chord([p(186, 330), p(326, 460)], 180, 360, fill=MOUTH, outline=INK, width=LW)


def starry(d):
    for cx in (L, R):
        ell(d, cx, EY, 56, 64, fill=WHITE)
        poly(d, star(cx, EY + 4, 44), fill=GOLD, w=7 * S)
        ell(d, cx + 14, EY - 18, 8, 8, fill=WHITE, outline=None)
    brow(d, 120, 118, 205, 108); brow(d, 307, 108, 392, 118)
    big_mouth(d, 256, 300, 110, 125)
    blush(d)


def focus(d):
    """drawing for dear life: squint, tongue poking out, sweat."""
    eye(d, L, 230, 52, 50, 22, (6, 4)); eye(d, R, 230, 52, 50, 22, (6, 4))
    lid(d, L, 230, 52, 50, 0.42, 10); lid(d, R, 230, 52, 50, 0.42, -10)
    brow(d, 108, 150, 210, 176, 1.5); brow(d, 302, 176, 404, 150, 1.5)
    d.line([p(190, 360), p(330, 350)], fill=INK, width=LW)
    ell(d, 318, 380, 26, 30, fill=TONGUE, outline=INK, w=6 * S)
    d.line([p(296, 352), p(342, 352)], fill=INK, width=LW)
    drop(d, 428, 150, 1.3); drop(d, 92, 175, 0.9)


def nervous(d):
    eye(d, L, 215, 54, 62, 22, (22, 0)); eye(d, R, 215, 54, 62, 22, (22, 0))
    brow(d, 118, 140, 205, 124); brow(d, 307, 124, 394, 140)
    pts = [p(180 + i * 19, 365 + 9 * math.sin(i * 1.6)) for i in range(9)]
    d.line(pts, fill=INK, width=LW, joint="curve")
    drop(d, 425, 150, 1.4); drop(d, 448, 225, 0.9)


def wow(d):
    for cx in (L, R):
        ell(d, cx, EY, 58, 68, fill=WHITE)
        ell(d, cx, EY + 6, 38, 44, fill=INK, outline=None)
        ell(d, cx + 14, EY - 10, 13, 13, fill=WHITE, outline=None)
        ell(d, cx - 14, EY + 22, 7, 7, fill=WHITE, outline=None)
    brow(d, 112, 106, 205, 96); brow(d, 307, 96, 400, 106)
    big_mouth(d, 256, 320, 70, 100, teeth_top=False, curve=0.7)
    blush(d)


def sad(d):
    eye(d, L, 225, 52, 60, 26, (0, 12)); eye(d, R, 225, 52, 60, 26, (0, 12))
    brow(d, 118, 160, 205, 130); brow(d, 307, 130, 394, 160)
    d.arc([p(186, 360), p(326, 440)], 200, 340, fill=INK, width=LW)
    drop(d, 120, 300, 0.9, TEAR)


def crayon(d):
    """simple kid-drawing face for drawn creatures (stick dad, sun): dot eyes + a big wobbly smile."""
    for cx in (190, 322):
        ell(d, cx, 210, 30, 34, fill=INK, outline=None)
        ell(d, cx + 9, 199, 9, 9, fill=WHITE, outline=None)
    pts = [p(140 + i * 23.2, 330 + 70 * math.sin(math.pi * i / 10) + (4 if i % 2 else -4)) for i in range(11)]
    d.line(pts, fill=INK, width=int(LW * 1.3), joint="curve")


FACES = {"happy": happy, "laugh": laugh, "scream": scream, "shocked": shocked, "scared": scared, "dizzy": dizzy, "angry": angry,
         "smug": smug, "creepy": creepy, "cry": cry, "starry": starry, "focus": focus, "nervous": nervous, "wow": wow, "sad": sad,
         "crayon": crayon}

if __name__ == "__main__":
    for n, f in FACES.items():
        img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        f(ImageDraw.Draw(img))
        img.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, f"v2_{n}.png"))
    print("ok", len(FACES))
