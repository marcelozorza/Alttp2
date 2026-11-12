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
# Famílias cujos vãos fechados dentro do corpo são preenchidos, e a cor usada
# quando não há outra em volta do vão.
# No macaco eles eram buracos: aparecia o chão entre o braço e o corpo e no
# lugar de um olho, e Marcelo viu o desenho "vazado" (2026-11-12).
FILL = {"monkey": "#3b2530"}


def _read(path):
    lines = path.read_text(encoding="utf-8").splitlines()
    start = lines.index("pixels") + 1
    first = lines.index("paleta")
    palette = dict(line.split() for line in lines[first + 1 : start - 1])
    return lines, first, start, palette


def _letter(lines, start, palette, color):
    """Letra da cor na paleta do arquivo, criada se faltar."""
    key = next((key for key, value in palette.items() if value.lower() == color), None)
    if key is None:
        key = next(c for c in string.ascii_letters if c not in palette)
        lines.insert(start - 1, "%s %s" % (key, color))
        palette[key] = color
        start += 1
    return key, start


def _outside(grid):
    """Casas transparentes ligadas à borda do quadro."""
    h, w = len(grid), len(grid[0])
    seen = {
        (x, y)
        for y in range(h)
        for x in range(w)
        if (x in (0, w - 1) or y in (0, h - 1)) and grid[y][x] == "."
    }
    queue = deque(seen)
    while queue:
        x, y = queue.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            a, b = x + dx, y + dy
            if 0 <= a < w and 0 <= b < h and grid[b][a] == "." and (a, b) not in seen:
                seen.add((a, b))
                queue.append((a, b))
    return seen


def fill(path, color):
    """Preenche os vãos fechados de um arquivo. Devolve quantos pixels."""
    lines, _, start, palette = _read(path)
    if any(line.startswith("usa ") for line in lines):
        return 0
    grid = [list(row) for row in lines[start:]]
    outside = _outside(grid)
    holes = {
        (x, y)
        for y in range(len(grid))
        for x in range(len(grid[0]))
        if grid[y][x] == "." and (x, y) not in outside
    }
    if not holes:
        return 0
    count = len(holes)
    # Cada vão recebe a cor que mais aparece em volta dele, fora a tinta: o
    # olho fica da cor do rosto e a fresta do braço, da cor do pelo.
    paint = {}
    while holes:
        region, queue = set(), deque([holes.pop()])
        while queue:
            x, y = queue.popleft()
            region.add((x, y))
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if (x + dx, y + dy) in holes:
                    holes.discard((x + dx, y + dy))
                    queue.append((x + dx, y + dy))
        votes = {}
        for x, y in region:
            for dy in range(-3, 4):
                for dx in range(-3, 4):
                    if 0 <= y + dy < len(grid) and 0 <= x + dx < len(grid[0]):
                        near = palette.get(grid[y + dy][x + dx], INK).lower()
                        if near != INK:
                            votes[near] = votes.get(near, 0) + 1
        paint[frozenset(region)] = max(votes, key=votes.get) if votes else color
    for region, tone in paint.items():
        key, shift = _letter(lines, start, palette, tone)
        start = shift
        for x, y in region:
            grid[y][x] = key
    path.write_text(
        "\n".join(lines[:start] + ["".join(row) for row in grid]) + "\n", encoding="utf-8"
    )
    return count


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
            if family in FILL:
                fill(path, FILL[family])
    return count


if __name__ == "__main__":
    print("%d quadros engrossados" % apply())
