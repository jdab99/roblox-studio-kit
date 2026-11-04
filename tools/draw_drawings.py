"""Kids' crayon drawings for reel 02 "The Scribble" (the paper props). Original art, deliberately childlike.
usage: python tools/draw_drawings.py <out_dir>  -> paper_<name>.png (512x512, paper colour baked in)
"""
import math, os, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont
FONT = ImageFont.truetype(r"C:\Windows\Fonts\comicbd.ttf", 40)

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
N = 512
PAPER = (250, 248, 238)
rng = random.Random(7)

C = dict(black=(28, 26, 30), green=(60, 170, 70), dgreen=(30, 110, 45), yellow=(255, 205, 40), orange=(255, 140, 30),
         red=(220, 45, 45), brown=(150, 95, 55), pink=(245, 130, 170), blue=(60, 120, 230), grey=(140, 145, 155),
         purple=(140, 70, 190), skin=(250, 200, 150), white=(255, 255, 255))


def crayon_line(d, pts, col, w=10, passes=3):
    for k in range(passes):
        jit = [(x + rng.uniform(-2.5, 2.5), y + rng.uniform(-2.5, 2.5)) for x, y in pts]
        a = 170 if k == 0 else 110
        d.line(jit, fill=col + (a,), width=max(2, int(w * rng.uniform(0.7, 1.0))), joint="curve")


def crayon_fill(d, poly, col, step=7):
    """scribbly hatching inside a polygon (diagonal strokes), like a kid colouring in."""
    xs, ys = [p[0] for p in poly], [p[1] for p in poly]
    mask = Image.new("L", (N, N), 0)
    ImageDraw.Draw(mask).polygon(poly, fill=255)
    layer = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    for c in range(int(min(xs) + min(ys)) - 40, int(max(xs) + max(ys)) + 40, step):
        ld.line([(c - min(ys) + 40, min(ys) - 40), (c - max(ys) - 40, max(ys) + 40)], fill=col + (150,), width=step + 3)
    layer.putalpha(Image.composite(layer.getchannel("A"), Image.new("L", (N, N), 0), mask))
    return layer


def circle(cx, cy, r, n=28, wob=0.06):
    return [(cx + r * (1 + rng.uniform(-wob, wob)) * math.cos(2 * math.pi * i / n), cy + r * (1 + rng.uniform(-wob, wob)) * math.sin(2 * math.pi * i / n)) for i in range(n + 1)]


def ellipse(cx, cy, rx, ry, n=30):
    return [(cx + rx * math.cos(2 * math.pi * i / n) + rng.uniform(-3, 3), cy + ry * math.sin(2 * math.pi * i / n) + rng.uniform(-3, 3)) for i in range(n + 1)]


class Pic:
    def __init__(self):
        self.img = Image.new("RGBA", (N, N), PAPER + (255,))
        # faint paper grain + a ruled-line feel
        g = ImageDraw.Draw(self.img)
        for y in range(40, N, 38):
            g.line([(0, y), (N, y)], fill=(200, 215, 240, 255), width=1)
        g.line([(52, 0), (52, N)], fill=(240, 170, 170, 255), width=1)
        self.d = ImageDraw.Draw(self.img, "RGBA")

    def fill(self, poly, col):
        self.img.alpha_composite(crayon_fill(self.d, poly, C[col]))
        self.d = ImageDraw.Draw(self.img, "RGBA")

    def line(self, pts, col, w=10):
        crayon_line(self.d, pts, C[col], w)

    def shape(self, poly, col, edge="black", w=8):
        self.fill(poly, col)
        self.line(poly, edge, w)

    def save(self, name):
        self.img.convert("RGB").filter(ImageFilter.SMOOTH).save(os.path.join(OUT, f"paper_{name}.png"))


def dragon():
    p = Pic()
    p.shape(ellipse(250, 300, 120, 70), "green")
    p.shape([(330, 260), (420, 200), (455, 230), (420, 270), (360, 300)], "green")  # neck + head
    p.shape([(200, 250), (230, 120), (300, 240)], "dgreen")  # wing
    p.shape([(130, 300), (40, 250), (60, 320), (140, 330)], "green")  # tail
    for x in (190, 230, 280, 320):
        p.line([(x, 360), (x - 5, 430)], "dgreen", 14)
    p.d.ellipse([428, 212, 440, 224], fill=C["black"])
    for i in range(6):  # fire
        p.line([(455, 225 + i * 4), (500, 200 + i * 14)], "orange" if i % 2 else "red", 12)
    p.save("dragon")


def horse():
    p = Pic()
    p.shape(ellipse(240, 270, 130, 60), "pink")
    p.shape([(350, 240), (400, 150), (450, 165), (420, 220), (370, 270)], "pink")
    p.line([(390, 160), (360, 200), (340, 230)], "purple", 16)
    for i, x in enumerate((140, 180, 220, 260, 300, 340)):
        p.line([(x, 320), (x + (8 if i % 2 else -8), 420)], "brown", 12)
    p.line([(110, 250), (60, 300)], "purple", 18)
    p.d.ellipse([415, 170, 427, 182], fill=C["black"])
    p.d.text((70, 455), "6 LEGS!!", fill=C["blue"], font=FONT)
    p.save("horse")


