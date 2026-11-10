"""Confere a pixel art de art/source contra as regras de harmonia.

Uso: python3 tools/check_art.py

Regras, decididas em 2026-11-10 para todos os desenhos conversarem entre si:

- Toda cor vem da paleta mestra (tools/art/palette.py).
- Nenhum desenho é uma grade grossa ampliada: se todo bloco de 2 por 2
  pixels tem uma cor só, o desenho foi feito em 16 px e dobrado.
- O SVG de art/ é o que tools/pixel_svg.py gera a partir do texto. Se alguém
  editou o texto e esqueceu de gerar, o jogo mostra o desenho antigo.

Cada falha sai numa linha ERRO, e o programa termina com código 1. Um desenho
que nenhum script ou cena usa sai numa linha AVISO, que não é falha.
"""

import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent / "art"))

import pixel_svg  # noqa: E402
from palette import COLORS  # noqa: E402

ROOT = pixel_svg.ROOT
# Lado mínimo para a regra do pixel dobrado: desenhos menores podem ter
# blocos de uma cor só por acaso.
MIN_SIDE = 12


def is_doubled(rows):
    height = len(rows)
    width = len(rows[0])
    if width % 2 or height % 2 or width < MIN_SIDE or height < MIN_SIDE:
        return False
    for y in range(0, height, 2):
        for x in range(0, width, 2):
            block = {rows[y][x], rows[y][x + 1], rows[y + 1][x], rows[y + 1][x + 1]}
            if len(block) > 1:
                return False
    return len({ch for row in rows for ch in row}) > 1


def used_names():
    text = []
    for pattern in ("*.gd", "*.tscn", "*.godot", "*.tres"):
        for path in ROOT.rglob(pattern):
            if ".godot" not in path.parts:
                text.append(path.read_text(encoding="utf-8", errors="ignore"))
    return "\n".join(text)


def main():
    master = {color.lower() for color in COLORS}
    cache = {}
    errors = 0
    code = used_names()
    names = sorted(p.stem for p in pixel_svg.SOURCE.glob("*.txt"))
    for name in names:
        palette, rows = pixel_svg.load(name, cache)
        used = {ch for row in rows for ch in row if ch != "."}
        strange = sorted({palette[ch] for ch in used if palette[ch].lower() not in master})
        if strange:
            print("ERRO %s: cor fora da paleta mestra: %s" % (name, ", ".join(strange)))
            errors += 1
        if is_doubled(rows):
            print("ERRO %s: pixels dobrados, desenho de grade grossa ampliado" % name)
            errors += 1
        svg = pixel_svg.OUTPUT / (name + ".svg")
        if not svg.exists():
            print("ERRO %s: falta o SVG, rode tools/pixel_svg.py" % name)
            errors += 1
        elif svg.read_text(encoding="utf-8") != pixel_svg.to_svg(name, palette, rows):
            print("ERRO %s: o SVG não acompanha o texto, rode tools/pixel_svg.py" % name)
            errors += 1
        # Quadros numerados costumam ser montados no código ("nome_%d").
        stem = name.rstrip("0123456789").rstrip("_")
        if (name + ".svg") not in code and (stem + "_") not in code:
            print("AVISO %s: nenhum script ou cena usa este desenho" % name)
    for svg in sorted(pixel_svg.OUTPUT.glob("*.svg")):
        if svg.stem not in names:
            print("ERRO %s: SVG sem texto em art/source" % svg.stem)
            errors += 1
    print("%d desenhos conferidos, %d com falha" % (len(names), errors))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
