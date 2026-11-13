"""Decalque de uma folha de referência para a grade de art/source.

Desde 2026-11-11, a pedido de Marcelo, os inimigos partem de folhas de
sprites em 8-bit geradas no Magnific (guardadas fora do repositório, em
/mnt/project-files/inimigos/). Este módulo decalca uma pose da folha: acha a
grade de pixels do desenho, lê a cor de cada casa, leva para as cores
escolhidas da paleta mestra e limpa a franja. O resultado é um rascunho: o
gerador de cada inimigo retoca olhos, dentes e marcas à mão, alinha os pés e
grava o texto em art/source, que continua sendo a fonte.

Precisa de Pillow e numpy, só para decalcar de novo.
"""

import numpy as np
from PIL import Image

import palette
from canvas import Canvas

INK = "#1e181e"


def trace(path, box, size, colors, bg_tol=38):
    """Decalca o recorte box da imagem, com pixels de size por size."""
    image = np.asarray(Image.open(path).convert("RGB").crop(box)).astype(float)
    h, w = image.shape[:2]
    background = np.median(image[:6].reshape(-1, 3), axis=0)

    def cell(ox, oy, i, j):
        return image[
            int(oy + j * size) + 1 : int(oy + (j + 1) * size),
            int(ox + i * size) + 1 : int(ox + (i + 1) * size),
        ]

    # O começo da grade é o que deixa cada casa com a cor mais uniforme.
    best = None
    for oy in np.arange(0, size, 0.5):
        for ox in np.arange(0, size, 0.5):
            error = 0.0
            for j in range(0, int((h - oy) / size), 3):
                for i in range(0, int((w - ox) / size), 3):
                    block = cell(ox, oy, i, j)
                    if block.size:
                        error += block.reshape(-1, 3).std(axis=0).sum()
            if best is None or error < best[0]:
                best = (error, ox, oy)
    _, ox, oy = best
    labs = [(color, palette._lab(color)) for color in colors]
    nx, ny = int((w - ox) / size), int((h - oy) / size)
    middles = [[None] * nx for _ in range(ny)]
    for j in range(ny):
        for i in range(nx):
            block = cell(ox, oy, i, j)
            if block.size:
                middles[j][i] = np.median(block.reshape(-1, 3), axis=0)

    def like_background(i, j):
        return middles[j][i] is None or np.abs(middles[j][i] - background).sum() < bg_tol

    # O fundo é só o que se liga à borda: um cinza igual ao fundo dentro do
    # desenho continua sendo desenho.
    outside = set()
    todo = [(i, j) for i in range(nx) for j in (0, ny - 1)]
    todo += [(i, j) for j in range(ny) for i in (0, nx - 1)]
    while todo:
        i, j = todo.pop()
        if (i, j) in outside or not (0 <= i < nx and 0 <= j < ny) or not like_background(i, j):
            continue
        outside.add((i, j))
        todo += [(i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)]
    out = Canvas(nx, ny)
    for j in range(ny):
        for i in range(nx):
            if (i, j) in outside or middles[j][i] is None:
                continue
            lab = palette._lab("#%02x%02x%02x" % tuple(int(v) for v in middles[j][i]))
            out.p[j][i] = min(labs, key=lambda t: sum((a - b) ** 2 for a, b in zip(lab, t[1])))[0]
    return out.crop()


def is_edge(c, x, y):
    return any(c.get(x + dx, y + dy) is None for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))


def clean(c, soft):
    """Fica só com a maior peça, tira a franja clara e fecha o contorno em
    tinta. soft são as cores escuras que podem virar contorno."""
    seen, best = set(), []
    for y in range(c.h):
        for x in range(c.w):
            if c.p[y][x] and (x, y) not in seen:
                piece, todo = [], [(x, y)]
                seen.add((x, y))
                while todo:
                    px, py = todo.pop()
                    piece.append((px, py))
                    for dx in (-1, 0, 1):
                        for dy in (-1, 0, 1):
                            near = (px + dx, py + dy)
                            if near not in seen and c.get(*near):
                                seen.add(near)
                                todo.append(near)
                if len(piece) > len(best):
                    best = piece
    keep = set(best)
    for y in range(c.h):
        for x in range(c.w):
            if (x, y) not in keep:
                c.p[y][x] = None
    for _ in range(2):
        fringe = [
            (x, y)
            for y in range(c.h)
            for x in range(c.w)
            if c.p[y][x] and c.p[y][x] not in soft and is_edge(c, x, y)
        ]
        for x, y in fringe:
            c.p[y][x] = None
    for y in range(c.h):
        for x in range(c.w):
            if c.p[y][x] and is_edge(c, x, y):
                c.p[y][x] = INK
    return c.crop()
