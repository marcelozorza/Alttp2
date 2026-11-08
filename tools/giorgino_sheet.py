"""Converte a folha de 20 poses do Giorgino, gerada por IA, em fontes de pixel art.

Uso: python3 tools/giorgino_sheet.py <folha.png> <altura_de_pe> <saida_dir>
Exemplo: python3 tools/giorgino_sheet.py folha.png 48 /tmp/gio
         cp /tmp/gio/giorgino_*.txt art/source/ && python3 tools/pixel_svg.py

A folha tem 4 colunas e 5 linhas, nesta ordem (linha por linha): andando de
frente (2 passos), de costas (2), de lado (2), correndo de frente (2), de
costas (2), de lado (2), estocada de frente, de costas, de lado e de lado
recolhendo, guarda de frente, de costas e de lado, e deitado. É a folha de
2026-11-08 com a espada (pedido em /mnt/project-files/giorgino/), que
substituiu a de 16 poses sem espada do mesmo dia. Precisa de numpy e Pillow.

Fundo: gradiente escuro e liso. A sprite é "pixel art falsa" com blocos
chatos e contorno escuro, então o que separa os dois é a borda: onde dois
pixels vizinhos diferem mais que EDGE. A sprite é tudo que a malha de bordas
fecha e que não é um vão de fundo (vão: região fechada com a mesma cor do
fundo logo ao lado). Escala única, tirada da primeira pose (de pé, de
frente) para a altura pedida. Cada pixel de saída recebe a cor da paleta
mais votada entre os pixels de origem que ele cobre.
"""
import sys
from collections import deque
from PIL import Image, ImageFilter
import numpy as np

SRC, HEIGHT, OUT = sys.argv[1], int(sys.argv[2]), sys.argv[3]
EDGE = 5.0
NAMES = [
    "giorgino_stand_down", "giorgino_stand_down_step", "giorgino_stand_up", "giorgino_stand_up_step",
    "giorgino_stand_side", "giorgino_stand_side_step", "giorgino_down", "giorgino_down_step",
    "giorgino_up", "giorgino_up_step", "giorgino_side", "giorgino_side_step",
    "giorgino_thrust_down", "giorgino_thrust_up", "giorgino_thrust_side", "giorgino_thrust_side_recover",
    "giorgino_guard_down", "giorgino_guard_up", "giorgino_guard_side", "giorgino_fallen",
]
COLS = 4
ROWS = len(NAMES) // COLS
COMMENTS = {
    "giorgino_stand_down": "andando, de frente", "giorgino_stand_down_step": "andando, de frente, passo 2",
    "giorgino_stand_up": "andando, de costas", "giorgino_stand_up_step": "andando, de costas, passo 2",
    "giorgino_stand_side": "andando, de lado (direita)", "giorgino_stand_side_step": "andando, de lado, passo 2",
    "giorgino_down": "correndo, de frente", "giorgino_down_step": "correndo, de frente, passo 2",
    "giorgino_up": "correndo, de costas", "giorgino_up_step": "correndo, de costas, passo 2",
    "giorgino_side": "correndo, de lado (direita)", "giorgino_side_step": "correndo, de lado, passo 2",
    "giorgino_thrust_down": "estocada, de frente", "giorgino_thrust_up": "estocada, de costas",
    "giorgino_thrust_side": "estocada, de lado (direita)",
    "giorgino_thrust_side_recover": "recolhendo a espada, de lado (direita)",
    "giorgino_guard_down": "parado em guarda, de frente", "giorgino_guard_up": "parado em guarda, de costas",
    "giorgino_guard_side": "parado em guarda, de lado (direita)", "giorgino_fallen": "deitado, sem vida",
}
PALETTE = [
    ("k", "#2a2329"), ("d", "#1e181e"), ("b", "#5c4232"), ("w", "#f4f1ea"), ("s", "#c7c1cf"),
    ("g", "#8f8a99"), ("n", "#141016"), ("p", "#e49aa4"), ("r", "#d9578a"), ("e", "#0e0b0d"),
    ("y", "#d4a53c"), ("o", "#8a6420"),
]
PAL_RGB = np.array([[int(h[i:i+2], 16) for i in (1, 3, 5)] for _, h in PALETTE], float)

im = Image.open(SRC).convert("RGB")
a = np.array(im).astype(int)
H, W = a.shape[:2]


