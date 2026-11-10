"""Desenhos do mundo de chegada, no traço de 2026-11-10 (8-bit revisitado).

Grama em quatro variações, caminho de terra, água em dois quadros, neve,
calçada e entulho junto das entradas, a franja de grama que arredonda as
bordas, as árvores, a pedra de salvamento e uma fachada por dungeon.

Uso: python3 tools/art/overworld.py && python3 tools/pixel_svg.py
"""

from canvas import Canvas, noise

INK = "#1e181e"
G0, G1, G2, G3, G4, G5 = "#12332f", "#1f5a3a", "#2f8a45", "#59b84c", "#a4dc5a", "#dff29a"
E0, E1, E2, E3, E4, E5 = "#3b2530", "#5c4232", "#8a5a3c", "#b9824e", "#ddb277", "#f3dfa6"
S0, S1, S2, S3, S4, S5, S6 = (
    "#1b1926",
    "#262335",
    "#3a3750",
    "#55526f",
    "#7c7b99",
    "#a9aac2",
    "#d6d8e6",
)
B0, B1, B2, B3, B4, B5 = "#141a3c", "#1a2452", "#27409a", "#3b7bdc", "#6cc3f2", "#c6efff"
P0, P1, P2, P3, P4 = "#1f1238", "#2e1a4f", "#55308f", "#8a59d0", "#c3a0f0"
R1, R2, R3 = "#9c2338", "#d83a3f", "#f0705c"
Y0, Y1, Y2 = "#d99a1c", "#f7c53a", "#fff1a8"
WHITE, FUR = "#ffffff", "#f4f1ea"
PINK = "#e49aa4"
T = 32


def tuft(c, x, y, dark=G2, light=G4):
    """Tufo de grama: três folhinhas."""
    c.px(x, y, dark)
    c.px(x + 1, y - 1, dark)
    c.px(x + 2, y, dark)
    c.px(x + 2, y - 2, light)
    c.px(x + 3, y - 1, dark)
    c.px(x + 4, y, dark)


def grass(variant):
    c = Canvas(T, T, G3)
    spots = {
        0: [(5, 9), (21, 24)],
        1: [(3, 6), (18, 12), (9, 22), (24, 27)],
        2: [(22, 8), (6, 26)],
        3: [(14, 18)],
    }[variant]
    for x, y in spots:
        tuft(c, x, y)
    # Pontos claros soltos, luz do alto à esquerda.
    for x, y in [(12, 4), (27, 15), (4, 17), (17, 29)][: 2 + variant % 2]:
        c.px(x, y, G4)
    if variant == 2:
        for x, y, petal in [(9, 10, WHITE), (20, 20, Y1), (26, 6, WHITE)]:
            flower(c, x, y, petal)
    if variant == 3:
        for x, y, petal in [(6, 8, PINK), (23, 13, Y1), (10, 25, PINK), (25, 26, WHITE)]:
            flower(c, x, y, petal)
    return c


def flower(c, x, y, petal):
    for dx, dy in [(0, -1), (-1, 0), (1, 0), (0, 1)]:
        c.px(x + dx, y + dy, petal)
    c.px(x, y, Y0 if petal != Y1 else R2)
    c.px(x, y + 2, G1)


def path(variant):
    c = Canvas(T, T, E4)
    stones = [(6, 7), (20, 5), (13, 17), (26, 22), (5, 25)]
    if variant:
        stones = [(24, 9), (9, 13), (17, 26), (4, 4)]
    for i, (x, y) in enumerate(stones):
        c.rect(x, y, 3, 2, E3)
        c.px(x, y, E5)
        if i % 2 == 0:
            c.px(x + 3, y + 1, E2)
    for x, y in [(15, 9), (28, 14), (3, 16), (22, 29), (11, 30)]:
        c.px(x, y, E3)
    return c


def water(frame):
    c = Canvas(T, T, B3)
    waves = [(3, 6, 7), (18, 11, 8), (8, 20, 6), (22, 26, 7), (1, 28, 4)]
    for x, y, w in waves:
        x = (x + frame * 5) % T
        for i in range(w):
            c.px((x + i) % T, y - (1 if 1 < i < w - 2 else 0), B4)
        c.px((x + 2) % T, y - 2, B5 if frame == 0 else B4)
    for x, y in [(12, 3), (27, 18), (5, 13)]:
        c.px((x + frame * 9) % T, y, B5)
    return c


