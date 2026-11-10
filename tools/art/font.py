"""Fonte de pixel do Giorgino, desenhada letra a letra.

Gera ui/font/giorgino.png e giorgino.fnt (letras de 7 pixels de altura) e
giorgino_big (o dobro, com as diagonais alisadas), no formato BMFont, que o
Godot importa como fonte. Tem as letras, os números, a pontuação e os acentos
do português.

Uso: python3 tools/art/font.py
"""

import pathlib

from PIL import Image

OUT = pathlib.Path(__file__).resolve().parent.parent.parent / "ui" / "font"
# Linhas acima das maiúsculas, para os acentos, e abaixo, para as pernas.
ABOVE, BODY, BELOW = 3, 7, 2
HEIGHT = ABOVE + BODY + BELOW

GLYPHS = {
    "A": ".###./#...#/#...#/#####/#...#/#...#/#...#",
    "B": "####./#...#/#...#/####./#...#/#...#/####.",
    "C": ".###./#...#/#..../#..../#..../#...#/.###.",
    "D": "####./#...#/#...#/#...#/#...#/#...#/####.",
    "E": "#####/#..../#..../####./#..../#..../#####",
    "F": "#####/#..../#..../####./#..../#..../#....",
    "G": ".###./#...#/#..../#.###/#...#/#...#/.###.",
    "H": "#...#/#...#/#...#/#####/#...#/#...#/#...#",
    "I": "###/.#./.#./.#./.#./.#./###",
    "J": "..###/...#./...#./...#./...#./#..#./.##..",
    "K": "#...#/#..#./#.#../##.../#.#../#..#./#...#",
    "L": "#..../#..../#..../#..../#..../#..../#####",
    "M": "#...#/##.##/#.#.#/#.#.#/#...#/#...#/#...#",
    "N": "#...#/##..#/#.#.#/#.#.#/#..##/#...#/#...#",
    "O": ".###./#...#/#...#/#...#/#...#/#...#/.###.",
    "P": "####./#...#/#...#/####./#..../#..../#....",
    "Q": ".###./#...#/#...#/#...#/#.#.#/#..#./.##.#",
    "R": "####./#...#/#...#/####./#.#../#..#./#...#",
    "S": ".####/#..../#..../.###./....#/....#/####.",
    "T": "#####/..#../..#../..#../..#../..#../..#..",
    "U": "#...#/#...#/#...#/#...#/#...#/#...#/.###.",
    "V": "#...#/#...#/#...#/#...#/.#.#./.#.#./..#..",
    "W": "#...#/#...#/#...#/#.#.#/#.#.#/##.##/#...#",
    "X": "#...#/#...#/.#.#./..#../.#.#./#...#/#...#",
    "Y": "#...#/#...#/.#.#./..#../..#../..#../..#..",
    "Z": "#####/....#/...#./..#../.#.../#..../#####",
    "a": "...../...../.###./....#/.####/#...#/.####",
    "b": "#..../#..../####./#...#/#...#/#...#/####.",
    "c": "..../..../.###/#.../#.../#.../.###",
    "d": "....#/....#/.####/#...#/#...#/#...#/.####",
    "e": "...../...../.###./#...#/#####/#..../.###.",
    "f": "..##/.#../###./.#../.#../.#../.#..",
    "g": "...../...../.####/#...#/#...#/#...#/.####/....#/.###.",
    "h": "#..../#..../####./#...#/#...#/#...#/#...#",
    "i": "#/./#/#/#/#/#",
    "j": "..#/.../..#/..#/..#/..#/..#/..#/##.",
    "k": "#.../#.../#..#/#.#./##../#.#./#..#",
    "l": "#./#./#./#./#./#./.#",
    "m": "...../...../##.#./#.#.#/#.#.#/#.#.#/#.#.#",
    "n": "...../...../####./#...#/#...#/#...#/#...#",
    "o": "...../...../.###./#...#/#...#/#...#/.###.",
    "p": "...../...../####./#...#/#...#/#...#/####./#..../#....",
    "q": "...../...../.####/#...#/#...#/#...#/.####/....#/....#",
    "r": "..../..../#.##/##../#.../#.../#...",
    "s": "..../..../.###/#.../.##./...#/###.",
    "t": ".#../.#../###./.#../.#../.#../..##",
    "u": "...../...../#...#/#...#/#...#/#...#/.####",
    "v": "...../...../#...#/#...#/#...#/.#.#./..#..",
    "w": "...../...../#...#/#.#.#/#.#.#/#.#.#/.#.#.",
    "x": "...../...../#...#/.#.#./..#../.#.#./#...#",
    "y": "...../...../#...#/#...#/#...#/#...#/.####/....#/.###.",
    "z": "...../...../#####/...#./..#../.#.../#####",
    "0": ".###./#...#/#..##/#.#.#/##..#/#...#/.###.",
    "1": "..#../.##../..#../..#../..#../..#../.###.",
    "2": ".###./#...#/....#/...#./..#../.#.../#####",
    "3": ".###./#...#/....#/..##./....#/#...#/.###.",
    "4": "...#./..##./.#.#./#..#./#####/...#./...#.",
    "5": "#####/#..../####./....#/....#/#...#/.###.",
    "6": ".###./#..../#..../####./#...#/#...#/.###.",
    "7": "#####/....#/...#./..#../..#../..#../..#..",
    "8": ".###./#...#/#...#/.###./#...#/#...#/.###.",
    "9": ".###./#...#/#...#/.####/....#/....#/.###.",
    ".": "././././././/#",
    ",": "../../../../../../.#/#.",
    ":": "./././#/././#",
    "!": "#/#/#/#/#/./#",
    "?": ".###./#...#/....#/...#./..#../...../..#..",
    "-": ".../.../.../###/.../.../...",
    "'": "#/#/./././././.",
    '"': "#.#/#.#/.../.../.../.../...",
    "(": ".#/#./#./#./#./#./.#",
    ")": "#./.#/.#/.#/.#/.#/#.",
    "/": "....#/...#./...#./..#../.#.../.#.../#....",
    "+": "...../..#../..#../#####/..#../..#../.....",
    "=": "..../..../####/..../####/..../....",
    "%": "##..#/##.#./...#./..#../.#.../.#.##/#..##",
    "<": "...#/..#./.#../#.../.#../..#./...#",
    ">": "#.../.#../..#./...#/..#./.#../#...",
    "x2": "",
}
GLYPHS[","] = "../../../../../.#/.#/#."
GLYPHS["."] = "./././././././#"[2:]
del GLYPHS["x2"]

