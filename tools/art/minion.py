"""Minion, o gatinho laranja: 12 quadros decalcados de uma folha do Magnific.

Pedido de Marcelo em 2026-11-11: refazer todos os inimigos no estilo da folha
do Rottweiler. O gato vem de uma folha de 12 poses (4 por 3) gerada lá, no
mesmo modelo e com a mesma grade de pixels. Este script decalca cada pose
(trace.py), tira os pontos soltos que o decalque deixa e alinha os quadros:
todos do mesmo tamanho, com os pés na mesma linha e o meio do corpo no meio
do quadro.

Substitui o gerador de 2026-11-10, que desenhava o gato por formas. A folha
fica fora do repositório. Sem ela este script não roda, e o texto em
art/source é a fonte.

Uso: python3 tools/art/minion.py [pasta da folha] && python3 tools/pixel_svg.py
"""

import sys

import trace
from canvas import Canvas

SHEET = "/mnt/project-files/inimigos/gato_ref/"
PIXEL = 4.23
INK = "#1e181e"
COLORS = [
    INK, "#8a5a3c", "#c85a1e", "#f08c2e", "#ddb277", "#f3dfa6", "#e49aa4", "#9c2338", "#ffffff",
    "#5c4232",
]
W, H = 48, 38
CX, GROUND = 24, 37
# A folha tem 4 colunas de 256 e 3 linhas de 190 pixels na prévia de 1024.
CELL_W, CELL_H = 256, 190

# Quadro: casa da folha (coluna, linha), coluna do decalque que fica no meio
# do quadro e o texto do comentário.
POSES = {
    "minion_walk_1": ((0, 0), 16, "de frente, passo 1"),
    "minion_walk_2": ((1, 0), 17, "de frente, passo 2"),
    "minion_back": ((2, 0), 12, "de costas, passo 1"),
    "minion_back_step": ((3, 0), 13, "de costas, passo 2"),
    "minion_side": ((0, 1), 21, "de lado, olhando para a direita, passo 1"),
    "minion_side_step": ((1, 1), 20, "de lado, passo 2"),
    "minion_windup": ((2, 1), 13, "agachado, rabo para cima, antes do bote"),
    "minion_lunge": ((3, 1), 17, "bote de frente, garras para fora"),
    "minion_lunge_up": ((0, 2), 14, "bote de costas"),
    "minion_lunge_side": ((1, 2), 22, "bote de lado"),
    "minion_recover": ((2, 2), 15, "tonto depois do bote"),
    "minion_hit": ((3, 2), 17, "levando dano"),
}


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


def draw(cell, middle, folder):
    col, row = cell
    box = (col * CELL_W + 6, row * CELL_H + 6, (col + 1) * CELL_W - 6, (row + 1) * CELL_H - 4)
    c = trace.clean(trace.trace(folder + "ref_12.jpg", box, PIXEL, COLORS), (INK, "#5c4232"))
    c.replace("#ffffff", "#f3dfa6")
    c.replace("#5c4232", "#8a5a3c")
    despeckle(c)
    frame = Canvas(W, H)
    frame.blit(c, CX - middle, GROUND - c.h)
    return frame


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else SHEET
    for name, (cell, middle, text) in POSES.items():
        draw(cell, middle, folder).save(
            name,
            "Minion, o gatinho laranja: %s.\nDecalcado de uma folha do Magnific por"
            " tools/art/minion.py." % text,
        )


if __name__ == "__main__":
    main()
