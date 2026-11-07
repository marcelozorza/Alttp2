extends Control
## Treino: o tutorial, um botão por capítulo, jogado avulso e sem gravar
## nada, e a sala de teste da física e do combate. Cada capítulo começa com
## as ferramentas dos dados dele.


func _ready() -> void:
	Progress.active = false
	var column := MenuKit.centered_column(self, Color(0.1, 0.11, 0.13, 1.0))
	column.add_child(MenuKit.label("Treino", 16))
	var first := MenuKit.button("Tutorial", _start.bind(ChapterData.TUTORIAL))
	column.add_child(first)
	for chapter: int in range(1, ChapterData.count() + 1):
		column.add_child(MenuKit.button("Capítulo %d" % chapter, _start.bind(chapter)))
	column.add_child(MenuKit.button("Sala de teste", _on_test_room))
	column.add_child(MenuKit.button("Voltar", _on_back))
	first.grab_focus.call_deferred()


func _start(chapter: int) -> void:
	RunSettings.chapter = chapter
	get_tree().change_scene_to_file(Flow.CHAPTER_SCENE)


func _on_test_room() -> void:
	get_tree().change_scene_to_file(Flow.TEST_ROOM_SCENE)


func _on_back() -> void:
	get_tree().change_scene_to_file(Flow.TITLE_SCENE)
