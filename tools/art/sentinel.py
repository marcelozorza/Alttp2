"""Sentinela, o chefe do castelo: um Rottweiler grande, de perfil, rosnando.

Pedido de Marcelo em 2026-11-11: o desenho antigo estava ruim, ele quer um
Rottweiler e propôs usar o Magnific para gerar sprites em 8-bit como guia.
As poses foram decalcadas de três folhas geradas lá (trace.py) e retocadas
aqui: pelo num tom só, olhos, dentes, língua e as rachaduras.

São 8 poses (dois passos, empinado e pancada, agachado, dois passos da
investida e cansado) em 3 camadas, que são trocas de cor do mesmo desenho:
a estátua de cimento (shell), com as rachaduras de borda clara da parede
quebrável, o corpo preso no gelo (frost) e a forma original, preto e fogo
(core), que é a que apanha. Todos os quadros têm o
mesmo tamanho, com os pés na mesma linha e o meio do corpo no meio do
quadro, para o desenho ficar sobre a área de contato também espelhado.

As folhas ficam fora do repositório. Sem elas este script não roda, e o
texto em art/source é a fonte.

Uso: python3 tools/art/sentinel.py [pasta das folhas] && python3 tools/pixel_svg.py
"""

import sys

import trace
from canvas import Canvas

SHEETS = "/mnt/project-files/inimigos/rottweiler_ref/"
PIXEL = 4.13
INK = "#1e181e"
COAT, TAN, TAN_DARK = "#262335", "#b9824e", "#8a5a3c"
RED, RED_DARK, GOLD, WHITE, PINK = "#d83a3f", "#9c2338", "#f7c53a", "#ffffff", "#e49aa4"
# Marcas de papel, trocadas pela cor de cada camada no fim.
SHADE, CRACK, CRACK_EDGE, EYE = "shade", "crack", "edge", "eye"
W, H = 80, 64
CX, GROUND = 40, 62

# Três estágios que se leem pela cor (pedido de Marcelo em 2026-11-11): a
# estátua de cimento, rachada, que só a bomba quebra, o corpo preso no gelo,
# que só a chama derrete, e o Rottweiler de verdade, que apanha da espada.
SPECK = "speck"
LAYERS = {
    "shell": {
        SHADE: "#55526f", COAT: "#7c7b99", SPECK: "#8b8aa8", TAN: "#a9aac2", TAN_DARK: "#8b8aa8",
        RED: "#55526f", RED_DARK: "#3a3750", GOLD: "#d6d8e6", WHITE: "#d6d8e6", PINK: "#a9aac2",
        CRACK: INK, CRACK_EDGE: "#d6d8e6", EYE: "#d6d8e6",
    },
    "frost": {
        SHADE: "#27409a", COAT: "#3b7bdc", SPECK: "#6cc3f2", TAN: "#c6efff", TAN_DARK: "#86a9d6",
        RED: "#27409a", RED_DARK: "#1a2452", GOLD: "#c6efff", PINK: "#c6efff",
        CRACK: "#c6efff", CRACK_EDGE: "#ffffff", EYE: WHITE,
    },
    "core": {
        SHADE: "#1b1926", SPECK: COAT, CRACK: COAT, CRACK_EDGE: COAT, EYE: GOLD,
    },
}
NAMES = {"shell": "estátua de cimento", "frost": "preso no gelo", "core": "forma original"}