def snow(variant):
    c = Canvas(T, T, FUR)
    for x, y, w in [(4, 8, 6), (19, 15, 8), (8, 25, 7)] if not variant else [(15, 6, 7), (3, 19, 6)]:
        c.rect(x, y, w, 1, B5)
        c.rect(x + 1, y + 1, w - 2, 1, B5)
    for x, y in [(25, 5), (12, 14), (28, 27), (3, 29)]:
        c.px(x, y, WHITE)
        c.px(x + 1, y + 1, S6)
    return c


def paving(variant):
    """Calçada do castelo: lajes roxas grandes com junta escura."""
    c = Canvas(T, T, P2)
    c.rect(0, 0, T, 1, P3)
    c.rect(0, 0, 1, T, P3)
    c.rect(0, T - 1, T, 1, P1)
    c.rect(T - 1, 0, 1, T, P1)
    if variant:
        c.rect(0, 15, T, 1, P1)
        c.rect(0, 16, T, 1, P3)
    else:
        c.rect(15, 0, 1, T, P1)
        c.rect(16, 0, 1, T, P3)
    for x, y in [(6, 6), (23, 9), (9, 24), (25, 25)]:
        c.px(x, y, P3)
    return c


def rubble(variant):
    """Chão das ruínas: lajes rachadas, tomadas pelo mato."""
    c = Canvas(T, T, S4)
    c.rect(0, 0, T, 1, S5)
    c.rect(0, 0, 1, T, S5)
    c.rect(0, T - 1, T, 1, S3)
    c.rect(T - 1, 0, 1, T, S3)
    crack = [(8, 0), (9, 5), (13, 9), (12, 15), (17, 20), (16, 31)]
    if variant:
        crack = [(0, 12), (7, 14), (12, 11), (20, 15), (26, 13), (31, 17)]
    for (x0, y0), (x1, y1) in zip(crack, crack[1:]):
        c.line(x0, y0, x1, y1, S2)
    for x, y in [(4, 22), (22, 5), (25, 26)]:
        c.rect(x, y, 4, 3, G2)
        c.rect(x + 1, y - 1, 2, 1, G3)
        c.px(x + 1, y, G4)
    return c


def fringe():
    """Franja de grama de 32 por 7: fica por cima da borda de outro chão,
    com a grama do lado de cima. O MapView a gira para os outros lados."""
    c = Canvas(T, 7)
    heights = [3, 4, 4, 3, 2, 3, 4, 5, 4, 3, 3, 2, 3, 4, 4, 3, 2, 2, 3, 4, 5, 5, 4, 3, 3, 4, 3, 2, 3, 4, 4, 3]
    for x, h in enumerate(heights):
        c.rect(x, 0, 1, h, G3)
        c.px(x, h, G1)
    for x in (2, 7, 13, 20, 25):
        c.px(x, 1, G4)
    return c


def corner():
    """Canto de grama de 9 por 9, para arredondar a quina de outro chão. A
    grama fica no canto de cima à esquerda."""
    c = Canvas(9, 9)
    rows = ["ggggggggd", "ggggggdd.", "gggggd...", "ggggd....", "gggd.....", "ggd......", "gd.......", "gd.......", "d........"]
    c.rows(0, 0, rows, {"g": G3, "d": G1})
    return c


def tree(variant):
    """Árvore de copa redonda, uma por casa da mata."""
    c = Canvas(T, T)
    # Sombra no chão e tronco.
    c.ellipse(16, 28.5, 11, 3, G0)
    c.rect(13, 22, 6, 8, E2)
    c.rect(13, 22, 2, 8, E3)
    c.rect(18, 22, 1, 8, E1)
    c.rect(12, 29, 8, 1, E1)
    # Copa em três tons, luz do alto à esquerda.
    c.ellipse(16, 13, 14, 12.5, G1)
    c.ellipse(14, 11, 11, 9, G2)
    clusters = [(9, 7), (15, 5), (8, 13), (16, 11)] if not variant else [(11, 6), (17, 8), (7, 11), (13, 13)]
    for x, y in clusters:
        c.rect(x, y, 4, 2, G3)
        c.rect(x + 1, y - 1, 2, 1, G3)
        c.px(x + 1, y - 1, G4)
    for x, y in [(21, 15), (24, 11), (19, 20), (11, 20), (5, 17)]:
        c.px(x, y, G0)
        c.px(x + 1, y + 1, G0)
    tr = c.copy()
    c.outline(INK)
    # A sombra do chão não leva contorno.
    for y in range(26, T):
        for x in range(T):
            if tr.get(x, y) is None:
                c.p[y][x] = None
            elif tr.get(x, y) == G0 and y >= 26:
                c.p[y][x] = G0
    c.rect(12, 30, 8, 1, INK)
    return c


