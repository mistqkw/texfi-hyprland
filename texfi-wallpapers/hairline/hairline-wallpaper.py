#!/usr/bin/env python3
"""Обои TexFi hairline (чистый PIL): тёмный фон, сетка 1px, синее свечение, тонкие кольца.
Без логотипа и текста. Запуск: wallpaper.py ШИРИНА ВЫСОТА ФАЙЛ"""
import sys, math, random
from PIL import Image, ImageDraw, ImageChops, ImageFilter

W, H = int(sys.argv[1]), int(sys.argv[2]); out = sys.argv[3]
S = W / 1920
BG, ACC = (10, 10, 12), (74, 125, 251)
cx, cy = W * 0.72, H * 0.62

def radial(cx_, cy_, rx, ry, k=1.0):
    """Маска 'L': 255 в центре, спадает по гауссу; rx, ry — радиус по осям."""
    size = 256
    g = Image.radial_gradient('L').resize((size, size))  # 0 в центре, 255 на краю
    edge = math.exp(-(k) ** 2 * 3.2)
    m = g.point(lambda v: int(255 * max(0.0, math.exp(-((v / 255.0) * k) ** 2 * 3.2) - edge) / (1 - edge)))
    m = m.resize((int(rx * 2 / 1.0), int(ry * 2 / 1.0)), Image.BICUBIC)
    full = Image.new('L', (W, H), 0)
    full.paste(m, (int(cx_ - rx), int(cy_ - ry)))
    return full

def solid(color): return Image.new('RGB', (W, H), color)
def scale(mask, f): return mask.point(lambda v: int(v * f))

img = solid(BG)
glow = radial(cx, cy, W * 0.85, H * 1.0, 1.0)
img.paste(solid(ACC), (0, 0), scale(glow, 0.17))
img.paste(solid((120, 130, 170)), (0, 0), scale(radial(W * 0.10, H * 0.02, W * 0.55, H * 0.7), 0.05))

# сетка 1px, шаг 48; видна слабо, ярче у свечения, гаснет к краям
step = max(8, round(48 * S))
grid = Image.new('L', (W, H), 0); gd = ImageDraw.Draw(grid)
for gx in range(0, W, step): gd.line([(gx, 0), (gx, H)], fill=255, width=1)
for gy in range(0, H, step): gd.line([(0, gy), (W, gy)], fill=255, width=1)
vign = radial(W / 2, H / 2, W * 0.80, H * 0.85, 0.9)
strength = ImageChops.add(scale(vign, 0.08), scale(glow, 0.17))
img.paste(solid((150, 175, 255)), (0, 0), ImageChops.multiply(grid, strength))

# кольца: рисуем в 2x и уменьшаем — тонкие и ровные
ss = 2
rings = Image.new('L', (W * ss, H * ss), 0); rd = ImageDraw.Draw(rings)
for r in (200, 330, 480, 660, 880, 1140, 1440):
    rr = r * S * ss
    rd.ellipse([cx * ss - rr, cy * ss - rr, cx * ss + rr, cy * ss + rr], outline=255, width=max(1, round(ss * 0.9)))
rings = rings.resize((W, H), Image.LANCZOS)
fade = radial(cx, cy, W * 0.75, H * 1.1, 0.8)
img.paste(solid((110, 150, 255)), (0, 0), ImageChops.multiply(rings, scale(fade, 0.55)))

# крошечные кресты на узлах сетки около свечения
marks = Image.new('L', (W, H), 0); md = ImageDraw.Draw(marks)
L = max(2, round(4 * S))
for i in range(int(cx // step) - 10, int(cx // step) + 11):
    for j in range(int(cy // step) - 7, int(cy // step) + 8):
        px, py = i * step, j * step
        if not (L < px < W - L and L < py < H - L): continue
        if (i + j) % 3: continue
        md.line([(px - L, py), (px + L, py)], fill=255); md.line([(px, py - L), (px, py + L)], fill=255)
mfade = radial(cx, cy, W * 0.38, H * 0.6, 1.0)
img.paste(solid((170, 195, 255)), (0, 0), ImageChops.multiply(marks, scale(mfade, 0.8)))

# лёгкое зерно против полос в градиентах
noise = Image.effect_noise((W, H), 6).point(lambda v: int(max(0, v - 128) * 0.35))
img = ImageChops.add(img, Image.merge('RGB', (noise, noise, noise)))
img.save(out, optimize=True); print(out, img.size)
