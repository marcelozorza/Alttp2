class_name Chest
extends StaticBody2D
## Baú que guarda um item. Abre com um golpe de espada, e o item vai direto
## para o personagem. O conteúdo vem da distribuição da seed, nunca do mapa.
##
## A origem fica no centro da base, para a ordenação por profundidade.

signal opened(chest: Chest)

const BODY_COLOR := Color(0.55, 0.34, 0.16, 1.0)
const LID_COLOR := Color(0.68, 0.44, 0.21, 1.0)
const BAND_COLOR := Color(0.92, 0.75, 0.3, 1.0)
const INSIDE_COLOR := Color(0.16, 0.1, 0.06, 1.0)
const SIZE := Vector2(14.0, 10.0)
## Ticks em que o item fica flutuando sobre o baú aberto.
const SHOW_ITEM_TICKS := 60

## Nome do local na lógica do capítulo.
@export var location_id := ""
## Item guardado.
@export var item := Item.Id.NONE

var is_open := false

var _open_tick := -1000


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)


## Só a espada abre o baú. Fogo e explosões não abrem, para que nenhum baú
## seja aberto do outro lado de uma parede ou de um bloqueio.
func take_hit(_amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if is_open or kind != Hit.Kind.SWORD:
		return
	is_open = true
	_open_tick = Engine.get_physics_frames()
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.give_item(item)
	opened.emit(self)
	queue_redraw()


## Redesenha enquanto o item aparece e mais uma vez depois, para apagá-lo.
func _physics_process(_delta: float) -> void:
	if is_open and Engine.get_physics_frames() - _open_tick <= SHOW_ITEM_TICKS + 1:
		queue_redraw()


func _draw() -> void:
	var half := SIZE.x / 2.0
	draw_rect(Rect2(Vector2(-half, -SIZE.y), SIZE), BODY_COLOR)
	if not is_open:
		draw_rect(Rect2(Vector2(-half, -SIZE.y - 3.0), Vector2(SIZE.x, 4.0)), LID_COLOR)
		draw_rect(Rect2(Vector2(-1.0, -SIZE.y), Vector2(2.0, 4.0)), BAND_COLOR)
		return
	draw_rect(Rect2(Vector2(-half + 1.0, -SIZE.y), Vector2(SIZE.x - 2.0, 3.0)), INSIDE_COLOR)
	draw_rect(Rect2(Vector2(-half, -SIZE.y - 5.0), Vector2(SIZE.x, 3.0)), LID_COLOR.darkened(0.2))
	var elapsed := Engine.get_physics_frames() - _open_tick
	if elapsed <= SHOW_ITEM_TICKS:
		var rise := minf(elapsed, 20.0) * 0.5
		ToolIcons.draw(self, item, Vector2(0.0, -SIZE.y - 10.0 - rise))
