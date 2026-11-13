class_name Magnet
extends StaticBody2D
## Ímã do laboratório: um pilar que, golpeado com a espada, liga por alguns
## segundos e puxa para perto os blocos de metal que estão na mesma linha
## ou coluna, de casa em casa, até encostarem nele ou em algo no caminho. É
## o jeito de trazer de volta um bloco que só dá para empurrar para longe.
## Só puxa blocos da própria sala. Arte provisória.
##
## A origem fica no centro da base, para a ordenação por profundidade.

const SIZE := Vector2(24.0, 16.0)
const PULL_TICKS := 240
const BODY_COLOR := Color(0.8, 0.25, 0.25)
const TIP_COLOR := Color(0.85, 0.85, 0.9)
const FIELD_COLOR := Color(1.0, 0.5, 0.5, 0.5)

var _on_tick := -100000


func _ready() -> void:
	collision_layer = Layers.SCENERY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)


func is_on() -> bool:
	return Clock.tick - _on_tick < PULL_TICKS


func take_hit(_amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if kind != Hit.Kind.SWORD or is_on():
		return
	_on_tick = Clock.tick
	Sfx.play(&"switch_press")


func _physics_process(_delta: float) -> void:
	if not is_on():
		return
	queue_redraw()
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	if not chapter:
		return
	var here := Pit.cell_of(global_position + Vector2(0.0, -SIZE.y / 2.0))
	for block: FreeBlock in get_tree().get_nodes_in_group("metal_blocks"):
		var cell := block.cell()
		if chapter.rooms.of_cell(cell) != chapter.rooms.of_cell(here):
			continue
		var offset := here - cell
		if (offset.x != 0) == (offset.y != 0) or absi(offset.x + offset.y) <= 1:
			continue
		block.pull(Vector2(offset.sign()))


func _draw() -> void:
	GroundShadow.draw(self, Vector2(0.0, -2.0), 28.0)
	draw_rect(Rect2(-14.0, -32.0, 28.0, 32.0), DoorArt.OUTLINE_COLOR)
	draw_rect(Rect2(-12.0, -30.0, 24.0, 28.0), BODY_COLOR)
	draw_rect(Rect2(-12.0, -30.0, 8.0, 8.0), TIP_COLOR)
	draw_rect(Rect2(4.0, -30.0, 8.0, 8.0), TIP_COLOR)
	if is_on():
		var radius := 18.0 + float(Clock.tick % 20)
		draw_arc(Vector2(0.0, -15.0), radius, 0.0, TAU, 24, FIELD_COLOR, 2.0)
