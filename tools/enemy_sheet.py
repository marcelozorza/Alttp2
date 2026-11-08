"""Converte uma folha de poses gerada por IA em fontes de pixel art de um inimigo.

Uso: python3 tools/enemy_sheet.py <inimigo> <folha.png> [saida_dir]
     python3 tools/enemy_sheet.py --lista
Exemplo: python3 tools/enemy_sheet.py ice_cube folha.png && python3 tools/pixel_svg.py

Sem saida_dir, grava direto em art/source/ e uma prévia em
/tmp/enemy_sheet/<inimigo>/preview.png. Mesmo método de tools/giorgino_sheet.py
(que absorveu o conversor do lobo): a sprite se separa do fundo pelas bordas do
desenho, a escala vem da primeira pose (altura em PRESETS), e cada pixel de
saída recebe a cor da paleta mais votada entre os pixels que cobre. A paleta
sai da própria folha: corte pela mediana nos tons apagados, mais algumas
cores fortes separadas (olhos, brilhos, estrelas), para não sumirem.

Cada inimigo em PRESETS diz a grade da folha, a altura da primeira pose em
pixels do jogo e o nome de cada célula, na ordem da folha, linha por linha.
Célula com None é descartada. As folhas de 2026-11-08 estão em
/mnt/project-files/inimigos/ e /mnt/project-files/ugly/ (o lobo).
"""
import pathlib
import sys
from collections import deque
from PIL import Image, ImageFilter
import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
EDGE = 5.0
LETTERS = "abcdefghijklmnopqrstuvwxyz"


def lunge_set(prefix):
    """As 16 poses no formato do lobo: andar, investida, preparo, descanso,
    golpe e queda."""
    return [
        f"{prefix}_down", f"{prefix}_down_step", f"{prefix}_up", f"{prefix}_up_step",
        f"{prefix}_side", f"{prefix}_side_step", f"{prefix}_lunge_down", f"{prefix}_lunge_down_step",
        f"{prefix}_lunge_up", f"{prefix}_lunge_up_step", f"{prefix}_lunge_side", f"{prefix}_lunge_side_step",
        f"{prefix}_windup", f"{prefix}_recover", f"{prefix}_hit", f"{prefix}_fallen",
    ]


def boss_set(prefix):
    """As 16 poses de um chefe: 8 com a casca e 8 com o núcleo exposto."""
    names = []
    for part in ("shell", "core"):
        names += [
            f"{prefix}_{part}_walk", f"{prefix}_{part}_walk_step",
            f"{prefix}_{part}_slam_windup", f"{prefix}_{part}_slam",
            f"{prefix}_{part}_charge_windup", f"{prefix}_{part}_charge",
            f"{prefix}_{part}_charge_step", f"{prefix}_{part}_recover",
        ]
    names[-1] = f"{prefix}_fallen"
    return names


PRESETS = {
    # O lobo, o cubo de gelo e a estalactite saíram daqui em 2026-11-08: foram
    # redesenhados à mão em art/source/ e não devem ser gerados de folha nenhuma.
    "monkey": dict(cols=4, rows=4, height=36, colors=10, accents=5, comment="Atirador de pedras, macaquinho",
                   names=[
        "monkey_down", "monkey_down_step", "monkey_up", "monkey_up_step",
        "monkey_side", "monkey_side_step", "monkey_throw_windup", "monkey_throw_windup_side",
        "monkey_throw_windup_up", "monkey_throw", "monkey_throw_side", "monkey_throw_up",
        "monkey_hit", "monkey_fallen", None, "monkey_taunt"]),
    "armadillo": dict(cols=4, rows=3, height=22, colors=11, accents=3, comment="Tatu de pedra", names=[
        "armadillo_down", "armadillo_down_step", "armadillo_up", "armadillo_up_step",
        "armadillo_side", "armadillo_side_step", "armadillo_ball", "armadillo_ball_side",
        "armadillo_hit", "armadillo_fallen", "armadillo_hide", "armadillo_threat"]),
    "bat": dict(cols=4, rows=4, height=17, colors=10, accents=5, comment="Morcego", names=lunge_set("bat")),
    "snake": dict(cols=4, rows=4, height=30, colors=10, accents=5, comment="Planta de espinhos, cobra",
                  names=lunge_set("snake")),
    "crab": dict(cols=4, rows=4, height=48, colors=12, accents=4, comment="Guardião, caranguejo",
                 names=boss_set("crab")),
    "cerberus": dict(cols=4, rows=4, height=56, colors=12, accents=5, comment="Colosso, cérbero",
                     names=boss_set("cerberus")),
}


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




def downscale(cell_nearest, fg, box, scale, palette):
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
            votes = np.bincount(q[ya:yb, xa:xb][mm], weights=weight[ya:yb, xa:xb][mm], minlength=len(palette))
            row += palette[int(votes.argmax())][0]
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




