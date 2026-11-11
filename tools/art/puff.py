"""Nuvem de quando um inimigo é vencido, em 4 quadros de 32 por 32.

Pedido de Marcelo em 2026-11-11: nenhum inimigo tinha animação de morte, o
gato só desaparecia. A nuvem estoura no lugar do inimigo: um tufo pequeno,
um tufo grande, o tufo se abrindo em bolas e, por fim, só as faíscas.

Uso: python3 tools/art/puff.py && python3 tools/pixel_svg.py
"""

import math

from canvas import Canvas

INK = "#1e181e"
WHITE, LIGHT, SHADE = "#ffffff", "#d6d8e6", "#a9aac2"
SIZE = 32
CENTER = 16


def ball(c, x, y, r):
    """Bola de fumaça: branca, com a sombra embaixo à direita."""
    c.ellipse(x + 0.6, y + 0.8, r, r, SHADE)
    c.ellipse(x, y, r - 0.4, r - 0.4, LIGHT)
    c.ellipse(x - r * 0.25, y - r * 0.25, r * 0.6, r * 0.6, WHITE)


def spark(c, x, y, long=2):
    """Faísca em cruz."""
    c.rect(x - long, y, long * 2 + 1, 1, WHITE)
    c.rect(x, y - long, 1, long * 2 + 1, WHITE)


def ring(c, count, distance, radius, turn=0.0):
    for i in range(count):
        angle = turn + i * math.tau / count
        ball(c, CENTER + math.cos(angle) * distance, CENTER + math.sin(angle) * distance, radius)


def frames():
    first = Canvas(SIZE, SIZE)
    ring(first, 5, 3.5, 3.5, 0.3)
    ball(first, CENTER, CENTER, 4.5)

    second = Canvas(SIZE, SIZE)
    ring(second, 6, 7.0, 4.5, 0.1)
    ball(second, CENTER, CENTER, 6.5)
    spark(second, 4, 5, 1)
    spark(second, 27, 8, 1)

    third = Canvas(SIZE, SIZE)
    ring(third, 6, 10.5, 3.2, 0.4)
    spark(third, CENTER, CENTER, 3)
    spark(third, 6, 26, 1)

    fourth = Canvas(SIZE, SIZE)
    ring(fourth, 6, 12.5, 1.6, 0.7)
    spark(fourth, CENTER, CENTER - 1, 2)
    spark(fourth, 24, 23, 1)
    spark(fourth, 8, 9, 1)

    texts = [
        "Nuvem do inimigo vencido: tufo pequeno.",
        "Nuvem do inimigo vencido: tufo grande.",
        "Nuvem do inimigo vencido: o tufo se abre em bolas.",
        "Nuvem do inimigo vencido: só as faíscas.",
    ]
    return list(zip([first, second, third, fourth], texts))


def main():
    for index, (canvas, text) in enumerate(frames()):
        canvas.outline(INK)
        canvas.save("death_puff_%d" % (index + 1), text + "\nGerado por tools/art/puff.py.")


if __name__ == "__main__":
    main()
