extends Node2D
## Sala de teste da física, do combate e das ferramentas. O personagem começa
## com todas elas, inclusive a chama forte, e há um degrau alto, uma parede
## rachada, um bloco de gelo, um gelo grosso e uma morsa de gelo para
## experimentar. Os bloqueios voltam ao reabrir a sala. Esc volta ao menu.

const TITLE_SCENE := "res://ui/title_screen.tscn"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back_to_menu"):
		get_tree().change_scene_to_file(TITLE_SCENE)
