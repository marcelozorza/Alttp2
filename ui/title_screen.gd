extends Control
## Tela de título. Continuar o jogo salvo, se houver, começar um jogo novo,
## ou ir ao treino, com cada capítulo avulso e a sala de teste.
##
## O jogo novo só grava por cima do salvo quando o personagem vence um
## capítulo ou encosta na pedra de salvamento.


func _ready() -> void:
	Progress.active = false
	var column := MenuKit.centered_column(self, Color(0.1, 0.11, 0.13, 1.0))
	column.add_child(MenuKit.label("Alttp2", 24))
	column.add_child(MenuKit.label("nome provisório", 8))
	var first: Button = null
	if Progress.exists():
		first = MenuKit.button("Continuar", _on_continue)
		column.add_child(first)
	var new_game := MenuKit.button("Novo jogo", _on_new_game)
	column.add_child(new_game)
	if not first:
		first = new_game
	column.add_child(MenuKit.button("Treino", _on_training))
	first.grab_focus.call_deferred()


func _on_continue() -> void:
	if Progress.load_file():
		get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)


func _on_new_game() -> void:
	Progress.start_new()
	get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)


func _on_training() -> void:
	get_tree().change_scene_to_file(Flow.TRAINING_SCENE)
