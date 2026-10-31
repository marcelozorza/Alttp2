extends Control
## Tela de título. Escolhe entre o capítulo na distribuição linear, o capítulo
## com uma seed aleatória e a sala de teste da física e do combate.

const CHAPTER_SCENE := "res://world/chapter_one/chapter_one.tscn"
const TEST_ROOM_SCENE := "res://world/test_room.tscn"


func _ready() -> void:
	var column := MenuKit.centered_column(self, Color(0.1, 0.11, 0.13, 1.0))
	column.add_child(MenuKit.label("Alttp2", 24))
	column.add_child(MenuKit.label("nome provisório", 8))
	var first := MenuKit.button("Capítulo 1: linear", _on_linear)
	column.add_child(first)
	column.add_child(MenuKit.button("Capítulo 1: seed aleatória", _on_random))
	column.add_child(MenuKit.button("Sala de teste", _on_test_room))
	first.grab_focus.call_deferred()


func _on_linear() -> void:
	RunSettings.randomized = false
	get_tree().change_scene_to_file(CHAPTER_SCENE)


func _on_random() -> void:
	RunSettings.randomized = true
	RunSettings.run_seed = RunSettings.new_seed()
	get_tree().change_scene_to_file(CHAPTER_SCENE)


func _on_test_room() -> void:
	get_tree().change_scene_to_file(TEST_ROOM_SCENE)
