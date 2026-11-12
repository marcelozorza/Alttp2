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


def leaf(c, x, hinge_left):
    """Folha de madeira aberta para dentro da sala, de pé sobre o batente: 20
    por 46, de topo arredondado, com tábuas, duas dobradiças de ferro do lado
    do batente e a argola do outro."""
    c.rect(x, 6, 20, 42, E2)
    c.rect(x + 2, 3, 16, 3, E2)
    c.rect(x + 4, 2, 12, 1, E2)
    for dx in (6, 13):
        c.rect(x + dx, 4, 1, 42, E1)
    c.rect(x + 3, 5, 14, 1, E3)
    c.rect(x + 2, 7, 1, 38, E3)
    hinge = x + (1 if hinge_left else 9)
    for y in (12, 34):
        c.rect(hinge, y, 10, 3, S3)
        c.rect(hinge, y, 10, 1, S5)
        c.px(hinge + 2, y + 1, S1)
        c.px(hinge + 7, y + 1, S1)
    ring = x + (13 if hinge_left else 3)
    c.rect(ring, 22, 4, 5, Y1)
    c.rect(ring + 1, 23, 2, 3, E0)
    c.px(ring, 22, Y2)
    # Traço grosso em volta, acompanhando o topo arredondado.
    for y in range(0, 48):
        for xx in range(x - 2, x + 22):
            if c.get(xx, y) is None and any(
                c.get(xx + dx, y + dy) not in (None, INK)
                for dx in range(-2, 3)
                for dy in range(-2, 3)
                if abs(dx) + abs(dy) <= 2
            ):
                c.px(xx, y, INK)


def exit_door():
    """128 por 80. Os 48 de cima ficam sobre o chão da sala: as duas folhas
    abertas e a soleira. Os 32 de baixo são o vão na parede: batentes de
    pedra e a luz de fora, que entra pelos degraus."""
    c = Canvas(128, 80)
    top = 48
    # Folhas abertas, uma sobre cada batente.
    leaf(c, 2, True)
    leaf(c, 106, False)
    # Batentes de pedra na parede.
    for x in (0, 104):
        c.rect(x, top, 24, 32, S3)
        c.rect(x + 3, top + 3, 18, 2, S5)
        c.rect(x + 3, top + 5, 2, 24, S4)
        c.rect(x + 3, top + 15, 18, 1, S1)
        c.rect(x + 3, top + 24, 18, 1, S1)
        c.rect(x + 12, top + 5, 1, 10, S1)
        c.rect(x + 8, top + 16, 1, 8, S1)
        c.rect(x + 16, top + 25, 1, 5, S1)
        c.frame(x, top, 24, 32, INK)
        c.frame(x + 1, top + 1, 22, 30, INK)
    # Vão: soleira de pedra clara, dois degraus banhados de luz e o clarão.
    c.rect(24, top - 4, 80, 8, S6)
    c.rect(24, top + 2, 80, 2, S5)
    c.rect(24, top + 4, 80, 8, E4)
    c.rect(24, top + 10, 80, 2, E3)
    c.rect(24, top + 12, 80, 8, E5)
    c.rect(24, top + 18, 80, 2, E4)
    c.rect(24, top + 20, 80, 12, Y2)
    for x in (44, 64, 84):
        c.rect(x, top - 4, 1, 6, S5)
    for x in (24, 100):
        c.rect(x, top + 4, 4, 16, E3)
    c.rect(24, top - 4, 80, 2, INK)
    return c


def main():
    exit_door().save(
        "exit_door",
        "Portão de saída da dungeon: duas folhas de madeira abertas e a luz de fora. 128 por 80.",
    )


if __name__ == "__main__":
    main()
