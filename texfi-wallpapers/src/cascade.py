# -*- coding: utf-8 -*-
"""«Каскад» — обои из грамматики знака, а не из самого знака.

Ставить логотип на обои нельзя: это уже не обои, а реклама на своём же
телефоне. Но у знака есть то, что работает и без него — строй. Строки
выровнены по правому краю, каждая следующая короче, и всё заканчивается
квадратным блоком-курсором: местом, где система продолжает писать.

Этот строй и разложен на весь кадр. Пропорции взяты из брендбука без
пересчёта: штрих к шагу как 12 к 18, то есть четыре клетки к шести.
Длины строк кратны шести клеткам — тому же шагу, которым в знаке сдвинута
вторая строка относительно первой.

Плоским это было бы, если бы все строки светились одинаково. Поэтому
яркость каждой клетки берётся из того же поля света, что и в «Матрице»:
строки выходят из темноты по диагонали и в неё же уходят. Цветным, как и
положено, бывает только курсор — и только там, куда дошёл свет.
"""
import math, os, random
from PIL import Image, ImageDraw

OUT = '/tmp/claude-1000/-home-mista--------/c81872d7-c4ff-4b62-998d-763257e21816/scratchpad/art'
INK   = (14, 15, 17)
PLATE = (237, 239, 241)
BLUE  = (42, 99, 255)
BLUEL = (76, 124, 255)

def lattice(ix, iy, seed):
    h = (ix*374761393 + iy*668265263 + seed*2246822519) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    h ^= h >> 16
    return (h & 0xFFFF) / 0xFFFF

def smooth(t):
    return t*t*(3 - 2*t)

def value_noise(x, y, seed):
    ix, iy = math.floor(x), math.floor(y)
    fx, fy = smooth(x-ix), smooth(y-iy)
    a = lattice(ix,   iy,   seed); b = lattice(ix+1, iy,   seed)
    c = lattice(ix,   iy+1, seed); d = lattice(ix+1, iy+1, seed)
    return (a*(1-fx) + b*fx)*(1-fy) + (c*(1-fx) + d*fx)*fy

def fbm(x, y, seed, octaves=4, falloff=0.42):
    v, amp, norm, f = 0.0, 1.0, 0.0, 1.0
    for o in range(octaves):
        v += value_noise(x*f, y*f, seed+o) * amp
        norm += amp; amp *= falloff; f *= 2.0
    return v / norm

def clamp(v, a=0.0, b=1.0):
    return a if v < a else (b if v > b else v)


# --- строй --------------------------------------------------------------
# Абзац строится ровно как знак: несколько строк с общим правым краем,
# каждая короче предыдущей, и курсор под последней.

STROKE = 4     # клеток — штрих (12 единиц брендбука)
STEP   = 6     # клеток — шаг между строками (18 единиц)
QUANT  = 6     # квант длины строки — тот же шаг

