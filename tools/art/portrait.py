"""Retrato do Jorginho para a tela de título: a imagem em pixel art que
Marcelo mandou em 2026-11-13, reduzida, sem o fundo e levada à paleta mestra.
A imagem de origem fica fora do repositório, em /mnt/project-files/giorgino/.

Uso, de dentro de tools/art: python3 portrait.py <imagem> [tamanho]
"""

import sys

from PIL import Image

import palette
from canvas import Canvas

INK = "#1e181e"
# Cores que o retrato pode usar: tinta, pelo, terra, rosa e pedra.
RAMPS = ("ink", "fur", "earth", "pink", "stone")
ALLOWED = [color for ramp in RAMPS for color in palette.RAMPS[ramp]]


def _nearest(rgb):
    lab = palette._lab("#%02x%02x%02x" % rgb)
    return min(ALLOWED, key=lambda c: sum((a - b) ** 2 for a, b in zip(lab, palette._LAB[c])))


def _background(image):
    """Fundo: o que se alcança a partir das bordas passando só por pixels da
    cor de areia do fundo. O traço escuro em volta do cachorro segura."""
    w, h = image.size
    px = image.load()

    def sandy(x, y):
        r, g, b = px[x, y]
        return 110 < r < 215 and 15 < r - b < 110 and g < r and g > b and r + g + b < 560

    seen = set()
    stack = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h) or not sandy(x, y):
            continue
        seen.add((x, y))
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return seen


def portrait(path, size):
    source = Image.open(path).convert("RGB")
    # O fundo sai na imagem grande, onde o traço é contínuo.
    work = source.resize((size * 4, size * 4), Image.LANCZOS)
    back = _background(work)
    small = source.resize((size, size), Image.LANCZOS)
    c = Canvas(size, size)
    for y in range(size):
        for x in range(size):
            out = sum((x * 4 + dx, y * 4 + dy) in back for dx in range(4) for dy in range(4))
            if out < 8:
                c.px(x, y, _nearest(small.getpixel((x, y))))
    c.outline(INK)
    return c


if __name__ == "__main__":
    size = int(sys.argv[2]) if len(sys.argv) > 2 else 112
    portrait(sys.argv[1], size).save(
        "title_portrait", "Retrato do Jorginho na tela de título, de uma imagem de Marcelo."
    )
