class_name Flow
## As telas do jogo e para onde cada uma volta.
##
## No jogo contínuo, sair de um capítulo leva ao mundo, na entrada da dungeon.
## No treino, leva ao menu de título.

const TITLE_SCENE := "res://ui/title_screen.tscn"
const TRAINING_SCENE := "res://ui/training_screen.tscn"
const OVERWORLD_SCENE := "res://world/overworld/overworld.tscn"
const CHAPTER_SCENE := "res://world/chapter/chapter.tscn"
const TEST_ROOM_SCENE := "res://world/test_room.tscn"


## Sai do capítulo em andamento.
static func leave_chapter(tree: SceneTree) -> void:
	tree.paused = false
	if Progress.active:
		Progress.return_entrance = RunSettings.chapter
		tree.change_scene_to_file(OVERWORLD_SCENE)
	else:
		tree.change_scene_to_file(TITLE_SCENE)


static func go_to_title(tree: SceneTree) -> void:
	tree.paused = false
	tree.change_scene_to_file(TITLE_SCENE)


## Recomeça a cena atual do zero: um capítulo volta ao início, com o que o
## personagem tinha ao entrar, porque nada do meio do capítulo fica gravado.
static func restart_scene(tree: SceneTree) -> void:
	tree.paused = false
	tree.reload_current_scene()
