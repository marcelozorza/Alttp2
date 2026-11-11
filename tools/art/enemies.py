"""Inimigos comuns decalcados de folhas do Magnific.

Pedido de Marcelo em 2026-11-11: refazer todos os inimigos no estilo da folha
do Rottweiler. Cada inimigo tem uma folha de 12 poses gerada lá, no mesmo
modelo e com a mesma grade de pixels, guardada fora do repositório em
/mnt/project-files/inimigos/<pasta>/ref_12.jpg. Este script acha as casas da
folha pelas linhas que as separam, decalca cada pose (trace.py), tira os
pontos soltos e alinha os quadros de cada inimigo: todos do mesmo tamanho,
com a base na mesma linha e o meio do apoio no meio do quadro.

Substitui os geradores por formas de 2026-11-10 (minion, lobo, morcego,
cobra, tatu e cubo de gelo). Sem as folhas este script não roda, e o texto
em art/source é a fonte.

Uso: python3 tools/art/enemies.py [inimigo ...] && python3 tools/pixel_svg.py
"""

import sys

import numpy as np
from PIL import Image

import trace
from canvas import Canvas

SHEETS = "/mnt/project-files/inimigos/"
PIXEL = 4.23
INK = "#1e181e"
WHITE = "#ffffff"

# Inimigo: pasta da folha, cores da paleta mestra que o decalque pode usar,
# cores escuras que podem virar contorno, e os quadros na ordem das casas da
# folha. Um quadro é (nome, texto) ou (nome, texto, meio), quando o meio do
# apoio não é o meio dos pés. Em "copies", quadros que repetem outro.
FAMILIES = {
    "minion": dict(
        folder="gato_ref",
        text="Minion, o gatinho laranja",
        colors=[INK, "#8a5a3c", "#c85a1e", "#f08c2e", "#ddb277", "#f3dfa6", "#e49aa4", "#9c2338"],
        soft=[INK],
        frames=[
            ("minion_walk_1", "de frente, passo 1", 16),
            ("minion_walk_2", "de frente, passo 2", 17),
            ("minion_back", "de costas, passo 1", 12),
            ("minion_back_step", "de costas, passo 2", 13),
            ("minion_side", "de lado, olhando para a direita, passo 1", 21),
            ("minion_side_step", "de lado, passo 2", 20),
            ("minion_windup", "agachado, rabo para cima, antes do bote", 13),
            ("minion_lunge", "bote de frente, garras para fora", 17),
            ("minion_lunge_up", "bote de costas", 14),
            ("minion_lunge_side", "bote de lado", 22),
            ("minion_recover", "tonto depois do bote", 15),
            ("minion_hit", "levando dano", 17),
        ],
    ),
    "wolf": dict(
        folder="lobo_ref",
        text="Lobo (ugly)",
        colors=[INK, "#3a3750", "#55526f", "#7c7b99", "#a9aac2", "#d6d8e6", WHITE, "#f7c53a",
                "#9c2338", "#d83a3f", "#7a1a78", "#c038b8", "#ee7fe0"],
        soft=[INK, "#3a3750"],
        frames=[
            ("wolf_down", "de frente, passo 1"),
            ("wolf_down_step", "de frente, passo 2"),
            ("wolf_up", "de costas, passo 1"),
            ("wolf_up_step", "de costas, passo 2"),
            ("wolf_side", "de lado, olhando para a direita, passo 1"),
            ("wolf_side_step", "de lado, passo 2"),
            ("wolf_lunge_down", "bote de frente, garras abertas"),
            ("wolf_lunge_up", "bote de costas"),
            ("wolf_lunge_side", "bote de lado, de quatro"),
            ("wolf_throw_windup", "erguendo a bola de gosma"),
            ("wolf_throw", "depois de lançar"),
            ("wolf_hit", "levando dano"),
        ],
        copies={
            "wolf_lunge_down_step": "wolf_lunge_down",
            "wolf_lunge_up_step": "wolf_lunge_up",
            "wolf_lunge_side_step": "wolf_lunge_side",
        },
    ),
    "bat": dict(
        folder="morcego_ref",
        text="Morcego",
        colors=[INK, "#2e1a4f", "#55308f", "#8a59d0", "#c3a0f0", "#f7c53a", WHITE, "#d83a3f"],
        soft=[INK, "#2e1a4f"],
        frames=[
            ("bat_down", "de frente, asas para cima"),
            ("bat_down_step", "de frente, asas para baixo"),
            ("bat_up", "de costas, asas para cima"),
            ("bat_up_step", "de costas, asas para baixo"),
            ("bat_side", "de lado, olhando para a direita, asas para cima"),
            ("bat_side_step", "de lado, asas para baixo"),
            ("bat_windup", "asas recolhidas, antes do mergulho"),
            ("bat_lunge_down", "mergulho de frente"),
            ("bat_lunge_up", "mergulho de costas"),
            ("bat_lunge_side", "mergulho de lado"),
            ("bat_recover", "cansado depois do mergulho"),
            ("bat_hit", "levando dano"),
        ],
        copies={
            "bat_lunge_down_step": "bat_lunge_down",
            "bat_lunge_up_step": "bat_lunge_up",
            "bat_lunge_side_step": "bat_lunge_side",
        },
    ),
    "snake": dict(
        folder="cobra_ref",
        text="Cobra",
        colors=[INK, "#12332f", "#1f5a3a", "#2f8a45", "#d99a1c", "#f3dfa6", "#f7c53a", WHITE,
                "#9c2338"],
        soft=[INK, "#12332f"],
        frames=[
            ("snake_down", "de frente, enrolada, passo 1"),
            ("snake_down_step", "de frente, passo 2"),
            ("snake_up", "de costas, passo 1"),
            ("snake_up_step", "de costas, passo 2"),
            ("snake_side", "de lado, olhando para a direita, passo 1"),
            ("snake_side_step", "de lado, passo 2"),
            ("snake_windup", "capuz aberto, o aviso do bote"),
            ("snake_lunge_side_step", "bote de lado, recolhendo"),
            ("snake_lunge_up", "bote de costas"),
            ("snake_lunge_side", "bote de lado, esticada"),
            ("snake_recover", "cansada depois do bote"),
            ("snake_lunge_down", "bote de frente"),
        ],
        copies={
            "snake_lunge_down_step": "snake_lunge_down",
            "snake_lunge_up_step": "snake_lunge_up",
            "snake_hit": "snake_recover",
        },
    ),
    "armadillo": dict(
        folder="tatu_ref",
        text="Tatu de pedra",
        colors=[INK, "#3a3750", "#55526f", "#7c7b99", "#a9aac2", "#8a5a3c", "#b9824e", "#ddb277",
                "#f3dfa6"],
        soft=[INK, "#3a3750"],
        frames=[
            ("armadillo_down", "de frente, passo 1"),
            ("armadillo_down_step", "de frente, passo 2"),
            ("armadillo_up", "de costas, passo 1"),
            ("armadillo_up_step", "de costas, passo 2"),
            ("armadillo_side", "de lado, olhando para a direita, passo 1"),
            ("armadillo_side_step", "de lado, passo 2"),
            ("armadillo_threat", "de pé, ameaçando"),
            ("armadillo_hide", "escondido no casco"),
            ("armadillo_ball", "enrolado em bola, de frente"),
            ("armadillo_ball_side", "bola rolando, de lado"),
            ("armadillo_hit", "levando dano"),
            ("armadillo_fallen", "tonto"),
        ],
    ),
    "ice_cube": dict(
        folder="cubo_de_gelo_ref",
        text="Cubo de gelo",
        colors=[INK, "#27409a", "#3b7bdc", "#6cc3f2", "#c6efff", WHITE, "#e49aa4", "#d83a3f",
                "#86a9d6"],
        soft=[INK, "#27409a"],
        frames=[
            ("ice_cube_down", "de frente, passo 1"),
            ("ice_cube_down_step", "de frente, passo 2"),
            ("ice_cube_up", "de costas, passo 1"),
            ("ice_cube_up_step", "de costas, passo 2"),
            ("ice_cube_side", "de lado, olhando para a direita, passo 1"),
            ("ice_cube_side_step", "de lado, passo 2"),
            ("ice_cube_windup", "achatado, antes do bote"),
            ("ice_cube_lunge_down", "bote de frente"),
            ("ice_cube_lunge_up", "bote de costas"),
            ("ice_cube_lunge_side", "bote de lado, deslizando"),
            ("ice_cube_recover", "tonto depois do bote"),
            ("ice_cube_hit", "levando dano"),
        ],
        copies={
            "ice_cube_lunge_down_step": "ice_cube_lunge_down",
            "ice_cube_lunge_up_step": "ice_cube_lunge_up",
            "ice_cube_lunge_side_step": "ice_cube_lunge_side",
            "ice_cube_fallen": "ice_cube_recover",
        },
    ),
}


