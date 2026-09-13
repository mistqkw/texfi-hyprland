# -*- coding: utf-8 -*-
"""«Горизонт» — пейзаж, вычисленный, а не снятый.

Объём здесь делается единственным способом, который есть у пиксельной
графики: не размытием, а плотностью решётки. Полутонов не существует —
есть матрица Байера, которая решает, какая клетка какого цвета. Отсюда и
всё остальное: дымка на дальних грядах, освещённые склоны, ореол светила
и отражение внизу — всё это одна и та же операция с разной плотностью.
"""
import math, os
from PIL import Image, ImageDraw

OUT = '/tmp/claude-1000/-home-mista--------/c81872d7-c4ff-4b62-998d-763257e21816/scratchpad/art'
INK, PLATE = (14, 15, 17), (237, 239, 241)
BLUE, BLUEL = (42, 99, 255), (76, 124, 255)

BAYER8 = [
    [ 0,32, 8,40, 2,34,10,42],[48,16,56,24,50,18,58,26],
    [12,44, 4,36,14,46, 6,38],[60,28,52,20,62,30,54,22],
    [ 3,35,11,43, 1,33, 9,41],[51,19,59,27,49,17,57,25],
    [15,47, 7,39,13,45, 5,37],[63,31,55,23,61,29,53,21],
]

def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(a[i] + (b[i]-a[i])*t) for i in range(3))

def on(bx, by, t):
    """Решение матрицы: включена ли клетка при плотности t (0..1)."""
    return t * 64 > BAYER8[by % 8][bx % 8]

