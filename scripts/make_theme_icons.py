"""Draws the matching app icon for each theme that doesn't have one yet (owner, 2026-11-14), in the style of the
existing icons: a soft two-tone background, the theme's ball lit from the upper left with a highlight arc and a soft
shadow, and the theme's own marks. 1024 x 1024 RGB PNG (no alpha), drawn at 2x and scaled down.

Colors come from App/Shared/GumColors.swift (base, light, dark). Run from the repo root:
    python3 scripts/make_theme_icons.py            # writes the missing appiconsets
    python3 scripts/make_theme_icons.py --sheet    # also writes /tmp/theme_icons_sheet.png to review
"""
import json, math, os, re, sys, random
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 2048           # drawing size (2x)
OUT = 1024
CX, CY, R = S // 2, int(S * 0.53), int(S * 0.31)
ASSETS = "App/Promptly/Assets.xcassets"


def palette_colors():
    s = open("App/Shared/GumColors.swift").read()
    out = {}
    for name in ["base", "light", "dark"]:
        body = re.search(r"    var %s: Color \{\n        switch self \{\n(.*?)\n        \}\n    \}" % name, s, re.S).group(1)
        d = {}
        for line in body.split("\n"):
            m = re.match(r"\s*case (.+?): (?:Self\.)?rgb\(0x([0-9A-Fa-f]{6})\)", line)
            if m:
                for c in m.group(1).split(","):
                    d[c.strip().lstrip(".")] = tuple(int(m.group(2)[i:i + 2], 16) for i in (0, 2, 4))
        out[name] = d
    return out


C = palette_colors()

# Background: top and bottom colors, chosen to sit behind each ball like the existing icons.
BG = {
    "disco": ("#3A1C71", "#120A2A"), "soap": ("#CDE7FF", "#F3D9F7"), "planet": ("#1B2350", "#0B0F26"),
    "basketball": ("#F6E2CC", "#E8C49A"), "donut": ("#FFD6E5", "#F7A9C6"), "waterBalloon": ("#E3F4FF", "#AFDDF7"),
    "eyeball": ("#2E2F6B", "#141532"), "fishbowl": ("#3FA9D9", "#1F6E9E"), "moodRing": ("#F3E9D2", "#E2CFA2"),
    "lavaLamp": ("#3A145A", "#1A0830"), "soccer": ("#3E9B4F", "#24703A"), "hockey": ("#E8F1F7", "#BFD6E6"),
    "tennis": ("#2F7D57", "#1C5A3C"), "golf": ("#6CBF5E", "#3E9446"), "baseball": ("#2B4C7E", "#16294A"),
    "bowling": ("#E9D7B8", "#C9A877"), "pixel": ("#1E1E3A", "#0E0E1E"), "gumball": ("#F25C5C", "#B8323A"),
    "cherry": ("#FFE3E3", "#F7B6B6"), "orange": ("#E9F6E0", "#BFE2A8"), "macaron": ("#FFF4E6", "#F7DCC0"),
    "cakePop": ("#FFF0B8", "#F7D774"), "earth": ("#0B1030", "#03051A"), "sun": ("#7ACBF5", "#3E9ED9"),
    "dandelion": ("#9ED36A", "#5E9E3A"), "atom": ("#0F1A3A", "#050A1E"), "geode": ("#E9E4F7", "#C9BEE9"),
    "yarn": ("#F5E9DC", "#E6CDB2"), "arcadeButton": ("#1E1E2A", "#0A0A12"), "clock": ("#2E4A6B", "#172A40"),
    "marble": ("#F5EEDF", "#E3D3B3"), "duck": ("#7FD3F7", "#3FA9D9"), "easterEgg": ("#E6F7D9", "#BFE6A8"),
    "valentine": ("#FFE0EA", "#F7A9C2"), "fireworks": ("#0B1030", "#1F1450"), "beachBall": ("#FFE9B8", "#F2C46B"),
    "zen": ("#EFE9DD", "#D9CFBA"),
}


def hexrgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def background(name):
    top, bot = (hexrgb(c) for c in BG[name])
    t = np.linspace(0, 1, S)[:, None, None]
    img = (np.array(top) * (1 - t) + np.array(bot) * t) * np.ones((S, S, 3))
    return Image.fromarray(img.astype(np.uint8), "RGB")