def stickdad():
    p = Pic()
    p.line(circle(256, 140, 55), "black", 9)
    p.d.ellipse([230, 125, 242, 137], fill=C["black"]); p.d.ellipse([270, 125, 282, 137], fill=C["black"])
    p.line([(225, 160), (256, 178), (288, 160)], "black", 8)
    p.line([(256, 195), (256, 350)], "black", 10)
    p.line([(160, 250), (256, 230), (352, 250)], "black", 10)
    p.line([(256, 350), (195, 460)], "black", 10); p.line([(256, 350), (318, 460)], "black", 10)
    p.line([(210, 80), (300, 80)], "brown", 12)
    p.d.text((340, 120), "DAD", fill=C["red"], font=FONT)
    p.save("stickdad")


def sun():
    p = Pic()
    p.shape(circle(256, 256, 110), "yellow", "orange", 10)
    for i in range(12):
        a = 2 * math.pi * i / 12
        p.line([(256 + 130 * math.cos(a), 256 + 130 * math.sin(a)), (256 + 210 * math.cos(a), 256 + 210 * math.sin(a))], "orange", 14)
    p.d.ellipse([210, 215, 230, 240], fill=C["black"]); p.d.ellipse([282, 215, 302, 240], fill=C["black"])
    p.line([(205, 290), (256, 320), (307, 290)], "red", 10)
    p.save("sun")


def pickle():
    p = Pic()
    p.shape(ellipse(256, 150, 70, 80), "skin")
    p.shape([(150, 60), (360, 60), (330, 110), (180, 110)], "brown")  # hair bun-ish
    p.shape(circle(256, 50, 40), "brown")
    p.line(circle(225, 145, 20), "black", 6); p.line(circle(287, 145, 20), "black", 6)  # glasses
    p.line([(225, 195), (256, 210), (290, 195)], "red", 8)
    p.shape([(180, 235), (332, 235), (370, 450), (142, 450)], "green")
    p.line([(180, 250), (110, 360)], "skin", 14); p.line([(332, 250), (400, 360)], "skin", 14)
    p.d.text((150, 462), "MRS PICKLE", fill=C["black"], font=FONT)
    p.save("pickle")


def robot():
    p = Pic()
    p.shape([(180, 60), (330, 60), (330, 170), (180, 170)], "grey")
    p.d.ellipse([205, 90, 245, 130], fill=C["red"]); p.d.ellipse([265, 90, 305, 130], fill=C["red"])
    p.line([(255, 60), (255, 25)], "black", 8); p.d.ellipse([245, 12, 268, 35], fill=C["yellow"])
    p.shape([(150, 185), (360, 185), (360, 360), (150, 360)], "blue")
    p.shape([(220, 230), (290, 230), (290, 300), (220, 300)], "yellow")
    p.line([(150, 200), (70, 300)], "grey", 22); p.line([(360, 200), (440, 300)], "grey", 22)
    p.line([(200, 360), (195, 470)], "grey", 24); p.line([(310, 360), (315, 470)], "grey", 24)
    p.d.text((380, 60), "MAX", fill=C["red"], font=FONT)
    p.save("robot")


def monster(scribbled=False):
    p = Pic()
    p.shape(ellipse(256, 280, 140, 150), "purple")
    for i in range(10):  # ten wiggly arms all round the body
        a = 2 * math.pi * (i + 0.5) / 10
        pts = [(256 + (140 + k * 18) * math.cos(a) + 12 * math.sin(k * 1.3), 280 + (150 + k * 16) * math.sin(a) * 0.85 + 12 * math.cos(k * 1.3)) for k in range(7)]
        p.line(pts, "purple", 13)
    p.d.ellipse([195, 200, 235, 245], fill=C["yellow"]); p.d.ellipse([280, 200, 320, 245], fill=C["yellow"])
    teeth = [(170 + i * 17, 330 + (22 if i % 2 else 0)) for i in range(11)]
    p.line(teeth, "white", 8); p.line([(170, 325), (342, 325)], "black", 6)
    if scribbled:
        for k in range(70):
            cx, cy = 256 + rng.uniform(-150, 150), 280 + rng.uniform(-150, 140)
            r = rng.uniform(30, 90)
            p.line(circle(cx, cy, r, 10, 0.4), "black", 9)
    p.save("monster_scribbled" if scribbled else "monster")


def scribble():
    p = Pic()
    pts = []
    for k in range(260):
        a = k * 0.55
        r = 70 + 60 * math.sin(k * 0.13) + rng.uniform(-30, 30)
        pts.append((256 + r * math.cos(a) + rng.uniform(-20, 20), 260 + r * 0.8 * math.sin(a) + rng.uniform(-20, 20)))
    crayon_line(p.d, pts, C["black"], 9, 2)
    p.save("scribble")


def blank():
    Pic().save("blank")


for f in (dragon, horse, stickdad, sun, pickle, robot, scribble, blank):
    f()
monster(False)
monster(True)
print("ok")
