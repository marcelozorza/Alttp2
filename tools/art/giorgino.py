"""Giorgino decalcado de folhas do Magnific, no tamanho grande (58 px de pé).

Pedido de Marcelo em 2026-11-11: redesenhar o Giorgino no mesmo traço dos
inimigos novos, sem o contorno grosso, no tamanho grande. Corpo todo branco,
sem pintinhas. De costas, duas pintas pretas sobre a coluna: uma redonda no
meio das costas e outra logo acima da saída do rabo.

As folhas ficam fora do repositório, em /mnt/project-files/giorgino/
magnific_ref/. Sem elas este script não roda, e o texto em art/source é a
fonte. Cada quadro é recortado no tamanho do desenho, e o script imprime o
ponto dos pés de cada um para player/giorgino_art.gd.

Uso: python3 tools/art/giorgino.py && python3 tools/giorgino_goo_art.py
     && python3 tools/pixel_svg.py
"""

import enemies
import trace
from canvas import Canvas

SHEETS = "/mnt/project-files/giorgino/magnific_ref/"
PIXEL = 4.2
INK = "#1e181e"
DARK = "#2a2329"
BROWN = "#5c4232"
WHITE = "#f4f1ea"
SHADE = "#c7c1cf"
PINK = "#d9578a"
STEEL = "#7c7b99"
SHINE = "#d6d8e6"
GOLD = "#d99a1c"
COLORS = [INK, DARK, BROWN, SHADE, WHITE, PINK, STEEL, SHINE, GOLD]
GRAYS = (SHADE, STEEL, SHINE)
DARKS = (INK, DARK, BROWN)

# Quadro: texto, folha, casa da folha (número, ou recorte à mão quando a
# folha não tem grade regular) e o tipo de vista.
POSES = {
    "stand_down": ("de pé, de frente", "andar_b.jpg", 0, "front"),
    "stand_down_step": ("de pé, de frente, segundo passo", "andar_b.jpg", 0, "front_step"),
    "stand_up": ("de pé, de costas", "andar_b.jpg", 2, "back"),
    "stand_up_step": ("de pé, de costas, segundo passo", "andar_b.jpg", 3, "back"),
    "stand_side": ("de pé, de lado", "andar_b.jpg", 4, "side"),
    "stand_side_step": ("de pé, de lado, segundo passo", "ref_grande.jpg", (800, 10, 960, 280), "side"),
    "down": ("galope, de frente", "galope_grande.jpg", 0, "front"),
    "down_step": ("galope, de frente, segundo passo", "galope_grande.jpg", 1, "front"),
    "up": ("galope, de costas", "galope_grande.jpg", 2, "back"),
    "up_step": ("galope, de costas, segundo passo", "galope_grande.jpg", 3, "back"),
    "side": ("galope, de lado", "galope_grande.jpg", 4, "side"),
    "side_step": ("galope, de lado, segundo passo", "galope_grande.jpg", 5, "side"),
    "thrust_down": ("golpe para baixo", "ref_grande.jpg", (345, 300, 445, 550), "thrust_down"),
    "thrust_up": ("golpe para cima", "extra_6.jpg", 2, "thrust_up"),
    "thrust_side": ("golpe de lado", "ref_grande.jpg", (575, 300, 757, 550), "thrust_side"),
    "fallen": ("deitado, sem vida", "extra_6.jpg", (350, 295, 675, 420), "fallen"),
}
# Alcance da área de dano de Sword a partir dos pés: de lado, para baixo e
# para cima. A lâmina de cada golpe tem de chegar até lá.
REACH_SIDE, REACH_DOWN, REACH_UP = 36, 32, 48


def pieces(c, colors):
    """Peças ligadas feitas das cores dadas."""
    seen, out = set(), []
    for y in range(c.h):
        for x in range(c.w):
            if c.p[y][x] in colors and (x, y) not in seen:
                piece, todo = [], [(x, y)]
                seen.add((x, y))
                while todo:
                    px, py = todo.pop()
                    piece.append((px, py))
                    for near in ((px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)):
                        if c.get(*near) in colors and near not in seen:
                            seen.add(near)
                            todo.append(near)
                out.append(piece)
    return out


def touches(c, piece, color):
    return any(
        c.get(x + dx, y + dy) == color
        for x, y in piece
        for dx in (-2, -1, 0, 1, 2)
        for dy in (-2, -1, 0, 1, 2)
    )


def whiten(c):
    """Corpo todo branco: só fica cinza o que é lâmina, ligado à guarda."""
    for piece in pieces(c, GRAYS):
        if not (len(piece) >= 10 and touches(c, piece, GOLD)):
            for x, y in piece:
                c.p[y][x] = WHITE