def ball_layer(light, base, dark, cx=CX, cy=CY, rx=R, ry=None):
    """A lit sphere (or egg when ry != rx) as an RGBA layer."""
    ry = ry or rx
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    nx, ny = (xx - cx) / rx, (yy - cy) / ry
    inside = nx ** 2 + ny ** 2 <= 1
    hx, hy = -0.24, -0.48
    d = np.sqrt((nx - hx) ** 2 + (ny - hy) ** 2) / 1.45
    d = np.clip(d, 0, 1)
    l, b, k = (np.array(c, np.float32) for c in (light, base, dark))
    col = np.where(d[..., None] < 0.45, l + (b - l) * (d[..., None] / 0.45), b + (k - b) * ((d[..., None] - 0.45) / 0.55))
    a = np.zeros((S, S), np.float32)
    a[inside] = 255
    # Soft antialiased edge.
    edge = np.sqrt(nx ** 2 + ny ** 2)
    a = np.where((edge > 0.995) & (edge <= 1.0), (1.0 - edge) / 0.005 * 255, a)
    rgba = np.dstack([np.clip(col, 0, 255), a]).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def shadow(img, color, cx=CX, cy=CY, r=R):
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(sh)
    d.ellipse([cx - r * 0.85, cy + r * 0.82, cx + r * 0.85, cy + r * 1.08], fill=color + (90,))
    sh = sh.filter(ImageFilter.GaussianBlur(S * 0.02))
    img.alpha_composite(sh)


def highlight(img, cx=CX, cy=CY, r=R, strength=150):
    hl = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(hl)
    w = int(r * 0.07)
    d.arc([cx - r * 0.78, cy - r * 0.78, cx + r * 0.78, cy + r * 0.78], 200, 245, fill=(255, 255, 255, strength), width=w)
    d.ellipse([cx - r * 0.43, cy - r * 0.6, cx - r * 0.25, cy - r * 0.47], fill=(255, 255, 255, int(strength * 0.9)))
    hl = hl.filter(ImageFilter.GaussianBlur(S * 0.003))
    img.alpha_composite(hl)


def clip_to_ball(layer, cx=CX, cy=CY, rx=R, ry=None):
    ry = ry or rx
    m = Image.new("L", (S, S), 0)
    ImageDraw.Draw(m).ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=255)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(layer, (0, 0), Image.fromarray(np.minimum(np.array(m), np.array(layer.split()[3]))))
    return out


def sparkle(d, x, y, s, color=(255, 255, 255, 230)):
    d.polygon([(x, y - s), (x + s * 0.22, y - s * 0.22), (x + s, y), (x + s * 0.22, y + s * 0.22),
               (x, y + s), (x - s * 0.22, y + s * 0.22), (x - s, y), (x - s * 0.22, y - s * 0.22)], fill=color)


