"""Monta uma imagem de cada capítulo a partir dos dados do mapa e da pixel art.

Uso: python3 tools/chapter_preview.py [saida_dir]
Exemplo: python3 tools/chapter_preview.py /tmp/previa

Grava <saida>/<capitulo>.png na escala do jogo (32 px por casa) e
<saida>/quatro_dungeons.png com as quatro lado a lado, reduzidas. Serve para
ver as dungeons sem abrir o Godot, como referência para redesenhar os
cenários (pedido de Marcelo em 2026-11-08). O desenho segue world/map_view.gd
e world/dungeon_theme.gd: topo e faces das paredes, chão em tabuleiro, sombras,
adornos pelo mesmo sorteio fixo, tapete, bloqueios, baús, objetos, inimigos e
o Giorgino no início. É uma aproximação: as diagonais das quinas e os efeitos
que piscam ficam de fora. Precisa de Pillow.
"""
import pathlib
import re
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import pixel_svg  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
TILE = 32
FACE_DEPTH = 24
HALF_FACE = 16
SHADOW = 6
SHADOW_COLOR = (0, 0, 0, 77)
ROOM = (20, 10)
CARPET = (6, 4)
PLAIN_FLOOR = ".:^"
CARPET_FLOOR = ".@muiwsxyz*&%$"

CHAPTERS = [
    ("tutorial", "world/tutorial/tutorial_data.gd", ""),
    ("capitulo_1", "world/chapter_one/chapter_one_data.gd", "_castle"),
    ("capitulo_2", "world/chapter_two/chapter_two_data.gd", "_ice"),
    ("capitulo_3", "world/chapter_three/chapter_three_data.gd", "_moss"),
]
## A galeria mistura os quatro temas, um por tela (ROOM_THEMES nos dados).
GALLERY = ("galeria", "world/gallery/gallery_data.gd")
THEME_SUFFIX = {"stone": "", "castle": "_castle", "ice": "_ice", "moss": "_moss"}
THEMES = {
    "": dict(sconce="torch", flame="flame_1", spacing=5, floor_props=["bones_pile"]),
    "_castle": dict(sconce="candelabra", spacing=6, hangings=["banner"], hanging_chance=18, carpet=True),
    "_ice": dict(sconce="torch", flame="flame_blue_1", spacing=5, floor_props=["ice_crystal"],
                 overlay="frost", overlay_chance=9, icicles="icicles", icicle_chance=30),
    "_moss": dict(sconce="torch", flame="flame_1", spacing=7, hangings=["vine"], hanging_chance=22,
                  floor_props=["bones_pile"], overlay="moss_patch", overlay_chance=12, cobweb="cobweb",
                  cobweb_chance=45),
}
ENEMIES = {
    "m": "minion_walk_1", "u": "wolf_down", "i": "ice_cube_down", "w": "stalactite_down",
    "s": "monkey_down", "x": "armadillo_down", "y": "bat_down", "z": "snake_down",
    "*": "crab_shell_walk", "&": "sentinel_shell", "%": "crab_thick_walk", "$": "cerberus_shell_walk",
}
OBJECTS = {"c": "crate", "0": "heavy_block", "=": "floor_switch"}
BLOCK_ART = {
    "CRACKED": "cracked_wall", "LOCKED": "locked_door", "BOSS_DOOR": "boss_door", "GATE": "gate_door",
}

_cache = {}


def art(name):
    """Imagem RGBA de um desenho de art/source."""
    if name in _cache:
        return _cache[name]
    palette, rows = pixel_svg.load(name, {})
    img = Image.new("RGBA", (max(len(r) for r in rows), len(rows)), (0, 0, 0, 0))
    px = img.load()
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch != ".":
                h = palette[ch]
                px[x, y] = tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)
    _cache[name] = img
    return img