ACCENTS = {
    "acute": ["..#", ".#."],
    "grave": ["#..", ".#."],
    "circ": [".#.", "#.#"],
    "tilde": [".#.#", "#.#."],
}
# Letra acentuada: (letra base, acento). O "i" acentuado perde o pingo.
COMPOSED = {
    "á": ("a", "acute"), "à": ("a", "grave"), "â": ("a", "circ"), "ã": ("a", "tilde"),
    "é": ("e", "acute"), "ê": ("e", "circ"), "í": ("i", "acute"),
    "ó": ("o", "acute"), "ô": ("o", "circ"), "õ": ("o", "tilde"), "ú": ("u", "acute"),
    "Á": ("A", "acute"), "À": ("A", "grave"), "Â": ("A", "circ"), "Ã": ("A", "tilde"),
    "É": ("E", "acute"), "Ê": ("E", "circ"), "Í": ("I", "acute"),
    "Ó": ("O", "acute"), "Ô": ("O", "circ"), "Õ": ("O", "tilde"), "Ú": ("U", "acute"),
}  # fmt: skip
CEDILLA = {"ç": "c", "Ç": "C"}
SPACE_WIDTH = 3


def glyph_rows(ch):
    """Linhas de um caractere numa caixa de HEIGHT de altura."""
    if ch in COMPOSED:
        base, accent = COMPOSED[ch]
        body = GLYPHS[base].split("/")
        if base == "i":
            body = [".#.", "...", ".#.", ".#.", ".#.", ".#.", ".#."]
            body[0] = "..."
        width = max(len(r) for r in body)
        mark = ACCENTS[accent]
        mark_width = max(len(r) for r in mark)
        width = max(width, mark_width)
        rows = ["." * width for _ in range(HEIGHT)]
        for i, row in enumerate(body):
            rows[ABOVE + i] = row.ljust(width, ".")
        # Minúscula: o acento fica logo acima da altura do "x", com 1 de vão.
        top = 0 if base.isupper() else ABOVE - 1
        if base.isupper():
            top = 0
        left = (width - mark_width) // 2
        for i, row in enumerate(mark):
            rows[top + i] = ("." * left + row).ljust(width, ".")
        return rows
    if ch in CEDILLA:
        body = GLYPHS[CEDILLA[ch]].split("/")
        width = max(len(r) for r in body)
        rows = ["." * width for _ in range(HEIGHT)]
        for i, row in enumerate(body):
            rows[ABOVE + i] = row.ljust(width, ".")
        mid = width // 2
        rows[ABOVE + BODY] = ("." * mid + "#").ljust(width, ".")
        rows[ABOVE + BODY + 1] = ("." * (mid - 1) + "#").ljust(width, ".")
        return rows
    body = [r for r in GLYPHS[ch].split("/")]
    width = max(len(r) for r in body)
    rows = ["." * width for _ in range(HEIGHT)]
    for i, row in enumerate(body):
        rows[ABOVE + i] = row.ljust(width, ".")
    return rows


