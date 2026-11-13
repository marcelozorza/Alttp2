extends Control
## Tela de título: jogo novo, modo randomizado com uma semente, ou o Playtest (a Galeria de testes).
##
## Não há "Continuar": o jogo não tem salvamento entre sessões, vai-se até o
## fim toda vez (decisão de Marcelo em 2026-11-13). Dentro de uma sessão, a
## pedra de salvamento do mundo marca de onde se volta depois de uma derrota.
## "Dungeon de teste" e "Treino" saíram do menu no mesmo dia. A tela de treino
## continua no projeto, para os testes.


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
	var first := MenuKit.button("Novo jogo", _on_new_game)
	column.add_child(first)
	column.add_child(MenuKit.button("Randomizado", _on_randomized))
	column.add_child(MenuKit.button("Playtest", _on_gallery))
	first.grab_focus.call_deferred()


func _on_new_game() -> void:
	Progress.start_new()
	get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)


func _on_randomized() -> void:
	get_tree().change_scene_to_file(Flow.SEED_SCENE)


## O tutorial é jogado avulso, como no treino: nada é gravado.
## A galeria: as quatro salas de teste com todos os elementos do jogo, uma
## por tema, sem perder vida (pedido de Marcelo em 2026-11-08).
func _on_gallery() -> void:
	RunSettings.chapter = ChapterData.GALLERY
	get_tree().change_scene_to_file(Flow.CHAPTER_SCENE)