def convert(key, src, out_dir):
    preset = PRESETS[key]
    cols, rows_count = preset["cols"], preset["rows"]
    im = Image.open(src).convert("RGB")
    a = np.array(im).astype(int)
    H, W = a.shape[:2]
    CW, CH = W // cols, H // rows_count
    sprites = []
    for i, name in enumerate(preset["names"]):
        if name is None:
            continue
        r, c = divmod(i, cols)
        cell = a[r * CH:(r + 1) * CH, c * CW:(c + 1) * CW]
        fg = foreground_mask(cell)
        fg = dilate(erode(fg, 2), 2)
        _, comps = components(fg)
        best = max(len(comp) for comp in comps)
        fg = np.zeros_like(fg)
        # fica o corpo e as partes soltas grandes, como as estrelas do atordoado,
        # menos pedaços pequenos encostados na beira, que são da pose vizinha
        for comp in comps:
            cys = [p[0] for p in comp]
            at_edge = min(cys) == 0 or max(cys) >= CH - 2
            if at_edge and len(comp) < best * 0.2:
                continue
            if len(comp) >= best * 0.004 and len(comp) >= 40:
                for y, x in comp:
                    fg[y, x] = True
        ys, xs = np.where(fg)
        box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
        sprites.append((name, (r, c), cell, fg, box))
        print(name, "tam", box[2] - box[0], box[3] - box[1])

    x0, y0, x1, y1 = sprites[0][4]
    scale = preset["height"] / (y1 - y0)
    print("escala", 1 / scale, "px de origem por pixel")

    pixels = np.concatenate([cell[fg] for _, _, cell, fg, _ in sprites]).astype(np.uint8)
    mx, mn = pixels.max(axis=1).astype(int), pixels.min(axis=1).astype(int)
    vivid = (mx - mn) > 60
    raw = median_cut(pixels[~vivid], preset["colors"])
    raw = raw[np.argsort(raw.sum(axis=1))]
    if vivid.sum() > 50:
        raw = np.concatenate([raw, median_cut(pixels[vivid], preset["accents"])])
    palette = [(LETTERS[i], "#%02x%02x%02x" % tuple(int(v) for v in rgb)) for i, rgb in enumerate(raw)]
    pal_rgb = raw.astype(float)
    flat = a.reshape(-1, 3).astype(float)
    dist = ((flat[:, None, :] - pal_rgb[None, :, :]) ** 2).sum(axis=2)
    nearest = dist.argmin(axis=1).reshape(H, W)

    out_dir.mkdir(parents=True, exist_ok=True)
    preview_dir = pathlib.Path("/tmp/enemy_sheet") / key
    preview_dir.mkdir(parents=True, exist_ok=True)
    previews = []
    for name, (r, c), cell, fg, box in sprites:
        cell_nearest = nearest[r * CH:(r + 1) * CH, c * CW:(c + 1) * CW]
        rows = trim(unspeckle(downscale(cell_nearest, fg, box, scale, palette)))
        comment = "%s, %s, da folha de IA de 2026-11-08, reduzida e quantizada." % (
            preset["comment"], name[len(key) + 1:].replace("_", " "))
        order = [p[0] for p in palette]
        used = sorted({ch for row in rows for ch in row if ch != "."}, key=order.index)
        lines = ["# " + comment, "paleta"] + ["%s %s" % kv for kv in palette if kv[0] in used] + ["pixels"] + rows
        (out_dir / f"{name}.txt").write_text("\n".join(lines) + "\n")
        print(name, "->", len(rows[0]), "x", len(rows))
        img = Image.new("RGBA", (len(rows[0]), len(rows)), (0, 0, 0, 0))
        pal = dict(palette)
        for y, row in enumerate(rows):
            for x, ch in enumerate(row):
                if ch != ".":
                    hx = pal[ch]
                    img.putpixel((x, y), tuple(int(hx[i:i + 2], 16) for i in (1, 3, 5)) + (255,))
        previews.append(img)
    Z = 4
    side = 100 * Z + 8
    sheet = Image.new("RGBA", (cols * side, rows_count * side), (70, 110, 70, 255))
    for (name, (r, c), _, _, _), img in zip(sprites, previews):
        big = img.resize((img.width * Z, img.height * Z), Image.NEAREST)
        sheet.paste(big, (c * side + (side - big.width) // 2, r * side + side - 8 - big.height), big)
    sheet.save(preview_dir / "preview.png")
    print("prévia", preview_dir / "preview.png")


def median_cut(px, count):
    strip = Image.fromarray(px.reshape(1, -1, 3))
    quant = strip.quantize(count, method=Image.Quantize.MEDIANCUT)
    return np.array(quant.getpalette()[: count * 3]).reshape(-1, 3)


def main(arguments):
    if arguments[:1] == ["--lista"]:
        print("\n".join(PRESETS))
        return 0
    if len(arguments) < 2 or arguments[0] not in PRESETS:
        print(__doc__)
        return 1
    out_dir = pathlib.Path(arguments[2]) if len(arguments) > 2 else ROOT / "art" / "source"
    convert(arguments[0], arguments[1], out_dir)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
