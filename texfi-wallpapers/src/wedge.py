# -*- coding: utf-8 -*-
"""«Клин» — луч прожектора из угла, а не окружность и не рельеф.

Форма держится на двух прямых — границах углового сектора из вершины в
углу кадра, а не на расстоянии до точки (как halo) и не на шуме по сетке
(как matrix). Яркость гладко падает по двум осям сразу: вдоль луча —
к дальнему концу, поперёк — к границам сектора. Лёгкий fbm-шум добавлен
поверх тем же способом, что и в halo — органика без потери гладкости.

Акцент — одна прямая линия по верхней границе клина, а не по яркости:
там, где угол до этой границы меньше порога. Ровно один штрих на весь
кадр, как и в остальном ките.

Кадр в основном чёрный: клин занимает свой угол, свет по-прежнему
приходит с одной стороны, а не заливает всё вокруг.
"""
import math, os
from PIL import Image, ImageDraw

OUT = '/home/mista/Загрузки/texfi kit v2'
INK, PLATE = (14, 15, 17), (237, 239, 241)
BLUE, BLUEL = (42, 99, 255), (76, 124, 255)


def lattice(ix, iy, seed):
    h = (ix*374761393 + iy*668265263 + seed*2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h ^= h >> 16
    return (h & 0xFFFF) / 0xFFFF


def smoothstep(t):
    t = max(0.0, min(1.0, t))
    return t*t*(3 - 2*t)


def value_noise(x, y, seed):
    ix, iy = math.floor(x), math.floor(y)
    fx, fy = smoothstep(x-ix), smoothstep(y-iy)
    a = lattice(ix,   iy,   seed); b = lattice(ix+1, iy,   seed)
    c = lattice(ix,   iy+1, seed); d = lattice(ix+1, iy+1, seed)
    return (a*(1-fx) + b*fx)*(1-fy) + (c*(1-fx) + d*fx)*fy


def fbm(x, y, seed, octaves=3, falloff=0.5):
    v, amp, norm, f = 0.0, 1.0, 0.0, 1.0
    for o in range(octaves):
        v += value_noise(x*f, y*f, seed+o) * amp
        norm += amp; amp *= falloff; f *= 2.0
    return v / norm


def build(W, H, cell, gap, name, seed, apex, angle_center_deg, angle_span_deg,
          dark=True, length_frac=0.95, accent_side='upper',
          accent_width_deg=1.4, grain=0.10, dim=1.0, icon_zone=None):
    """dim и icon_zone - как в matrix.py/halo.py: -home - тот же кадр и тот
    же seed, только притушенный, с дополнительным гашением в зоне иконок.
    """
    bg = INK if dark else PLATE
    lamp = (255, 255, 255) if dark else (14, 15, 17)
    acc = BLUEL if dark else BLUE
    img = Image.new('RGB', (W, H), bg)
    d = ImageDraw.Draw(img)
    cols, rows = W // cell, H // cell
    ax, ay = apex[0]*cols, apex[1]*rows
    ac = math.radians(angle_center_deg)
    half = math.radians(angle_span_deg/2)
    max_len = length_frac * math.hypot(cols, rows)
    upper_angle = ac - half
    lower_angle = ac + half

    for cy in range(rows):
        for cx in range(cols):
            dx, dy = cx-ax, cy-ay
            dist = math.hypot(dx, dy)
            if dist < 1e-6:
                continue
            ang = math.atan2(dy, dx)
            da = (ang - ac + math.pi) % (2*math.pi) - math.pi
            if abs(da) > half + math.radians(2):
                continue
            along = max(0.0, 1.0 - dist/max_len)
            across = 1.0 - smoothstep(abs(da)/half)
            core = (along ** 1.3) * (across ** 1.6)
            n = fbm(cx*0.05, cy*0.05, seed) - 0.5
            t = max(0.0, min(1.0, core + n*grain*core))

            da_upper = (ang - upper_angle + math.pi) % (2*math.pi) - math.pi
            da_lower = (ang - lower_angle + math.pi) % (2*math.pi) - math.pi
            edge_da = da_upper if accent_side == 'upper' else da_lower
            aw = math.radians(accent_width_deg)
            is_accent = abs(edge_da) < aw and dist < max_len

            if icon_zone is not None:
                top, bot = icon_zone
                v = cy / max(1, rows-1)
                if top <= v <= bot:
                    t *= 0.42
                else:
                    edge = min(abs(v-top), abs(v-bot))
                    t *= 0.42 + min(1.0, edge/0.10) * 0.58

            if t < 0.02 and not is_accent:
                continue
            base = lamp
            if is_accent:
                k = (1.0 - abs(edge_da)/aw) * along
                k = max(0.0, min(1.0, k*1.3))
                base = tuple(int(lamp[i] + (acc[i]-lamp[i])*k) for i in range(3))
                t = max(t, 0.25 + 0.7*k)
            t *= dim ** (0.5 if is_accent else 1.0)
            color = tuple(int(bg[i] + (base[i]-bg[i])*t) for i in range(3))
            x0, y0 = cx*cell, cy*cell
            d.rectangle([x0, y0, x0+cell-gap-1, y0+cell-gap-1], fill=color)

    img.save(os.path.join(OUT, name), optimize=True)
    return name


for n in [build(1440, 3120, 12, 3, 'wedge/phone/texfi-wedge-1440x3120-dark-lock.png',
                seed=17, apex=(0.02, 0.02), angle_center_deg=62, angle_span_deg=26),
          build(1440, 3120, 12, 3, 'wedge/phone/texfi-wedge-1440x3120-dark-home.png',
                seed=17, apex=(0.02, 0.02), angle_center_deg=62, angle_span_deg=26,
                dim=0.55, icon_zone=(0.30, 0.97)),
          build(2560, 1440, 14, 3, 'wedge/desktop/texfi-wedge-2560x1440-dark.png',
                seed=17, apex=(0.06, 0.02), angle_center_deg=48, angle_span_deg=30),
          build(1920, 1080, 11, 3, 'wedge/desktop/texfi-wedge-1920x1080-dark.png',
                seed=17, apex=(0.06, 0.02), angle_center_deg=48, angle_span_deg=30),
          build(2560, 1440, 14, 3, 'wedge/desktop/texfi-wedge-2560x1440-dark-calm.png',
                seed=17, apex=(0.06, 0.02), angle_center_deg=48, angle_span_deg=30,
                dim=0.6)]:
    print(n, round(os.path.getsize(os.path.join(OUT, n))/1024), 'КБ')
