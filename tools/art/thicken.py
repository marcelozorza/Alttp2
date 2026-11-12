"""Engrossa o contorno de fora dos personagens, para acompanhar o do Giorgino.

Pedido de Marcelo em 2026-11-12: o traço externo de todos os personagens tem
a grossura do traço do Giorgino (2 pixels), e o que está dentro do corpo fica
como está. O Giorgino tem 2 pixels de tinta em volta e os inimigos tinham 1.
Este script soma um anel de 1 pixel de tinta por fora da silhueta de cada
quadro, sem tocar em nenhum pixel que já existia. O desenho cresce 1 pixel
para cada lado. Os vãos fechados dentro do corpo (entre as pernas, na curva
do rabo) não ganham anel.

Cada arquivo engrossado leva a linha MARK no cabeçalho, então rodar de novo
não engrossa duas vezes. Os geradores dos inimigos e dos chefes chamam
apply() no fim, porque um quadro regravado volta com o contorno fino.

Uso: python3 tools/art/thicken.py && python3 tools/pixel_svg.py
"""

import string
from collections import deque
from pathlib import Path

SOURCE = Path(__file__).resolve().parents[2] / "art" / "source"
INK = "#1e181e"
MARK = "# Contorno de fora engrossado por tools/art/thicken.py."
FAMILIES = [
    "minion", "wolf", "bat", "snake", "armadillo", "ice_cube", "stalactite", "monkey",
    "sentinel", "crab", "cerberus",
]


def thicken(path):
    """Engrossa um arquivo. Devolve False se ele já estava engrossado."""
    lines = path.read_text(encoding="utf-8").splitlines()
    if MARK in lines or any(line.startswith("usa ") for line in lines):
        return False
    start = lines.index("pixels") + 1
    first = lines.index("paleta")
    palette = dict(line.split() for line in lines[first + 1 : start - 1])
    ink = next((key for key, color in palette.items() if color.lower() == INK), None)
    if ink is None:
        ink = next(c for c in string.ascii_letters if c not in palette)
        lines.insert(start - 1, "%s %s" % (ink, INK))
        start += 1
    rows = lines[start:]
    width = len(rows[0])
    grid = [list("." + row + ".") for row in rows]
    grid = [["."] * (width + 2)] + grid + [["."] * (width + 2)]
    h, w = len(grid), width + 2
    # Fundo de fora: o transparente ligado à borda do quadro.
    outside = {(0, 0)}
    queue = deque(outside)
    while queue:
        x, y = queue.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a, b = x + dx, y + dy
            if 0 <= a < w and 0 <= b < h and grid[b][a] == "." and (a, b) not in outside:
                outside.add((a, b))
                queue.append((a, b))
    ring = [
        (x, y)
        for x, y in outside
        if any(
            0 <= x + dx < w and 0 <= y + dy < h and grid[y + dy][x + dx] != "."
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
        )
    ]
    for x, y in ring:
        grid[y][x] = ink
    header = lines[:first] + [MARK] + lines[first:start]
    path.write_text("\n".join(header + ["".join(row) for row in grid]) + "\n", encoding="utf-8")
    return True


def apply(families=FAMILIES):
    """Engrossa todos os quadros das famílias dadas e devolve quantos mudou."""
    count = 0
    for family in families:
        for path in sorted(SOURCE.glob(family + "_*.txt")):
            count += thicken(path)
    return count


if __name__ == "__main__":
    print("%d quadros engrossados" % apply())
