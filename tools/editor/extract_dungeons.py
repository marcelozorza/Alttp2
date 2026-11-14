"""Lê os dados das 4 dungeons do jogo e devolve um dicionário para o editor.

Usado por build_editor.py. Lê os arquivos de dados em texto, sem o Godot.
"""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

DUNGEONS = [
    ("tutorial", "Dungeon de teste (tutorial)", "world/tutorial/tutorial_data.gd", "stone"),
    ("cap1", "Dungeon 1 (castelo)", "world/chapter_one/chapter_one_data.gd", "castle"),
    ("cap2", "Dungeon 2 (geleira)", "world/chapter_two/chapter_two_data.gd", "ice"),
    ("cap3", "Dungeon 3 (pedreira)", "world/chapter_three/chapter_three_data.gd", "moss"),
]


def _block(text: str, name: str) -> str:
    """Corpo de uma constante entre colchetes ou chaves."""
    match = re.search(r"^const " + name + r" := ([\[{])", text, re.M)
    if not match:
        return ""
    opener = match.group(1)
    closer = "]" if opener == "[" else "}"
    start = match.end()
    depth = 1
    i = start
    while depth:
        if text[i] == opener:
            depth += 1
        elif text[i] == closer:
            depth -= 1
        i += 1
    return text[start : i - 1]


def read(path: str) -> dict:
    text = (ROOT / path).read_text(encoding="utf-8")
    rows = re.findall(r'^\s*"(.*)",\s*$', _block(text, "MAP"), re.M)
    blocks = dict(re.findall(r'"(.)":\s*ChapterMap\.Block\.(\w+)', _block(text, "BLOCKS")))
    items = dict(re.findall(r'"(.)":\s*Item\.Id\.(\w+)', _block(text, "ITEMS")))
    rooms = [
        [int(n) for n in m]
        for m in re.findall(r"Rect2i\((\d+),\s*(\d+),\s*(\d+),\s*(\d+)\)", _block(text, "ROOMS"))
    ]
    messages = [
        [int(x), int(y), bytes(t, "utf-8").decode("unicode_escape").encode("latin-1").decode("utf-8")]
        for x, y, t in re.findall(
            r'Vector2i\((\d+),\s*(\d+)\):\s*"((?:[^"\\]|\\.)*)"', _block(text, "MESSAGES")
        )
    ]
    tools = re.findall(r"Item\.Id\.(\w+)", _block(text, "STARTING_TOOLS"))
    return {
        "rows": rows,
        "blocks": blocks,
        "items": items,
        "rooms": rooms,
        "messages": messages,
        "startingTools": tools,
    }


def all_dungeons() -> list:
    result = []
    for key, name, path, theme in DUNGEONS:
        data = read(path)
        data.update({"id": key, "name": name, "theme": theme, "source": path})
        result.append(data)
    return result


if __name__ == "__main__":
    for d in all_dungeons():
        width = max(len(r) for r in d["rows"])
        print(d["id"], width, len(d["rows"]), len(d["blocks"]), len(d["items"]), d["rooms"], len(d["messages"]))
        print("  ", sorted(set("".join(d["rows"]))))