# Pose: folha, recorte, coluna do decalque que fica no meio do quadro, canto
# da cabeça (para os retoques), retoques da cabeça e rachaduras do corpo.
POSES = {
    "walk": dict(
        text="passo 1", sheet="ref_1.jpg", box=(360, 20, 670, 250), middle=29, head=(39, 0),
        eye=[(15, 7)], pupil=[(16, 7)], teeth=[(16, 15), (19, 15)],
        cracks=[[(12, 18), (14, 21), (12, 24), (14, 27)], [(26, 17), (28, 20), (26, 23), (28, 26)]],
    ),
    "walk_step": dict(
        text="passo 2", sheet="ref_3.jpg", box=(20, 20, 330, 255), middle=30, head=(39, 0),
        eye=[(15, 7)], pupil=[(16, 7)], teeth=[(16, 15), (19, 15)],
        cracks=[[(14, 19), (16, 22), (14, 25), (16, 28)], [(28, 18), (30, 21), (28, 24), (30, 27)]],
    ),
    "slam_windup": dict(
        text="empinado, antes da pancada", sheet="ref_3.jpg", box=(370, 10, 670, 280),
        middle=22, head=(33, 0),
        eye=[(13, 6)], pupil=[(14, 6)], teeth=[(15, 11), (17, 11), (15, 14), (17, 14)],
        mouth=[(15, 12), (16, 12), (15, 13), (16, 13), (16, 11), (16, 14)],
        cracks=[[(12, 38), (15, 40), (13, 43), (16, 46)], [(24, 24), (27, 27), (25, 30), (28, 33)]],
    ),
    "slam": dict(
        text="pancada no chão", sheet="ref_1.jpg", box=(380, 330, 680, 545), middle=30,
        head=(38, 0),
        eye=[(16, 7), (16, 8)], pupil=[(17, 8)], teeth=[(15, 15), (16, 14), (17, 15), (18, 16)],
        cracks=[[(10, 22), (12, 25), (10, 28), (12, 31)], [(24, 15), (26, 18), (24, 21), (26, 24)]],
    ),
    "charge_windup": dict(
        text="agachado, antes da investida", sheet="ref_1.jpg", box=(700, 70, 1010, 255),
        middle=30, head=(40, 0),
        eye=[(16, 16)], pupil=[(17, 16)], teeth=[],
        cracks=[[(10, 10), (12, 13), (10, 16), (12, 19)], [(24, 6), (26, 9), (24, 12), (26, 15)]],
    ),
    "charge": dict(
        text="investida, esticado", sheet="ref_3.jpg", box=(5, 360, 335, 520), middle=36,
        head=(47, 0),
        eye=[(16, 7)], pupil=[(17, 7)], teeth=[(15, 14), (18, 14)],
        cracks=[[(22, 8), (24, 11), (22, 14)], [(36, 7), (38, 10), (36, 13)]],
    ),
    "charge_step": dict(
        text="investida, recolhido", sheet="ref_3.jpg", box=(720, 40, 1015, 255), middle=30,
        head=(37, 0),
        eye=[(16, 8)], pupil=[(17, 8)], teeth=[(16, 16), (19, 16)],
        cracks=[[(10, 14), (12, 17), (10, 20), (12, 23)], [(24, 8), (26, 11), (24, 14), (26, 17)]],
    ),
    "recover": dict(
        text="cansado depois de atacar", sheet="ref_3.jpg", box=(390, 350, 645, 545),
        middle=25, head=(31, 2),
        eye=[], pupil=[], teeth=[],
        tongue=[(x, y) for x in (22, 23, 24) for y in (19, 20, 21)],
        cracks=[[(8, 10), (10, 13), (8, 16), (10, 19)], [(20, 6), (22, 9), (20, 12), (22, 15)]],
    ),
}


def draw(pose, folder):
    colors = [INK, COAT, "#3a3750", TAN, TAN_DARK, RED, RED_DARK, GOLD, WHITE, PINK]
    c = trace.clean(trace.trace(folder + pose["sheet"], pose["box"], PIXEL, colors), (COAT, INK))
    # Pelo num tom só, e nada de branco ou rosa que o decalque deixou solto.
    for stray in ("#3a3750", WHITE, PINK):
        c.replace(stray, COAT)
    for y in range(c.h):
        for x in range(c.w):
            if c.p[y][x] == INK and not trace.is_edge(c, x, y):
                c.p[y][x] = SHADE
    # Grãos do cimento e brilhos do gelo, sempre nos mesmos lugares.
    for y in range(c.h):
        for x in range(c.w):
            if c.p[y][x] == COAT and (x * 7 + y * 13) % 11 == 0 and (x + y * 3) % 4 == 0:
                c.p[y][x] = SPECK
    for line in pose["cracks"]:
        marks = []
        for (x0, y0), (x1, y1) in zip(line, line[1:]):
            n = max(abs(x1 - x0), abs(y1 - y0))
            marks += [(x0 + (x1 - x0) * i // n, y0 + (y1 - y0) * i // n) for i in range(n + 1)]
        for x, y in marks:
            if c.get(x + 1, y) in (COAT, SHADE):
                c.p[y][x + 1] = CRACK_EDGE
        for x, y in marks:
            if c.get(x, y) in (COAT, SHADE, CRACK_EDGE):
                c.p[y][x] = CRACK
    hx, hy = pose["head"]
    for key, color in (("mouth", RED_DARK), ("eye", EYE), ("pupil", SHADE), ("teeth", WHITE), ("tongue", PINK)):
        for x, y in pose.get(key, []):
            c.px(hx + x, hy + y, color)
    frame = Canvas(W, H)
    frame.blit(c, CX - pose["middle"], GROUND - c.h)
    return frame


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else SHEETS
    for name, pose in POSES.items():
        base = draw(pose, folder)
        for layer, swap in LAYERS.items():
            frame = base.copy()
            frame.p = [[swap.get(color, color) for color in row] for row in frame.p]
            frame.save(
                "sentinel_%s_%s" % (layer, name),
                "Sentinela (Rottweiler), %s: %s. Olha para a direita.\nDecalcado de uma folha do"
                " Magnific e retocado por tools/art/sentinel.py." % (NAMES[layer], pose["text"]),
            )


if __name__ == "__main__":
    main()