def body_middle(c):
    xs = sorted(x for y in range(c.h) for x in range(c.w) if c.p[y][x] == WHITE)
    return xs[len(xs) // 2]


def back_spots(c):
    """De costas: tira as pintas da folha e pinta as duas sobre a coluna."""
    collar = max(y for y in range(c.h) for x in range(c.w) if c.p[y][x] == PINK)
    inner = Canvas(c.w, c.h)
    for y in range(collar + 2, c.h):
        for x in range(c.w):
            if c.p[y][x] in DARKS and not trace.is_edge(c, x, y):
                inner.p[y][x] = INK
    ys = []
    for piece in pieces(inner, (INK,)):
        cells = set(piece)
        if any(all((x + dx, y + dy) in cells for dx in (0, 1) for dy in (0, 1, 2)) for x, y in piece):
            ys += [y for _, y in piece]
            for x, y in piece:
                c.p[y][x] = WHITE
    if not ys:
        return
    middle = body_middle(c) + 0.5
    for cy in (min(ys) + 2.5, max(ys) - 1.5):
        c.ellipse(middle, cy, 2.5, 2.5, INK)


def lift_leg(c):
    """Segundo passo de frente: a perna da esquerda do desenho sobe 2 pixels."""
    middle = body_middle(c)
    out = c.copy()
    for y in range(c.h - 12, c.h):
        for x in range(middle - 10, middle):
            if c.p[y][x] in GRAYS + (GOLD,):
                continue
            source = c.get(x, y + 3)
            out.p[y][x] = None if source in GRAYS + (GOLD,) else source
    return out.crop()


def blade_tip(c, direction):
    """Ponta da lâmina: o cinza mais longe na direção dada."""
    gray = [(x, y) for y in range(c.h) for x in range(c.w) if c.p[y][x] in GRAYS]
    blade = [p for piece in pieces(c, GRAYS) if touches(c, piece, GOLD) for p in piece] or gray
    if direction == "right":
        return max(blade)
    if direction == "down":
        return max(blade, key=lambda p: p[1])
    return min(blade, key=lambda p: p[1])


def stretch(c, direction, amount):
    """Alonga a lâmina repetindo uma fatia dela, amount pixels, sem mexer no
    resto do desenho."""
    if amount <= 0:
        return c
    tx, ty = blade_tip(c, direction)
    if direction == "right":
        out = Canvas(c.w + amount, c.h)
        for y in range(c.h):
            row = c.p[y] + [None] * amount
            if abs(y - ty) <= 3:
                cut = tx - 5
                row = c.p[y][:cut] + [c.p[y][cut]] * amount + c.p[y][cut:]
            out.p[y] = row
        return out
    out = Canvas(c.w, c.h + amount)
    for x in range(c.w):
        column = [c.p[y][x] for y in range(c.h)]
        if abs(x - tx) <= 3 and direction == "down":
            cut = ty - 5
            column = column[:cut] + [column[cut]] * amount + column[cut:]
        elif abs(x - tx) <= 3:
            cut = ty + 5
            column = column[:cut] + [column[cut]] * amount + column[cut:]
        elif direction == "down":
            column = column + [None] * amount
        else:
            column = [None] * amount + column
        for y in range(out.h):
            out.p[y][x] = column[y]
    return out


def thin_lines(c):
    """Tira os riscos de 1 pixel de largura soltos no fundo: a linha da grade
    da folha que atravessa um recorte."""
    for _ in range(2):
        thin = [
            (x, y)
            for y in range(c.h)
            for x in range(c.w)
            if c.p[y][x] and c.get(x - 1, y) is None and c.get(x + 1, y) is None
        ]
        for x, y in thin:
            c.p[y][x] = None


def draw(name):
    text, sheet, cell, kind = POSES[name]
    path = SHEETS + sheet
    box = cell if isinstance(cell, tuple) else enemies.cells(path)[cell]
    c = trace.trace(path, box, PIXEL, COLORS)
    if isinstance(cell, tuple):
        thin_lines(c)
    c = trace.clean(c, tuple(COLORS))
    whiten(c)
    enemies.despeckle(c)
    if kind == "back" or kind == "thrust_up":
        back_spots(c)
    if kind == "front_step":
        c = lift_leg(c)
    middle = body_middle(c)
    feet = [middle + 0.5, c.h - 8.0]
    if kind == "thrust_side":
        tip_y = blade_tip(c, "right")[1]
        for y in range(c.h):
            for x in range(c.w):
                if c.p[y][x] in GRAYS and abs(y - tip_y) > 3:
                    c.p[y][x] = WHITE
        c = stretch(c, "right", int(feet[0] + REACH_SIDE) - blade_tip(c, "right")[0])
    elif kind == "thrust_down":
        tip_x, tip_y = blade_tip(c, "down")
        c = stretch(c, "down", int(feet[1] + REACH_DOWN) - tip_y)
        feet[0] = tip_x + 0.5
    elif kind == "thrust_up":
        tip_x, tip_y = blade_tip(c, "up")
        grow = int(REACH_UP - (feet[1] - tip_y))
        c = stretch(c, "up", grow)
        feet[1] += max(grow, 0)
        feet[0] = (middle + tip_x) / 2.0 + 0.5
    elif kind == "fallen":
        feet = [c.w / 2.0, c.h / 2.0]
    c.save(
        "giorgino_" + name,
        "Giorgino: %s.\nDecalcado de uma folha do Magnific por tools/art/giorgino.py." % text,
    )
    return c, feet


def main():
    for name in POSES:
        c, feet = draw(name)
        print("%-16s %3d por %3d  pés Vector2(%.1f, %.1f)" % (name, c.w, c.h, feet[0], feet[1]))


if __name__ == "__main__":
    main()
