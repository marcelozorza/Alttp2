"""Gera a pixel art da gosma do ugly, em art/source/goo_*.txt.

Marcelo pediu em 2026-11-08 que a granada do ugly vire um blob de gosma
magenta, que o estouro seja respingo dessa mesma cor e que a área atingida
tenha textura de líquido pegajoso. Saem quatro desenhos:

- goo_blob_1 e goo_blob_2: a bola de gosma em voo, esticada e achatada, 16x16.
- goo_splash_1 a goo_splash_3: o respingo do estouro, crescendo com gotas
  voando para fora.
- goo_puddle: a poça pegajosa que fica no chão depois do estouro, com borda
  escura, brilhos, bolhas e fios.
- goo_target: só a borda pontilhada da poça, a marca de onde a gosma vai cair.
- goo_coat: a gosma grudada no Giorgino enquanto a espada está travada, 48x48.
  O shader player/goo_coat.gdshader pinta esse desenho só onde a sprite tem
  pixel, a partir do alto dela, então a gosma cobre a cabeça e escorre pelo
  corpo em qualquer pose.

Os desenhos do estouro são feitos em 48 por 48 e ampliados 2 vezes, para
96 por 96, a área de 3 por 3 casas, como a explosão da bomba. As formas são
círculos sorteados com semente fixa, então o resultado é sempre o mesmo.

Uso: python3 tools/goo_art.py && python3 tools/pixel_svg.py
"""

import math
import pathlib
import random

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "art" / "source"
SIZE = 48
SCALE = 2
CENTER = (SIZE - 1) / 2.0
PALETTE = {
    "o": "#4a0c40",
    "d": "#8e2280",
    "p": "#d24cbc",
    "l": "#ef80dc",
    "h": "#ffd2f4",
}


def inside(circles, x, y):
    return any(math.hypot(x - cx, y - cy) < r for cx, cy, r in circles)


def lobes(rng, count, distance, radius):
    out = []
    for i in range(count):
        angle = (i + rng.uniform(-0.3, 0.3)) * 2.0 * math.pi / count
        d = rng.uniform(*distance)
        out.append((CENTER + math.cos(angle) * d, CENTER + math.sin(angle) * d, rng.uniform(*radius)))
    return out


def droplets(rng, count, distance, radius):
    out = []
    for _ in range(count):
        angle = rng.uniform(0.0, 2.0 * math.pi)
        d = rng.uniform(*distance)
        out.append((CENTER + math.cos(angle) * d, CENTER + math.sin(angle) * d, rng.uniform(*radius)))
    return out


def shape(circles, size):
    return [[inside(circles, x, y) for x in range(size)] for y in range(size)]


def edge_distance(mask):
    """Distância de cada pixel de dentro até a borda, em passos."""
    size = len(mask)
    dist = [[0 if mask[y][x] else -1 for x in range(size)] for y in range(size)]
    frontier = []
    for y in range(size):
        for x in range(size):
            if not mask[y][x]:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < size and 0 <= ny < size) or not mask[ny][nx]:
                    dist[y][x] = 1
                    frontier.append((x, y))
                    break
    step = 1
    while frontier:
        step += 1
        nxt = []
        for x, y in frontier:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < size and 0 <= ny < size and mask[ny][nx] and dist[ny][nx] == 0:
                    dist[ny][nx] = step
                    nxt.append((nx, ny))
        frontier = nxt
    return dist


def paint(circles, size, rng, bubbles=0):
    """Gosma com contorno escuro, sombra embaixo à direita e brilho em cima à
    esquerda de cada círculo, mais bolhas claras espalhadas."""
    mask = shape(circles, size)
    dist = edge_distance(mask)
    grid = [["." for _ in range(size)] for _ in range(size)]
    for y in range(size):
        for x in range(size):
            if not mask[y][x]:
                continue
            if dist[y][x] == 1:
                grid[y][x] = "o"
                continue
            grid[y][x] = "p"
            # sombra no lado de baixo à direita, perto da borda
            for cx, cy, r in circles:
                d = math.hypot(x - cx, y - cy)
                if d < r and r >= 2.5:
                    rx, ry = (x - cx) / r, (y - cy) / r
                    if rx * 0.6 + ry * 0.8 > 0.55 and dist[y][x] <= 3:
                        grid[y][x] = "d"
    # brilho: um arco claro no alto à esquerda de cada círculo grande
    for cx, cy, r in circles:
        if r < 3.0:
            continue
        for a in range(200, 260, 6):
            angle = math.radians(a)
            for k in (0.55, 0.62):
                x = int(round(cx + math.cos(angle) * r * k))
                y = int(round(cy + math.sin(angle) * r * k))
                if 0 <= x < size and 0 <= y < size and grid[y][x] in "pd":
                    grid[y][x] = "l"
        x = int(round(cx - r * 0.35))
        y = int(round(cy - r * 0.45))
        if 0 <= x < size and 0 <= y < size and grid[y][x] in "pdl":
            grid[y][x] = "h"
    # bolhas: anel claro com miolo branco
    for _ in range(bubbles):
        for _try in range(20):
            x, y = rng.randrange(size), rng.randrange(size)
            if dist[y][x] >= 4:
                break
        else:
            continue
        grid[y][x] = "h"
        for dx, dy in ((1, 0), (0, 1)):
            if grid[y + dy][x + dx] in "pd":
                grid[y + dy][x + dx] = "l"
    return grid


