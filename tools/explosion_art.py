"""Gera os quadros da explosão da bomba, em art/source/explosion_1.txt a 4.

A explosão é desenhada em 56 por 56 pixels, com raio 26 no auge, e ampliada
2 vezes na saída, para 112 por 112, como os outros desenhos desde que a
resolução dobrou (2026-11-07): o raio ampliado é o raio de dano da bomba. São quatro quadros: o clarão, a bola de fogo crescendo com
línguas para fora, o anel no tamanho cheio com o meio já escurecendo e a
fumaça se desfazendo. Cada quadro é uma nuvem de círculos de tamanhos e
posições sorteados com semente fixa, então o resultado é sempre o mesmo, e
as cores vêm da profundidade do pixel dentro da nuvem, do branco no miolo ao
vermelho na borda. Marcelo pediu a troca do círculo vetorial em 2026-11-07.

Uso: python3 tools/explosion_art.py && python3 tools/pixel_svg.py
"""

import math
import pathlib
import random

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "art" / "source"
SIZE = 56
# Ampliação na saída: cada pixel sorteado vira um quadrado de SCALE por SCALE.
SCALE = 2
CENTER = (SIZE - 1) / 2.0
PALETTE = {
    "w": "#fff8dc",
    "y": "#ffd23f",
    "o": "#ff7a1a",
    "r": "#c43018",
    "k": "#4a2a26",
    "s": "#6e625c",
    "l": "#a09690",
}


def puffs(rng, count, distance, radius, center_radius=0.0):
    """Círculos em volta do centro, mais um no centro quando center_radius > 0."""
    out = []
    if center_radius > 0.0:
        out.append((CENTER, CENTER, center_radius))
    for i in range(count):
        angle = (i + rng.uniform(-0.3, 0.3)) * 2.0 * math.pi / count
        d = rng.uniform(*distance)
        out.append((CENTER + math.cos(angle) * d, CENTER + math.sin(angle) * d, rng.uniform(*radius)))
    return out


def depth(circles, x, y):
    """Quanto o pixel está para dentro da nuvem: 0 na borda, 1 no centro do círculo."""
    best = 0.0
    for cx, cy, r in circles:
        d = math.hypot(x - cx, y - cy)
        if d < r:
            best = max(best, 1.0 - d / r)
    return best


def band(value, bands):
    """Primeira cor cujo limite a profundidade alcança."""
    for limit, color in bands:
        if value >= limit:
            return color
    return "."


def spikes(grid, rng, count, inner, outer, color):
    """Línguas de fogo retas, de 1 pixel de largura, do raio inner ao outer."""
    for i in range(count):
        angle = (i + rng.uniform(-0.4, 0.4)) * 2.0 * math.pi / count
        length = rng.uniform(*outer)
        step = 0.5
        d = inner
        while d <= length:
            x = int(round(CENTER + math.cos(angle) * d))
            y = int(round(CENTER + math.sin(angle) * d))
            if 0 <= x < SIZE and 0 <= y < SIZE and grid[y][x] == ".":
                grid[y][x] = color
            d += step


def embers(grid, rng, count, distance, colors):
    for _ in range(count):
        angle = rng.uniform(0.0, 2.0 * math.pi)
        d = rng.uniform(*distance)
        x = int(round(CENTER + math.cos(angle) * d))
        y = int(round(CENTER + math.sin(angle) * d))
        if 0 <= x < SIZE and 0 <= y < SIZE:
            grid[y][x] = rng.choice(colors)


def frame(circles, bands, hole=None):
    grid = [["."] * SIZE for _ in range(SIZE)]
    for y in range(SIZE):
        for x in range(SIZE):
            value = depth(circles, x, y)
            color = band(value, bands) if value > 0.0 else "."
            if hole and math.hypot(x - CENTER, y - CENTER) < hole[0]:
                color = hole[1]
            grid[y][x] = color
    return grid


def build():
    rng = random.Random(7)
    frames = []
    # 1: o clarão, pequeno e quase branco.
    circles = puffs(rng, 3, (5.0, 7.0), (3.5, 5.0), 9.0)
    frames.append(frame(circles, ((0.55, "w"), (0.25, "y"), (0.0, "o"))))
    # 2: a bola de fogo crescendo, com línguas para fora.
    circles = puffs(rng, 6, (9.0, 13.0), (6.0, 8.5), 13.0)
    grid = frame(circles, ((0.7, "w"), (0.42, "y"), (0.15, "o"), (0.0, "r")))
    spikes(grid, rng, 7, 14.0, (19.0, 25.0), "y")
    frames.append(grid)
    # 3: o anel cheio, raio 26, com o miolo escurecendo.
    circles = puffs(rng, 9, (15.0, 18.0), (7.5, 10.0), 0.0)
    grid = frame(circles, ((0.55, "y"), (0.25, "o"), (0.08, "r"), (0.0, "k")), (8.0, "k"))
    embers(grid, rng, 8, (2.0, 8.0), ["o", "y"])
    frames.append(grid)
    # 4: a fumaça se desfazendo e umas brasas.
    circles = puffs(rng, 9, (14.0, 20.0), (6.0, 8.5), 0.0)
    grid = frame(circles, ((0.5, "l"), (0.15, "s"), (0.0, "k")))
    embers(grid, rng, 10, (10.0, 26.0), ["o", "y", "r"])
    frames.append(grid)
    return frames


def main():
    for index, grid in enumerate(build(), start=1):
        used = {c for row in grid for c in row if c != "."}
        lines = [
            f"# Quadro {index} da explosão da bomba, gerado por tools/explosion_art.py.",
            "# Não edite à mão: mude o gerador e rode de novo.",
            "paleta",
        ]
        lines += [f"{letter} {PALETTE[letter]}" for letter in PALETTE if letter in used]
        lines.append("pixels")
        for row in grid:
            big = "".join(ch * SCALE for ch in row)
            lines += [big] * SCALE
        (OUTPUT / f"explosion_{index}.txt").write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"explosion_{index}.txt")


if __name__ == "__main__":
    main()
