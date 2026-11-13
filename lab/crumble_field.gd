class_name CrumbleField
extends Node2D
## Piso quebradiço do laboratório: casas que racham quando o personagem pisa
## e caem quando ele sai de cima. Pisar de novo onde o piso já caiu é queda:
## ele perde vida e volta à entrada da sala. Obriga a planejar um caminho que
## não repete casa. O piso volta inteiro a cada entrada na sala e depois de
## cada queda. Pular não quebra nem cai. Arte provisória.
##
## Um só nó cuida de todo o piso quebradiço do capítulo, na camada dos
## interruptores, acima do chão.

enum State { WHOLE, CRACKED, GONE }

const DAMAGE := 1
const WHOLE_COLOR := Color(0.62, 0.55, 0.45, 0.9)
const CRACKED_COLOR := Color(0.5, 0.4, 0.32, 0.95)
const CRACK_COLOR := Color(0.12, 0.08, 0.08)
const GONE_COLOR := Color(0.05, 0.04, 0.08)

## Estado de cada casa: Vector2i para State.
var cells := {}

## Casa em que o personagem estava no último tick.
var _standing := Vector2i(-1, -1)
var _room := Rect2i()


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	if not player or not chapter:
		return
	if chapter.current_room() != _room:
		_room = chapter.current_room()
		_restore()
	var cell := Pit.cell_of(player.global_position)
	if player.is_airborne():
		cell = Vector2i(-1, -1)
	if cell != _standing:
		if cells.get(_standing, State.WHOLE) == State.CRACKED:
			cells[_standing] = State.GONE
			Sfx.play(&"wall_break")
			queue_redraw()
		_standing = cell
	if not cells.has(cell):
		return
	if cells[cell] == State.WHOLE:
		cells[cell] = State.CRACKED
		Sfx.play(&"step")
		queue_redraw()
	elif cells[cell] == State.GONE and not player.is_dead():
		_restore()
		player.fall_into_pit(chapter.room_entry_point, DAMAGE)


func _restore() -> void:
	for cell: Vector2i in cells:
		cells[cell] = State.WHOLE
	_standing = Vector2i(-1, -1)
	queue_redraw()


func _draw() -> void:
	var tile := float(ChapterMap.TILE)
	for cell: Vector2i in cells:
		var corner := Vector2(cell) * tile
		var rect := Rect2(corner + Vector2.ONE, Vector2(tile - 2.0, tile - 2.0))
		match cells[cell]:
			State.WHOLE:
				draw_rect(rect, WHOLE_COLOR)
				draw_line(
					corner + Vector2(6.0, 10.0), corner + Vector2(14.0, 18.0), CRACK_COLOR, 1.0
				)
			State.CRACKED:
				draw_rect(rect, CRACKED_COLOR)
				draw_line(
					corner + Vector2(4.0, 6.0), corner + Vector2(16.0, 16.0), CRACK_COLOR, 2.0
				)
				draw_line(
					corner + Vector2(16.0, 16.0), corner + Vector2(12.0, 28.0), CRACK_COLOR, 2.0
				)
				draw_line(
					corner + Vector2(16.0, 16.0), corner + Vector2(28.0, 12.0), CRACK_COLOR, 2.0
				)
			State.GONE:
				draw_rect(rect, GONE_COLOR)