def big_bubbles(grid, rng, count):
    """Bolhas grandes presas na gosma: anel escuro, miolo claro e um ponto de
    brilho no alto à esquerda, para a superfície parecer grossa e grudenta."""
    size = len(grid)
    pattern = [".dd.", "dhld", "dlld", ".dd."]
    for _ in range(count):
        for _try in range(40):
            cx, cy = rng.randrange(2, size - 6), rng.randrange(2, size - 6)
            box = [(cx + i, cy + j) for j in range(-1, 5) for i in range(-1, 5)]
            if all(grid[y][x] in "pl" for x, y in box):
                break
        else:
            continue
        for j, row in enumerate(pattern):
            for i, ch in enumerate(row):
                if ch != ".":
                    grid[cy + j][cx + i] = ch


def strings(grid, rng, circles, count):
    """Fios pegajosos de 1 pixel ligando gotas soltas ao centro."""
    for cx, cy, r in circles[:count]:
        steps = int(math.hypot(cx - CENTER, cy - CENTER))
        for i in range(steps):
            t = i / max(steps, 1)
            x = int(round(cx + (CENTER - cx) * t))
            y = int(round(cy + (CENTER - cy) * t))
            if grid[y][x] == ".":
                grid[y][x] = "o"


def puddle_circles(rng):
    body = [(CENTER, CENTER, 14.0)] + lobes(rng, 9, (11.0, 16.0), (5.0, 7.5))
    drops = droplets(rng, 6, (21.5, 22.5), (1.8, 2.3))
    return body, drops


def build():
    rng = random.Random(11)
    out = {}
    # bola em voo, esticada na vertical e achatada na horizontal
    tall = [(7.5, 9.0, 5.5), (7.5, 5.5, 4.5), (9.5, 12.0, 3.0), (5.0, 12.5, 2.2)]
    wide = [(7.5, 9.5, 5.5), (4.5, 9.5, 4.0), (10.5, 9.5, 4.0), (8.0, 13.0, 2.4)]
    out["goo_blob_1"] = (paint(tall, 16, rng), 1)
    out["goo_blob_2"] = (paint(wide, 16, rng), 1)
    body, drops = puddle_circles(random.Random(5))
    # respingo: o miolo cresce e as gotas voam para fora
    small = [(CENTER, CENTER, 7.0)] + lobes(rng, 5, (5.0, 7.0), (3.0, 4.5))
    flying = droplets(rng, 8, (12.0, 15.0), (2.2, 3.0))
    out["goo_splash_1"] = (paint(small + flying, SIZE, rng), SCALE)
    mid = [(CENTER, CENTER, 11.0)] + lobes(rng, 7, (8.0, 12.0), (4.0, 6.0))
    flying = droplets(rng, 10, (17.0, 20.0), (2.2, 3.0))
    out["goo_splash_2"] = (paint(mid + flying, SIZE, rng), SCALE)
    flying = droplets(rng, 10, (20.0, 21.5), (2.2, 2.8))
    out["goo_splash_3"] = (paint(body + flying, SIZE, rng, 6), SCALE)
    grid = paint(body + drops, SIZE, random.Random(3), 14)
    big_bubbles(grid, random.Random(9), 6)
    strings(grid, rng, drops, 4)
    out["goo_puddle"] = (grid, SCALE)
    # marca do alvo: borda pontilhada da mesma poça
    mask = shape(body, SIZE)
    dist = edge_distance(mask)
    target = [["." for _ in range(SIZE)] for _ in range(SIZE)]
    for y in range(SIZE):
        for x in range(SIZE):
            if dist[y][x] == 1 and (x + y) % 3 != 0:
                target[y][x] = "p"
    out["goo_target"] = (target, SCALE)
    out["goo_coat"] = (coat(random.Random(21)), 1)
    return out


def coat(rng):
    """Capa de gosma de cima para baixo: cobre o alto, com a borda de baixo
    irregular, escorridos finos e respingos soltos mais embaixo."""
    size = 48
    circles = [(x, rng.uniform(4.0, 9.0), rng.uniform(4.0, 6.5)) for x in range(-2, size + 4, 5)]
    for x in range(1, size, 7):
        length = rng.uniform(12.0, 24.0)
        y = 8.0
        while y < length:
            circles.append((x + rng.uniform(-0.6, 0.6), y, 1.4))
            y += 1.0
        circles.append((x, length, 2.3))
    for _ in range(6):
        circles.append((rng.uniform(2.0, 46.0), rng.uniform(26.0, 42.0), rng.uniform(1.4, 2.2)))
    grid = paint(circles, size, rng, 5)
    # sem contorno escuro: a gosma fica por cima do contorno da sprite
    return [["d" if ch == "o" else ch for ch in row] for row in grid]


def main():
    for name, (grid, scale) in build().items():
        used = {c for row in grid for c in row if c != "."}
        lines = [
            f"# {name}, gosma do ugly, gerado por tools/goo_art.py.",
            "# Não edite à mão: mude o gerador e rode de novo.",
            "paleta",
        ]
        lines += [f"{letter} {PALETTE[letter]}" for letter in PALETTE if letter in used]
        lines.append("pixels")
        for row in grid:
            big = "".join(ch * scale for ch in row)
            lines += [big] * scale
        (OUTPUT / f"{name}.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"{name}.txt")


if __name__ == "__main__":
    main()
