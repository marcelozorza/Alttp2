class_name Crystal
extends StaticBody2D
## Cristal: interruptor de golpe. Reage a qualquer golpe, de perto ou de
## longe: espada, chama ou explosão. Cada golpe troca o estado da sala, que
## abre as barreiras azuis e fecha as laranja, ou o contrário
## (mechanics/room_mechanisms.gd). Arte provisória.
##
## A origem fica no centro da base, para a ordenação por profundidade.

## Emitido a cada golpe que vale.
signal struck

const SIZE := Vector2(22.0, 14.0)
## Ticks em que um golpe novo é ignorado depois de um que valeu.
const DEBOUNCE_TICKS := 10
const OFF_COLOR := Color(0.35, 0.55, 1.0)
const ON_COLOR := Color(1.0, 0.65, 0.25)

## Estado da sala, mostrado pela cor.
var lit := false:
	set(value):
		lit = value
		queue_redraw()

var _struck_tick := -1000


func _ready() -> void:
	collision_layer = Layers.SCENERY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)


func take_hit(_amount: int, _direction: Vector2, _kind := Hit.Kind.SWORD) -> void:
	if Clock.tick - _struck_tick < DEBOUNCE_TICKS:
		return
	_struck_tick = Clock.tick
	Sfx.play(&"switch_press")
	struck.emit()


func _draw() -> void:
	GroundShadow.draw(self, Vector2(0.0, -2.0), 24.0)
	var fill := ON_COLOR if lit else OFF_COLOR
	var points := PackedVector2Array(
		[Vector2(0.0, -30.0), Vector2(11.0, -14.0), Vector2(0.0, 0.0), Vector2(-11.0, -14.0)]
	)
	draw_colored_polygon(points, fill)
	draw_polyline(points + PackedVector2Array([points[0]]), DoorArt.OUTLINE_COLOR, 2.0)
	draw_line(points[0], points[2], Color(1.0, 1.0, 1.0, 0.5), 1.0)
