"""Sola de patinha: o item que o chefe deixa ao cair (art/source/relic.txt,
no lugar do losango dourado) e, maior, o enfeite ao lado do logotipo
(art/source/title_paw.txt). Pedido de Marcelo em 2026-11-13.

Uso, de dentro de tools/art: python3 paw.py
"""

from canvas import Canvas

INK = "#1e181e"
FUR, SHADE = "#f4f1ea", "#c7c1cf"
PAD, PAD_LIGHT = "#3b2530", "#5c4232"

# Almofadas em fração do quadro: centro x, centro y, raio x, raio y.
PADS = [
    (0.50, 0.66, 0.22, 0.15),
    (0.50, 0.58, 0.14, 0.12),
    (0.19, 0.44, 0.075, 0.10),
    (0.38, 0.27, 0.085, 0.11),
    (0.62, 0.27, 0.085, 0.11),
    (0.81, 0.44, 0.075, 0.10),
]


def _inside(x, y, size, grow):
    for cx, cy, rx, ry in PADS:
        dx = (x + 0.5 - cx * size) / (rx * size + grow)
        dy = (y + 0.5 - cy * size) / (ry * size + grow)
        if dx * dx + dy * dy <= 1.0:
            return True
    return False


def paw(size, fur, ink):
    """Almofadas marrons sobre o pelo claro, com fur pixels de pelo em volta
    e ink pixels de contorno."""
    c = Canvas(size, size)
    for y in range(size):
        for x in range(size):
            if _inside(x, y, size, 0.0):
                light = _inside(x + 1, y + 1, size, -1.0) and not _inside(x - 1, y - 1, size, -0.6)
                c.px(x, y, PAD_LIGHT if light else PAD)
            elif _inside(x, y, size, fur):
                c.px(x, y, FUR if _inside(x, y + 1, size, fur) else SHADE)
            elif _inside(x, y, size, fur + ink):
                c.px(x, y, INK)
    return c


if __name__ == "__main__":
    paw(24, 1.6, 1.6).save(
        "relic",
        "Relíquia do fim do capítulo: a sola de patinha.\n"
        "Contorno de fora engrossado por tools/art/thicken.py.",
    )
    paw(36, 2.4, 2.0).save("title_paw", "Sola de patinha ao lado do logotipo do título.")
