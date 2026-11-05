extends Control
## Tela de título. Para cada capítulo, escolhe entre a distribuição linear e
## uma seed aleatória. Também abre a sala de teste da física e do combate.

const CHAPTER_SCENE := "res://world/chapter/chapter.tscn"
const TEST_ROOM_SCENE := "res://world/test_room.tscn"


func _ready() -> void:
	var column := MenuKit.centered_column(self, Color(0.1, 0.11, 0.13, 1.0))
	column.add_child(MenuKit.label("Alttp2", 24))
	column.add_child(MenuKit.label("nome provisório", 8))
	var first: Button = null
	for chapter: int in range(1, ChapterData.count() + 1):
		var linear := MenuKit.button("Capítulo %d: linear" % chapter, _start.bind(chapter, false))
		column.add_child(linear)
		column.add_child(
			MenuKit.button("Capítulo %d: seed aleatória" % chapter, _start.bind(chapter, true))
		)
		if not first:
			first = linear
	column.add_child(MenuKit.button("Sala de teste", _on_test_room))
	first.grab_focus.call_deferred()


func _start(chapter: int, randomized: bool) -> void:
	RunSettings.chapter = chapter
	RunSettings.randomized = randomized
	if randomized:
		RunSettings.run_seed = RunSettings.new_seed()
	get_tree().change_scene_to_file(CHAPTER_SCENE)


func _on_test_room() -> void:
	get_tree().change_scene_to_file(TEST_ROOM_SCENE)
