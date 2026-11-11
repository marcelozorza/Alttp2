"""Objetos e adornos das dungeons no traço de 2026-11-10 (8-bit revisitado).

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


R0, R1, R2 = "#5e1830", "#9c2338", "#d83a3f"
G1, G2, G3, G4 = "#1f5a3a", "#2f8a45", "#59b84c", "#a4dc5a"
B5, WHITE = "#c6efff", "#ffffff"


def carpet():
    """Miolo do tapete do castelo: losangos pequenos em duas fileiras
    desencontradas, com um ponto claro no meio. Repete sem emenda. Em
    2026-11-11 Marcelo pediu o vermelho mais escuro, porque o tapete saltava
    do piso: o fundo desceu um tom na rampa, e os losangos e o ponto também."""
    c = Canvas(32, 32, R0)
    for cx, cy in [(8, 8), (24, 8), (0, 24), (16, 24), (32, 24)]:
        for d in range(4):
            c.rect(cx - 3 + d, cy - d, 7 - 2 * d, 1, "#3b2530")
            c.rect(cx - 3 + d, cy + d, 7 - 2 * d, 1, "#3b2530")
        c.px(cx, cy, R1)
    return c


def _sparkle(c, x, y, big, color):
    c.px(x, y, WHITE)
    for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
        c.px(x + dx, y + dy, color)
    if big:
        for dx, dy in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
            c.px(x + dx, y + dy, color)


def frost():
    """Geada sobre o chão: cristais pequenos e pontos soltos, transparente."""
    c = Canvas(32, 32)
    for x, y, big in [(5, 5, True), (14, 13, False), (25, 21, True), (8, 27, False), (24, 4, False)]:
        _sparkle(c, x, y, big, B5)
    for x, y in [(19, 8), (3, 17), (29, 13), (16, 25), (11, 20)]:
        c.px(x, y, B5)
    return c


def moss_patch():
    """Manchas de musgo sobre o chão: tufos redondos com um brilho."""
    c = Canvas(32, 32)
    for cx, cy, rx, ry in [(5, 5, 4, 2.5), (22, 7, 3, 2), (13, 15, 3.5, 2), (25, 23, 4, 2.5), (7, 24, 2.5, 1.5)]:
        c.ellipse(cx, cy + 1, rx, ry, G1)
        c.ellipse(cx, cy, rx, ry, G2)
        c.px(int(cx) - 1, int(cy) - 1, G3)
        c.px(int(cx), int(cy) - 1, G3)
    for x, y in [(17, 4), (2, 14), (29, 15), (18, 27)]:
        c.px(x, y, G2)
    return c


def vine():
    """Trepadeira pendurada na face da parede: caule ondulado e folhas
    alternadas, afinando na ponta."""
    c = Canvas(12, 28)
    for y in range(26):
        x = 5 + (1 if (y // 4) % 2 else 0)
        c.px(x, y, G1)
        if y < 20:
            c.px(x + 1, y, G2)
    for y, side in [(2, 1), (6, -1), (10, 1), (14, -1), (18, 1), (22, -1)]:
        x = 6 + (1 if (y // 4) % 2 else 0) if side > 0 else 5 + (1 if (y // 4) % 2 else 0)
        for d in range(1, 4):
            c.px(x + side * d, y + (d // 2), G3 if d < 3 else G4)
        c.px(x + side, y + 1, G2)
        c.px(x + side * 2, y + 2, G2)
    return c


def main():
    carpet().save("carpet", "Tapete vinho do castelo, o miolo, com losangos escuros.")
    frost().save("frost", "Geada sobre o chão, com transparência.")
    moss_patch().save("moss_patch", "Manchas de musgo sobre o chão, com transparência.")
    vine().save("vine", "Trepadeira pendurada na face da parede.")
    message_plate(False).save("message_plate", "Placa de mensagem no chão: pisar nela mostra um texto.")
    message_plate(True).save("message_plate_lit", "Placa de mensagem com o personagem em cima.")


if __name__ == "__main__":
    main()
