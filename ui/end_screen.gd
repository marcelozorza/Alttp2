class_name EndScreen
extends CanvasLayer
## Tela de fim do capítulo, com o tempo, o modo da partida e os baús abertos.
## Funciona com o jogo pausado.
##
## Os botões só respondem depois de um instante, para que o botão de ataque,
## que no teclado e no controle também confirma, não reinicie o capítulo por
## acidente.

const TITLE_SCENE := "res://ui/title_screen.tscn"
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
	_buttons.append(MenuKit.button("Jogar de novo", _on_replay))
	_buttons.append(MenuKit.button("Nova seed", _on_new_seed))
	_buttons.append(MenuKit.button("Menu", _on_menu))
	for button: Button in _buttons:
		column.add_child(button)


func show_results(time_text: String, mode_text: String, chests_text: String) -> void:
	_summary.text = "Tempo %s\n%s\nBaús abertos %s" % [time_text, mode_text, chests_text]
	visible = true
	for button: Button in _buttons:
		button.disabled = true
	await get_tree().create_timer(INPUT_DELAY).timeout
	for button: Button in _buttons:
		button.disabled = false
	_buttons[0].grab_focus()


## Joga de novo com a mesma distribuição: a mesma seed ou a linear.
func _on_replay() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_new_seed() -> void:
	RunSettings.randomized = true
	RunSettings.run_seed = RunSettings.new_seed()
	_on_replay()


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)
