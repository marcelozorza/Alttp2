"""Gera o editor de dungeons, um arquivo HTML único que abre no navegador.

Junta o modelo editor_template.html, os mapas das 4 dungeons (lidos por
extract_dungeons.py) e os desenhos de art/ usados como ícones.

Uso: python3 tools/editor/build_editor.py [arquivo de saída]
"""

import base64
import json
import re
import sys
from pathlib import Path

from extract_dungeons import ROOT, all_dungeons

HERE = Path(__file__).resolve().parent
THEMED = ["wall", "wall_face", "floor", "floor_alt", "high_floor", "high_floor_alt",
          "higher_floor", "higher_floor_alt", "cracked_wall"]
SPRITES = [
    "ice", "thick_ice", "ledge", "tall_ledge", "locked_door", "boss_door", "gate",
    "chest", "icon_bomb", "icon_fire", "icon_spring", "icon_heart", "icon_key", "icon_boss_key",
    "giorgino_stand_down", "heavy_block", "floor_switch", "crate", "message_plate", "message_plate_lit",
    "minion_walk_1", "wolf_down", "ice_cube_down", "stalactite_down", "monkey_down",
    "armadillo_down", "bat_down", "snake_down",
    "crab_shell_walk", "sentinel_shell", "crab_thick_walk", "cerberus_shell_walk",
]


def actor_sprites() -> dict:
    """Desenho de cada inimigo e chefe, pelo caractere do mapa.

    Segue a cena que world/chapter/chapter.gd liga a cada caractere e pega o
    primeiro desenho de art/ dessa cena. Assim, um inimigo redesenhado ou
    com desenho de outro nome aparece no editor ao gerar de novo.
    """
    chapter = (ROOT / "world/chapter/chapter.gd").read_text(encoding="utf-8")
    result = {}
    for char, scene in re.findall(r'"(.)": preload\("res://(enemies/\w+\.tscn)"\)', chapter):
        found = re.search(r"res://art/(\w+)\.svg", (ROOT / scene).read_text(encoding="utf-8"))
        if found:
            result[char] = found.group(1)
    return result


def sprite_names() -> list:
    names = list(SPRITES) + list(actor_sprites().values())
    for base in THEMED:
        for suffix in ("", "_castle", "_ice", "_moss"):
            names.append(base + suffix)
    return names


def main() -> None:
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "editor_de_dungeons.html"
    sprites = {}
    for name in sprite_names():
        path = ROOT / "art" / (name + ".svg")
        if path.exists():
            data = base64.b64encode(path.read_bytes()).decode("ascii")
            sprites[name] = "data:image/svg+xml;base64," + data
        else:
            print("sem desenho:", name)
    missing = [n for n in SPRITES if n not in sprites]
    if missing:
        sys.exit("ERRO: desenhos que o editor usa e não existem mais: " + ", ".join(missing))
    payload = {"dungeons": all_dungeons(), "sprites": sprites, "actorSprites": actor_sprites()}
    template = (HERE / "editor_template.html").read_text(encoding="utf-8")
    html = template.replace("/*DATA*/null", json.dumps(payload, ensure_ascii=False))
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html, encoding="utf-8")
    print(out, round(len(html) / 1024), "KB")


if __name__ == "__main__":
    main()
