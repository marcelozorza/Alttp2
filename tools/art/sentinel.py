"""Sentinela, o chefe do castelo: um Rottweiler grande, de perfil, rosnando.

Pedido de Marcelo em 2026-11-11: o desenho antigo estava ruim, ele quer um
Rottweiler e propôs usar o Magnific para gerar sprites em 8-bit como guia.

São 8 poses (dois passos, empinado e pancada, agachado, dois passos da
investida e cansado) em 3 estágios, cada um decalcado das suas folhas
(trace.py), duas folhas de 4 poses por estágio, com as mesmas poses:
a estátua de cimento rachada (shell), que só a bomba quebra, o cachorro de
gelo com pingentes (frost), que só a chama derrete, e a forma original,
preto e fogo (core), que apanha da espada. Marcelo pediu no mesmo dia que o
cimento e o gelo fossem desenhados pelo modelo, e não trocas de cor do
desenho original. Todos os quadros têm o mesmo tamanho, com os pés na mesma
linha e o meio do corpo no meio do quadro.

As folhas ficam fora do repositório. Sem elas este script não roda, e o
texto em art/source é a fonte.

Uso: python3 tools/art/sentinel.py [pasta das folhas] && python3 tools/pixel_svg.py
"""

import sys

import thicken

import enemies
import trace
from canvas import Canvas

SHEETS = "/mnt/project-files/inimigos/rottweiler_ref/"
PIXEL = 4.0
INK = "#1e181e"
W, H = 100, 96
CX, GROUND = 50, 94

# Estágio: folhas, cores da paleta mestra que o decalque pode usar, cores
# escuras que podem virar contorno e o texto do desenho.
LAYERS = {
    "shell": dict(
        sheets="cimento_%s.jpg", text="estátua de cimento",
        colors=[INK, "#3a3750", "#55526f", "#7c7b99", "#8b8aa8", "#a9aac2", "#d6d8e6"],
        soft=(INK, "#3a3750", "#55526f"),
    ),
    "frost": dict(
        sheets="gelo_%s.jpg", text="cachorro de gelo",
        colors=[INK, "#1a2452", "#27409a", "#3b7bdc", "#6cc3f2", "#c6efff", "#ffffff"],
        soft=(INK, "#1a2452", "#27409a"),
    ),
    "core": dict(
        sheets="grande_%s.jpg", text="forma original",
        colors=[INK, "#1b1926", "#262335", "#3a3750", "#b9824e", "#8a5a3c", "#d83a3f", "#9c2338",
                "#f7c53a", "#ffffff", "#e49aa4"],
        soft=(INK, "#1b1926", "#262335"),
    ),
}
# Pose: folha (a ou b) e casa da folha, da esquerda para a direita e de cima
# para baixo.
POSES = {
    "walk": ("passo 1", "a", 0),
    "walk_step": ("passo 2", "a", 1),
    "slam_windup": ("empinado, antes da pancada", "a", 2),
    "slam": ("pancada no chão", "a", 3),
    "charge_windup": ("agachado, antes da investida", "b", 0),
    "charge": ("investida, esticado", "b", 1),
    "charge_step": ("investida, recolhido", "b", 2),
    "recover": ("cansado depois de atacar", "b", 3),
}
CRACK_EDGE = "#d6d8e6"


def draw(layer, sheet, cell):
    box = enemies.cells(sheet, 6)[cell]
    c = trace.clean(trace.trace(sheet, box, PIXEL, layer["colors"]), layer["soft"])
    enemies.despeckle(c)
    if layer["text"] == "forma original":
        # Pelo num tom só.
        c.replace("#3a3750", "#262335")
    if layer["text"] == "estátua de cimento":
        # A rachadura ganha a borda clara da parede quebrável: a pista da bomba.
        dark = [
            (x, y) for y in range(c.h) for x in range(c.w)
            if c.p[y][x] == INK and not trace.is_edge(c, x, y)
        ]
        for x, y in dark:
            if c.get(x + 1, y) in ("#7c7b99", "#8b8aa8", "#55526f"):
                c.p[y][x + 1] = CRACK_EDGE
    frame = Canvas(W, H)
    frame.blit(c, CX - c.w // 2, GROUND - c.h)
    return frame


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else SHEETS
    for name, layer in LAYERS.items():
        for pose, (text, sheet, cell) in POSES.items():
            draw(layer, folder + layer["sheets"] % sheet, cell).save(
                "sentinel_%s_%s" % (name, pose),
                "Sentinela (Rottweiler), %s: %s. Olha para a direita.\nDecalcado de uma folha do"
                " Magnific por tools/art/sentinel.py." % (layer["text"], text),
            )


if __name__ == "__main__":
    main()
    # Um quadro regravado volta com o contorno fino.
    thicken.apply()
