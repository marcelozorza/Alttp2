extends Control
## Tela de título. Continuar o jogo salvo, se houver, começar um jogo novo,
## jogar o modo randomizado com uma seed, jogar o tutorial, que fica fora do
## mundo, ou ir ao treino, com cada capítulo avulso e a sala de teste.
##
## O jogo novo só grava por cima do salvo quando o personagem vence um
## capítulo ou encosta na pedra de salvamento.


func _ready() -> void:
	Progress.active = false
	var column := MenuKit.centered_column(self, TitleArt.SKY)
	var art := TitleArt.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	move_child(art, 1)
	# O logotipo fica no alto, desenhado pela arte: a coluna começa abaixo dele.
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 44.0)
	column.add_child(spacer)
	var first: Button = null
	if Progress.exists():
		first = MenuKit.button("Continuar", _on_continue)
		column.add_child(first)
	var new_game := MenuKit.button("Novo jogo", _on_new_game)
	column.add_child(new_game)
	if not first:
		first = new_game
	column.add_child(MenuKit.button("Randomizado", _on_randomized))
	column.add_child(MenuKit.button("Dungeon de teste", _on_tutorial))
	column.add_child(MenuKit.button("Treino", _on_training))
	column.add_child(MenuKit.button("Galeria", _on_gallery))
	first.grab_focus.call_deferred()


func _on_continue() -> void:
	if Progress.load_file():
		get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)


func _on_new_game() -> void:
	Progress.start_new()
	get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)


func _on_randomized() -> void:
	get_tree().change_scene_to_file(Flow.SEED_SCENE)


## O tutorial é jogado avulso, como no treino: nada é gravado.
func _on_tutorial() -> void:
	RunSettings.chapter = ChapterData.TUTORIAL
	get_tree().change_scene_to_file(Flow.CHAPTER_SCENE)


func _on_training() -> void:
	get_tree().change_scene_to_file(Flow.TRAINING_SCENE)


## A galeria: as quatro salas de teste com todos os elementos do jogo, uma
## por tema, sem perder vida (pedido de Marcelo em 2026-11-08).
func _on_gallery() -> void:
	RunSettings.chapter = ChapterData.GALLERY
	get_tree().change_scene_to_file(Flow.CHAPTER_SCENE)
