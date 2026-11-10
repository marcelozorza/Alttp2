"""Passada de harmonia em art/source, feita em 2026-11-10.

1. Todo desenho que ainda era a grade de 16 px ampliada 2 vezes (cada pixel
   virava um bloco de 2 por 2) é reduzido ao original e ampliado de novo com a
   regra Scale2x, que alisa as diagonais. O desenho continua o mesmo e passa a
   ter pixel fino, como o Giorgino.
2. Toda cor de toda paleta é trocada pela cor mais próxima da paleta mestra
   (tools/art/palette.py).

Roda uma vez. Rodar de novo não muda nada, porque depois da primeira passada
nenhum desenho tem pixel dobrado nem cor fora da paleta.

Uso: python3 tools/art/harmonize.py
"""

import pathlib

from palette import nearest

SOURCE = pathlib.Path(__file__).resolve().parent.parent.parent / "art" / "source"


def is_doubled(rows):
    if len(rows) < 4 or len(rows) % 2 or any(len(r) % 2 for r in rows):
        return False
    if any(rows[i] != rows[i + 1] for i in range(0, len(rows), 2)):
        return False
    return all(r[i] == r[i + 1] for r in rows for i in range(0, len(r), 2))


def scale2x(rows):
    h, w = len(rows), len(rows[0])

    def at(x, y):
        return rows[min(max(y, 0), h - 1)][min(max(x, 0), w - 1)]

    out = []
    for y in range(h):
        top, bottom = [], []
        for x in range(w):
            p, a, b, c, d = at(x, y), at(x, y - 1), at(x + 1, y), at(x - 1, y), at(x, y + 1)
            top.append(a if c == a and c != d and a != b else p)
            top.append(b if a == b and a != c and b != d else p)
            bottom.append(c if d == c and d != b and c != a else p)
            bottom.append(d if b == d and b != a and d != c else p)
        out.append("".join(top))
        out.append("".join(bottom))
    return out


def process(path, tiles):
    lines = path.read_text(encoding="utf-8").splitlines()
    if "pixels" in lines:
        start = lines.index("pixels") + 1
        rows = [r for r in lines[start:] if r.strip()]
        # Um tile que se repete lado a lado não pode ser alisado: as bordas
        # deixariam de casar com o vizinho.
        if is_doubled(rows) and path.stem not in tiles:
            small = [r[::2] for r in rows[::2]]
            lines = lines[:start] + scale2x(small)
    result, section = [], None
    for line in lines:
        if line in ("paleta", "pixels"):
            section = line
        elif section == "paleta" and line and not line.startswith(("#", "usa ")):
            key, color = line.split()
            line = "%s %s" % (key, nearest(color))
        result.append(line)
    text = "\n".join(result) + "\n"
    changed = text != path.read_text(encoding="utf-8")
    path.write_text(text, encoding="utf-8")
    return changed


def main():
    tiles = {"carpet", "frost", "moss_patch"}
    changed = sum(process(path, tiles) for path in sorted(SOURCE.glob("*.txt")))
    print("%d desenhos alterados" % changed)


if __name__ == "__main__":
    main()
