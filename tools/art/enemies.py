"""Inimigos comuns decalcados de folhas do Magnific.

Pedido de Marcelo em 2026-11-11: refazer todos os inimigos no estilo da folha
do Rottweiler. Cada inimigo tem uma folha de 12 poses gerada lá, no mesmo
modelo e com a mesma grade de pixels, guardada fora do repositório em
/mnt/project-files/inimigos/<pasta>/ref_12.jpg. Este script acha as casas da
folha pelas linhas que as separam, decalca cada pose (trace.py), tira os
pontos soltos e alinha os quadros de cada inimigo: todos do mesmo tamanho,
com a base na mesma linha e o meio do apoio no meio do quadro.

Substitui os geradores por formas de 2026-11-10 (minion, lobo, morcego,
cobra, tatu, cubo de gelo, estalactite e macaco). Sem as folhas este script não roda, e o texto
em art/source é a fonte.

Uso: python3 tools/art/enemies.py [inimigo ...] && python3 tools/pixel_svg.py
"""

import sys

import thicken

import numpy as np
from PIL import Image

import trace
from canvas import Canvas

SHEETS = "/mnt/project-files/inimigos/"
PIXEL = 4.23
INK = "#1e181e"
WHITE = "#ffffff"
# Tamanhos relativos pedidos por Marcelo em 2026-11-11, numa montagem com o
# Giorgino ao lado: cobra, tatu e morcego com três quartos do tamanho da
# folha. Ler a folha com um passo maior que o pixel dela amassava o traço,
# então essas famílias são decalcadas no tamanho da folha e reduzidas por
# shrink(), que refaz o contorno ("shrink" na família).

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
        # Três folhas de 4 poses, com o lobo grande: na montagem de Marcelo
        # ele tem quase uma vez e meia a altura do Giorgino.
        sheets=["grande_a.jpg", "grande_b.jpg", "grande_c.jpg"],
        pixel=4.8,
        # As linhas destas folhas são mais grossas.
        margin=6,
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
        shrink=True,
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
        shrink=True,
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
        shrink=True,
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
    "stalactite": dict(
        folder="estalactite_ref",
        text="Estalactite",
        colors=[INK, "#27409a", "#5a7fb5", "#86a9d6", "#b4cdec", "#c6efff", WHITE, "#e49aa4",
                "#d83a3f"],
        soft=[INK, "#27409a"],
        # A linha da folha passa por trás do bote de lado: sai antes da limpeza.
        thin_lines=True,
        # O bote de lado ocupa duas casas, então as casas vão escritas.
        boxes=[
            (4, 4, 252, 186), (260, 4, 508, 186), (516, 4, 764, 186), (772, 4, 1020, 186),
            (4, 194, 252, 376), (260, 194, 508, 376), (516, 194, 764, 376), (772, 194, 1020, 376),
            (518, 194, 764, 376), (4, 384, 252, 568), (340, 390, 624, 566), (626, 384, 766, 568),
            (790, 384, 1020, 568),
        ],
        frames=[
            ("stalactite_down", "de frente, passo 1"),
            ("stalactite_down_step", "de frente, passo 2"),
            ("stalactite_up", "de costas, passo 1"),
            ("stalactite_up_step", "de costas, passo 2"),
            ("stalactite_side", "de lado, olhando para a direita, passo 1"),
            ("stalactite_side_step", "de lado, passo 2"),
            ("stalactite_windup", "braços erguidos, antes do bote"),
            ("stalactite_lunge_down", "bote de frente"),
            ("stalactite_lunge_down_step", "bote de frente, segundo quadro"),
            ("stalactite_lunge_up", "bote de costas"),
            ("stalactite_lunge_side", "bote de lado, a ponta para a frente"),
            ("stalactite_recover", "tonta depois do bote"),
            ("stalactite_hit", "levando dano"),
        ],
        copies={
            "stalactite_lunge_up_step": "stalactite_lunge_up",
            "stalactite_lunge_side_step": "stalactite_lunge_side",
        },
    ),
    "monkey": dict(
        folder="macaco_ref",
        text="Macaco atirador",
        colors=[INK, "#3b2530", "#5c4232", "#8a5a3c", "#b9824e", "#ddb277", "#f3dfa6", WHITE,
                "#55526f", "#7c7b99", "#a9aac2"],
        soft=[INK, "#3b2530"],
        # O fundo preso dentro da curva do rabo sai. A pedra fica.
        holes=("#a9aac2", ("#55526f", "#7c7b99")),
        # Um tom mais escuro em tudo: o rosto e a barriga tinham a cor do piso
        # de areia das ruínas e o macaco parecia vazado (Marcelo, 2026-11-11).
        recolor=[("#5c4232", "#3b2530"), ("#8a5a3c", "#5c4232"), ("#b9824e", "#8a5a3c"),
                 ("#ddb277", "#b9824e"), ("#f3dfa6", "#ddb277")],
        frames=[
            ("monkey_down", "de frente, passo 1"),
            ("monkey_down_step", "de frente, passo 2"),
            ("monkey_up", "de costas, passo 1"),
            ("monkey_up_step", "de costas, passo 2"),
            ("monkey_side", "de lado, olhando para a direita, passo 1"),
            ("monkey_side_step", "de lado, passo 2"),
            ("monkey_throw_windup", "de frente, a pedra erguida"),
            ("monkey_throw", "de frente, depois de arremessar"),
            ("monkey_throw_windup_up", "de costas, a pedra erguida"),
            ("monkey_throw_up", "de costas, depois de arremessar"),
            ("monkey_throw_windup_side", "de lado, a pedra erguida"),
            ("monkey_throw_side", "de lado, depois de arremessar"),
        ],
        copies={"monkey_hit": "monkey_down_step"},
    ),
}


