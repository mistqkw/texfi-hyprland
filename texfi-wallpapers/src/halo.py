# -*- coding: utf-8 -*-
"""«Ореол» — не рельеф, а одно гладкое пятно света в углу кадра.

От matrix это отличается на уровне макроформы, а не только сида: там
источник формы — рельеф (гряды, нормаль, скользящий свет), здесь источник
формы — один радиальный градиент, посчитанный аналитически, без всякого
рельефа. Лёгкий fbm-шум добавлен поверх только затем, чтобы гладкое поле
не выглядело стерильным превью-градиентом из графического редактора —
доля шума в итоговой яркости небольшая, форму держит именно градиент.

Кадр в основном чёрный. Свечение занимает малую часть площади и лежит в
одном углу — так же, как в остальном ките свет всегда приходит с одной
стороны, а не заливает кадр целиком.

Акцент — один контур: тонкое кольцо на границе, где радиальная яркость
пересекает выбранный порог. Не порог по яркости пикселя (как в matrix),
а порог по расстоянию до центра — отсюда ровно одна чистая линия, а не
россыпь синих клеток там, где рельеф случайно оказался ярким.
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


def build(W, H, cell, gap, name, seed=5, focus=(0.80, 0.22), dark=True,
          radius_frac=0.30, power=2.6, ring_pos=0.62, ring_width=0.04,
          grain=0.14, dim=1.0, icon_zone=None):
    """dim и icon_zone работают как в matrix.py: домашний экран — та же
    сцена и тот же seed, только притушенная, с дополнительным гашением в
    полосе, где стоят иконки. Между lock и home ничего, кроме яркости, не
    меняется — свечение и кольцо остаются на тех же местах.
    """
    bg = INK if dark else PLATE
    lamp = (255, 255, 255) if dark else (14, 15, 17)
    acc = BLUEL if dark else BLUE
    img = Image.new('RGB', (W, H), bg)
    d = ImageDraw.Draw(img)
    cols, rows = W // cell, H // cell
    fx0, fy0 = focus[0]*cols, focus[1]*rows
    R = radius_frac * math.hypot(cols, rows)

    for cy in range(rows):
        for cx in range(cols):
            dist = math.hypot(cx-fx0, cy-fy0) / R
            core = (1.0 - smoothstep(dist)) ** power
            n = fbm(cx*0.06, cy*0.06, seed) - 0.5
            t = max(0.0, min(1.0, core + n*grain))

            is_ring = abs(dist - ring_pos) < ring_width
            if icon_zone is not None:
                top, bot = icon_zone
                v = cy / max(1, rows-1)
                if top <= v <= bot:
                    t *= 0.42
                else:
                    edge = min(abs(v-top), abs(v-bot))
                    t *= 0.42 + min(1.0, edge/0.10) * 0.58

            if t < 0.02 and not is_ring:
                continue

            base = lamp
            if is_ring:
                edge_k = 1.0 - abs(dist-ring_pos)/ring_width
                base = tuple(int(lamp[i] + (acc[i]-lamp[i])*edge_k) for i in range(3))
                t = max(t, 0.35 + 0.65*edge_k)
            # Кольцо гасится слабее остального - иначе на приглушённом
            # домашнем экране оно тонет первым, как и синий акцент в matrix.
            t *= dim ** (0.5 if is_ring else 1.0)
            color = tuple(int(bg[i] + (base[i]-bg[i])*t) for i in range(3))
            x0, y0 = cx*cell, cy*cell
            d.rectangle([x0, y0, x0+cell-gap-1, y0+cell-gap-1], fill=color)

    img.save(os.path.join(OUT, name), optimize=True)
    return name


for n in [build(1440, 3120, 12, 3, 'halo/phone/texfi-halo-1440x3120-dark-lock.png',
                seed=5, focus=(0.74, 0.16), radius_frac=0.34),
          build(1440, 3120, 12, 3, 'halo/phone/texfi-halo-1440x3120-dark-home.png',
                seed=5, focus=(0.74, 0.16), radius_frac=0.34, dim=0.55,
                icon_zone=(0.30, 0.97)),
          build(2560, 1440, 14, 3, 'halo/desktop/texfi-halo-2560x1440-dark.png',
                seed=5),
          build(1920, 1080, 11, 3, 'halo/desktop/texfi-halo-1920x1080-dark.png',
                seed=5),
          build(2560, 1440, 14, 3, 'halo/desktop/texfi-halo-2560x1440-dark-calm.png',
                seed=5, dim=0.6)]:
    print(n, round(os.path.getsize(os.path.join(OUT, n))/1024), 'КБ')