def cell_box(i):
    """Limites da célula i na folha: linha por linha, COLS por linha."""
    r, c = divmod(i, COLS)
    return (r * H // ROWS, (r + 1) * H // ROWS, c * W // COLS, (c + 1) * W // COLS)


def dilate(mask, r):
    img = Image.fromarray((mask.astype(np.uint8)) * 255)
    return np.array(img.filter(ImageFilter.MaxFilter(2 * r + 1))) > 0


def erode(mask, r):
    img = Image.fromarray((mask.astype(np.uint8)) * 255)
    return np.array(img.filter(ImageFilter.MinFilter(2 * r + 1))) > 0


def components(mask):
    """Rótulos (0 = fora) e lista de componentes conexos (4 vizinhos)."""
    h, w = mask.shape
    labels = np.zeros((h, w), int)
    comps = []
    for y0 in range(h):
        for x0 in range(w):
            if mask[y0, x0] and labels[y0, x0] == 0:
                idx = len(comps) + 1
                comp = []
                q = deque([(y0, x0)])
                labels[y0, x0] = idx
                while q:
                    y, x = q.popleft()
                    comp.append((y, x))
                    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < h and 0 <= xx < w and mask[yy, xx] and labels[yy, xx] == 0:
                            labels[yy, xx] = idx
                            q.append((yy, xx))
                comps.append(comp)
    return labels, comps


def foreground_mask(cell):
    f = cell.astype(float)
    h, w = f.shape[:2]
    # borda: maior diferença entre vizinhos em qualquer canal
    d = np.zeros((h, w))
    dx = np.abs(f[:, 1:] - f[:, :-1]).max(axis=2)
    dy = np.abs(f[1:, :] - f[:-1, :]).max(axis=2)
    d[:, 1:] = np.maximum(d[:, 1:], dx)
    d[:, :-1] = np.maximum(d[:, :-1], dx)
    d[1:, :] = np.maximum(d[1:, :], dy)
    d[:-1, :] = np.maximum(d[:-1, :], dy)
    edge = dilate(d > EDGE, 1)
    free = ~edge
    labels, comps = components(free)
    background = np.zeros((h, w), bool)
    holes = []
    for comp in comps:
        ys = [p[0] for p in comp]
        xs = [p[1] for p in comp]
        if min(ys) == 0 or min(xs) == 0 or max(ys) == h - 1 or max(xs) == w - 1:
            for y, x in comp:
                background[y, x] = True
        else:
            holes.append(comp)
    lum = f.mean(axis=2)
    mx, mn = f.max(axis=2), f.min(axis=2)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1), 0)
    sprite = ~background
    # vãos: regiões fechadas com a cor do fundo ao redor
    for comp in holes:
        m = np.zeros((h, w), bool)
        for y, x in comp:
            m[y, x] = True
        ring = dilate(m, 8) & background
        if ring.sum() < 20:
            continue
        hole_lum = lum[m].mean()
        if abs(hole_lum - lum[ring].mean()) < 4.0 and sat[m].max() < 0.25 and lum[m].std() < 3.0:
            sprite &= ~m
    sprite = erode(sprite, 1)
    return sprite


sprites = []
for i, name in enumerate(NAMES):
    y0, y1, x0, x1 = cell_box(i)
    cell = a[y0:y1, x0:x1]
    fg = foreground_mask(cell)
    fg = dilate(erode(fg, 2), 2)
    _, comps = components(fg)
    best = max(comps, key=len)
    fg = np.zeros_like(fg)
    for y, x in best:
        fg[y, x] = True
    ys, xs = np.where(fg)
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    sprites.append((name, cell, fg, box))
    print(name, "bbox", box, "tam", box[2] - box[0], box[3] - box[1])

x0, y0, x1, y1 = sprites[0][3]
scale = HEIGHT / (y1 - y0)
print("escala", scale, "px de origem por pixel", 1 / scale)

# quantiza cada pixel de origem na paleta
flat = a.reshape(-1, 3).astype(float)
dist = ((flat[:, None, :] - PAL_RGB[None, :, :]) ** 2).sum(axis=2)
nearest = dist.argmin(axis=1).reshape(H, W)


