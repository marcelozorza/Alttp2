"""Objetos das dungeons no traço de 2026-11-10 (8-bit revisitado).

Uso: python3 tools/art/objects.py && python3 tools/pixel_svg.py
"""

from canvas import Canvas

INK = "#1e181e"
S1, S2, S3, S4, S5, S6 = "#262335", "#3a3750", "#55526f", "#7c7b99", "#a9aac2", "#d6d8e6"
Y0, Y1, Y2 = "#d99a1c", "#f7c53a", "#fff1a8"
O1 = "#c85a1e"
FUR = "#f4f1ea"


def message_plate(lit):
    """Placa de mensagem: disco dourado com um ponto de exclamação, numa
    moldura de pedra. Acesa, o disco clareia e ganha raios."""
    c = Canvas(32, 32)
    c.ellipse(16, 16, 13, 13, S3)
    c.ellipse(16, 16, 11.5, 11.5, S5)
    c.ellipse(16, 16, 10, 10, Y0)
    c.ellipse(16, 15.5, 9, 9, Y2 if lit else Y1)
    if not lit:
        c.ellipse(13.5, 12.5, 4, 3, Y2)
        c.ellipse(16, 15.5, 6, 6, Y1)
    mark = INK if lit else O1
    c.rect(15, 9, 2, 8, mark)
    c.rect(14, 9, 4, 3, mark)
    c.rect(15, 19, 2, 2, mark)
    c.outline(INK)
    if lit:
        for x, y in [(16, 0), (15, 0), (16, 31), (15, 31), (0, 15), (0, 16), (31, 15), (31, 16)]:
            c.px(x, y, Y2)
        for x, y in [(4, 4), (27, 4), (4, 27), (27, 27)]:
            c.px(x, y, Y2)
    return c


def main():
    message_plate(False).save("message_plate", "Placa de mensagem no chão: pisar nela mostra um texto.")
    message_plate(True).save("message_plate_lit", "Placa de mensagem com o personagem em cima.")


if __name__ == "__main__":
    main()
