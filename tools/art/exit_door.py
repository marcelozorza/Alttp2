"""Porta de saída da dungeon: um vão aberto na parede de baixo, com a luz de
fora. Quarta versão, de 2026-11-13: Marcelo quis uma porta só, aberta, sem
colunas, sem folhas e sem tapete. As anteriores foram um vão estreito com
grama ("um pote de ácido verde"), um portão de duas folhas e um arco de
madeira.

Uso, de dentro de tools/art: python3 exit_door.py
"""

from canvas import Canvas

INK = "#1e181e"
S3, S4, S5 = "#55526f", "#7c7b99", "#a9aac2"
Y2 = "#fff1a8"


def exit_door():
    """72 por 32, do tamanho do trecho de parede que cobre: moldura de pedra,
    e a luz de fora numa cor só, o amarelo claro que Marcelo escolheu."""
    c = Canvas(72, 32)
    c.rect(0, 0, 72, 32, INK)
    c.rect(2, 0, 68, 32, S4)
    c.rect(2, 0, 1, 32, S5)
    c.rect(67, 0, 3, 32, S3)
    c.rect(6, 0, 60, 32, INK)
    c.rect(8, 2, 56, 30, Y2)
    return c


def main():
    exit_door().save(
        "exit_door",
        "Porta de saída da dungeon: vão aberto na parede de baixo, com a luz de fora. 72 por 32.",
    )


if __name__ == "__main__":
    main()
