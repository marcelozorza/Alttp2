"""Coco que o macaco joga, no lugar da pedra (pedido de Marcelo em
2026-11-13). Antes o projétil era um quadrado de cor chapada.

Uso, de dentro de tools/art: python3 coconut.py
"""

from canvas import Canvas

INK = "#1e181e"
DARK, BROWN, LIGHT = "#3b2530", "#5c4232", "#8a5a3c"


def coconut():
    """16 por 16: casca redonda e peluda, luz em cima à esquerda, sombra
    embaixo e os três olhos do coco."""
    c = Canvas(16, 16)
    c.ellipse(8, 8, 6.0, 6.0, DARK)
    c.ellipse(7.5, 7.5, 5.5, 5.5, BROWN)
    c.ellipse(6, 5.5, 2.5, 1.5, LIGHT)
    for x, y in ((9, 6), (11, 8), (8, 9)):
        c.px(x, y, DARK)
    for x, y in ((5, 10), (7, 12), (10, 11)):
        c.px(x, y, DARK)
    c.outline(INK, diagonal=True)
    c.outline(INK)
    return c


if __name__ == "__main__":
    coconut().save("coconut", "Coco que o macaco joga.")
