extends Control
## Tela de título: jogo novo, modo randomizado com uma semente, ou o Playtest (a Galeria de testes).
##
## Não há "Continuar": o jogo não tem salvamento entre sessões, vai-se até o
## fim toda vez (decisão de Marcelo em 2026-11-13). Dentro de uma sessão, a
## pedra de salvamento do mundo marca de onde se volta depois de uma derrota.
## "Dungeon de teste" e "Treino" saíram do menu no mesmo dia. A tela de treino
## continua no projeto, para os testes.

const MENU_AREA := Rect2(472.0, 104.0, 140.0, 100.0)


func _ready() -> void:
	Progress.active = false
	var column := MenuKit.centered_column(self, TitleArt.SKY)
	var art := TitleArt.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	move_child(art, 1)
	# O retrato ocupa o meio da tela: o menu fica à direita, no céu, com botões
	# mais justos que os das outras telas (pedido de Marcelo em 2026-11-13).
	column.add_theme_constant_override("separation", 6)
	var holder: Control = column.get_parent()
	holder.set_anchors_preset(Control.PRESET_TOP_LEFT)
	holder.position = MENU_AREA.position + Vector2(TitleArt.shift(get_viewport_rect().size.x), 0.0)
	holder.size = MENU_AREA.size
	var first := MenuKit.button("Novo jogo", _on_new_game)
	var entries: Array[Button] = [
		first,
		MenuKit.button("Randomizado", _on_randomized),
		MenuKit.button("Playtest", _on_gallery),
	]
	for entry: Button in entries:
		MenuKit.compact(entry)
		column.add_child(entry)
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
