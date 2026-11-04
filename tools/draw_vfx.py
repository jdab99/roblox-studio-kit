"""VFX textures for the Blocky Tales director (white on transparent, tinted in Studio): glow ring, 4-point sparkle,
soft puff, radial speed lines, radial burst, soft glow dot. usage: python tools/draw_vfx.py <out_dir>
"""
import math, os, random, sys
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
N = 512
rng = random.Random(3)


def save(img, name):
    img.save(os.path.join(OUT, f"vfx_{name}.png"))


def ring():
    a = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(a)
    d.ellipse([40, 40, N - 40, N - 40], outline=255, width=26)
    a = a.filter(ImageFilter.GaussianBlur(14))
    b = Image.new("L", (N, N), 0)
    ImageDraw.Draw(b).ellipse([52, 52, N - 52, N - 52], outline=255, width=8)
    a = Image.composite(Image.new("L", (N, N), 255), a, b.filter(ImageFilter.GaussianBlur(2)))
    img = Image.new("RGBA", (N, N), (255, 255, 255, 0))
    img.putalpha(a)
    save(img, "ring")


def sparkle():
    a = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(a)
    c = N / 2
    for ang, L in ((0, 240), (90, 240), (45, 120), (135, 120)):
        r = math.radians(ang)
        dx, dy = math.cos(r), math.sin(r)
        px, py = -dy, dx
        w = 18 if L > 200 else 10
        d.polygon([(c - dx * L, c - dy * L), (c + px * w, c + py * w), (c + dx * L, c + dy * L), (c - px * w, c - py * w)], fill=255)
    a = a.filter(ImageFilter.GaussianBlur(2))
    glow = Image.new("L", (N, N), 0)
    ImageDraw.Draw(glow).ellipse([c - 60, c - 60, c + 60, c + 60], fill=200)
    glow = glow.filter(ImageFilter.GaussianBlur(30))
    a = Image.composite(a, glow, a)
    img = Image.new("RGBA", (N, N), (255, 255, 255, 0))
    img.putalpha(a)
    save(img, "sparkle")


def puff():
    a = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(a)
    for _ in range(9):
        r = rng.uniform(70, 130)
        x, y = N / 2 + rng.uniform(-90, 90), N / 2 + rng.uniform(-70, 70)
        d.ellipse([x - r, y - r, x + r, y + r], fill=230)
    a = a.filter(ImageFilter.GaussianBlur(10))
    img = Image.new("RGBA", (N, N), (255, 255, 255, 0))
    img.putalpha(a)
    save(img, "puff")


def speedlines():
    """anime radial speed lines, clear centre (screen overlay)."""
    a = Image.new("L", (N * 2, N * 2), 0)
    d = ImageDraw.Draw(a)
    c = N
    for i in range(110):
        ang = rng.uniform(0, 2 * math.pi)
        r0 = rng.uniform(N * 0.55, N * 0.8)
        w = rng.uniform(0.004, 0.012)
        p1 = (c + math.cos(ang - w) * N * 1.6, c + math.sin(ang - w) * N * 1.6)
        p2 = (c + math.cos(ang + w) * N * 1.6, c + math.sin(ang + w) * N * 1.6)
        p0 = (c + math.cos(ang) * r0, c + math.sin(ang) * r0)
        d.polygon([p0, p1, p2], fill=int(rng.uniform(150, 255)))
    img = Image.new("RGBA", (N * 2, N * 2), (255, 255, 255, 0))
    img.putalpha(a.filter(ImageFilter.GaussianBlur(1)))
    img.resize((1024, 1024), Image.LANCZOS).save(os.path.join(OUT, "vfx_speedlines.png"))


def burst():
    a = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(a)
    c = N / 2
    for i in range(16):
        ang = 2 * math.pi * i / 16 + rng.uniform(-0.05, 0.05)
        L = rng.uniform(150, 245)
        w = 0.07
        d.polygon([(c + math.cos(ang - w) * 40, c + math.sin(ang - w) * 40), (c + math.cos(ang) * L, c + math.sin(ang) * L),
                   (c + math.cos(ang + w) * 40, c + math.sin(ang + w) * 40)], fill=255)
    d.ellipse([c - 70, c - 70, c + 70, c + 70], fill=255)
    a = a.filter(ImageFilter.GaussianBlur(4))
    img = Image.new("RGBA", (N, N), (255, 255, 255, 0))
    img.putalpha(a)
    save(img, "burst")


def glow():
    a = Image.new("L", (N, N), 0)
    ImageDraw.Draw(a).ellipse([96, 96, N - 96, N - 96], fill=255)
    a = a.filter(ImageFilter.GaussianBlur(60))
    img = Image.new("RGBA", (N, N), (255, 255, 255, 0))
    img.putalpha(a)
    save(img, "glow")


for f in (ring, sparkle, puff, speedlines, burst, glow):
    f()
print("ok")


def star_pts(cx, cy, r, inner=0.48, rot=-90):
    pts = []
    for i in range(10):
        a = math.radians(rot + i * 36)
        rr = r if i % 2 == 0 else r * inner
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return pts


def wish_star():
    """the wish star: chunky gold star, dark outline, white shine, soft gold glow (readable at phone size)."""
    S = 4
    big = Image.new("RGBA", (N * S, N * S), (0, 0, 0, 0))
    c = N * S / 2
    glow = Image.new("L", (N * S, N * S), 0)
    ImageDraw.Draw(glow).polygon(star_pts(c, c, 230 * S, 0.5), fill=170)
    glow = glow.filter(ImageFilter.GaussianBlur(28 * S))
    big.paste((255, 214, 90, 255), (0, 0), glow)
    d = ImageDraw.Draw(big)
    d.polygon(star_pts(c, c + 6 * S, 196 * S, 0.5), fill=(120, 60, 10, 255))  # outline / drop
    d.polygon(star_pts(c, c, 178 * S, 0.5), fill=(255, 196, 30, 255))
    d.polygon(star_pts(c, c - 10 * S, 140 * S, 0.5), fill=(255, 226, 90, 255))
    d.polygon([(c - 70 * S, c - 60 * S), (c - 20 * S, c - 120 * S), (c - 4 * S, c - 100 * S), (c - 50 * S, c - 44 * S)], fill=(255, 255, 240, 255))
    big.resize((N, N), Image.LANCZOS).save(os.path.join(OUT, "vfx_star.png"))


def ghost_star():
    """the empty spot: a dashed white star outline."""
    S = 4
    a = Image.new("L", (N * S, N * S), 0)
    d = ImageDraw.Draw(a)
    pts = star_pts(N * S / 2, N * S / 2, 190 * S, 0.5)
    pts.append(pts[0])
    for i in range(10):
        (x1, y1), (x2, y2) = pts[i], pts[i + 1]
        for k in range(0, 6, 2):
            u0, u1 = k / 6, (k + 1) / 6
            d.line([(x1 + (x2 - x1) * u0, y1 + (y2 - y1) * u0), (x1 + (x2 - x1) * u1, y1 + (y2 - y1) * u1)], fill=255, width=14 * S)
    img = Image.new("RGBA", (N * S, N * S), (255, 255, 255, 0))
    img.putalpha(a)
    img.resize((N, N), Image.LANCZOS).save(os.path.join(OUT, "vfx_ghoststar.png"))


wish_star()
ghost_star()
print("stars ok")
