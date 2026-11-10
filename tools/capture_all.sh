#!/bin/sh
# Captura o mundo, os quatro capítulos, a Galeria e as telas numa pasta, para
# comparar a arte antes e depois de uma mudança. Rodar numa cópia do projeto
# fora do repositório, depois do --import:
#
#     sh tools/capture_all.sh /pasta/de/saida [godot]
set -u
OUT="$1"
GODOT="${2:-godot}"
mkdir -p "$OUT"
run() {
	xvfb-run -a -s "-screen 0 2600x2600x24" "$GODOT" --path . res://tools/capture.tscn -- "$@" 2>&1 | grep -e "CAPTURA" -e "SCRIPT ERROR"
}
run overworld "$OUT/mundo.png"
run chapter 0 "$OUT/tutorial.png"
run chapter 1 "$OUT/capitulo_1.png"
run chapter 2 "$OUT/capitulo_2.png"
run chapter 3 "$OUT/capitulo_3.png"
run chapter -1 "$OUT/galeria.png"
run scene res://ui/title_screen.tscn "$OUT/titulo.png"
run scene res://ui/seed_screen.tscn "$OUT/seed.png"
