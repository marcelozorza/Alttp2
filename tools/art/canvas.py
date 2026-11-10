"""Tela de pixels para escrever os desenhos de art/source por programa.

Cada pixel guarda uma cor em "#rrggbb" ou None (transparente). save() escolhe
uma letra por cor e grava o arquivo de texto que tools/pixel_svg.py lê. Os
geradores ficam em tools/art/, um por família de desenhos, e o texto gerado
continua sendo a fonte: dá para retocar à mão, desde que o gerador não rode
de novo por cima.
"""

import pathlib
import string

SOURCE = pathlib.Path(__file__).resolve().parent.parent.parent / "art" / "source"
LETTERS = string.ascii_lowercase + string.ascii_uppercase + string.digits


class Canvas:
    def __init__(self, width, height, fill=None):
        self.w, self.h = width, height
        self.p = [[fill] * width for _ in range(height)]

    def copy(self):
        other = Canvas(self.w, self.h)
        other.p = [row[:] for row in self.p]
        return other

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.p[y][x]
        return None

    def px(self, x, y, color):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.p[y][x] = color

    def rect(self, x, y, w, h, color):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.px(xx, yy, color)

    def frame(self, x, y, w, h, color):
        self.rect(x, y, w, 1, color)
        self.rect(x, y + h - 1, w, 1, color)
        self.rect(x, y, 1, h, color)
        self.rect(x + w - 1, y, 1, h, color)

    def line(self, x0, y0, x1, y1, color):
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
        err = dx + dy
        while True:
            self.px(x0, y0, color)
            if x0 == x1 and y0 == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x0 += sx
            if e2 <= dx:
                err += dx
                y0 += sy

    def ellipse(self, cx, cy, rx, ry, color):
        """Elipse cheia, com centro e raios que podem ser meios pixels."""
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1.0:
                    self.px(x, y, color)

    def poly(self, points, color):
        """Polígono cheio, por varredura."""
        ys = [p[1] for p in points]
        for y in range(min(ys), max(ys) + 1):
            xs = []
            for i, (x0, y0) in enumerate(points):
                x1, y1 = points[(i + 1) % len(points)]
                if y0 == y1:
                    continue
                if min(y0, y1) <= y < max(y0, y1):
                    xs.append(x0 + (y - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            for a, b in zip(xs[::2], xs[1::2]):
                for x in range(int(round(a)), int(round(b)) + 1):
                    self.px(x, y, color)
        for i, (x0, y0) in enumerate(points):
            x1, y1 = points[(i + 1) % len(points)]
            self.line(x0, y0, x1, y1, color)

    def rows(self, x, y, rows, colors):
        """Desenha um trecho escrito à mão: letras de `colors`, "." pula."""
        for dy, row in enumerate(rows):
            for dx, ch in enumerate(row):
                if ch != "." and ch != " ":
                    self.px(x + dx, y + dy, colors[ch])

    def blit(self, other, x, y):
        for yy in range(other.h):
            for xx in range(other.w):
                color = other.p[yy][xx]
                if color is not None:
                    self.px(x + xx, y + yy, color)

    def replace(self, old, new):
        for row in self.p:
            for x, color in enumerate(row):
                if color == old:
                    row[x] = new

    def outline(self, color, diagonal=False):
        """Contorno de 1 pixel por fora de tudo o que não é transparente."""
        near = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        if diagonal:
            near += [(1, 1), (-1, 1), (1, -1), (-1, -1)]
        marks = []
        for y in range(self.h):
            for x in range(self.w):
                if self.p[y][x] is None and any(
                    self.get(x + dx, y + dy) is not None for dx, dy in near
                ):
                    marks.append((x, y))
        for x, y in marks:
            self.p[y][x] = color

    def flip_h(self):
        other = Canvas(self.w, self.h)
        other.p = [row[::-1] for row in self.p]
        return other

    def flip_v(self):
        other = Canvas(self.w, self.h)
        other.p = [row[:] for row in self.p[::-1]]
        return other

    def crop(self):
        """Recorta as margens transparentes."""
        xs = [x for y in range(self.h) for x in range(self.w) if self.p[y][x] is not None]
        ys = [y for y in range(self.h) for x in range(self.w) if self.p[y][x] is not None]
        other = Canvas(max(xs) - min(xs) + 1, max(ys) - min(ys) + 1)
        for y in range(other.h):
            other.p[y] = self.p[y + min(ys)][min(xs) : max(xs) + 1]
        return other

    def save(self, name, comment):
        colors = []
        for row in self.p:
            for color in row:
                if color is not None and color not in colors:
                    colors.append(color)
        letter = {color: LETTERS[i] for i, color in enumerate(colors)}
        lines = ["# " + line for line in comment.strip().splitlines()]
        lines.append("paleta")
        lines += ["%s %s" % (letter[color], color) for color in colors]
        lines.append("pixels")
        for row in self.p:
            lines.append("".join("." if c is None else letter[c] for c in row))
        (SOURCE / (name + ".txt")).write_text("\n".join(lines) + "\n", encoding="utf-8")


def load(name):
    """Lê um desenho de art/source como Canvas, seguindo as linhas "usa"."""
    palette, rows, base = {}, [], None
    section = None
    for raw in (SOURCE / (name + ".txt")).read_text(encoding="utf-8").splitlines():
        line = raw.rstrip()
        if not line or line.startswith("#"):
            continue
        if line in ("paleta", "pixels"):
            section = line
        elif line.startswith("usa "):
            base = line[4:].strip()
        elif section == "paleta":
            key, color = line.split()
            palette[key] = color.lower()
        elif section == "pixels":
            rows.append(line)
    if base:
        rows = _rows_of(base)
    canvas = Canvas(max(len(r) for r in rows), len(rows))
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                canvas.p[y][x] = palette[ch]
    return canvas


def _rows_of(name):
    rows, base = [], None
    section = None
    for raw in (SOURCE / (name + ".txt")).read_text(encoding="utf-8").splitlines():
        line = raw.rstrip()
        if line in ("paleta", "pixels"):
            section = line
        elif line.startswith("usa "):
            base = line[4:].strip()
        elif section == "pixels" and line and not line.startswith("#"):
            rows.append(line)
    return _rows_of(base) if base else rows


def noise(x, y, salt=0):
    """Sorteio fixo de 0 a 99 por pixel, para grãos que não mudam."""
    h = (x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)
    h = ((h ^ (h >> 13)) * 1274126177) & 0x7FFFFFFF
    return h % 100