def paragraphs(rows, cols, seed, margin_right=5, margin_left=5):
    rnd = random.Random(seed)
    maxlen = cols - margin_right - margin_left
    maxlen -= maxlen % QUANT
    bars = []          # (row0, col0, width, is_cursor)
    slot = 1
    nslots = (rows - 1) // STEP
    while slot < nslots:
        n = rnd.choice([3, 4, 4, 5, 5, 6])
        # Абзац начинается длинной строкой — иначе каскаду неоткуда падать
        # и весь строй прижимается к правому краю.
        length = rnd.randrange(int(maxlen*0.72)//QUANT, maxlen//QUANT + 1) * QUANT
        for i in range(n):
            if slot >= nslots: break
            r0 = slot * STEP
            bars.append((r0, cols - margin_right - length, length, False))
            # Сокращение всегда есть: две строки одной длины — это уже не
            # каскад, а таблица.
            length -= rnd.choice([1, 1, 2, 3]) * QUANT
            if length < QUANT: length = QUANT
            slot += 1
        if slot < nslots:
            r0 = slot * STEP
            bars.append((r0, cols - margin_right - STROKE, STROKE, True))
            slot += 1
        slot += 1   # одна пустая строка между абзацами
    return bars


def build(W, H, cell, gap, name, seed=11, dark=True, dim=1.0,
          icon_zone=None, tilt=0.5, margin_right=5):
    pitch = cell + gap
    cols, rows = W // pitch, H // pitch
    ox = (W - cols*pitch + gap) // 2
    oy = (H - rows*pitch + gap) // 2

    bg   = INK if dark else PLATE
    lamp = PLATE if dark else INK
    acc  = BLUEL if dark else BLUE

    # Поле света — то же, что в «Матрице»: крупная форма, вытянутая вдоль
    # строк, чтобы свет шёл полосами, а не пятнами.
    # Поперёк строк шум должен меняться медленно: на высокой частоте кадр
    # распадается на светлые и тёмные полосы, и нижняя треть гаснет
    # целиком.
    fa, fc = 0.9 / cols, 1.0 / cols
    def light(cx, cy):
        h = fbm(cx*fa, (cy - cx*tilt)*fc, seed)
        u, v = cx/(cols-1), cy/(rows-1)
        # Свет идёт справа. Это не вкусовщина: правый край — единственная
        # общая черта у всех строк и у знака, и растворяться должен
        # рваный левый конец, а не она.
        reach = (1 - u)
        # Затухание пологое. Крутое обрубало левые концы строк раньше,
        # чем они успевали появиться, и треть кадра стояла пустой.
        k = max(0.0, 1.0 - reach*0.60) ** 0.85
        # Вертикаль только подмешивается шумом, иначе кадр распадается на
        # светлую и тёмную половины.
        return (0.52 + (h-0.5)*0.90) * k

    bars = paragraphs(rows, cols, seed, margin_right=margin_right)
    # Карта: какие клетки заняты строками и какие из них курсор.
    occ = {}
    for r0, c0, w, is_cur in bars:
        for r in range(r0, min(r0+STROKE, rows)):
            for c in range(max(0, c0), min(c0+w, cols)):
                occ[(r, c)] = is_cur

    # Нормировка по занятым клеткам: если считать по всему кадру, пустой
    # фон утянет шкалу вниз и строки выгорят в белое.
    vals = sorted(light(c, r) for (r, c) in occ)
    # Нижний перцентиль почти нулевой: именно в этом хвосте живут левые
    # концы строк, и если срезать его, они исчезнут.
    lo = vals[int(len(vals)*0.05)]
    hi = vals[int(len(vals)*0.99)]
    rng = max(1e-6, hi - lo)

    img = Image.new('RGB', (W, H), bg)
    d = ImageDraw.Draw(img)
    side = cell

    for r in range(rows):
        for c in range(cols):
            key = (r, c)
            on = key in occ
            t = clamp((light(c, r) - lo) / rng) ** 1.2
            if on:
                is_cur = occ[key]
                base = acc if is_cur else lamp
                # У курсора есть нижний порог яркости. Приглушённый синий
                # перестаёт быть Signal Blue и становится просто серо-голубым
                # пятном — а это единственное цветное место в кадре, и оно
                # должно звучать в полную силу везде, куда попало.
                k = max(t, 0.62) if is_cur else t
            else:
                # Фон не пустой: та же сетка, но на пороге видимости. Без
                # неё строки висят в вакууме, и кадр опять становится
                # плоским.
                base = lamp
                k = t * 0.085
            k *= dim
            if icon_zone:
                top, bot = icon_zone
                v = r/(rows-1)
                if top <= v <= bot:
                    k *= 0.45
                else:
                    edge = min(abs(v-top), abs(v-bot))
                    k *= 0.45 + min(1.0, edge/0.10)*0.55
            if k <= 0.004:
                continue
            col = tuple(int(bg[i] + (base[i]-bg[i])*k) for i in range(3))
            x0 = ox + c*pitch
            y0 = oy + r*pitch
            d.rectangle([x0, y0, x0+side-1, y0+side-1], fill=col)

    os.makedirs(OUT, exist_ok=True)
    p = os.path.join(OUT, name)
    img.save(p)
    print(p, W, 'x', H, '|', cols, 'x', rows, 'клеток |', len(bars), 'строк')
    return p

if __name__ == '__main__':
    # Телефон. Замок — в полную силу, домашний — приглушённый, с провалом
    # в зоне иконок: проверено, что иначе подписи под иконками тонут.
    for dark in (True, False):
        tag = 'dark' if dark else 'light'
        build(1440, 3120, 12, 3, f'texfi-cascade-1440x3120-{tag}-lock.png',
              seed=11, dark=dark)
        build(1440, 3120, 12, 3, f'texfi-cascade-1440x3120-{tag}-home.png',
              seed=11, dark=dark, dim=0.52, icon_zone=(0.26, 0.97))
    # Десктоп. Клетка мельче, чем на телефоне: высота кадра втрое меньше,
    # и на крупной клетке в него влезает десяток строк — это читается уже
    # не как текст, а как жалюзи.
    for dark in (True, False):
        tag = 'dark' if dark else 'light'
        build(2560, 1440, 9, 2, f'texfi-cascade-2560x1440-{tag}.png',
              seed=23, dark=dark, margin_right=8)
    build(1920, 1080, 7, 2, 'texfi-cascade-1920x1080-dark.png',
          seed=23, dark=True, margin_right=8)
    build(2560, 1440, 9, 2, 'texfi-cascade-2560x1440-dark-calm.png',
          seed=23, dark=True, dim=0.58, margin_right=8)
