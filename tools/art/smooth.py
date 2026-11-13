"""Alisa a silhueta de desenhos decalcados: tira as farpas de contorno (pontas
de 1 ou 2 pixels que sobram do decalque) e fecha os dentes (reentrâncias
estreitas na borda). Marcelo viu um "dent" no topo do macaco em 2026-11-13 e
pediu para procurar os defeitos na sprite toda.

Mexe só no texto de art/source: abre a silhueta (erosão e dilatação de 3 por
3, que apaga o que é mais fino que 3 pixels) e depois a fecha (dilatação e
erosão), pintando de contorno o que foi preenchido. Rodar de novo depois de
regerar a família em enemies.py.

Uso, de dentro de tools/art: python3 smooth.py monkey
"""

import sys

from canvas import SOURCE

INK = "#1e181e"
AROUND = [(dx, dy) for dy in (-1, 0, 1) for dx in (-1, 0, 1)]


def _erode(mask):
    h, w = len(mask), len(mask[0])
    return [
        [
            all(0 <= y + dy < h and 0 <= x + dx < w and mask[y + dy][x + dx] for dx, dy in AROUND)
            for x in range(w)
        ]
        for y in range(h)
    ]


def _dilate(mask):
    h, w = len(mask), len(mask[0])
    return [
        [
            any(0 <= y + dy < h and 0 <= x + dx < w and mask[y + dy][x + dx] for dx, dy in AROUND)
            for x in range(w)
        ]
        for y in range(h)
    ]


def smooth(path):
    lines = path.read_text().split("\n")
    start = lines.index("pixels") + 1
    ink = next(l.split()[0] for l in lines[:start] if l.endswith(INK) and not l.startswith("#"))
    rows = [list(row) for row in lines[start:] if row]
    mask = [[c != "." for c in row] for row in rows]
    opened = _dilate(_erode(mask))
    opened = [[a and b for a, b in zip(ra, rb)] for ra, rb in zip(opened, mask)]
    closed = _erode(_dilate(opened))
    changed = 0
    for y, row in enumerate(rows):
        for x, c in enumerate(row):
            keep = opened[y][x] or closed[y][x]
            if c != "." and not keep:
                row[x] = "."
                changed += 1
            elif c == "." and keep:
                row[x] = ink
                changed += 1
    # O que ficou na borda depois de tirar uma farpa vira contorno.
    h, w = len(rows), len(rows[0])
    for y in range(h):
        for x in range(w):
            if rows[y][x] in (".", ink):
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h) or rows[ny][nx] == ".":
                    rows[y][x] = ink
                    changed += 1
                    break
    path.write_text("\n".join(lines[:start] + ["".join(row) for row in rows]) + "\n")
    return changed


if __name__ == "__main__":
    for family in sys.argv[1:]:
        for source in sorted(SOURCE.glob(family + "_*.txt")):
            print(source.stem, smooth(source))
