class_name PauseMenu
extends CanvasLayer
## Menu de pausa. O botão de pausa (Start ou Esc) para o jogo e mostra as
## opções: continuar, ver o mapa no capítulo, ou sair. No capítulo, sair leva
## ao mundo no jogo contínuo e ao menu de título no treino, e perde o que foi
## feito no capítulo. No mundo e na sala de teste, sair leva ao menu de título.
##
## O botão Mapa esconde este menu e abre a tela de mapa (ui/map_screen.gd),
## que volta para cá ao fechar. Ele só aparece onde há uma tela de mapa na
## cena, no grupo "map_screen".
##
## Não abre enquanto outra tela, como a de fim, a de derrota ou a de mapa,
## estiver com o jogo parado, nem com o personagem sem vida, para a tela de
## derrota poder aparecer.

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
	column.add_child(MenuKit.label("Pausa", 32))
	if Progress.active and Progress.seed != 0:
		column.add_child(MenuKit.label("Seed %06d" % Progress.seed, 16))
	_buttons.append(MenuKit.button("Continuar", resume))
	if _map_screen():
		_buttons.append(MenuKit.button("Mapa", _on_map))
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
	refocus()


## Devolve o foco ao primeiro botão, ao abrir e ao voltar da tela de mapa.
func refocus() -> void:
	_buttons[0].grab_focus()


func _player_is_dead() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	return player != null and player.is_dead()


func _map_screen() -> CanvasLayer:
	return get_tree().get_first_node_in_group("map_screen") as CanvasLayer


func resume() -> void:
	visible = false
	Music.set_paused(false)
	get_tree().paused = false


func _on_map() -> void:
	var map_screen := _map_screen()
	if map_screen == null:
		return
	visible = false
	map_screen.call("open", self)


func _on_exit() -> void:
	Music.set_paused(false)
	if exit_to_title:
		Flow.go_to_title(get_tree())
	else:
		Flow.leave_chapter(get_tree())
