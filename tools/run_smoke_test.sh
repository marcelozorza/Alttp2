#!/bin/sh
# Roda o teste de fumaça (tools/smoke_test.gd) no Godot sem tela e falha se
# aparecer erro de script ou se o teste não chegar ao fim. É o que a
# verificação do GitHub roda a cada push.
#
#     sh tools/run_smoke_test.sh            usa o godot do PATH
#     sh tools/run_smoke_test.sh /caminho/do/godot
#
# Os erros do driver de áudio, que não existe sem tela, são ignorados.
set -u
GODOT="${1:-godot}"
LOG="$(mktemp)"
"$GODOT" --headless --path . --import > /dev/null 2>&1
"$GODOT" --headless --fixed-fps 60 --path . res://tools/smoke_test.tscn 2>&1 | tee "$LOG"
if grep -q "SCRIPT ERROR" "$LOG"; then
	echo "FALHOU: erro de script no teste de fumaça"
	exit 1
fi
if grep "ERROR" "$LOG" | grep -v -e "audio" -e "init_output_device" -e "status < 0" -e "still in use" | grep -q .; then
	echo "FALHOU: erro do motor no teste de fumaça"
	exit 1
fi
if ! grep -q "^CONTINUAR" "$LOG"; then
	echo "FALHOU: o teste de fumaça não chegou ao fim"
	exit 1
fi
# Os valores impressos são comparados, linha a linha, com os de
# tools/smoke_expected.txt. A linha do ossinho fica de fora, porque depende
# de sorteio. Quando uma mudança de propósito altera um valor, confira a
# diferença e grave o arquivo de novo com:
#
#     sh tools/run_smoke_test.sh godot gravar
FOUND="$(mktemp)"
grep -E "^[A-ZÁÉÍÓÚÃÕÇ ]+: " "$LOG" | grep -v -e "^OSSINHO" -e "^WARNING" -e "^ERROR" -e "^SCRIPT ERROR" > "$FOUND"
if [ "${2:-}" = "gravar" ]; then
	cp "$FOUND" tools/smoke_expected.txt
	echo "Valores esperados gravados em tools/smoke_expected.txt."
elif ! diff tools/smoke_expected.txt "$FOUND"; then
	echo "FALHOU: algum valor do teste de fumaça mudou (esperado < e encontrado >)"
	exit 1
fi
# Os mecanismos de sala têm um teste próprio, que confere cada um na bancada
# e atravessa as salas de tempo pelos botões (tools/mechanics_test.gd).
MECH="$(mktemp)"
"$GODOT" --headless --fixed-fps 60 --path . res://tools/mechanics_test.tscn 2>&1 | tee "$MECH"
if grep -q -e "SCRIPT ERROR" -e "^FALHOU" "$MECH" || ! grep -q "^MECANISMOS: .* 0 falhas" "$MECH"; then
	echo "FALHOU: o teste dos mecanismos acusou erro"
	exit 1
fi
echo "Teste de fumaça sem erros."
