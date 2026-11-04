"""Draw Blocky's face decals (transparent PNGs, classic Roblox face layout).
usage: python draw_faces.py <out_dir>
"""
import math, os, sys
from PIL import Image, ImageDraw

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
S = 4  # supersample
W = 512 * S
INK = (25, 20, 20, 255)
WHITE = (255, 255, 255, 255)
BLUSH = (255, 120, 110, 110)
TEAR = (90, 170, 255, 230)
MOUTH = (120, 30, 40, 255)
TONGUE = (235, 90, 100, 255)
LW = 14 * S


def p(x, y):
    return (x * S, y * S)


def eye(d, cx, cy, rx=34, ry=44, look=(0, 6), pupil=17, lid=0.0, lid_tilt=0):
    """White oval eye with outline and pupil. lid = fraction covered from the top (sneaky/angry)."""
    box = [p(cx - rx, cy - ry), p(cx + rx, cy + ry)]
    d.ellipse(box, fill=WHITE, outline=INK, width=LW // 2 + 2 * S)
    px, py = cx + look[0], cy + look[1]
    d.ellipse([p(px - pupil, py - pupil), p(px + pupil, py + pupil)], fill=INK)
    d.ellipse([p(px - pupil * 0.35 + 6, py - pupil * 0.6), p(px + pupil * 0.2 + 6, py - pupil * 0.05)], fill=WHITE)
    if lid > 0:
        top = cy - ry - 4
        cut = cy - ry + 2 * ry * lid
        d.polygon([p(cx - rx - 6, top), p(cx + rx + 6, top), p(cx + rx + 6, cut - lid_tilt), p(cx - rx - 6, cut + lid_tilt)],
                  fill=(0, 0, 0, 0))
        d.line([p(cx - rx - 2, cut + lid_tilt), p(cx + rx + 2, cut - lid_tilt)], fill=INK, width=LW)


def brow(d, x1, y1, x2, y2):
    d.line([p(x1, y1), p(x2, y2)], fill=INK, width=LW + 2 * S)
    for x, y in ((x1, y1), (x2, y2)):
        d.ellipse([p(x - 8, y - 8), p(x + 8, y + 8)], fill=INK)


def arc_mouth(d, cx, cy, w, h, up=True):
    box = [p(cx - w, cy - h), p(cx + w, cy + h)]
    d.arc(box, 20 if up else 200, 160 if up else 340, fill=INK, width=LW)


def face(name, draw_fn):
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    draw_fn(d)
    # zoom in so the face fills the front of the head, like classic Roblox faces
    img = img.crop((80 * S, 70 * S, 432 * S, 422 * S)).resize((512, 512), Image.LANCZOS)
    img.save(os.path.join(OUT, f"blocky_{name}.png"))


def happy(d):
    eye(d, 186, 220); eye(d, 326, 220)
    brow(d, 150, 152, 220, 146); brow(d, 292, 146, 362, 152)
    d.chord([p(186, 270), p(326, 380)], 0, 180, fill=MOUTH, outline=INK, width=LW)
    d.chord([p(222, 330), p(290, 378)], 0, 180, fill=TONGUE)
    d.ellipse([p(118, 285), p(168, 315)], fill=BLUSH); d.ellipse([p(344, 285), p(394, 315)], fill=BLUSH)


def shocked(d):
    eye(d, 186, 210, rx=40, ry=52, look=(0, 0), pupil=11); eye(d, 326, 210, rx=40, ry=52, look=(0, 0), pupil=11)
    brow(d, 146, 128, 214, 118); brow(d, 298, 118, 366, 128)
    d.ellipse([p(226, 300), p(286, 385)], fill=MOUTH, outline=INK, width=LW)


def scared(d):
    eye(d, 186, 215, rx=38, ry=48, look=(-6, 2), pupil=10); eye(d, 326, 215, rx=38, ry=48, look=(-6, 2), pupil=10)
    brow(d, 150, 140, 214, 122); brow(d, 298, 122, 362, 140)
    pts = [p(196 + i * 12, 335 + (10 if i % 2 else -10)) for i in range(11)]
    d.line(pts, fill=INK, width=LW, joint="curve")
    d.polygon([p(392, 150), p(378, 182), p(406, 182)], fill=TEAR)
    d.ellipse([p(377, 170), p(407, 200)], fill=TEAR)


def sneaky(d):
    eye(d, 186, 225, look=(14, 8), lid=0.45, lid_tilt=-6); eye(d, 326, 225, look=(14, 8), lid=0.45, lid_tilt=6)
    brow(d, 150, 168, 220, 178); brow(d, 292, 178, 362, 168)
    d.arc([p(220, 290), p(330, 350)], 10, 120, fill=INK, width=LW)


def angry(d):
    eye(d, 186, 228, look=(4, 4), lid=0.35, lid_tilt=10); eye(d, 326, 228, look=(-4, 4), lid=0.35, lid_tilt=-10)
    brow(d, 146, 160, 224, 186); brow(d, 288, 186, 366, 160)
    d.rectangle([p(206, 318), p(306, 352)], fill=WHITE, outline=INK, width=LW // 2 + 2 * S)
    for x in (231, 256, 281):
        d.line([p(x, 320), p(x, 350)], fill=INK, width=5 * S)


def sad(d):
    eye(d, 186, 225, look=(0, 10)); eye(d, 326, 225, look=(0, 10))
    brow(d, 150, 160, 214, 144); brow(d, 298, 144, 362, 160)
    arc_mouth(d, 256, 370, 52, 34, up=False)
    for x in (178, 334):
        d.rounded_rectangle([p(x - 9, 272), p(x + 9, 400)], radius=9 * S, fill=TEAR)


def sleep(d):
    # closed eyes (downward arcs), small open snoring mouth
    for cx in (186, 326):
        d.arc([p(cx - 38, 190), p(cx + 38, 250)], 20, 160, fill=INK, width=LW)
    brow(d, 150, 160, 220, 160); brow(d, 292, 160, 362, 160)
    d.ellipse([p(236, 315), p(276, 360)], fill=MOUTH, outline=INK, width=LW)


def laugh(d):
    # squeezed-shut happy eyes (upward arcs) + big open laugh
    for cx in (186, 326):
        d.arc([p(cx - 36, 200), p(cx + 36, 260)], 200, 340, fill=INK, width=LW)
    brow(d, 150, 150, 220, 140); brow(d, 292, 140, 362, 150)
    d.chord([p(176, 262), p(336, 400)], 0, 180, fill=MOUTH, outline=INK, width=LW)
    d.chord([p(222, 340), p(290, 398)], 0, 180, fill=TONGUE)
    d.ellipse([p(118, 285), p(168, 315)], fill=BLUSH); d.ellipse([p(344, 285), p(394, 315)], fill=BLUSH)


for n, f in [("happy", happy), ("shocked", shocked), ("scared", scared), ("sneaky", sneaky), ("angry", angry), ("sad", sad),
             ("sleep", sleep), ("laugh", laugh)]:
    face(n, f)
print("ok")
