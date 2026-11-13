"""Monte de neve acumulada no chão da geleira. Entrou no lugar dos cristais
de gelo azul-claros, que Marcelo não quis no cenário (2026-11-13).

Uso, de dentro de tools/art: python3 snow_pile.py
"""

from canvas import Canvas

INK = "#1e181e"
WHITE, FUR = "#ffffff", "#f4f1ea"
F1, F2 = "#86a9d6", "#b4cdec"


def snow_pile():
    """26 por 18: dois montes redondos, um maior atrás e um menor na frente,
    com a sombra azulada embaixo e o brilho no alto."""
    c = Canvas(26, 18)
    c.ellipse(11, 10, 8.5, 6.5, F2)
    c.ellipse(18, 12, 5.5, 4.0, F2)
    c.rect(3, 12, 20, 4, F2)
    c.ellipse(10.5, 8.5, 7.5, 5.0, FUR)
    c.ellipse(17.5, 11, 4.5, 2.6, FUR)
    c.ellipse(9, 7, 4.5, 2.4, WHITE)
    c.rect(15, 10, 4, 1, WHITE)
    c.rect(4, 15, 18, 1, F1)
    c.outline(INK, diagonal=True)
    c.outline(INK)
    return c


def main():
    snow_pile().save("snow_pile", "Monte de neve acumulada no chão da geleira.")


if __name__ == "__main__":
    main()
