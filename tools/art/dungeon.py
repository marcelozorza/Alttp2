"""Cenários das dungeons no traço de 2026-11-10 (8-bit revisitado).

Para cada tema (pedra, castelo, gelo e ruínas): chão em duas variações, chão
alto e mais alto, topo de parede, face de frente, face lateral e parede
rachada. Para todos: degrau, degrau duplo, portas, grade, gelo e gelo grosso.
Cada tema tem a lajota e o tijolo com forma própria, e não só outra paleta.

Uso: python3 tools/art/dungeon.py && python3 tools/pixel_svg.py
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
G0, G1, G2, G3, G4 = "#12332f", "#1f5a3a", "#2f8a45", "#59b84c", "#a4dc5a"
B0, B1, B2, B3, B4, B5 = "#141a3c", "#1a2452", "#27409a", "#3b7bdc", "#6cc3f2", "#c6efff"
P0, P1, P2, P3, P4 = "#1f1238", "#2e1a4f", "#55308f", "#8a59d0", "#c3a0f0"
R0, R1, R2, R3 = "#5e1830", "#9c2338", "#d83a3f", "#f0705c"
Y0, Y1, Y2 = "#d99a1c", "#f7c53a", "#fff1a8"
FUR, WHITE = "#f4f1ea", "#ffffff"
F0, F1, F2 = "#5a7fb5", "#86a9d6", "#b4cdec"
T = 32

# Por tema: tons do chão (base, luz, junta), do topo da parede (base, grão) e
# da face (tijolo, luz, junta, friso).
THEMES = {
    "": {"floor": (S3, S4, S2), "top": (S0, S1), "face": (S2, S3, S0, S5)},
    "_castle": {"floor": (S5, S6, S4), "top": (P0, P1), "face": (P2, P3, P1, Y1)},
    "_ice": {"floor": (F1, F2, F0), "top": (B0, B1), "face": (B2, B3, B1, FUR)},
    "_moss": {"floor": (S4, S5, S3), "top": (G0, G1), "face": (G1, G2, G0, G3)},
}
HIGH = (E4, E5, E3)
HIGHER = (E5, FUR, E4)


def slab(c, x, y, w, h, base, light, dark):
    """Laje com luz em cima e à esquerda e junta embaixo e à direita."""
    c.rect(x, y, w, h, base)
    c.rect(x, y, w, 1, light)
    c.rect(x, y, 1, h, light)
    c.rect(x, y + h - 1, w, 1, dark)
    c.rect(x + w - 1, y, 1, h, dark)


def floor(theme, tones, alt):
    base, light, dark = tones
    c = Canvas(T, T, base)
    if theme == "":
        # Pedra crua: uma laje grande, ou duas meias lajes.
        if alt:
            slab(c, 0, 0, 16, T, base, light, dark)
            slab(c, 16, 0, 16, T, base, light, dark)
        else:
            slab(c, 0, 0, T, T, base, light, dark)
        for x, y in [(7, 9), (22, 20), (11, 25)]:
            c.px(x + alt * 3, y, dark)
    elif theme == "_castle":
        # Xadrez de mármore: a casa alternada é mais escura, com um losango.
        if alt:
            base, light, dark = dark, base, S3 if tones[0] == S5 else tones[2]
            if tones is HIGH:
                base, light, dark = E3, E4, E2
            if tones is HIGHER:
                base, light, dark = E4, E5, E3
        slab(c, 0, 0, T, T, base, light, dark)
        if alt:
            c.poly([(16, 10), (22, 16), (16, 22), (10, 16)], light)
            c.poly([(16, 12), (20, 16), (16, 20), (12, 16)], base)
    elif theme == "_ice":
        # Gelo liso: riscos de brilho em diagonal e trincas finas.
        streaks = [(5, 12, 6), (18, 26, 8)] if not alt else [(20, 14, 6)]
        for x, y, n in streaks:
            for i in range(n):
                c.px(x + i, y - i, light)
                c.px(x + i + 1, y - i, light)
        crack = [(27, 2), (24, 6), (26, 10)] if not alt else []
        for (x0, y0), (x1, y1) in zip(crack, crack[1:]):
            c.line(x0, y0, x1, y1, dark)
    else:
        # Ruínas: lajes rachadas com mato nas frestas.
        slab(c, 0, 0, T, T, base, light, dark)
        crack = [(20, 1), (22, 6), (19, 10), (23, 14)] if alt else []
        for (x0, y0), (x1, y1) in zip(crack, crack[1:]):
            c.line(x0, y0, x1, y1, dark)
        for x, y in [(4, 24)] if not alt else [(25, 26)]:
            c.rect(x, y, 4, 3, G2)
            c.rect(x + 1, y - 1, 2, 1, G3)
            c.px(x + 1, y, G4)
    return c


def wall_top(tones):
    base, grain = tones
    c = Canvas(T, T, base)
    for x, y in [(6, 5), (21, 9), (12, 19), (26, 24), (4, 27)]:
        c.rect(x, y, 2, 1, grain)
    return c


def bricks(c, theme, tones, x0, y0, w, h, course, length):
    """Fiadas de tijolo numa área. As juntas verticais desencontram."""
    brick, light, joint, _trim = tones
    c.rect(x0, y0, w, h, brick)
    row = 0
    y = y0
    while y < y0 + h:
        c.rect(x0, y, w, 1, light)
        end = min(y + course, y0 + h)
        c.rect(x0, end - 1, w, 1, joint)
        offset = (row % 2) * (length // 2)
        for x in range(x0 + offset, x0 + w, length):
            c.rect(x, y, 1, end - y, joint)
        if theme == "_moss" and row % 2 == 0:
            c.rect(x0 + 5 + row * 3, y + 2, 3, 2, G2)
            c.px(x0 + 6 + row * 3, y + 2, G3)
        if theme == "_ice":
            c.px(x0 + 3 + offset, y + 2, B4)
            c.px(x0 + 4 + offset, y + 3, B4)
        y += course
        row += 1


def wall_face(theme, top, tones):
    """Face de frente: o chão fica ao sul. Os 24 pixels de baixo são a face,
    com um friso no alto e a linha escura do rodapé."""
    c = wall_top(top)
    bricks(c, theme, tones, 0, 10, T, 21, 7, 16)
    c.rect(0, 8, T, 2, tones[3])
    c.rect(0, 9, T, 1, tones[1] if theme != "_castle" else Y0)
    c.rect(0, 31, T, 1, INK)
    return c


def wall_side(theme, top, tones):
    """Face lateral: o chão fica a leste. Os 24 pixels da direita são a face,
    com as fiadas em pé, como a lateral vista em perspectiva."""
    brick, light, joint, trim = tones
    c = wall_top(top)
    c.rect(10, 0, 21, T, brick)
    col = 0
    for x in range(10, 31, 7):
        c.rect(x, 0, 1, T, light)
        c.rect(x + 6, 0, 1, T, joint)
        for y in range((col % 2) * 8, T, 16):
            c.rect(x, y, 7, 1, joint)
        col += 1
    c.rect(8, 0, 2, T, trim)
    c.rect(9, 0, 1, T, light if theme != "_castle" else Y0)
    c.rect(31, 0, 1, T, INK)
    return c


def cracked_wall(theme, top, tones):
    """Parede rachada: a face de tijolos na casa inteira, com uma rachadura
    grande e lascas, a pista da bomba."""
    c = Canvas(T, T)
    bricks(c, theme, tones, 0, 2, T, 29, 7, 16)
    c.rect(0, 0, T, 2, tones[3])
    c.rect(0, 31, T, 1, INK)
    crack = [(15, 2), (13, 8), (17, 13), (14, 19), (18, 24), (16, 30)]
    for (xa, ya), (xb, yb) in zip(crack, crack[1:]):
        c.line(xa, ya, xb, yb, INK)
        c.line(xa + 1, ya, xb + 1, yb, INK)
    for (xa, ya), (xb, yb) in [((13, 8), (7, 11)), ((17, 13), (24, 15)), ((14, 19), (8, 23)), ((18, 24), (25, 27))]:
        c.line(xa, ya, xb, yb, INK)
    for x, y in [(11, 5), (20, 10), (10, 16), (21, 21)]:
        c.px(x, y, tones[1])
    return c


def ledge(tall):
    """Face do degrau: a mesma pedra quente do chão alto, na sombra."""
    h = 64 if tall else 32
    brick, light, joint = (E2, E3, E1) if tall else (E3, E4, E2)
    c = Canvas(T, h)
    bricks(c, "", (brick, light, joint, None), 0, 3, T, h - 4, 7 if not tall else 10, 16)
    c.rect(0, 0, T, 2, E5 if not tall else E4)
    c.rect(0, 2, T, 1, joint)
    c.rect(0, h - 1, T, 1, INK)
    return c


def locked_door():
    """Porta trancada: tábuas com cintas de ferro e a fechadura dourada."""
    c = Canvas(T, T, E3)
    for x in (0, 8, 16, 24):
        c.rect(x, 0, 1, T, E4)
        c.rect(x + 7, 0, 1, T, E2)
    for y in (4, 24):
        c.rect(0, y, T, 4, S3)
        c.rect(0, y, T, 1, S5)
        c.rect(0, y + 3, T, 1, S2)
        for x in (4, 12, 20, 28):
            c.px(x, y + 1, S6)
    c.rect(11, 10, 10, 12, Y1)
    c.rect(11, 10, 10, 1, Y2)
    c.rect(11, 21, 10, 1, Y0)
    c.frame(10, 9, 12, 14, INK)
    c.rect(15, 13, 2, 2, INK)
    c.rect(14, 12, 4, 3, INK)
    c.rect(15, 15, 2, 4, INK)
    c.frame(0, 0, T, T, INK)
    return c


def boss_door():
    """Porta do chefe: vermelha, com rebites dourados e a fechadura grande."""
    c = Canvas(T, T, R1)
    c.rect(2, 2, 28, 28, R2)
    c.rect(2, 2, 28, 1, R3)
    c.rect(2, 2, 1, 28, R3)
    c.rect(4, 28, 26, 2, R1)
    c.rect(28, 4, 2, 26, R1)
    for x, y in [(4, 4), (26, 4), (4, 26), (26, 26)]:
        c.rect(x, y, 2, 2, Y1)
        c.px(x, y, Y2)
    # Caveira dourada de fechadura.
    c.ellipse(16, 14, 7, 6.5, Y1)
    c.rect(12, 18, 8, 5, Y1)
    c.ellipse(14, 10, 3, 1.5, Y2)
    c.rect(12, 13, 3, 3, INK)
    c.rect(17, 13, 3, 3, INK)
    c.rect(15, 17, 2, 2, INK)
    for x in (13, 16, 19):
        c.rect(x, 21, 1, 2, INK)
    c.frame(0, 0, T, T, INK)
    return c


def gate_door():
    """Grade de ferro: barras em pé sobre o vão escuro."""
    c = Canvas(T, T, S0)
    for x in (2, 8, 14, 20, 26):
        c.rect(x, 0, 4, T, S4)
        c.rect(x, 0, 1, T, S5)
        c.rect(x + 3, 0, 1, T, S3)
    for y in (4, 24):
        c.rect(0, y, T, 4, S4)
        c.rect(0, y, T, 1, S6)
        c.rect(0, y + 3, T, 1, S2)
    c.rect(0, 0, T, 1, INK)
    c.rect(0, 31, T, 1, INK)
    return c


def ice(thick, top_only):
    """Bloco de gelo: o topo claro e, na frente, a face com brilhos. O gelo
    grosso é o mesmo desenho, dois tons mais escuro, para mostrar que a chama
    comum não basta. Ele tinha cristais brancos e o topo da cor da face do
    gelo comum, e Marcelo não entendeu do que se tratava (2026-11-11): "tem
    que ser como o primeiro, mas mais escuro"."""
    top, face, deep, shine = (B5, B4, B3, WHITE) if not thick else (B3, B2, B1, B5)
    c = Canvas(T, T, top)
    for x, y, n in [(4, 6, 4), (20, 4, 3)]:
        for i in range(n):
            c.px(x + i, y - (i // 2), shine)
    if top_only:
        return c
    c.rect(0, 11, T, 21, face)
    c.rect(0, 10, T, 1, shine)
    for x, y, n in [(4, 26, 9), (7, 27, 9), (20, 22, 5)]:
        for i in range(n):
            c.px(x + i, y - i, top)
    for x in (13, 25):
        c.rect(x, 13, 1, 17, deep)
    c.rect(0, 30, T, 1, deep)
    c.rect(0, 31, T, 1, INK)
    return c


def main():
    names = {"": "da pedra", "_castle": "do castelo", "_ice": "da geleira", "_moss": "das ruínas"}
    for theme, parts in THEMES.items():
        text = names[theme]
        for alt in (0, 1):
            suffix = ("_alt" if alt else "") + theme
            floor(theme, parts["floor"], alt).save("floor" + suffix, "Chão %s, variação %d." % (text, alt + 1))
            floor(theme, HIGH, alt).save("high_floor" + suffix, "Chão alto %s, variação %d. Cor quente." % (text, alt + 1))
            floor(theme, HIGHER, alt).save("higher_floor" + suffix, "Chão mais alto %s, variação %d." % (text, alt + 1))
        wall_top(parts["top"]).save("wall" + theme, "Topo da parede %s." % text)
        wall_face(theme, parts["top"], parts["face"]).save("wall_face" + theme, "Face de frente da parede %s. Os 24 pixels de baixo são a face." % text)
        wall_side(theme, parts["top"], parts["face"]).save("wall_side" + theme, "Face lateral da parede %s. Os 24 pixels da direita são a face." % text)
        cracked_wall(theme, parts["top"], parts["face"]).save("cracked_wall" + theme, "Parede rachada %s: só a bomba abre." % text)
    ledge(False).save("ledge", "Face do degrau, 32 de altura.")
    ledge(True).save("tall_ledge", "Face do degrau duplo, 64 de altura, mais escura.")
    locked_door().save("locked_door", "Porta trancada, uma casa.")
    boss_door().save("boss_door", "Porta do chefe, uma casa.")
    gate_door().save("gate_door", "Grade que o interruptor abre, uma casa.")
    ice(False, False).save("ice", "Gelo: topo e face.")
    ice(False, True).save("ice_top", "Gelo: só o topo, para a casa com outro bloco ao sul.")
    ice(True, False).save("thick_ice", "Gelo grosso: topo e face.")
    ice(True, True).save("thick_ice_top", "Gelo grosso: só o topo.")


if __name__ == "__main__":
    main()
