class_name EndScreen
extends CanvasLayer
## Tela de fim do capítulo, com o tempo, o capítulo e os baús abertos.
## Funciona com o jogo pausado. No jogo contínuo, o primeiro botão volta ao
## mundo, na entrada da dungeon. No treino, volta ao menu de título.
##
## Os botões só respondem depois de um instante, para que o botão de ataque,
## que no teclado e no controle também confirma, não reinicie o capítulo por
## acidente.

## Segundos com os botões desligados depois que a tela aparece.
const INPUT_DELAY := 0.8

var _summary: Label
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var column := MenuKit.centered_column(self, Color(0.05, 0.05, 0.08, 0.85))
	column.add_child(MenuKit.label("Capítulo concluído", 16))
	_summary = MenuKit.label("", 10)
	column.add_child(_summary)
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