def downscale(cell_nearest, fg, box, scale):
    """Cor mais votada da paleta por caixa, e cobertura da máscara. Os pixels
    na borda da máscara são a transição suavizada da IA e pesam menos."""
    x0, y0, x1, y1 = box
    sw, sh = x1 - x0, y1 - y0
    tw, th = max(1, round(sw * scale)), max(1, round(sh * scale))
    q = cell_nearest[y0:y1, x0:x1]
    m = fg[y0:y1, x0:x1]
    core = erode(fg, 2)[y0:y1, x0:x1]
    weight = np.where(core, 1.0, 0.25)
    rows = []
    ys = np.linspace(0, sh, th + 1)
    xs = np.linspace(0, sw, tw + 1)
    for ty in range(th):
        ya, yb = int(round(ys[ty])), max(int(round(ys[ty + 1])), int(round(ys[ty])) + 1)
        row = ""
        for tx in range(tw):
            xa, xb = int(round(xs[tx])), max(int(round(xs[tx + 1])), int(round(xs[tx])) + 1)
            mm = m[ya:yb, xa:xb]
            if mm.mean() < 0.5:
                row += "."
                continue
            votes = np.bincount(q[ya:yb, xa:xb][mm], weights=weight[ya:yb, xa:xb][mm], minlength=len(PALETTE))
            row += PALETTE[int(votes.argmax())][0]
        rows.append(row)
    return rows


def unspeckle(rows):
    """Tira pixels sem nenhum vizinho de lado."""
    h, w = len(rows), len(rows[0])
    grid = [list(r) for r in rows]
    for y in range(h):
        for x in range(w):
            if grid[y][x] == ".":
                continue
            alone = True
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and rows[yy][xx] != ".":
                    alone = False
            if alone:
                grid[y][x] = "."
    return ["".join(r) for r in grid]


def trim(rows):
    while rows and set(rows[0]) == {"."}:
        rows = rows[1:]
    while rows and set(rows[-1]) == {"."}:
        rows = rows[:-1]
    cols = [i for i in range(len(rows[0])) if any(r[i] != "." for r in rows)]
    return [r[cols[0]:cols[-1] + 1] for r in rows]


def fill_enclosed(rows):
    # vão fechado no meio do desenho é pelo escuro, não fundo: a cabeça de costas perdia o miolo
    h, w = len(rows), len(rows[0])
    grid = [list(r) for r in rows]
    outside = set()
    stack = [(y, x) for y in range(h) for x in range(w) if y in (0, h - 1) or x in (0, w - 1)]
    while stack:
        y, x = stack.pop()
        if (y, x) in outside or not (0 <= y < h and 0 <= x < w) or grid[y][x] != ".":
            continue
        outside.add((y, x))
        stack += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
    for y in range(h):
        for x in range(w):
            if grid[y][x] == "." and (y, x) not in outside:
                grid[y][x] = "k"
    return ["".join(r) for r in grid]


previews = []
for i, (name, cell, fg, box) in enumerate(sprites):
    cy0, cy1, cx0, cx1 = cell_box(i)
    cell_nearest = nearest[cy0:cy1, cx0:cx1]
    rows = fill_enclosed(trim(unspeckle(downscale(cell_nearest, fg, box, scale))))
    comment = "Giorgino %s, da folha de IA de 2026-11-08, reduzida e quantizada." % COMMENTS[name]
    order = [p[0] for p in PALETTE]
    used = sorted({ch for row in rows for ch in row if ch != "."}, key=order.index)
    lines = ["# " + comment, "paleta"] + ["%s %s" % kv for kv in PALETTE if kv[0] in used] + ["pixels"] + rows
    open("%s/%s.txt" % (OUT, name), "w").write("\n".join(lines) + "\n")
    print(name, "->", len(rows[0]), "x", len(rows))
    img = Image.new("RGBA", (len(rows[0]), len(rows)), (0, 0, 0, 0))
    pal = dict(PALETTE)
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                hx = pal[ch]
                img.putpixel((x, y), tuple(int(hx[i:i + 2], 16) for i in (1, 3, 5)) + (255,))
    previews.append(img)

Z = 4
sheet = Image.new("RGBA", (COLS * (64 * Z + 8), ROWS * (64 * Z + 8)), (90, 60, 130, 255))
for i, img in enumerate(previews):
    r, c = divmod(i, COLS)
    big = img.resize((img.width * Z, img.height * Z), Image.NEAREST)
    sheet.paste(big, (c * (64 * Z + 8) + (64 * Z - big.width) // 2, r * (64 * Z + 8) + 64 * Z - big.height), big)
sheet.save(OUT + "/preview.png")
# máscaras, para conferir a separação
msheet = Image.new("L", (W, H), 0)
for i, (name, cell, fg, box) in enumerate(sprites):
    cy0, cy1, cx0, cx1 = cell_box(i)
    msheet.paste(Image.fromarray(fg.astype(np.uint8) * 255), (cx0, cy0))
msheet.save(OUT + "/masks.png")
print("preview", OUT + "/preview.png")
