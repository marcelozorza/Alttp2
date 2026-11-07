extends Control
## Tela de título. Continuar o jogo salvo, se houver, começar um jogo novo,
## jogar o tutorial, que fica fora do mundo, ou ir ao treino, com cada
## capítulo avulso e a sala de teste.
##
## O jogo novo só grava por cima do salvo quando o personagem vence um
## capítulo ou encosta na pedra de salvamento.


func _ready() -> void:
	Progress.active = false
	var column := MenuKit.centered_column(self, Color(0.1, 0.11, 0.13, 1.0))
	column.add_child(MenuKit.label("Giorgino", 24))
	var first: Button = null
	if Progress.exists():
		first = MenuKit.button("Continuar", _on_continue)
		column.add_child(first)
	var new_game := MenuKit.button("Novo jogo", _on_new_game)
	column.add_child(new_game)
	if not first:
		first = new_game
	column.add_child(MenuKit.button("Tutorial", _on_tutorial))
	column.add_child(MenuKit.button("Treino", _on_training))
	first.grab_focus.call_deferred()


func _on_continue() -> void:
	if Progress.load_file():
		get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)


func _on_new_game() -> void:
	Progress.start_new()
	get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)


## O tutorial é jogado avulso, como no treino: nada é gravado.
func _on_tutorial() -> void:
	RunSettings.chapter = ChapterData.TUTORIAL
	get_tree().change_scene_to_file(Flow.CHAPTER_SCENE)


func _on_training() -> void:
	get_tree().change_scene_to_file(Flow.TRAINING_SCENE)
