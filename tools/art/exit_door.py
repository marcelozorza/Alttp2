"""Porta de saída da dungeon: o vão na parede de baixo da primeira sala, por
onde se vê a grama do mundo. Pedido de Marcelo em 2026-11-12: sem porta, o
jogador não pensa em sair da dungeon.

Uso, de dentro de tools/art: python3 exit_door.py
"""

from canvas import Canvas

INK = "#1e181e"
S1, S2, S3, S4, S5, S6 = "#262335", "#3a3750", "#55526f", "#7c7b99", "#a9aac2", "#d6d8e6"
G2, G3, G4, G5 = "#2f8a45", "#59b84c", "#a4dc5a", "#dff29a"
E4, E5 = "#ddb277", "#f3dfa6"


def exit_door():
    """64 por 32: dois batentes de pedra, a soleira clara no alto, junto do
    chão da sala, e a grama de fora embaixo."""
    c = Canvas(64, 32)
    # Batentes.
    for x in (0, 50):
        c.rect(x, 0, 14, 32, S3)
        c.rect(x + 2, 2, 10, 2, S5)
        c.rect(x + 2, 4, 2, 26, S4)
        c.rect(x + 2, 14, 10, 1, S2)
        c.rect(x + 2, 24, 10, 1, S2)
        c.rect(x + 7, 4, 1, 10, S2)
        c.rect(x + 5, 15, 1, 9, S2)
        c.rect(x + 9, 25, 1, 5, S2)
    # Grama de fora, mais clara perto da soleira, onde bate a luz.
    c.rect(14, 0, 36, 32, G3)
    c.rect(14, 8, 36, 6, G4)
    for x, y in [(18, 18), (27, 24), (38, 17), (44, 26), (22, 28), (33, 21)]:
        c.px(x, y, G2)
        c.px(x + 1, y - 1, G2)
        c.px(x + 2, y, G2)
        c.px(x + 2, y - 2, G5)
    for x, y in [(20, 11), (31, 10), (41, 12)]:
        c.px(x, y, G5)
        c.px(x + 1, y, G5)
    # Soleira: degrau de pedra clara.
    c.rect(14, 0, 36, 6, S6)
    c.rect(14, 4, 36, 2, S5)
    c.rect(14, 6, 36, 2, G2)
    c.rect(25, 0, 1, 4, S5)
    c.rect(38, 0, 1, 4, S5)
    # Sombra dos batentes sobre a grama.
    c.rect(14, 8, 2, 24, G2)
    c.rect(48, 8, 2, 24, G2)
    # Traço grosso por fora e na borda de dentro dos batentes.
    c.frame(0, 0, 64, 32, INK)
    c.frame(1, 1, 62, 30, INK)
    c.rect(14, 0, 36, 2, None)
    c.rect(14, 30, 36, 2, None)
    c.rect(12, 0, 2, 32, INK)
    c.rect(50, 0, 2, 32, INK)
    c.rect(14, 30, 36, 2, G3)
    c.rect(14, 0, 36, 2, S6)
    return c


def main():
    exit_door().save(
        "exit_door",
        "Porta de saída da dungeon, na parede de baixo. 64 por 32, vão de 36 no meio.",
    )


if __name__ == "__main__":
    main()
