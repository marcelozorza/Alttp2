"""Sentinela, o chefe do castelo: um Rottweiler grande, de perfil, rosnando.

Pedido de Marcelo em 2026-11-11: o desenho antigo estava ruim, ele quer um
Rottweiler e propôs usar o Magnific para gerar sprites em 8-bit como guia.
As poses são decalcadas de duas folhas de 4 poses geradas lá (trace.py), com
pixels menores que os da primeira folha: na montagem de tamanhos de Marcelo
(2026-11-11) o Rottweiler é bem maior que o Giorgino. Aqui o pelo fica num
tom só e entram as rachaduras.

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

import enemies
import trace
from canvas import Canvas

SHEETS = "/mnt/project-files/inimigos/rottweiler_ref/"
PIXEL = 4.0
INK = "#1e181e"
COAT, TAN, TAN_DARK = "#262335", "#b9824e", "#8a5a3c"
RED, RED_DARK, GOLD, WHITE, PINK = "#d83a3f", "#9c2338", "#f7c53a", "#ffffff", "#e49aa4"
# Marcas de papel, trocadas pela cor de cada camada no fim.
SHADE, CRACK, CRACK_EDGE = "shade", "crack", "edge"
W, H = 100, 96
CX, GROUND = 50, 94

# Três estágios que se leem pela cor (pedido de Marcelo em 2026-11-11): a
# estátua de cimento, rachada, que só a bomba quebra, o corpo preso no gelo,
# que só a chama derrete, e o Rottweiler de verdade, que apanha da espada.
SPECK = "speck"
LAYERS = {
    "shell": {
        SHADE: "#55526f", COAT: "#7c7b99", SPECK: "#8b8aa8", TAN: "#a9aac2", TAN_DARK: "#8b8aa8",
        RED: "#55526f", RED_DARK: "#3a3750", GOLD: "#d6d8e6", WHITE: "#d6d8e6", PINK: "#a9aac2",
        CRACK: INK, CRACK_EDGE: "#d6d8e6",
    },
    "frost": {
        SHADE: "#27409a", COAT: "#3b7bdc", SPECK: "#6cc3f2", TAN: "#c6efff", TAN_DARK: "#86a9d6",
        RED: "#27409a", RED_DARK: "#1a2452", GOLD: "#c6efff", PINK: "#c6efff",
        CRACK: "#c6efff", CRACK_EDGE: "#ffffff",
    },
    "core": {
        SHADE: "#1b1926", SPECK: COAT, CRACK: COAT, CRACK_EDGE: COAT,
    },
}
NAMES = {"shell": "estátua de cimento", "frost": "preso no gelo", "core": "forma original"}

# Pose: folha e casa da folha (da esquerda para a direita, de cima para baixo).
POSES = {
    "walk": dict(text="passo 1", sheet="grande_a.jpg", cell=0),
    "walk_step": dict(text="passo 2", sheet="grande_a.jpg", cell=1),
    "slam_windup": dict(text="empinado, antes da pancada", sheet="grande_a.jpg", cell=2),
    "slam": dict(text="pancada no chão", sheet="grande_a.jpg", cell=3),
    "charge_windup": dict(text="agachado, antes da investida", sheet="grande_b.jpg", cell=0),
    "charge": dict(text="investida, esticado", sheet="grande_b.jpg", cell=1),
    "charge_step": dict(text="investida, recolhido", sheet="grande_b.jpg", cell=2),
    "recover": dict(text="cansado depois de atacar", sheet="grande_b.jpg", cell=3),
}


def crack(c, x, y):
    """Rachadura em zigue-zague para baixo, só por cima do pelo."""
    marks = []
    for step in range(12):
        marks.append((x + (1, 2, 1, 0)[step % 4], y + step))
    marks = [(mx, my) for mx, my in marks if c.get(mx, my) in (COAT, SHADE, SPECK)]
    for mx, my in marks:
        if c.get(mx + 1, my) in (COAT, SHADE, SPECK):
            c.p[my][mx + 1] = CRACK_EDGE
    for mx, my in marks:
        c.p[my][mx] = CRACK


def draw(pose, folder):
    colors = [INK, COAT, "#3a3750", TAN, TAN_DARK, RED, RED_DARK, GOLD, WHITE, PINK]
    box = enemies.cells(folder + pose["sheet"], 6)[pose["cell"]]
    c = trace.clean(trace.trace(folder + pose["sheet"], box, PIXEL, colors), (COAT, INK))
    enemies.despeckle(c)
    # Pelo num tom só.
    c.replace("#3a3750", COAT)
    for y in range(c.h):
        for x in range(c.w):
            if c.p[y][x] == INK and not trace.is_edge(c, x, y):
                c.p[y][x] = SHADE
    # Grãos do cimento e brilhos do gelo, sempre nos mesmos lugares.
    for y in range(c.h):
        for x in range(c.w):
            if c.p[y][x] == COAT and (x * 7 + y * 13) % 11 == 0 and (x + y * 3) % 4 == 0:
                c.p[y][x] = SPECK
    # Duas rachaduras no tronco, a partir do lombo: a pista da bomba.
    for share in (0.3, 0.55):
        x = int(c.w * share)
        top = next((y for y in range(c.h) if c.p[y][x] in (COAT, SHADE, SPECK)), None)
        if top is not None:
            crack(c, x, top + 3)
    frame = Canvas(W, H)
    frame.blit(c, CX - c.w // 2, GROUND - c.h)
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