def scale2x(rows):
    """Dobra uma letra alisando as diagonais (regra Scale2x)."""
    h, w = len(rows), len(rows[0])

    def at(x, y):
        return rows[y][x] if 0 <= x < w and 0 <= y < h else "."

    out = [["."] * (w * 2) for _ in range(h * 2)]
    for y in range(h):
        for x in range(w):
            p, a, b, c, d = at(x, y), at(x, y - 1), at(x + 1, y), at(x - 1, y), at(x, y + 1)
            e = [p, p, p, p]
            if c == a and c != d and a != b:
                e[0] = a
            if a == b and a != c and b != d:
                e[1] = b
            if d == c and d != b and c != a:
                e[2] = c
            if b == d and b != a and d != c:
                e[3] = d
            out[y * 2][x * 2], out[y * 2][x * 2 + 1] = e[0], e[1]
            out[y * 2 + 1][x * 2], out[y * 2 + 1][x * 2 + 1] = e[2], e[3]
    return ["".join(r) for r in out]


def build(name, big):
    chars = sorted(list(GLYPHS) + list(COMPOSED) + list(CEDILLA))
    scale = 2 if big else 1
    glyphs = {}
    for ch in chars:
        rows = glyph_rows(ch)
        glyphs[ch] = scale2x(rows) if big else rows
    cell_h = HEIGHT * scale
    per_row = 16
    cell_w = max(len(g[0]) for g in glyphs.values()) + 1
    sheet_rows = (len(chars) + per_row - 1) // per_row
    image = Image.new("RGBA", (per_row * cell_w, sheet_rows * (cell_h + 1)), (0, 0, 0, 0))
    lines = [
        'info face="%s" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 '
        "aa=1 padding=0,0,0,0 spacing=0,0" % (name, cell_h),
        "common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0"
        % (cell_h + scale, (ABOVE + BODY) * scale, image.width, image.height),
        'page id=0 file="%s.png"' % name,
        "chars count=%d" % (len(chars) + 1),
        "char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15"
        % (SPACE_WIDTH * scale),
    ]
    for i, ch in enumerate(chars):
        rows = glyphs[ch]
        x0, y0 = (i % per_row) * cell_w, (i // per_row) * (cell_h + 1)
        for y, row in enumerate(rows):
            for x, bit in enumerate(row):
                if bit == "#":
                    image.putpixel((x0 + x, y0 + y), (255, 255, 255, 255))
        lines.append(
            "char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15"
            % (ord(ch), x0, y0, len(rows[0]), cell_h, len(rows[0]) + scale)
        )
    OUT.mkdir(parents=True, exist_ok=True)
    image.save(OUT / (name + ".png"))
    (OUT / (name + ".fnt")).write_text("\n".join(lines) + "\n", encoding="utf-8")
    return len(chars)


if __name__ == "__main__":
    print(build("giorgino", False), "letras")
    build("giorgino_big", True)
