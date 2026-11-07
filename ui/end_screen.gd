class_name EndScreen
extends CanvasLayer
## Tela de fim do capítulo, com o tempo, o capítulo e os baús abertos.
## Funciona com o jogo pausado. No jogo contínuo, o primeiro botão volta ao
## mundo, na entrada da dungeon. No treino, volta ao menu de título.
##
## Ao vencer a última dungeon no jogo contínuo, vira a tela de vitória: mostra
## o tempo do jogo inteiro e convida ao modo randomizado, o jogo de verdade
## (pedido de Marcelo em 2026-11-07). Enquanto esse modo não existe, o botão
## dele aparece desligado.
##
## Os botões só respondem depois de um instante, para que o botão de ataque,
## que no teclado e no controle também confirma, não reinicie o capítulo por
## acidente.

## Segundos com os botões desligados depois que a tela aparece.
const INPUT_DELAY := 0.8

var _title: Label
var _summary: Label
var _random_button: Button
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var column := MenuKit.centered_column(self, Color(0.05, 0.05, 0.08, 0.85))
	var title := "Capítulo concluído"
	if RunSettings.chapter == ChapterData.TUTORIAL:
		title = "Tutorial concluído"
	_title = MenuKit.label(title, 16)
	column.add_child(_title)
	_summary = MenuKit.label("", 10)
	column.add_child(_summary)
	_random_button = MenuKit.button("Modo randomizado (em breve)", _on_leave)
	_random_button.disabled = true
	_random_button.visible = false
	column.add_child(_random_button)
	if Progress.active:
		_buttons.append(MenuKit.button("Voltar ao mundo", _on_leave))
		_buttons.append(MenuKit.button("Jogar de novo", _on_replay))
	else:
		_buttons.append(MenuKit.button("Jogar de novo", _on_replay))
		_buttons.append(MenuKit.button("Menu", _on_leave))
	for button: Button in _buttons:
		column.add_child(button)


func show_results(time_text: String, chapter_text: String, chests_text: String) -> void:
	_summary.text = "Tempo %s\n%s\nBaús abertos %s" % [time_text, chapter_text, chests_text]
	await _appear()


## Vitória: o tempo do jogo inteiro desde o Novo jogo, o da última dungeon e o
## convite ao modo randomizado.
func show_victory(run_time_text: String, time_text: String, chests_text: String) -> void:
	_title.text = "Você venceu as três dungeons"
	_summary.text = (
		(
			"Tempo total %s\nÚltima dungeon em %s, baús abertos %s\n\n"
			% [run_time_text, time_text, chests_text]
		)
		+ "O jogo de verdade começa agora: as mesmas dungeons\n"
		+ "com os itens embaralhados por uma seed. Em breve."
	)
	_random_button.visible = true
	await _appear()


func _appear() -> void:
	visible = true
	for button: Button in _buttons:
		button.disabled = true
	await get_tree().create_timer(INPUT_DELAY).timeout
	for button: Button in _buttons:
		button.disabled = false
	_buttons[0].grab_focus()


func _on_replay() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_leave() -> void:
	Flow.leave_chapter(get_tree())
