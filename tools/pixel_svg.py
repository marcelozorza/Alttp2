"""Converte a pixel art em texto de art/source/ em arquivos SVG em art/.

Cada arquivo .txt de art/source/ descreve um desenho:

    # comentário
    paleta
    o #2a2230
    w #f4f1ea
    pixels
    ..oo..
    .owwo.

Cada letra da grade é um pixel com a cor da paleta, e "." é transparente.
Uma linha "usa outro_nome" no lugar da grade reaproveita os pixels de outro
desenho com a paleta deste, como a troca de paleta do Super Nintendo.

Cada pixel vira um quadrado do SVG, juntando pixels vizinhos da mesma cor numa
linha. O Godot importa o SVG no tamanho original, um pixel do desenho por
pixel da tela, então o desenho fica nítido como pixel art.

Uso: python3 tools/pixel_svg.py
"""

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / "art" / "source"
OUTPUT = ROOT / "art"


def parse(path):
    palette, rows, base = {}, [], None
    section = None
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.rstrip()
        if not line or line.startswith("#"):
            continue
        if line in ("paleta", "pixels"):
            section = line
            continue
        if line.startswith("usa "):
            base = line[4:].strip()
            continue
        if section == "paleta":
            key, color = line.split()
            palette[key] = color
        elif section == "pixels":
            rows.append(line)
    return palette, rows, base


def load(name, cache):
    if name in cache:
        return cache[name]
    palette, rows, base = parse(SOURCE / (name + ".txt"))
    if base:
        rows = load(base, cache)[1]
    cache[name] = (palette, rows)
    return cache[name]


def to_svg(name, palette, rows):
    width = max(len(r) for r in rows)
    height = len(rows)
    for y, row in enumerate(rows):
        if len(row) != width:
            raise SystemExit("%s: linha %d tem %d pixels, esperado %d" % (name, y, len(row), width))
        for ch in row:
            if ch != "." and ch not in palette:
                raise SystemExit("%s: cor %r fora da paleta" % (name, ch))
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
        'viewBox="0 0 %d %d" shape-rendering="crispEdges">' % (width, height, width, height)
    ]
    for y, row in enumerate(rows):
        x = 0
        while x < width:
            ch = row[x]
            start = x
            while x < width and row[x] == ch:
                x += 1
            if ch == ".":
                continue
            parts.append(
                '<rect x="%d" y="%d" width="%d" height="1" fill="%s"/>'
                % (start, y, x - start, palette[ch])
            )
    parts.append("</svg>")
    return "\n".join(parts) + "\n"


def main():
    cache = {}
    names = sorted(p.stem for p in SOURCE.glob("*.txt"))
    for name in names:
        palette, rows = load(name, cache)
        (OUTPUT / (name + ".svg")).write_text(to_svg(name, palette, rows), encoding="utf-8")
    print("%d desenhos convertidos" % len(names))
    return 0


if __name__ == "__main__":
    sys.exit(main())
