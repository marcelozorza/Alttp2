"""Chefes de frente decalcados de folhas do Magnific: o caranguejo (guardião
de gelo e guardião antigo) e o cérbero (colosso).

Pedido de Marcelo em 2026-11-11: refazer todos os inimigos no estilo da folha
do Rottweiler. Cada chefe tem folhas de 6 poses geradas lá, guardadas fora do
repositório em /mnt/project-files/inimigos/<pasta>/. Cada camada (casca e
núcleo) escolhe as suas poses pelas casas das folhas. Os quadros de um chefe
têm todos o mesmo tamanho, com a base na mesma linha e o meio do desenho no
meio do quadro. A sentinela tem gerador próprio (sentinel.py).

Sem as folhas este script não roda, e o texto em art/source é a fonte.

Uso: python3 tools/art/bosses.py [chefe ...] && python3 tools/pixel_svg.py
"""

import sys

import thicken

import enemies
import trace
from canvas import Canvas

SHEETS = "/mnt/project-files/inimigos/"
PIXEL = 4.2
INK = "#1e181e"
WHITE = "#ffffff"
TEXTS = {
    "walk": "passo 1",
    "walk_step": "passo 2",
    "slam_windup": "preparando a pancada",
    "slam": "pancada no chão",
    "charge_windup": "preparando a investida",
    "charge": "investida, passo 1",
    "charge_step": "investida, passo 2",
    "recover": "cansado depois de atacar",
}
# Gelo grosso do guardião antigo: a casca do caranguejo em azul-marinho.
THICK = {"#c6efff": "#3b7bdc", "#6cc3f2": "#27409a", "#3b7bdc": "#1a2452", WHITE: "#6cc3f2"}

# Chefe: pasta, cores da paleta mestra, cores escuras que podem virar
# contorno e, por camada, a pose de cada quadro como (folha, casa). Em
# "swaps", camadas que são trocas de cor de outra.
BOSSES = {
    "crab": dict(
        folder="caranguejo_ref",
        text="Caranguejo",
        colors=[INK, "#0e0b0d", "#3b2530", "#5e1830", "#9c2338", "#27409a", "#3b7bdc", "#6cc3f2",
                "#c6efff", WHITE],
        soft=(INK, "#0e0b0d", "#3b2530", "#5e1830"),
        layers={
            "shell": ("com a casca de gelo", {
                "walk": ("ref_1.jpg", 0), "walk_step": ("ref_1.jpg", 3),
                "slam_windup": ("ref_1.jpg", 1), "slam": ("ref_1.jpg", 2),
                "charge_windup": ("ref_2.jpg", 2), "charge": ("ref_1.jpg", 4),
                "charge_step": ("ref_1.jpg", 0), "recover": ("ref_2.jpg", 2),
            }),
            "core": ("sem a casca", {
                "walk": ("ref_1.jpg", 5), "walk_step": ("ref_2.jpg", 5),
                "slam_windup": ("ref_2.jpg", 3), "slam": ("ref_2.jpg", 4),
                "charge_windup": ("ref_2.jpg", 5), "charge": ("ref_2.jpg", 4),
                "charge_step": ("ref_1.jpg", 5),
            }),
        },
        swaps={"thick": ("shell", "com a casca de gelo grosso", THICK)},
    ),
    "cerberus": dict(
        folder="cerbero_ref",
        text="Cérbero",
        colors=[INK, "#1b1926", "#262335", "#3a3750", "#8a5a3c", "#b9824e", "#55526f", "#7c7b99",
                "#a9aac2", "#c85a1e", "#f08c2e", "#f7c53a", "#fff1a8", "#d83a3f", "#e49aa4", WHITE],
        soft=(INK, "#1b1926", "#262335"),
        layers={
            "shell": ("com a armadura de pedra", {
                "walk": ("ref_1.jpg", 0), "walk_step": ("ref_2.jpg", 1),
                "slam_windup": ("ref_2.jpg", 2), "slam": ("ref_1.jpg", 2),
                "charge_windup": ("ref_1.jpg", 3), "charge": ("ref_2.jpg", 4),
                "charge_step": ("ref_2.jpg", 3), "recover": ("ref_2.jpg", 5),
            }),
            "core": ("sem a armadura, o peito em brasa", {
                "walk": ("ref_core.jpg", 0), "walk_step": ("ref_core.jpg", 1),
                "slam_windup": ("ref_1.jpg", 5), "slam": ("ref_core.jpg", 2),
                "charge_windup": ("ref_core.jpg", 3), "charge": ("ref_core.jpg", 4),
                "charge_step": ("ref_core.jpg", 0),
            }),
        },
    ),
}


def build(name):
    boss = BOSSES[name]
    folder = SHEETS + boss["folder"] + "/"
    boxes, drawn = {}, {}
    for layer, (_, poses) in boss["layers"].items():
        for pose, (sheet, cell) in poses.items():
            if sheet not in boxes:
                boxes[sheet] = enemies.cells(folder + sheet)
            c = trace.trace(folder + sheet, boxes[sheet][cell], PIXEL, boss["colors"])
            c = trace.clean(c, boss["soft"])
            enemies.despeckle(c)
            drawn[layer, pose] = c
    half = max((c.w + 1) // 2 for c in drawn.values())
    height = max(c.h for c in drawn.values()) + 1
    frames = {}
    for key, c in drawn.items():
        frame = Canvas(half * 2, height)
        frame.blit(c, half - c.w // 2, height - 1 - c.h)
        frames[key] = frame
    labels = {layer: text for layer, (text, _) in boss["layers"].items()}
    for layer, (source, text, swap) in boss.get("swaps", {}).items():
        labels[layer] = text
        for (other, pose), frame in list(frames.items()):
            if other == source:
                copy = frame.copy()
                copy.p = [[swap.get(color, color) for color in row] for row in copy.p]
                frames[layer, pose] = copy
    for (layer, pose), frame in frames.items():
        frame.save(
            "%s_%s_%s" % (name, layer, pose),
            "%s %s: %s.\nDecalcado de uma folha do Magnific por tools/art/bosses.py."
            % (boss["text"], labels[layer], TEXTS[pose]),
        )
    return half * 2, height


def main():
    for name in sys.argv[1:] or BOSSES:
        print(name, "%d por %d" % build(name))


if __name__ == "__main__":
    main()
    # Um quadro regravado volta com o contorno fino.
    thicken.apply()
