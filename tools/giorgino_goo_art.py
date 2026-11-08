"""Gera o Giorgino sujo de gosma: uma cópia de cada quadro com a gosma pintada.

Pedido de Marcelo em 2026-11-08: enquanto a espada está travada pela granada
do ugly, o Giorgino aparece coberto de gosma magenta, e isso tem que ser
desenho, não um efeito por cima (o shader de antes saiu). Para cada quadro
giorgino_*.txt sai um giorgino_goo_*.txt com a mesma forma: a gosma cobre o
alto do desenho (cabeça e ombros) e escorre em fios de comprimentos
diferentes pelo corpo, com borda escura, brilhos e gotas penduradas. O
padrão dos fios é sorteado com semente fixa por quadro, então o resultado é
sempre o mesmo e pode ser editado à mão depois, se for o caso.

Uso: python3 tools/giorgino_goo_art.py && python3 tools/pixel_svg.py
"""
import pathlib
import random
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "art" / "source"
sys.path.insert(0, str(ROOT / "tools"))
import pixel_svg  # noqa: E402

FRAMES = [
    "giorgino_stand_down", "giorgino_stand_down_step", "giorgino_stand_up", "giorgino_stand_up_step",
    "giorgino_stand_side", "giorgino_stand_side_step", "giorgino_down", "giorgino_down_step",
    "giorgino_up", "giorgino_up_step", "giorgino_side", "giorgino_side_step", "giorgino_fallen",
]
## Cores da gosma, as mesmas de tools/goo_art.py. As letras maiúsculas não
## colidem com as paletas do Giorgino.
GOO = {"D": "#8e2280", "P": "#d24cbc", "L": "#ef80dc", "H": "#ffd2f4"}
## Fração da altura do desenho coberta por inteiro, a partir do alto: só uma
## calota no alto da cabeça, para o rosto continuar à vista.
CAP = 0.2
## Comprimento dos fios abaixo da calota, em fração da altura, e a chance de
## cada par de colunas ter um fio.
DRIP_MIN, DRIP_MAX = 0.08, 0.4
DRIP_CHANCE = 0.55


def column_tops(rows):
    """Primeira linha com pixel de cada coluna, ou None."""
    tops = []
    for x in range(len(rows[0])):
        top = next((y for y, row in enumerate(rows) if row[x] != "."), None)
        tops.append(top)
    return tops


def goo_mask(rows, seed):
    """Onde a gosma cobre: a calota do alto e fios por coluna, só sobre
    pixels do desenho."""
    rng = random.Random(seed)
    h, w = len(rows), len(rows[0])
    tops = column_tops(rows)
    cap_end = int(h * CAP)
    mask = [[False] * w for _ in range(h)]
    # alguns pares de colunas ganham um fio, os outros param na calota
    lengths = []
    for x in range(0, w, 2):
        length = rng.uniform(DRIP_MIN, DRIP_MAX) if rng.random() < DRIP_CHANCE else 0.0
        lengths += [length, length]
    for x in range(w):
        if tops[x] is None:
            continue
        end = cap_end + int(h * lengths[x])
        for y in range(tops[x], min(h, end)):
            if rows[y][x] != ".":
                mask[y][x] = True
    # um respingo no corpo, uma elipse irregular pelo meio do desenho
    cx, cy = w * rng.uniform(0.4, 0.6), h * 0.58
    rx, ry = w * 0.2, h * 0.11
    for y in range(h):
        for x in range(w):
            wobble = 1.0 + 0.25 * ((x * 7 + y * 3) % 5 - 2) / 2.0
            if rows[y][x] != "." and ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= wobble:
                mask[y][x] = True
    return mask


def paint(rows, mask):
    """Pinta a gosma sobre o desenho: borda escura embaixo de cada fio e nas
    laterais, miolo rosa, brilho no alto à esquerda, gota na ponta."""
    h, w = len(rows), len(rows[0])
    out = [list(r) for r in rows]
    for y in range(h):
        for x in range(w):
            if not mask[y][x]:
                continue
            below = y + 1 < h and mask[y + 1][x]
            left = x > 0 and mask[y][x - 1]
            right = x + 1 < w and mask[y][x + 1]
            above = y > 0 and mask[y - 1][x]
            if not below or not left or not right:
                out[y][x] = "D"
            elif not above:
                out[y][x] = "L"
            else:
                out[y][x] = "P"
            if not above and (x * 3 + y) % 5 == 0:
                out[y][x] = "H"
    # gotas penduradas: um pixel escuro abaixo da ponta de alguns fios, dentro
    # do desenho, para a gosma parecer que escorre
    for x in range(w):
        for y in range(h - 2):
            if mask[y][x] and not mask[y + 1][x] and rows[y + 1][x] != "." and (x * 5 + y) % 3 == 0:
                out[y + 1][x] = "D"
                if rows[y + 2][x] != "." and x % 2 == 0:
                    out[y + 2][x] = "P"
    return ["".join(r) for r in out]


def main():
    for i, name in enumerate(FRAMES):
        palette, rows = pixel_svg.load(name, {})
        mask = goo_mask(rows, seed=1000 + i)
        painted = paint(rows, mask)
        used = sorted({ch for row in painted for ch in row if ch != "."})
        lines = [
            "# Giorgino sujo de gosma, cópia de %s com a gosma pintada por" % name,
            "# tools/giorgino_goo_art.py. Mude o gerador e rode de novo, ou edite à mão.",
            "paleta",
        ]
        for key, color in list(palette.items()) + list(GOO.items()):
            if key in used:
                lines.append("%s %s" % (key, color))
        lines += ["pixels"] + painted
        (SOURCE / ("giorgino_goo_" + name[len("giorgino_"):] + ".txt")).write_text("\n".join(lines) + "\n")
        print(name, "->", "giorgino_goo_" + name[len("giorgino_"):])


if __name__ == "__main__":
    main()