def read_data(path):
    text = (ROOT / path).read_text(encoding="utf-8")
    rows = re.findall(r'^\t"([^"]*)",$', text.split("const MAP := [")[1].split("\n]")[0], re.M)
    blocks = dict(re.findall(r'"(.)": ChapterMap\.Block\.(\w+)', text.split("const BLOCKS := {")[1].split("}")[0]))
    room_themes = {}
    if "const ROOM_THEMES := {" in text:
        body = text.split("const ROOM_THEMES := {")[1].split("}")[0]
        for sx, sy, name in re.findall(r'Vector2i\((\d+), (\d+)\): "(\w+)"', body):
            room_themes[(int(sx), int(sy))] = THEME_SUFFIX[name]
    return rows, blocks, room_themes


def chance(x, y, salt):
    h = ((x * 73856093) ^ (y * 19349663) ^ (salt * 83492791)) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return (h & 0x7FFFFFFF) % 100


class Chapter:
    def __init__(self, rows, blocks, suffix, room_themes=None):
        self.rows, self.blocks, self.suffix = rows, blocks, suffix
        self.theme = THEMES[suffix]
        self.default_suffix = suffix
        self.room_themes = room_themes or {}
        self.height = len(rows)
        self.width = max(len(r) for r in rows)
        self.img = Image.new("RGBA", (self.width * TILE, self.height * TILE), (0, 0, 0, 255))
        self.draw = ImageDraw.Draw(self.img, "RGBA")

    def select(self, x, y):
        """Escolhe o tema da tela onde está a casa, quando o capítulo mistura temas."""
        if self.room_themes:
            self.suffix = self.room_themes.get((x // ROOM[0], y // ROOM[1]), self.default_suffix)
            self.theme = THEMES[self.suffix]

    def tile(self, x, y):
        if 0 <= y < self.height and 0 <= x < len(self.rows[y]):
            return self.rows[y][x]
        return " "

    def is_floor(self, x, y):
        return self.tile(x, y) not in "# "

    def level(self, x, y):
        ch = self.tile(x, y)
        if ch == "^":
            return 2
        if ch == ":":
            return 1
        if ch in ".# ":
            return 0
        level = 0
        for dx, dy in ((0, -1), (0, 1), (-1, 0), (1, 0)):
            n = self.tile(x + dx, y + dy)
            if n == "^":
                return 2
            if n == ":":
                level = 1
        return level

    def paste(self, name, x, y, flip=False):
        img = art(name)
        if flip:
            img = img.transpose(Image.FLIP_LEFT_RIGHT)
        self.img.alpha_composite(img, (int(x), int(y)))

    def floor_name(self, level, alternate):
        base = {2: "higher_floor", 1: "high_floor", 0: "floor"}[level]
        return base + ("_alt" if alternate else "") + self.suffix

    def render(self):
        for y in range(self.height):
            for x in range(self.width):
                ch = self.tile(x, y)
                if ch == " ":
                    continue
                self.select(x, y)
                if ch == "#":
                    self.wall(x, y)
                    continue
                self.paste(self.floor_name(self.level(x, y), (x + y) % 2 == 0), x * TILE, y * TILE)
                t = self.theme
                if t.get("overlay") and ch in PLAIN_FLOOR and chance(x, y, 4) < t["overlay_chance"]:
                    self.paste(t["overlay"], x * TILE, y * TILE)
                self.shadows(x, y)
        self.decor()
        self.things()
        return self.img

    def wall(self, x, y):
        ox, oy = x * TILE, y * TILE
        self.paste("wall" + self.suffix, ox, oy)
        n, s = self.is_floor(x, y - 1), self.is_floor(x, y + 1)
        w, e = self.is_floor(x - 1, y), self.is_floor(x + 1, y)
        face = art("wall_face" + self.suffix)
        side = art("wall_side" + self.suffix)

        def depth(a, b):
            return 0 if not a else (HALF_FACE if b else FACE_DEPTH)

        dn, ds, dw, de = depth(n, s), depth(s, n), depth(w, e), depth(e, w)
        if s:
            self.img.alpha_composite(face.crop((0, TILE - ds, TILE, TILE)), (ox, oy + TILE - ds))
        if n:
            flipped = face.transpose(Image.FLIP_TOP_BOTTOM)
            self.img.alpha_composite(flipped.crop((0, 0, TILE, dn)), (ox, oy))
        if e:
            self.img.alpha_composite(side.crop((TILE - de, dn, TILE, TILE - ds)), (ox + TILE - de, oy + dn))
        if w:
            flipped = side.transpose(Image.FLIP_LEFT_RIGHT)
            self.img.alpha_composite(flipped.crop((0, dn, dw, TILE - ds)), (ox, oy + dn))

    def shadows(self, x, y):
        ox, oy = x * TILE, y * TILE
        if self.tile(x, y - 1) == "#":
            self.draw.rectangle((ox, oy, ox + TILE - 1, oy + SHADOW - 1), fill=SHADOW_COLOR)
        if self.tile(x - 1, y) == "#":
            top = SHADOW if self.tile(x, y - 1) == "#" else 0
            self.draw.rectangle((ox, oy + top, ox + SHADOW - 1, oy + TILE - 1), fill=SHADOW_COLOR)

    def decor(self):
        self.carpets()
        for y in range(self.height):
            last = -2
            for x in range(self.width):
                if self.tile(x, y) != "#" or not self.is_floor(x, y + 1):
                    continue
                self.select(x, y)
                t = self.theme
                ox, oy = x * TILE, y * TILE
                done = False
                if x - last >= 2:
                    done = self.wall_prop(x, y, ox, oy)
                if done:
                    last = x
                elif t.get("icicles") and chance(x, y, 3) < t["icicle_chance"]:
                    self.paste(t["icicles"], ox, oy + TILE - FACE_DEPTH)
        for y in range(self.height):
            for x in range(self.width):
                if self.tile(x, y) in PLAIN_FLOOR:
                    self.select(x, y)
                    self.floor_decor(x, y)

    def wall_prop(self, x, y, ox, oy):
        t = self.theme
        if t.get("sconce") and chance(x, y, 1) * t["spacing"] < 100:
            img = art(t["sconce"])
            cx, cy = ox + (TILE - img.width) // 2, oy + (TILE - img.height) // 2
            self.paste(t["sconce"], cx, cy)
            if t.get("flame"):
                self.paste(t["flame"], cx, cy - 10)
            return True
        if not t.get("hangings") or chance(x, y, 2) >= t["hanging_chance"]:
            return False
        name = t["hangings"][chance(x, y, 7) % len(t["hangings"])]
        img = art(name)
        cy = oy + TILE - img.height
        if cy < oy and self.tile(x, y - 1) != "#":
            return False
        self.paste(name, ox + (TILE - img.width) // 2, cy)
        return True

    def floor_decor(self, x, y):
        t = self.theme
        ox, oy = x * TILE, y * TILE
        above, left, right = self.tile(x, y - 1) == "#", self.tile(x - 1, y) == "#", self.tile(x + 1, y) == "#"
        if t.get("cobweb") and above and chance(x, y, 6) < t["cobweb_chance"]:
            if left:
                self.paste(t["cobweb"], ox, oy)
                return
            if right:
                self.paste(t["cobweb"], ox + TILE - art(t["cobweb"]).width, oy, flip=True)
                return
        if not t.get("floor_props") or not (above or left or right):
            return
        if chance(x, y, 5) >= 5:
            return
        name = t["floor_props"][chance(x, y, 8) % len(t["floor_props"])]
        img = art(name)
        self.paste(name, ox + (TILE - img.width) // 2, oy + TILE - img.height - 4)

    def carpets(self):
        screens = (-(-self.width // ROOM[0]), -(-self.height // ROOM[1]))
        for sy in range(screens[1]):
            for sx in range(screens[0]):
                self.select(sx * ROOM[0], sy * ROOM[1])
                if not self.theme.get("carpet"):
                    continue
                cx = sx * ROOM[0] + (ROOM[0] - CARPET[0]) // 2
                cy = sy * ROOM[1] + (ROOM[1] - CARPET[1]) // 2
                cells = [(x, y) for y in range(cy, cy + CARPET[1]) for x in range(cx, cx + CARPET[0])]
                if not all(self.tile(x, y) in CARPET_FLOOR for x, y in cells):
                    continue
                for x, y in cells:
                    self.paste("carpet", x * TILE, y * TILE)
                box = (cx * TILE, cy * TILE, (cx + CARPET[0]) * TILE - 1, (cy + CARPET[1]) * TILE - 1)
                self.draw.rectangle(box, outline=(64, 18, 26, 255), width=2)
                inner = (box[0] + 4, box[1] + 4, box[2] - 4, box[3] - 4)
                self.draw.rectangle(inner, outline=(214, 168, 64, 255), width=2)

    def things(self):
        """Bloqueios, baús, objetos, inimigos e o Giorgino, por cima do mapa."""
        for y in range(self.height):
            for x in range(self.width):
                ch = self.tile(x, y)
                ox, oy = x * TILE, y * TILE
                if ch in self.blocks:
                    self.block(ch, x, y)
                elif "A" <= ch <= "Z":
                    self.paste("chest", ox, oy)
                elif ch in OBJECTS:
                    self.paste(OBJECTS[ch], ox, oy)
                elif ch in ENEMIES:
                    self.sprite(ENEMIES[ch], ox, oy)
                elif ch == "@":
                    self.sprite("giorgino_stand_down", ox, oy)

    def sprite(self, name, ox, oy):
        img = art(name)
        self.paste(name, ox + (TILE - img.width) // 2, oy + TILE - img.height)

    def block(self, ch, x, y):
        kind = self.blocks[ch]
        ox, oy = x * TILE, y * TILE
        if kind in ("LEDGE", "TALL_LEDGE"):
            below = self.tile(x, y + 1) == ch
            if kind == "TALL_LEDGE" or (y > 0 and self.tile(x, y - 1) == ch):
                self.paste("tall_ledge" if kind == "TALL_LEDGE" else "ledge", ox, oy)
            else:
                self.paste("ledge", ox, oy)
            if not below:
                self.draw.rectangle((ox, oy + TILE, ox + TILE - 1, oy + TILE + 7), fill=SHADOW_COLOR)
            return
        if kind in ("ICE", "THICK_ICE"):
            prefix = "thick_ice" if kind == "THICK_ICE" else "ice"
            front = self.tile(x, y + 1) != ch
            self.paste(prefix if front else prefix + "_top", ox, oy)
            return
        self.paste(BLOCK_ART[kind], ox, oy)


def main(arguments):
    out = pathlib.Path(arguments[0]) if arguments else pathlib.Path("/tmp/chapter_preview")
    out.mkdir(parents=True, exist_ok=True)
    images = []
    for key, path, suffix in CHAPTERS:
        rows, blocks, _ = read_data(path)
        img = Chapter(rows, blocks, suffix).render()
        img.save(out / f"{key}.png")
        print(key, img.size)
        images.append((key, img))
    # as quatro numa só, cada uma reduzida à metade, uma embaixo da outra
    gap = 24
    width = max(img.width for _, img in images) // 2
    height = sum(img.height // 2 for _, img in images) + gap * (len(images) - 1)
    sheet = Image.new("RGBA", (width, height), (20, 18, 26, 255))
    y = 0
    for key, img in images:
        small = img.resize((img.width // 2, img.height // 2), Image.NEAREST)
        sheet.alpha_composite(small, (0, y))
        y += small.height + gap
    sheet.save(out / "quatro_dungeons.png")
    print("quatro", sheet.size)
    key, path = GALLERY
    rows, blocks, room_themes = read_data(path)
    img = Chapter(rows, blocks, "", room_themes).render()
    img.save(out / f"{key}.png")
    print(key, img.size)


if __name__ == "__main__":
    main(sys.argv[1:])
