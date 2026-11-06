class_name SwitchDoor
extends StaticBody2D
## Grade de ferro. Nenhuma ferramenta a abre: qualquer golpe só a faz tremer.
## Ela abre enquanto um interruptor da mesma sala estiver pressionado, e de
## vez quando um bloco pesado trava num interruptor. Ao abrir, afunda no chão
## como a porta trancada, e ao fechar volta a subir.
##
## A origem fica no canto superior esquerdo. O construtor do mapa define o
## tamanho antes de adicionar a grade à cena.

const TEXTURE := preload("res://art/gate_door.svg")
const SHAKE_TICKS := 8
const MOVE_TICKS := 12
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.3)
const SHADOW_HEIGHT := 3.0

## Tamanho em pixels.
@export var size := Vector2(16.0, 16.0)

var open := false

var _shape := CollisionShape2D.new()
var _move_tick := -1000
var _shake_tick := -1000


func _ready() -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	_shape.shape = rectangle
	_shape.position = size / 2.0
	add_child(_shape)


func set_open(value: bool) -> void:
	if value == open:
		return
	open = value
	_move_tick = Engine.get_physics_frames()
	_shape.set_deferred("disabled", open)
	Sfx.play(&"door_unlock" if open else &"bump")
	queue_redraw()


## Golpes não afetam a grade: ela só treme.
func take_hit(_amount: int, _direction: Vector2, _kind := Hit.Kind.SWORD) -> void:
	if open:
		return
	_shake_tick = Engine.get_physics_frames()
	Sfx.play(&"deny")
	queue_redraw()


func _physics_process(_delta: float) -> void:
	var now := Engine.get_physics_frames()
	if now - _shake_tick <= SHAKE_TICKS or now - _move_tick <= MOVE_TICKS:
		queue_redraw()


## Desenha a grade casa por casa. Aberta, ela fica afundada no chão.
func _draw() -> void:
	var progress := minf(float(Engine.get_physics_frames() - _move_tick) / MOVE_TICKS, 1.0)
	var height := 1.0 - progress if open else progress
	if height <= 0.0:
		return
	if height >= 1.0:
		draw_rect(Rect2(Vector2(0.0, size.y), Vector2(size.x, SHADOW_HEIGHT)), SHADOW_COLOR)
	var offset := Vector2.ZERO
	var elapsed := Engine.get_physics_frames() - _shake_tick
	if elapsed < SHAKE_TICKS:
		offset.x = 1.0 if posmod(elapsed, 4) < 2 else -1.0
	var tile := float(ChapterMap.TILE)
	for y: int in int(size.y / tile):
		for x: int in int(size.x / tile):
			var cell := Vector2(x, y) * tile + offset
			var visible_height := tile * height
			var source := Rect2(0.0, 0.0, tile, visible_height)
			var target := Rect2(cell + Vector2(0.0, tile - visible_height), source.size)
			draw_texture_rect_region(TEXTURE, target, source)