def save_stone(lit):
    """Pedra de salvamento: um marco de pedra com uma pata gravada."""
    c = Canvas(32, 40)
    c.ellipse(16, 36, 13, 3.5, G1)
    c.poly([(7, 35), (7, 12), (10, 7), (15, 4), (17, 4), (22, 7), (25, 12), (25, 35)], S4)
    c.poly([(9, 34), (9, 13), (11, 9), (15, 6), (16, 6), (16, 34)], S5)
    c.rect(23, 12, 2, 23, S3)
    c.rect(7, 32, 19, 3, S3)
    glow = Y1 if lit else S2
    core = Y2 if lit else S1
    # Pata: almofada e quatro dedos.
    c.ellipse(16, 21, 4, 3.5, glow)
    for x, y in [(10, 15), (14, 12), (18, 12), (22, 15)]:
        c.ellipse(x + 0.5, y + 0.5, 1.5, 2, glow)
    c.rect(15, 20, 2, 2, core)
    base = c.copy()
    c.outline(INK)
    for y in range(34, 40):
        for x in range(32):
            if base.get(x, y) in (None, G1):
                c.p[y][x] = base.get(x, y)
    return c


def gate():
    """Grade de ferro da entrada trancada, 24 por 32."""
    c = Canvas(24, 32)
    for x in (1, 6, 11, 16, 21):
        c.rect(x, 0, 2, 32, S4)
        c.rect(x, 0, 1, 32, S5)
    for y in (5, 17, 27):
        c.rect(0, y, 24, 2, S3)
        c.rect(0, y, 24, 1, S5)
    c.rect(9, 13, 6, 7, S2)
    c.frame(9, 13, 6, 7, INK)
    c.rect(11, 15, 2, 3, Y1)
    return c


def arch(c, stone, light, dark, joint):
    """Corpo comum das fachadas: bloco de 64 por 64 com o vão escuro da
    porta no meio (24 de largura, da linha 30 ao chão)."""
    c.rect(4, 14, 56, 50, stone)
    c.rect(4, 14, 56, 2, light)
    c.rect(4, 14, 2, 50, light)
    c.rect(57, 16, 3, 48, dark)
    # Fiadas de pedra.
    for row, y in enumerate(range(24, 64, 10)):
        c.rect(4, y, 56, 1, joint)
        for x in range(10 + (row % 2) * 7, 60, 14):
            c.rect(x, y - 9 if row else 16, 1, 9 if row else 8, joint)
    # Vão da porta em arco.
    c.rect(18, 34, 28, 30, joint)
    c.ellipse(32, 35, 14, 9, joint)
    c.rect(20, 36, 24, 28, S0)
    c.ellipse(32, 36, 12, 7, S0)


