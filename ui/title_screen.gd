extends Control
## Tela de título. Um botão por capítulo e a sala de teste da física e do
## combate.

const CHAPTER_SCENE := "res://world/chapter/chapter.tscn"
const TEST_ROOM_SCENE := "res://world/test_room.tscn"


func _ready() -> void:
	var column := MenuKit.centered_column(self, Color(0.1, 0.11, 0.13, 1.0))
	column.add_child(MenuKit.label("Alttp2", 24))
	column.add_child(MenuKit.label("nome provisório", 8))
	var first: Button = null
	for chapter: int in range(1, ChapterData.count() + 1):
		var button := MenuKit.button("Capítulo %d" % chapter, _start.bind(chapter))
		column.add_child(button)
		if not first:
			first = button
	column.add_child(MenuKit.button("Sala de teste", _on_test_room))
	first.grab_focus.call_deferred()


func _start(chapter: int) -> void:
	RunSettings.chapter = chapter
	get_tree().change_scene_to_file(CHAPTER_SCENE)


func _on_test_room() -> void:
	get_tree().change_scene_to_file(TEST_ROOM_SCENE)
