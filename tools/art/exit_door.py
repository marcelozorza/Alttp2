"""Porta de saída da dungeon: um portão de madeira de duas folhas, abertas
para dentro da sala, num vão largo da parede de baixo, com os degraus que
descem para fora. Pedido de Marcelo em 2026-11-12. A primeira versão, um vão
estreito com grama, parecia "um pote de ácido verde": ele pediu o dobro do
tamanho, madeira e duas folhas.

Uso, de dentro de tools/art: python3 exit_door.py
"""

from canvas import Canvas

INK = "#1e181e"
S0, S1, S2, S3, S4, S5, S6 = (
    "#1b1926",
    "#262335",
    "#3a3750",
    "#55526f",
    "#7c7b99",
    "#a9aac2",
    "#d6d8e6",
)
E0, E1, E2, E3, E4, E5 = "#3b2530", "#5c4232", "#8a5a3c", "#b9824e", "#ddb277", "#f3dfa6"
Y1, Y2 = "#f7c53a", "#fff1a8"


def leaf(c, hinge_x, free_x):
    """Folha aberta em perspectiva forçada: um trapézio, alto na dobradiça,
    junto do arco, e mais baixo na borda solta, que avança para o meio do
    vão. Tábuas, almofadas, dobradiças de ferro e argola."""
    step = 1 if free_x > hinge_x else -1
    span = abs(free_x - hinge_x)
    for i in range(span + 1):
        x = hinge_x + i * step
        top = 30 + round(12 * i / span)
        bottom = 93 - round(9 * i / span)
        edge = i < 2 or i > span - 2
        for y in range(top, bottom + 1):
            color = E2
            if edge or y < top + 2 or y > bottom - 2:
                color = INK
            elif y < top + 4:
                color = E4
            elif i in (span // 2, span // 2 + 1):
                color = E1
            elif 5 <= i <= span - 5 and i not in range(span // 2 - 3, span // 2 + 5):
                inner_top, inner_bottom = top + 9, bottom - 8
                middle = (top + bottom) // 2
                if y in (inner_top, inner_bottom, middle - 2, middle + 2):
                    color = E1
                elif inner_top < y < inner_bottom and not middle - 2 < y < middle + 2:
                    color = E3
            c.px(x, y, color)
    for y in (40, 78):
        c.rect(min(hinge_x, hinge_x + 3 * step), y, 4, 3, S5)
        c.px(hinge_x + step, y + 1, S1)
    ring = free_x - 5 * step
    c.rect(ring - 1, 60, 3, 5, Y1)
    c.px(ring, 62, E0)


def exit_door():
    """128 por 96, de frente, como a referência que Marcelo mandou. Um arco
    de madeira de pé sobre a parede de baixo, o vão com a luz de fora e as
    duas folhas abertas para dentro, em perspectiva. Os 32 de baixo cobrem a
    parede e os 64 de cima ficam sobre o chão da sala."""
    c = Canvas(128, 96)
    # Arco: tinta por fora, madeira, tinta por dentro e o vão.
    for rx, ry, top, color in [
        (64, 44, 0, INK),
        (62, 42, 2, E3),
        (58, 38, 6, E2),
        (52, 34, 12, INK),
        (50, 32, 14, E5),
    ]:
        c.ellipse(64, top + ry, rx, ry, color)
        c.rect(64 - rx, top + ry, rx * 2, 96 - top - ry, color)
    # Veios da madeira do arco.
    for x in (5, 9, 118, 122):
        c.rect(x, 50, 1, 44, E1)
    # Luz de fora: mais forte embaixo, com o caminho de pedra.
    c.rect(14, 62, 100, 34, Y2)
    c.rect(14, 84, 100, 12, S6)
    c.rect(14, 84, 100, 2, S5)
    for x in (40, 64, 88):
        c.rect(x, 86, 1, 10, S5)
    leaf(c, 15, 44)
    leaf(c, 112, 83)
    return c


def main():
    exit_door().save(
        "exit_door",
        "Portão de saída da dungeon: arco de madeira e duas folhas abertas em perspectiva. 128 por 96.",
    )


if __name__ == "__main__":
    main()
