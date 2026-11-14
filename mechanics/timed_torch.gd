class_name TimedTorch
extends StaticBody2D
## Tocha de chão com tempo, um braseiro que a chama acende. Arte provisória.
##
## Acesa, a tocha apaga sozinha depois de burn_time segundos. Com todas as
## tochas da sala acesas ao mesmo tempo, as portas amarelas abrem de vez
## (mechanics/room_mechanisms.gd) e as tochas ficam acesas (held). O tempo é
## curto de propósito: é preciso correr de uma tocha à outra e não gastar
## chamas à toa, porque a recarga da chama não cabe no tempo de uma tocha.
##
## A origem fica no centro da base, para a ordenação por profundidade.

signal changed

const SIZE := Vector2(20.0, 14.0)
const BOWL_COLOR := Color(0.45, 0.4, 0.42)
const FLAME_COLOR := Color(1.0, 0.7, 0.2)
const CORE_COLOR := Color(1.0, 0.95, 0.6)

## Segundos acesa (pedido de Marcelo em 2026-11-14: 4 segundos).
var burn_time := 4.0
var lit := false
## Ligado quando a porta já abriu: a tocha não apaga mais.
var held := false

var _lit_tick := 0


func _ready() -> void:
	collision_layer = Layers.SCENERY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)


func take_hit(_amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if not Hit.is_fire(kind):
		return
	_lit_tick = Clock.tick
	if not lit:
		lit = true
		Sfx.play(&"fire_hit")
		changed.emit()
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not lit:
		return
	queue_redraw()
	if not held and Clock.tick - _lit_tick >= GameMath.ticks(burn_time):
		lit = false
		Sfx.play(&"ice_melt")
		changed.emit()


## Fração do tempo que ainda resta, de 1 a 0.
func _remaining() -> float:
	if held:
		return 1.0
	return clampf(1.0 - float(Clock.tick - _lit_tick) / GameMath.ticks(burn_time), 0.0, 1.0)


func _draw() -> void:
	GroundShadow.draw(self, Vector2(0.0, -2.0), 22.0)
	draw_rect(Rect2(-11.0, -16.0, 22.0, 16.0), DoorArt.OUTLINE_COLOR)
	draw_rect(Rect2(-9.0, -14.0, 18.0, 12.0), BOWL_COLOR)
	if not lit:
		return
	var height := 8.0 + 14.0 * _remaining()
	var sway := 2.0 if posmod(Clock.tick, 12) < 6 else -2.0
	var flame := PackedVector2Array(
		[Vector2(-8.0, -14.0), Vector2(sway, -14.0 - height), Vector2(8.0, -14.0)]
	)
	draw_colored_polygon(flame, FLAME_COLOR)
	var core := PackedVector2Array(
		[Vector2(-4.0, -14.0), Vector2(sway / 2.0, -14.0 - height / 2.0), Vector2(4.0, -14.0)]
	)
	draw_colored_polygon(core, CORE_COLOR)
