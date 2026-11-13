"""Filete claro em volta dos ícones de item, como o da bomba, para lerem
sobre fundo escuro (pedido de Marcelo em 2026-11-13: "todos os itens terão o
filete branco como a bomba").

Acrescenta uma volta de 1 pixel na cor do filete por fora do contorno. Os
vãos fechados do desenho (argola da chave, espiral da mola) ficam vazios. O
desenho ganha 1 pixel de cada lado, então o centro não muda. Quem já tem a
letra do filete na paleta é deixado como está.

Uso, de dentro de tools/art: python3 rim.py
"""

import pathlib

SOURCE = pathlib.Path(__file__).resolve().parent.parent.parent / "art" / "source"
RIM = "#a9aac2"
LETTER = "R"
# O coração reaproveita os pixels do coração do HUD: recebe a grade própria.
ICONS = ("sword", "fire", "spring", "key", "boss_key", "heart", "sword_locked")


def _read(name):
    head, rows, base = [], [], None
    in_pixels = False
    for line in (SOURCE / (name + ".txt")).read_text(encoding="utf-8").splitlines():
        if line.startswith("usa "):
            base = line[4:].strip()
        elif in_pixels:
            rows.append(line)
        else:
            head.append(line)
            in_pixels = line == "pixels"
    return head, rows, base


def _rimmed(rows):
    width = max(len(row) for row in rows) + 2
    grid = ["." * width] + ["." + row.ljust(width - 2, ".") + "." for row in rows] + ["." * width]
    height = len(grid)
    outside = set()
    stack = [(0, 0)]
    while stack:
        x, y = stack.pop()
        if (x, y) in outside or not (0 <= x < width and 0 <= y < height) or grid[y][x] != ".":
            continue
        outside.add((x, y))
        stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    result = []
    for y in range(height):
        line = ""
        for x in range(width):
            near = any(
                0 <= x + dx < width and 0 <= y + dy < height and grid[y + dy][x + dx] != "."
                for dx in (-1, 0, 1)
                for dy in (-1, 0, 1)
            )
            line += LETTER if (x, y) in outside and near else grid[y][x]
        result.append(line)
    return result


def main():
    for icon in ICONS:
        name = "icon_" + icon
        head, rows, base = _read(name)
        if any(line.startswith(LETTER + " ") for line in head):
            continue
        entry = "%s %s" % (LETTER, RIM)
        if base and base[5:] in ICONS:
            # A base já traz o filete: basta a cor na paleta deste.
            text = "\n".join(head + [entry, "usa " + base]) + "\n"
            (SOURCE / (name + ".txt")).write_text(text, encoding="utf-8")
            print(name)
            continue
        if base:
            rows = _read(base)[1]
            head.append("pixels")
        head.insert(head.index("pixels"), entry)
        text = "\n".join(head + _rimmed(rows)) + "\n"
        (SOURCE / (name + ".txt")).write_text(text, encoding="utf-8")
        print(name)


if __name__ == "__main__":
    main()