def cells(path, margin=0):
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
        return [(a + 5 + margin, b - 4 - margin) for a, b in zip(edges, edges[1:]) if b - a > 100]

    boxes = []
    for top, bottom in cuts(line, 1, image.shape[0]):
        for left, right in cuts(line[top:bottom], 0, image.shape[1]):
            boxes.append((left, top, right, bottom))
    return boxes


def open_holes(c, color, keep_near):
    """Tira as manchas da cor do fundo presas dentro do desenho, menos as que
    encostam nas cores de keep_near."""
    seen = set()
    for y in range(c.h):
        for x in range(c.w):
            if c.p[y][x] != color or (x, y) in seen:
                continue
            piece, todo, keep = [], [(x, y)], False
            seen.add((x, y))
            while todo:
                px, py = todo.pop()
                piece.append((px, py))
                for near in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                    if c.get(*near) in keep_near:
                        keep = True
                    if c.get(*near) == color and near not in seen:
                        seen.add(near)
                        todo.append(near)
            if not keep:
                for px, py in piece:
                    c.p[py][px] = None


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


def shrink(c):
    """Reduz o desenho a três quartos, limpo: 3 pixels novos para cada 4 da
    folha. Ler a folha com passo maior amassa o traço (linhas que dobram ou
    somem), e Marcelo pediu em 2026-11-11 o tatu redesenhado do tamanho
    certo. Aqui cada pixel novo pega a cor que mais aparece na área dele, o
    contorno é refeito com 1 pixel por fora da silhueta e as linhas de dentro
    são afinadas para 1 pixel."""
    w, h = (c.w * 3 + 3) // 4, (c.h * 3 + 3) // 4
    out = Canvas(w, h)
    ink = [[0.0] * w for _ in range(h)]
    for ty in range(h):
        for tx in range(w):
            votes, inside, lines = {}, 0, 0
            for sy in range(ty * 4, ty * 4 + 4):
                for sx in range(tx * 4, tx * 4 + 4):
                    color = c.get(sx // 3, sy // 3)
                    if color is None:
                        continue
                    inside += 1
                    if color == INK:
                        if not trace.is_edge(c, sx // 3, sy // 3):
                            lines += 1
                    else:
                        votes[color] = votes.get(color, 0) + 1
            if inside >= 8:
                out.p[ty][tx] = max(votes, key=votes.get) if votes else INK
                ink[ty][tx] = lines / 16.0
    # Cor de quem ficou só com tinta: a do vizinho colorido mais perto.
    for ty in range(h):
        for tx in range(w):
            if out.p[ty][tx] == INK:
                near = [out.get(tx + dx, ty + dy) for dx, dy in ((0, 1), (1, 0), (0, -1), (-1, 0))]
                near = [color for color in near if color not in (None, INK)]
                if near:
                    out.p[ty][tx] = near[0]
    # Linhas de dentro: onde a tinta cobre boa parte do pixel, afinadas.
    marks = {(x, y) for y in range(h) for x in range(w) if out.p[y][x] and ink[y][x] >= 0.4}
    changed = True
    while changed:
        changed = False
        for x, y in sorted(marks, key=lambda p: ink[p[1]][p[0]]):
            block = [
                [(x + dx + ox, y + dy + oy) for dx in (0, 1) for dy in (0, 1)]
                for ox in (-1, 0)
                for oy in (-1, 0)
            ]
            if any(all(p in marks for p in cells4) for cells4 in block):
                marks.discard((x, y))
                changed = True
                break
    for x, y in marks:
        out.p[y][x] = INK
    for y in range(h):
        for x in range(w):
            if out.p[y][x] and trace.is_edge(out, x, y):
                out.p[y][x] = INK
    return out.crop()


def support_middle(c):
    """Meio das três linhas de baixo do desenho: onde ele pisa."""
    xs = [x for y in range(c.h - 3, c.h) for x in range(c.w) if c.p[y][x] is not None]
    return (min(xs) + max(xs) + 1) // 2


def build(name):
    family = FAMILIES[name]
    folder = SHEETS + family["folder"] + "/"
    boxes = []
    for sheet in family.get("sheets", ["ref_12.jpg"]):
        boxes += [(folder + sheet, box) for box in family.get("boxes") or cells(folder + sheet, family.get("margin", 0))]
    if len(boxes) != len(family["frames"]):
        sys.exit("%s: a folha tem %d casas, esperava %d" % (name, len(boxes), len(family["frames"])))
    drawn = {}
    for (sheet, box), frame in zip(boxes, family["frames"]):
        c = trace.trace(sheet, box, family.get("pixel", PIXEL), family["colors"])
        if family.get("thin_lines"):
            for _ in range(2):
                thin = [
                    (x, y)
                    for y in range(c.h)
                    for x in range(c.w)
                    if c.p[y][x] and c.get(x - 1, y) is None and c.get(x + 1, y) is None
                ]
                for x, y in thin:
                    c.p[y][x] = None
        if family.get("holes"):
            open_holes(c, *family["holes"])
        c = trace.clean(c, family["soft"])
        despeckle(c)
        if family.get("shrink"):
            c = shrink(c)
        for old, new in family.get("recolor", []):
            c.replace(old, new)
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
    # Um quadro regravado volta com o contorno fino.
    thicken.apply()
