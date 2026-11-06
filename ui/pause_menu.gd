class_name PauseMenu
extends CanvasLayer
## Menu de pausa. O botão de pausa (Start, Back ou Esc) para o jogo e mostra
## as opções: continuar, ou sair. No capítulo, sair leva ao mundo no jogo
## contínuo e ao menu de título no treino, e perde o que foi feito no
## capítulo. No mundo e na sala de teste, sair leva ao menu de título.
##
## Não abre enquanto outra tela, como a de fim ou a de derrota, estiver com o
## jogo parado, nem com o personagem sem vida, para a tela de derrota poder
## aparecer.

## Texto do botão de sair.
@export var exit_text := "Sair do capítulo"
## Ligado, sair leva sempre ao menu de título.
@export var exit_to_title := false

var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var column := MenuKit.centered_column(self, Color(0.05, 0.05, 0.08, 0.75))
	column.add_child(MenuKit.label("Pausa", 16))
	_buttons.append(MenuKit.button("Continuar", resume))
	_buttons.append(MenuKit.button(exit_text, _on_exit))
	for button: Button in _buttons:
		column.add_child(button)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if visible:
		resume()
	elif not get_tree().paused and not _player_is_dead():
		open()


func open() -> void:
	get_tree().paused = true
	Music.set_paused(true)
	visible = true
	Sfx.play(&"menu_confirm")
	_buttons[0].grab_focus()


func _player_is_dead() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	return player != null and player.is_dead()


func resume() -> void:
	visible = false
	Music.set_paused(false)
	get_tree().paused = false


func _on_exit() -> void:
	Music.set_paused(false)
	if exit_to_title:
		Flow.go_to_title(get_tree())
	else:
		Flow.leave_chapter(get_tree())