def facade(kind):
    c = Canvas(64, 64)
    if kind == "stone":
        arch(c, S4, S5, S3, S2)
        # Escoras de madeira e uma placa com a espada: a dungeon de teste.
        c.rect(16, 30, 4, 34, E2)
        c.rect(16, 30, 1, 34, E3)
        c.rect(44, 30, 4, 34, E2)
        c.rect(44, 30, 1, 34, E3)
        c.rect(14, 26, 36, 5, E3)
        c.rect(14, 26, 36, 1, E4)
        c.rect(14, 30, 36, 1, E1)
        c.rect(25, 8, 14, 12, E4)
        c.frame(25, 8, 14, 12, E1)
        c.line(28, 17, 35, 10, S6)
        c.line(29, 17, 36, 10, S5)
        c.line(28, 14, 31, 17, Y1)
    elif kind == "castle":
        arch(c, P2, P3, P1, P0)
        # Ameias, friso dourado e dois estandartes.
        for x in range(4, 60, 12):
            c.rect(x, 6, 8, 8, P2)
            c.rect(x, 6, 8, 1, P3)
            c.rect(x, 6, 1, 8, P3)
        c.rect(4, 20, 56, 2, Y1)
        c.rect(4, 22, 56, 1, Y0)
        for x in (8, 49):
            c.rect(x, 24, 7, 16, R2)
            c.rect(x, 24, 2, 16, R3)
            c.poly([(x, 40), (x + 3, 44), (x + 6, 40)], R2)
            c.rect(x + 2, 29, 3, 3, Y1)
    elif kind == "ice":
        arch(c, B3, B4, B2, B1)
        # Capa de neve e pingentes de gelo.
        c.rect(2, 10, 60, 6, FUR)
        c.ellipse(14, 10, 10, 4, FUR)
        c.ellipse(34, 9, 13, 5, FUR)
        c.ellipse(52, 10, 9, 4, FUR)
        c.rect(2, 15, 60, 1, B5)
        for x, h in [(8, 7), (15, 4), (24, 6), (39, 5), (47, 8), (55, 4)]:
            c.poly([(x, 16), (x + 3, 16), (x + 1, 16 + h)], B5)
            c.px(x, 16, WHITE)
    else:
        arch(c, S4, S5, S3, S2)
        # Ruína: canto quebrado, musgo e trepadeiras.
        c.poly([(44, 14), (60, 14), (60, 26)], None)
        for y in range(14, 27):
            for x in range(44, 61):
                if (x - 44) > (y - 14) * 1.3:
                    c.p[y][x] = None
        c.rect(4, 12, 30, 4, G2)
        c.rect(6, 11, 12, 1, G3)
        c.rect(22, 11, 8, 1, G3)
        for x, h in [(7, 18), (12, 9), (27, 13), (50, 22), (55, 12)]:
            for i in range(h):
                c.px(x + (1 if i % 4 == 2 else 0), 16 + i if x < 40 else 28 + i, G2)
                if i % 3 == 1:
                    c.px(x + 1, (16 + i) if x < 40 else 28 + i, G3)
        c.line(22, 40, 26, 47, S2)
        c.line(26, 47, 24, 52, S2)
    # Degrau claro na soleira.
    c.rect(18, 62, 28, 2, E4 if kind == "stone" else c.get(6, 40))
    c.outline(INK)
    return c


def main():
    for i in range(4):
        grass(i).save("grass_%d" % (i + 1), "Grama do mundo, variação %d. Tons chapados, tufos e flores." % (i + 1))
    for i in range(2):
        path(i).save("path_%d" % (i + 1), "Caminho de terra do mundo, variação %d." % (i + 1))
        water(i).save("water_%d" % (i + 1), "Água do mundo, quadro %d da ondulação." % (i + 1))
        snow(i).save("snow_%d" % (i + 1), "Neve junto da entrada da geleira, variação %d." % (i + 1))
        paving(i).save("paving_%d" % (i + 1), "Calçada junto da entrada do castelo, variação %d." % (i + 1))
        rubble(i).save("rubble_%d" % (i + 1), "Lajes rachadas junto da entrada das ruínas, variação %d." % (i + 1))
        tree(i).save("tree_%d" % (i + 1), "Árvore da mata, variação %d. Uma por casa." % (i + 1))
    fringe().save("grass_fringe", "Franja de grama sobre a borda de outro chão. A grama fica em cima.")
    corner().save("grass_corner", "Canto de grama que arredonda a quina de outro chão.")
    save_stone(False).save("save_stone", "Pedra de salvamento: marco de pedra com uma pata gravada.")
    save_stone(True).save("save_stone_lit", "Pedra de salvamento acesa, logo depois de gravar.")
    gate().save("gate", "Grade de ferro que fecha a entrada de uma dungeon trancada.")
    names = {"stone": "da dungeon de teste, com escoras e a placa da espada", "castle": "do castelo", "ice": "da geleira", "moss": "das ruínas"}
    for kind, text in names.items():
        facade(kind).save("entrance_" + kind, "Fachada da entrada %s. 64 por 64, vão de 24 no meio." % text)


if __name__ == "__main__":
    main()