def cells(path):
    """Casas da folha, por linha, achadas pelas linhas cinza que as separam."""
    image = np.asarray(Image.open(path).convert("RGB")).astype(int)
    background = np.median(image.reshape(-1, 3), axis=0)
    line = (np.abs(image - background).sum(axis=2) > 60) & (image.std(axis=2) < 14)

    def cuts(mask, axis, length):
        share = mask.mean(axis=axis)
        marks = [i for i in range(len(share)) if share[i] > 0.97]
        edges, last = [0], -10
        for mark in marks:
            if mark - last > 3:
                edges.append(mark)
            last = mark
        edges.append(length)
        return [(a + 5, b - 4) for a, b in zip(edges, edges[1:]) if b - a > 100]

    boxes = []
    for top, bottom in cuts(line, 1, image.shape[0]):
        for left, right in cuts(line[top:bottom], 0, image.shape[1]):
            boxes.append((left, top, right, bottom))
    return boxes


def despeckle(c):
    """Um ponto de cor sozinho no meio de outra cor vira a cor em volta."""
    for y in range(c.h):
        for x in range(c.w):
            color = c.p[y][x]
            if color is None or color == INK:
                continue
            near = [c.get(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
            if color in near:
                continue
            for other in set(near):
                if other not in (None, INK) and near.count(other) >= 3:
                    c.p[y][x] = other


def support_middle(c):
    """Meio das três linhas de baixo do desenho: onde ele pisa."""
    xs = [x for y in range(c.h - 3, c.h) for x in range(c.w) if c.p[y][x] is not None]
    return (min(xs) + max(xs) + 1) // 2


def build(name):
    family = FAMILIES[name]
    sheet = SHEETS + family["folder"] + "/ref_12.jpg"
    boxes = cells(sheet)
    if len(boxes) != len(family["frames"]):
        sys.exit("%s: a folha tem %d casas, esperava %d" % (name, len(boxes), len(family["frames"])))
    drawn = {}
    for box, frame in zip(boxes, family["frames"]):
        c = trace.clean(trace.trace(sheet, box, PIXEL, family["colors"]), family["soft"])
        despeckle(c)
        middle = frame[2] if len(frame) > 2 else support_middle(c)
        drawn[frame[0]] = (c, middle, frame[1])
    half = max(max(middle, c.w - middle) for c, middle, _ in drawn.values())
    height = max(c.h for c, _, _ in drawn.values()) + 1
    texts = {}
    for frame_name, (c, middle, text) in drawn.items():
        frame = Canvas(half * 2, height)
        frame.blit(c, half - middle, height - 1 - c.h)
        drawn[frame_name] = frame
        texts[frame_name] = text
    for copy, source in family.get("copies", {}).items():
        drawn[copy] = drawn[source]
        texts[copy] = texts[source]
    for frame_name, frame in drawn.items():
        frame.save(
            frame_name,
            "%s: %s.\nDecalcado de uma folha do Magnific por tools/art/enemies.py."
            % (family["text"], texts[frame_name]),
        )
    return half * 2, height


def main():
    for name in sys.argv[1:] or FAMILIES:
        print(name, "%d por %d" % build(name))


if __name__ == "__main__":
    main()