def hashed(x, y, seed=1):
    x, y, seed = int(x), int(y), int(seed*1000)
    h = (x*374761393 + y*668265263 + seed*2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h ^= h >> 16
    return (h & 0xFFFF) / 0xFFFF

def ridge(cols, seed, rough, base):
    """Силуэт гряды: три гармоники со сглаживанием.

    Шума по колонке нет намеренно: он давал одиночные пики в один блок, и
    гряда читалась осциллограммой. Рваность даёт третья гармоника,
    скользящее среднее срезает то, что осталось острого.
    """
    raw = []
    for x in range(cols+1):
        v = (math.sin(x/cols*math.pi*2 + seed)*0.5
             + math.sin(x/cols*math.pi*5.3 + seed*2)*0.22
             + math.sin(x/cols*math.pi*11.7 + seed*3)*0.09)
        raw.append(base + v*rough)
    k = max(2, cols//90)
    return [sum(raw[max(0,i-k):i+k+1])/len(raw[max(0,i-k):i+k+1]) for i in range(len(raw))]

def build(W, H, cell, name, dark=True, sky_to=0.62, water=True):
    bg = INK if dark else PLATE
    tone = (255,255,255) if dark else (14,15,17)
    sun_c = BLUEL if dark else BLUE
    img = Image.new('RGB', (W, H), bg)
    d = ImageDraw.Draw(img)
    cols, rows = math.ceil(W/cell), math.ceil(H/cell)
    hz = int(rows*sky_to)
    # Береговая линия. Гряды кончаются на ней, ниже — вода. Без этого
    # гряда доходила до нижнего края, а рябь рисовалась поверх неё, и
    # выходила вода на склоне горы.
    wline = int(rows*0.80) if water else rows

    def put(bx, by, color):
        d.rectangle([bx*cell, by*cell, (bx+1)*cell, (by+1)*cell], fill=color)

    sun = (int(cols*0.66), int(hz*0.40))
    sun_r = max(2, int(cols*0.032))

    # --- Небо: плотность растёт к горизонту, у зенита почти чисто -------
    # На светлой теме тот же дитеринг звучит заметно громче: тёмная точка
    # на светлом бросается в глаза сильнее, чем светлая на тёмном. Отсюда
    # и разная сила — иначе небо превращается в плотную синюю сетку.
    sky_hi = mix(bg, BLUEL if dark else BLUE, 0.22 if dark else 0.16)
    for by in range(hz):
        t = (by/hz) ** 1.5 * (0.75 if dark else 0.42)
        for bx in range(cols):
            if on(bx, by, t):
                put(bx, by, sky_hi)

    # --- Звёзды: только в тёмной теме и только вверху ------------------
    # У горизонта их нет: там небо светлее, и звезда там читалась бы
    # грязью, а не звездой.
    if dark:
        for by in range(int(hz*0.72)):
            fade = 1.0 - by/(hz*0.72)
            for bx in range(cols):
                h = hashed(bx, by, 11)
                if h > 1 - 0.012*fade:
                    put(bx, by, mix(bg, tone, 0.55 if h > 0.9975 else 0.3))

    # --- Ореол светила: ступенчатые кольца, а не размытие ---------------
    halo = sun_r*4.5
    for by in range(max(0, int(sun[1]-halo)), min(hz, int(sun[1]+halo))):
        for bx in range(max(0, int(sun[0]-halo)), min(cols, int(sun[0]+halo))):
            dist = math.hypot(bx-sun[0], by-sun[1])
            if dist <= sun_r:
                put(bx, by, sun_c)
            elif dist < halo:
                t = (1 - (dist-sun_r)/(halo-sun_r)) ** 2.3
                if on(bx, by, t):
                    put(bx, by, mix(bg, sun_c, 0.55))

    # --- Гряды: дальние светлее и в дымке, ближние плотнее --------------
    # (сид, размах, тон, дымка). Тон — удалённость от фона к контрастному.
    #
    # Порядок тонов зависит от темы, и это не придирка. Ночью дальние гряды
    # поднимает дымка: они светлее ближних, а ближние проваливаются почти
    # в чёрный и читаются только на фоне подсвеченного неба. Днём наоборот:
    # дальнее выцветает к белому, ближнее набирает плотность. Один и тот же
    # порядок на обеих темах давал перевёрнутую глубину — дальнее выходило
    # ближе ближнего.
    plans = [(0.0, 0.30, 0.175, 0.85), (1.7, 0.20, 0.105, 0.45), (3.4, 0.12, 0.05, 0.0)]
    if not dark:
        tones = [p[2] for p in plans][::-1]
        plans = [(p[0], p[1], tones[i], p[3]) for i, p in enumerate(plans)]
    for i, (seed, rough, base_tone, haze) in enumerate(plans):
        base = hz + rows*0.055*i
        prof = ridge(cols, seed, rows*rough, base)
        body = mix(bg, tone, base_tone)
        lit  = mix(bg, tone, base_tone*1.9)
        for bx in range(cols):
            top = int(prof[bx])
            # Склон, отвёрнутый от светила, темнее; обращённый — светлее.
            # Наклон берётся по соседним колонкам: это и есть «свет сбоку».
            slope = prof[min(cols, bx+1)] - prof[max(0, bx-1)]
            toward = (sun[0] - bx)
            facing = (slope > 0) == (toward > 0)
            silhouette = dark and i == len(plans)-1
            for by in range(top, wline):
                depth = by - top
                # Дымка: у самой кромки дальняя гряда почти растворена в
                # небе и набирает плотность вниз. Так дальнее и читается
                # дальним — без единого размытия.
                if haze > 0 and depth < rows*0.10:
                    t = (depth/(rows*0.10)) ** 0.8
                    if not on(bx, by, t*(1-haze) + (1-haze)*0.15):
                        continue
                # Освещённая полоса под кромкой — объём склона.
                if facing and not silhouette and depth < max(2, rows*0.035):
                    t = 1 - depth/max(2, rows*0.035)
                    put(bx, by, lit if on(bx, by, t) else body)
                else:
                    put(bx, by, body)

    # --- Вода: горизонтальные полосы и отражение светила ---------------
    if water:
        wtop = wline
        # Вода темнее всего у берега и светлеет к зрителю — так читается
        # плоскость, уходящая вдаль, а не вертикальная стена.
        for by in range(wtop, rows):
            k = (by - wtop) / max(1, rows - wtop)
            base_w = mix(bg, tone, 0.03 + k*0.06)
            for bx in range(cols):
                put(bx, by, base_w)
        # Рябь: редкие горизонтальные штрихи, ближе к зрителю длиннее.
        # Частая рябь читалась пунктиром и тянула взгляд на себя — вода
        # должна лежать под сценой, а не спорить с ней.
        wcol = mix(bg, tone, 0.11)
        for by in range(wtop, rows):
            k = (by - wtop) / max(1, rows - wtop)
            if by % max(3, int(3 + k*5)):
                continue
            run = max(2, int(3 + k*9))
            for bx in range(cols):
                if hashed(bx//run, by, 5) > 0.72:
                    put(bx, by, wcol)
        # Дорожка от светила: расходится книзу и редеет. Узкий конус
        # читался не отражением, а деревцем посреди воды.
        base_w = max(4, int(cols*0.035))
        for by in range(wtop, rows):
            k = (by - wtop) / max(1, rows - wtop)
            spread = int(base_w + k * cols * 0.16)
            for bx in range(sun[0]-spread, sun[0]+spread+1):
                if not (0 <= bx < cols):
                    continue
                # Край дорожки спадает полого: острый давал треугольник,
                # и отражение читалось ёлкой, а не бликом на воде.
                edge = (1 - abs(bx - sun[0]) / max(1, spread)) ** 0.55
                if on(bx, by, edge * (0.8 - k*0.35)):
                    put(bx, by, mix(bg, sun_c, 0.30 if dark else 0.20))

    img.save(os.path.join(OUT, name), optimize=True)
    return name

for n in [build(2560, 1440, 10, 'texfi-horizon-2560x1440-dark.png',  True,  0.62),
          build(2560, 1440, 10, 'texfi-horizon-2560x1440-light.png', False, 0.62),
          build(1920, 1080, 8,  'texfi-horizon-1920x1080-dark.png',  True,  0.62),
          build(1920, 1080, 8,  'texfi-horizon-1920x1080-light.png', False, 0.62),
          build(1440, 3120, 9,  'texfi-horizon-1440x3120-dark.png',  True,  0.70),
          build(1440, 3120, 9,  'texfi-horizon-1440x3120-light.png', False, 0.70)]:
    print(n, round(os.path.getsize(os.path.join(OUT,n))/1024), 'КБ')
