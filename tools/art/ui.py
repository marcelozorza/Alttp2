"""Desenhos das telas: o logotipo do título.

Uso: python3 tools/art/ui.py && python3 tools/pixel_svg.py
"""

import font
from canvas import Canvas

INK = "#1e181e"
FUR, SHADE = "#f4f1ea", "#c7c1cf"
Y0, Y1 = "#d99a1c", "#f7c53a"
PINK = "#d9578a"


def logo():
    """GIORGINO em letras de 28 pixels: as letras da fonte ampliadas 4 vezes
    com as diagonais alisadas, brancas, com base cinza, contorno e sombra."""
    rows = None
    for ch in "GIORGINO":
        glyph = font.glyph_rows(ch)[font.ABOVE : font.ABOVE + font.BODY]
        glyph = [r + "." for r in glyph]
        rows = glyph if rows is None else [a + b for a, b in zip(rows, glyph)]
    rows = font.scale2x(font.scale2x(rows))
    w, h = len(rows[0]), len(rows)
    c = Canvas(w + 6, h + 8)
    for y, row in enumerate(rows):
        for x, bit in enumerate(row):
            if bit == "#":
                c.px(x + 2, y + 2, SHADE if y >= h - 6 else FUR)
    # Coleira rosa: uma faixa fina atravessando as letras.
    for y in range(h - 9, h - 7):
        for x in range(c.w):
            if c.get(x, y + 2) is not None:
                c.px(x, y + 2, PINK)
    c.outline(INK, diagonal=True)
    shadow = c.copy()
    out = Canvas(c.w, c.h)
    for y in range(c.h):
        for x in range(c.w):
            if shadow.get(x, y) is not None:
                out.px(x + 1, y + 3, Y0)
    out.blit(c, 0, 0)
    return out.crop()


if __name__ == "__main__":
    logo().save("logo", "Logotipo do título: GIORGINO com a coleira rosa do herói.")
