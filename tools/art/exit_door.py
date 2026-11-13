"""Porta de saída da dungeon: um vão aberto na parede de baixo, com a luz de
fora. Quarta versão, de 2026-11-13: Marcelo quis uma porta só, aberta, sem
colunas, sem folhas e sem tapete. As anteriores foram um vão estreito com
grama ("um pote de ácido verde"), um portão de duas folhas e um arco de
madeira.

Uso, de dentro de tools/art: python3 exit_door.py
"""

from canvas import Canvas

INK = "#1e181e"
S3, S4, S5, S6 = "#55526f", "#7c7b99", "#a9aac2", "#d6d8e6"
E4 = "#ddb277"
Y1, Y2, WHITE = "#f7c53a", "#fff1a8", "#ffffff"


def exit_door():
    """72 por 32, do tamanho do trecho de parede que cobre: moldura de pedra,
    soleira clara, a luz de fora mais forte embaixo e dois degraus."""
    c = Canvas(72, 32)
    c.rect(0, 0, 72, 32, INK)
    c.rect(2, 0, 68, 32, S4)
    c.rect(2, 0, 2, 32, S5)
    c.rect(66, 0, 4, 32, S3)
    c.rect(6, 0, 60, 32, INK)
    c.rect(8, 2, 56, 30, Y2)
    c.rect(8, 2, 56, 3, S6)
    c.rect(8, 5, 56, 1, S5)
    c.rect(8, 14, 56, 18, WHITE)
    for y in (13, 22):
        c.rect(8, y, 56, 1, Y1)
    c.rect(8, 6, 3, 26, E4)
    c.rect(61, 6, 3, 26, E4)
    return c


def main():
    exit_door().save(
        "exit_door",
        "Porta de saída da dungeon: vão aberto na parede de baixo, com a luz de fora. 72 por 32.",
    )


if __name__ == "__main__":
    main()