def marks(name, img):
    """The theme's own details, drawn on a layer clipped to the ball unless noted."""
    L = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(L)
    top = Image.new("RGBA", (S, S), (0, 0, 0, 0))   # drawn over the ball, not clipped
    t = ImageDraw.Draw(top)
    rnd = random.Random(name)
    x0, y0, x1, y1 = CX - R, CY - R, CX + R, CY + R
    w = int(R * 0.035)
    if name == "basketball":
        k = (40, 20, 10, 255)
        d.line([(CX, y0), (CX, y1)], fill=k, width=w); d.line([(x0, CY), (x1, CY)], fill=k, width=w)
        d.arc([x0 - R * 0.55, y0, CX - R * 0.2, y1], -60, 60, fill=k, width=w)
        d.arc([CX + R * 0.2, y0, x1 + R * 0.55, y1], 120, 240, fill=k, width=w)
    elif name == "soccer":
        k = (30, 30, 34, 255)
        def pent(cx, cy, r, rot=0):
            return [(cx + r * math.cos(rot + i * 2 * math.pi / 5 - math.pi / 2), cy + r * math.sin(rot + i * 2 * math.pi / 5 - math.pi / 2)) for i in range(5)]
        d.polygon(pent(CX, CY, R * 0.28), fill=k)
        for i in range(5):
            a = i * 2 * math.pi / 5 - math.pi / 2
            px, py = CX + R * 0.78 * math.cos(a), CY + R * 0.78 * math.sin(a)
            d.polygon(pent(px, py, R * 0.24, math.pi / 5), fill=k)
            d.line([(CX + R * 0.28 * math.cos(a), CY + R * 0.28 * math.sin(a)), (px, py)], fill=k, width=w // 2)
    elif name == "tennis":
        k = (250, 250, 245, 255)
        d.arc([x0 - R * 0.7, y0 + R * 0.1, CX + R * 0.1, y1 - R * 0.1], -55, 55, fill=k, width=int(w * 1.4))
        d.arc([CX - R * 0.1, y0 + R * 0.1, x1 + R * 0.7, y1 - R * 0.1], 125, 235, fill=k, width=int(w * 1.4))
    elif name == "golf":
        for i in range(70):
            a = rnd.uniform(0, 2 * math.pi); rr = R * math.sqrt(rnd.uniform(0, 0.92))
            x, y = CX + rr * math.cos(a), CY + rr * math.sin(a); s = R * 0.05
            d.ellipse([x - s, y - s, x + s, y + s], fill=(190, 192, 196, 140))
    elif name == "baseball":
        red = (200, 30, 40, 255)
        for side in (-1, 1):
            box = [x0 - R * 0.6, y0, CX - R * 0.25, y1] if side < 0 else [CX + R * 0.25, y0, x1 + R * 0.6, y1]
            d.arc(box, -60 if side < 0 else 120, 60 if side < 0 else 240, fill=red, width=w // 2)
            cx = (box[0] + box[2]) / 2; rx = (box[2] - box[0]) / 2; ry = (box[3] - box[1]) / 2
            for j in range(-5, 6):
                a = math.radians(j * 10 + (0 if side < 0 else 180))
                x, y = cx + rx * math.cos(a), CY + ry * math.sin(a)
                d.line([(x - side * R * 0.06, y - R * 0.03), (x + side * R * 0.06, y + R * 0.03)], fill=red, width=w // 2)
    elif name == "bowling":
        for dx, dy in [(-0.18, -0.25), (0.12, -0.32), (-0.02, -0.02)]:
            x, y, s = CX + R * dx, CY + R * dy, R * 0.1
            d.ellipse([x - s, y - s, x + s, y + s], fill=(15, 6, 30, 255))
    elif name == "hockey":
        pass  # drawn as a puck below
    elif name == "pixel":
        pass  # pixelated after drawing
    elif name == "gumball":
        cols = [(255, 90, 90), (255, 212, 59), (61, 165, 255), (61, 220, 151), (255, 138, 61), (155, 92, 255), (255, 127, 176)]
        for i in range(34):
            a = rnd.uniform(0, 2 * math.pi); rr = R * math.sqrt(rnd.uniform(0, 0.8))
            x, y = CX + rr * math.cos(a), CY + R * 0.12 + rr * math.sin(a) * 0.85; s = R * 0.13
            c = cols[i % len(cols)]
            d.ellipse([x - s, y - s, x + s, y + s], fill=c + (255,))
            d.ellipse([x - s * 0.55, y - s * 0.65, x - s * 0.15, y - s * 0.3], fill=(255, 255, 255, 140))
        t.rectangle([CX - R * 0.45, y1 - R * 0.05, CX + R * 0.45, y1 + R * 0.28], fill=(200, 40, 50, 255))
        t.rectangle([CX - R * 0.12, y1 + R * 0.06, CX + R * 0.12, y1 + R * 0.18], fill=(240, 200, 60, 255))
    elif name == "cherry":
        t.line([(CX, y0 + R * 0.05), (CX + R * 0.3, y0 - R * 0.45)], fill=(90, 60, 30, 255), width=int(w * 1.2))
        t.ellipse([CX + R * 0.25, y0 - R * 0.6, CX + R * 0.75, y0 - R * 0.35], fill=(70, 150, 60, 255))
    elif name == "orange":
        for i in range(160):
            a = rnd.uniform(0, 2 * math.pi); rr = R * math.sqrt(rnd.uniform(0, 0.95))
            x, y = CX + rr * math.cos(a), CY + rr * math.sin(a); s = R * 0.018
            d.ellipse([x - s, y - s, x + s, y + s], fill=(200, 100, 10, 110))
        t.ellipse([CX - R * 0.05, y0 - R * 0.25, CX + R * 0.45, y0 + R * 0.02], fill=(70, 150, 60, 255))
        t.ellipse([CX - R * 0.08, y0 - R * 0.06, CX + R * 0.08, y0 + R * 0.06], fill=(90, 110, 40, 255))
    elif name == "macaron":
        pass  # drawn as a macaron below
    elif name == "cakePop":
        t.rectangle([CX - R * 0.04, y1 - R * 0.05, CX + R * 0.04, y1 + R * 0.55], fill=(250, 248, 240, 255))
        cols = [(255, 255, 255), (61, 165, 255), (255, 212, 59), (61, 220, 151), (155, 92, 255)]
        for i in range(60):
            a = rnd.uniform(0, 2 * math.pi); rr = R * math.sqrt(rnd.uniform(0, 0.9))
            x, y = CX + rr * math.cos(a), CY + rr * math.sin(a); ang = rnd.uniform(0, math.pi)
            dx, dy = R * 0.05 * math.cos(ang), R * 0.05 * math.sin(ang)
            d.line([(x - dx, y - dy), (x + dx, y + dy)], fill=cols[i % 5] + (255,), width=int(w * 0.8))
    elif name == "earth":
        g = (70, 160, 80, 255)
        for (dx, dy, sx, sy) in [(-0.35, -0.2, 0.32, 0.45), (0.25, -0.35, 0.35, 0.22), (0.3, 0.25, 0.3, 0.35), (-0.15, 0.45, 0.25, 0.15)]:
            d.ellipse([CX + R * (dx - sx), CY + R * (dy - sy), CX + R * (dx + sx), CY + R * (dy + sy)], fill=g)
        d.ellipse([CX - R * 0.6, y0 - R * 0.1, CX + R * 0.6, y0 + R * 0.18], fill=(240, 248, 255, 220))
    elif name == "sun":
        for i in range(12):
            a = i * math.pi / 6
            t.polygon([(CX + R * 1.08 * math.cos(a - 0.12), CY + R * 1.08 * math.sin(a - 0.12)),
                       (CX + R * 1.38 * math.cos(a), CY + R * 1.38 * math.sin(a)),
                       (CX + R * 1.08 * math.cos(a + 0.12), CY + R * 1.08 * math.sin(a + 0.12))], fill=(255, 196, 40, 255))
    elif name == "dandelion":
        for i in range(90):
            a = rnd.uniform(0, 2 * math.pi); rr = R * rnd.uniform(0.2, 1.0)
            x, y = CX + rr * math.cos(a), CY + rr * math.sin(a)
            d.line([(CX, CY), (x, y)], fill=(220, 220, 210, 120), width=max(2, w // 4))
            s = R * 0.05; d.ellipse([x - s, y - s, x + s, y + s], fill=(255, 255, 255, 200))
        t.line([(CX, y1), (CX - R * 0.1, y1 + R * 0.6)], fill=(80, 140, 50, 255), width=int(w * 1.2))
    elif name == "atom":
        for rot in (0, 60, 120):
            o = Image.new("RGBA", (S, S), (0, 0, 0, 0)); od = ImageDraw.Draw(o)
            od.ellipse([CX - R * 0.85, CY - R * 0.32, CX + R * 0.85, CY + R * 0.32], outline=(120, 200, 255, 255), width=int(w * 0.9))
            L.alpha_composite(o.rotate(rot, center=(CX, CY), resample=Image.BICUBIC))
        s = R * 0.13; d.ellipse([CX - s, CY - s, CX + s, CY + s], fill=(255, 120, 160, 255))
    elif name == "geode":
        d.ellipse([CX - R * 0.62, CY - R * 0.62, CX + R * 0.62, CY + R * 0.62], fill=(110, 70, 170, 255))
        for i in range(36):
            a = i * 2 * math.pi / 36; r1, r2 = R * 0.62, R * rnd.uniform(0.2, 0.42)
            d.polygon([(CX + r1 * math.cos(a - 0.09), CY + r1 * math.sin(a - 0.09)), (CX + r2 * math.cos(a), CY + r2 * math.sin(a)),
                       (CX + r1 * math.cos(a + 0.09), CY + r1 * math.sin(a + 0.09))], fill=(190, 150, 240, 255) if i % 2 else (150, 100, 210, 255))
        d.ellipse([CX - R * 0.2, CY - R * 0.2, CX + R * 0.2, CY + R * 0.2], fill=(70, 40, 120, 255))
    elif name == "yarn":
        k = (150, 30, 60, 170)
        for i in range(9):
            off = -R + i * R * 0.25
            d.arc([CX - R * 1.3, CY + off - R * 0.9, CX + R * 1.3, CY + off + R * 0.9], 200, 340, fill=k, width=w // 2)
        for i in range(5):
            off = -R * 0.6 + i * R * 0.3
            d.arc([CX + off - R * 0.4, CY - R * 1.1, CX + off + R * 0.4, CY + R * 1.1], 100, 260, fill=k, width=w // 2)
        t.line([(x1 - R * 0.1, CY + R * 0.4), (x1 + R * 0.3, y1 + R * 0.3)], fill=C["dark"]["yarn"] + (255,), width=w)
    elif name == "arcadeButton":
        pass  # base drawn below
    elif name == "clock":
        k = (40, 40, 46, 255)
        for i in range(12):
            a = i * math.pi / 6; r1 = R * (0.78 if i % 3 else 0.7)
            d.line([(CX + r1 * math.cos(a), CY + r1 * math.sin(a)), (CX + R * 0.86 * math.cos(a), CY + R * 0.86 * math.sin(a))], fill=k, width=w if i % 3 == 0 else w // 2)
        d.line([(CX, CY), (CX + R * 0.35, CY - R * 0.25)], fill=k, width=int(w * 1.3))
        d.line([(CX, CY), (CX - R * 0.1, CY - R * 0.62)], fill=k, width=w)
        s = R * 0.05; d.ellipse([CX - s, CY - s, CX + s, CY + s], fill=(232, 85, 58, 255))
        t.rectangle([CX - R * 0.12, y0 - R * 0.16, CX + R * 0.12, y0 + R * 0.02], fill=(200, 160, 60, 255))
    elif name == "marble":
        for c, off in [((232, 85, 58), 0), ((61, 165, 255), 2.1), ((255, 212, 59), 4.2)]:
            pts = [(CX + R * 0.55 * math.sin(u / 6 + off) * math.cos(u / 9), CY - R * 0.7 + u * R * 0.05) for u in range(0, 29)]
            d.line(pts, fill=c + (230,), width=int(w * 2.2), joint="curve")
    elif name == "duck":
        t.polygon([(x1 - R * 0.15, CY - R * 0.15), (x1 + R * 0.35, CY - R * 0.02), (x1 - R * 0.1, CY + R * 0.15)], fill=(255, 140, 30, 255))
        s = R * 0.09; d.ellipse([CX + R * 0.35 - s, CY - R * 0.35 - s, CX + R * 0.35 + s, CY - R * 0.35 + s], fill=(25, 25, 30, 255))
        d.ellipse([CX + R * 0.37 - s * 0.35, CY - R * 0.38 - s * 0.35, CX + R * 0.37 + s * 0.35, CY - R * 0.38 + s * 0.35], fill=(255, 255, 255, 255))
    elif name == "easterEgg":
        pass  # egg shape and bands below
    elif name == "valentine":
        pass  # heart shape below
    elif name == "fireworks":
        cols = [(255, 212, 59), (255, 90, 150), (61, 220, 151), (120, 200, 255)]
        for j, (dx, dy) in enumerate([(-0.35, -0.3), (0.3, -0.2), (0.0, 0.3)]):
            cx, cy = CX + R * dx, CY + R * dy
            for i in range(14):
                a = i * 2 * math.pi / 14
                d.line([(cx + R * 0.08 * math.cos(a), cy + R * 0.08 * math.sin(a)), (cx + R * 0.3 * math.cos(a), cy + R * 0.3 * math.sin(a))], fill=cols[j % 4] + (255,), width=w // 2)
        for i in range(12):
            sparkle(t, rnd.uniform(S * 0.1, S * 0.9), rnd.uniform(S * 0.08, S * 0.3), S * 0.012, (255, 240, 200, 220))
    elif name == "beachBall":
        cols = [(232, 60, 60), (255, 212, 59), (61, 165, 255), (61, 200, 120)]
        for i in range(6):
            if i % 2: continue
            a0 = i * 60
            d.pieslice([x0 - R * 0.1, y0 - R * 0.1, x1 + R * 0.1, y1 + R * 0.1], a0 - 90, a0 - 30, fill=cols[(i // 2) % 4] + (255,))
        s = R * 0.13; d.ellipse([CX - s, CY - s, CX + s, CY + s], fill=(255, 255, 255, 255))
    elif name == "zen":
        for i in range(1, 6):
            rr = R * 0.16 * i
            d.ellipse([CX + R * 0.15 - rr, CY + R * 0.1 - rr * 0.6, CX + R * 0.15 + rr, CY + R * 0.1 + rr * 0.6], outline=(210, 205, 195, 200), width=max(3, w // 3))
    elif name == "disco":
        n = 14
        for i in range(n + 1):
            u = -R + i * 2 * R / n
            d.line([(x0, CY + u), (x1, CY + u)], fill=(90, 95, 110, 255), width=max(3, w // 3))
            d.line([(CX + u, y0), (CX + u, y1)], fill=(90, 95, 110, 255), width=max(3, w // 3))
        for i in range(20):
            gx, gy = rnd.randrange(n), rnd.randrange(n)
            d.rectangle([x0 + gx * 2 * R / n + 4, y0 + gy * 2 * R / n + 4, x0 + (gx + 1) * 2 * R / n - 4, y0 + (gy + 1) * 2 * R / n - 4], fill=(255, 255, 255, 170))
        for i in range(10):
            sparkle(t, rnd.uniform(S * 0.08, S * 0.92), rnd.uniform(S * 0.08, S * 0.92), S * 0.014, (255, 230, 255, 220))
    elif name == "soap":
        for c, off in [((255, 150, 220), 0), ((120, 220, 255), 1.5), ((255, 230, 120), 3.0)]:
            d.arc([x0 + R * 0.1, y0 + R * 0.1, x1 - R * 0.1, y1 - R * 0.1], int(math.degrees(off)) + 20, int(math.degrees(off)) + 90, fill=c + (150,), width=int(w * 2.5))
    elif name == "planet":
        for i in range(5):
            y = CY - R * 0.6 + i * R * 0.3
            d.rectangle([x0, y, x1, y + R * 0.12], fill=(200, 140, 80, 120))
    elif name == "donut":
        pass  # torus drawn below
    elif name == "waterBalloon":
        pass
    elif name == "eyeball":
        d.ellipse([CX - R * 0.42, CY - R * 0.42, CX + R * 0.42, CY + R * 0.42], fill=(60, 140, 220, 255))
        d.ellipse([CX - R * 0.2, CY - R * 0.2, CX + R * 0.2, CY + R * 0.2], fill=(15, 15, 20, 255))
        d.ellipse([CX - R * 0.32, CY - R * 0.3, CX - R * 0.18, CY - R * 0.16], fill=(255, 255, 255, 230))
        for i in range(8):
            a = rnd.uniform(0, 2 * math.pi)
            d.line([(CX + R * 0.95 * math.cos(a), CY + R * 0.95 * math.sin(a)), (CX + R * 0.6 * math.cos(a + 0.1), CY + R * 0.6 * math.sin(a + 0.1))], fill=(230, 120, 130, 160), width=max(3, w // 4))
    elif name == "fishbowl":
        d.rectangle([x0, CY - R * 0.15, x1, y1], fill=(90, 180, 230, 150))
        fx, fy = CX - R * 0.05, CY + R * 0.28
        d.ellipse([fx - R * 0.22, fy - R * 0.13, fx + R * 0.22, fy + R * 0.13], fill=(255, 140, 30, 255))
        d.polygon([(fx + R * 0.18, fy), (fx + R * 0.42, fy - R * 0.14), (fx + R * 0.42, fy + R * 0.14)], fill=(255, 120, 20, 255))
        s = R * 0.03; d.ellipse([fx - R * 0.13 - s, fy - R * 0.03 - s, fx - R * 0.13 + s, fy - R * 0.03 + s], fill=(20, 20, 20, 255))
        for i in range(3):
            s = R * (0.03 + 0.015 * i); bx, by = fx - R * 0.3, fy - R * (0.25 + 0.17 * i)
            d.ellipse([bx - s, by - s, bx + s, by + s], outline=(255, 255, 255, 200), width=max(3, w // 4))
    elif name == "moodRing":
        swirl = Image.new("RGBA", (S, S), (0, 0, 0, 0)); sd = ImageDraw.Draw(swirl)
        for c, off in [((40, 210, 170), 10), ((170, 70, 230), 130), ((30, 90, 230), 250)]:
            sd.pieslice([x0 + R * 0.1, y0 + R * 0.1, x1 - R * 0.1, y1 - R * 0.1], off, off + 110, fill=c + (255,))
        swirl = swirl.rotate(0).filter(ImageFilter.GaussianBlur(R * 0.12))
        L.alpha_composite(swirl)
        t.arc([CX - R * 1.12, CY - R * 1.12, CX + R * 1.12, CY + R * 1.12], 20, 160, fill=(214, 170, 70, 255), width=int(R * 0.12))
    elif name == "lavaLamp":
        for (dx, dy, s) in [(-0.25, -0.35, 0.22), (0.2, 0.0, 0.3), (-0.15, 0.45, 0.25), (0.35, -0.5, 0.12)]:
            d.ellipse([CX + R * (dx - s), CY + R * (dy - s * 1.2), CX + R * (dx + s), CY + R * (dy + s * 1.2)], fill=(255, 150, 50, 230))
    return L, top


def render(name):
    img = background(name).convert("RGBA")
    light, base, dark = C["light"][name], C["base"][name], C["dark"][name]
    rx, ry, cy = R, R, CY
    if name in ("easterEgg", "waterBalloon"):
        ry = int(R * 1.18); cy = CY + int(R * 0.02)
    shadow(img, tuple(int(c * 0.45) for c in dark), cy=cy, r=rx)
    if name == "hockey":
        # A puck: dark top face over a band, seen at a slant.
        d = ImageDraw.Draw(img)
        top, band = int(R * 0.45), int(R * 0.32)
        d.rectangle([CX - R, CY - band // 2, CX + R, CY + band // 2], fill=(22, 22, 24, 255))
        d.ellipse([CX - R, CY + band // 2 - top, CX + R, CY + band // 2 + top], fill=(22, 22, 24, 255))
        d.ellipse([CX - R, CY - band // 2 - top, CX + R, CY - band // 2 + top], fill=(52, 52, 58, 255))
        d.arc([CX - R * 0.8, CY - band // 2 - top * 0.8, CX + R * 0.8, CY - band // 2 + top * 0.8], 190, 260, fill=(255, 255, 255, 120), width=int(R * 0.04))
        for i in range(30):
            x = CX - R * 0.95 + i * R * 1.9 / 29
            d.line([(x, CY - band // 2 + R * 0.05), (x, CY + band // 2)], fill=(40, 40, 44, 255), width=6)
        return img
    if name == "arcadeButton":
        d = ImageDraw.Draw(img)
        d.ellipse([CX - R * 1.05, CY + R * 0.2, CX + R * 1.05, CY + R * 0.85], fill=(30, 30, 36, 255))
        d.rectangle([CX - R * 1.05, CY + R * 0.1, CX + R * 1.05, CY + R * 0.52], fill=(30, 30, 36, 255))
        d.ellipse([CX - R * 1.05, CY - R * 0.15, CX + R * 1.05, CY + R * 0.4], fill=(55, 55, 64, 255))
        dome = ball_layer(light, base, dark, cx=CX, cy=CY - int(R * 0.05), rx=int(R * 0.8), ry=int(R * 0.6))
        img.alpha_composite(dome)
        highlight(img, cy=CY - int(R * 0.15), r=int(R * 0.7))
        return img
    if name == "donut":
        torus = ball_layer(light, base, dark)
        icing = ball_layer((255, 200, 225), (247, 140, 185), (200, 90, 140), rx=int(R * 0.95))
        d = ImageDraw.Draw(icing)
        rnd = random.Random("donut")
        cols = [(255, 255, 255), (61, 165, 255), (255, 212, 59), (61, 220, 151), (155, 92, 255)]
        for i in range(70):
            a = rnd.uniform(0, 2 * math.pi); rr = R * rnd.uniform(0.42, 0.85)
            x, y = CX + rr * math.cos(a), CY + rr * math.sin(a); ang = rnd.uniform(0, math.pi)
            dx, dy = R * 0.05 * math.cos(ang), R * 0.05 * math.sin(ang)
            d.line([(x - dx, y - dy), (x + dx, y + dy)], fill=cols[i % 5] + (255,), width=int(R * 0.03))
        img.alpha_composite(torus); img.alpha_composite(icing)
        hole = background(name).convert("RGBA")
        m = Image.new("L", (S, S), 0); ImageDraw.Draw(m).ellipse([CX - R * 0.3, CY - R * 0.3, CX + R * 0.3, CY + R * 0.3], fill=255)
        img.paste(hole, (0, 0), m)
        ImageDraw.Draw(img).ellipse([CX - R * 0.3, CY - R * 0.3, CX + R * 0.3, CY + R * 0.3], outline=tuple(dark) + (255,), width=int(R * 0.05))
        highlight(img)
        return img
    if name == "macaron":
        # Two domed shells with a cream filling and ruffled feet, seen from the side.
        d = ImageDraw.Draw(img)
        shell_top = ball_layer(light, base, dark, cx=CX, cy=CY - int(R * 0.2), rx=R, ry=int(R * 0.42))
        shell_bot = ball_layer(light, base, dark, cx=CX, cy=CY + int(R * 0.38), rx=R, ry=int(R * 0.36))
        img.alpha_composite(shell_bot)
        d.rounded_rectangle([CX - R * 0.92, CY - R * 0.02, CX + R * 0.92, CY + R * 0.2], radius=int(R * 0.1), fill=(255, 248, 236, 255))
        for i in range(24):
            x = CX - R * 0.95 + i * R * 1.9 / 23
            d.ellipse([x - R * 0.05, CY - R * 0.1, x + R * 0.05, CY + R * 0.0], fill=tuple(dark) + (255,))
        img.alpha_composite(shell_top)
        highlight(img, cy=CY - int(R * 0.25), r=int(R * 0.7))
        return img
    if name == "valentine":
        # A heart-shaped balloon: a lit sphere clipped to a heart outline.
        sphere = ball_layer(light, base, dark, cx=CX, cy=CY - int(R * 0.1), rx=int(R * 1.25))
        m = Image.new("L", (S, S), 0)
        pts = []
        for i in range(400):
            u = i / 400 * 2 * math.pi
            x = 16 * math.sin(u) ** 3
            y = 13 * math.cos(u) - 5 * math.cos(2 * u) - 2 * math.cos(3 * u) - math.cos(4 * u)
            pts.append((CX + x / 16 * R * 1.05, CY - R * 0.05 - y / 16 * R * 1.05))
        ImageDraw.Draw(m).polygon(pts, fill=255)
        heart = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        heart.paste(sphere, (0, 0), m)
        img.alpha_composite(heart)
        highlight(img, cx=CX - int(R * 0.35), cy=CY - int(R * 0.3), r=int(R * 0.55))
        t = ImageDraw.Draw(img)
        for (x, y) in [(0.2, 0.2), (0.8, 0.25), (0.15, 0.75), (0.85, 0.7)]:
            sparkle(t, S * x, S * y, S * 0.014, (255, 255, 255, 230))
        return img
    if name == "valentine_old":
        # A heart-shaped balloon: two lobes and a point.
        lobe_r = int(R * 0.6)
        for dx in (-0.45, 0.45):
            img.alpha_composite(ball_layer(light, base, dark, cx=CX + int(R * dx), cy=CY - int(R * 0.25), rx=lobe_r))
        tri = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ImageDraw.Draw(tri).polygon([(CX - R * 1.02, CY - R * 0.12), (CX + R * 1.02, CY - R * 0.12), (CX, CY + R * 0.95)], fill=tuple(base) + (255,))
        tri.alpha_composite(ball_layer(light, base, dark, cx=CX, cy=CY - int(R * 0.1), rx=int(R * 0.55)))
        img.alpha_composite(tri)
        for dx in (-0.45, 0.45):
            img.alpha_composite(ball_layer(light, base, dark, cx=CX + int(R * dx), cy=CY - int(R * 0.25), rx=lobe_r))
        highlight(img, cx=CX - int(R * 0.45), cy=CY - int(R * 0.25), r=lobe_r)
        t = ImageDraw.Draw(img)
        for (x, y) in [(0.2, 0.2), (0.8, 0.25), (0.15, 0.75), (0.85, 0.7)]:
            sparkle(t, S * x, S * y, S * 0.014, (255, 255, 255, 230))
        return img
    img.alpha_composite(ball_layer(light, base, dark, cy=cy, rx=rx, ry=ry))
    L, top = marks(name, img)
    if name == "easterEgg":
        d = ImageDraw.Draw(L)
        for i, c in enumerate([(255, 150, 200), (255, 220, 110), (160, 120, 240)]):
            y = cy - ry * 0.45 + i * ry * 0.42
            pts = [(CX - R + j * R / 6, y + (R * 0.08 if j % 2 else -R * 0.08)) for j in range(13)]
            d.line(pts, fill=c + (255,), width=int(R * 0.09))
    img.alpha_composite(clip_to_ball(L, cy=cy, rx=rx, ry=ry))
    if name == "waterBalloon":
        d = ImageDraw.Draw(top)
        d.polygon([(CX - R * 0.12, cy - ry + R * 0.02), (CX + R * 0.12, cy - ry + R * 0.02), (CX, cy - ry - R * 0.2)], fill=tuple(dark) + (255,))
        d.ellipse([CX - R * 0.1, cy - ry - R * 0.32, CX + R * 0.1, cy - ry - R * 0.14], fill=tuple(dark) + (255,))
    img.alpha_composite(top)
    highlight(img, cy=cy, r=rx, strength=110 if name in ("disco", "pixel") else 150)
    if name == "soap":
        ImageDraw.Draw(img).ellipse([CX - R, CY - R, CX + R, CY + R], outline=(255, 255, 255, 170), width=int(R * 0.025))
    if name == "pixel":
        small = img.resize((32, 32), Image.NEAREST)
        img = small.resize((S, S), Image.NEAREST)
    return img


def wanted():
    """Themes whose icon the app asks for (hasIcon) but that have no appiconset yet."""
    names = list(C["base"].keys())   # every GumPalette case has a base color
    out = []
    for n in names:
        if n == "bubblegum": continue
        icon = "AppIcon-" + n[0].upper() + n[1:]
        if not os.path.exists(f"{ASSETS}/{icon}.appiconset"):
            out.append((n, icon))
    return out


if __name__ == "__main__":
    todo = wanted()
    made = []
    for name, icon in todo:
        im = render(name).convert("RGB").resize((OUT, OUT), Image.LANCZOS)
        folder = f"{ASSETS}/{icon}.appiconset"
        os.makedirs(folder, exist_ok=True)
        im.save(f"{folder}/{icon}.png", optimize=True)
        json.dump({"images": [{"filename": f"{icon}.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}],
                   "info": {"author": "xcode", "version": 1}}, open(f"{folder}/Contents.json", "w"), indent=2)
        made.append((name, im))
        print("made", icon)
    if "--sheet" in sys.argv and made:
        cols = 8
        sheet = Image.new("RGB", (cols * 200, ((len(made) + cols - 1) // cols) * 200), "white")
        for i, (_, im) in enumerate(made):
            sheet.paste(im.resize((200, 200)), ((i % cols) * 200, (i // cols) * 200))
        sheet.save("/tmp/theme_icons_sheet.png")
