class_name Crystal
extends StaticBody2D
## Interruptor de golpe do laboratório. Arte provisória.
##
## O cristal (blast_only desligado) reage a qualquer golpe, de perto ou de
## longe: espada, chama ou explosão. Cada golpe troca o estado da sala, que
## abre as barreiras azuis e fecha as laranja, ou o contrário.
##
## O alvo de explosão (blast_only ligado) só reage à explosão da bomba, e uma
## vez só: abre de vez as portas roxas da sala. Os outros golpes só o fazem
## tremer.
##
## A origem fica no centro da base, para a ordenação por profundidade.

## Emitido a cada golpe que vale.
signal struck

const SIZE := Vector2(22.0, 14.0)
## Ticks em que um golpe novo é ignorado depois de um que valeu.
const DEBOUNCE_TICKS := 10
const OFF_COLOR := Color(0.35, 0.55, 1.0)
const ON_COLOR := Color(1.0, 0.65, 0.25)
const TARGET_COLOR := Color(0.75, 0.45, 1.0)
const DONE_COLOR := Color(0.45, 0.9, 0.5)

var blast_only := false
## Estado mostrado: o da sala no cristal, ou "já explodido" no alvo.
var lit := false:
	set(value):
		lit = value
		queue_redraw()

var _struck_tick := -1000
var _shake_tick := -1000


func _ready() -> void:
	collision_layer = Layers.SCENERY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)


func take_hit(_amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if blast_only and (lit or not Hit.is_blast(kind)):
		if not lit:
			_shake_tick = Clock.tick
			Sfx.play(&"deny")
		return
	if Clock.tick - _struck_tick < DEBOUNCE_TICKS:
		return
	_struck_tick = Clock.tick
	Sfx.play(&"switch_press")
	struck.emit()


func _physics_process(_delta: float) -> void:
	if Clock.tick - _shake_tick <= DoorArt.SHAKE_TICKS + 1:
		queue_redraw()


func _draw() -> void:
	var shake := DoorArt.shake_offset(_shake_tick)
	GroundShadow.draw(self, Vector2(0.0, -2.0), 24.0)
	if blast_only:
		var color := DONE_COLOR if lit else TARGET_COLOR
		var center := Vector2(0.0, -14.0) + shake
		draw_circle(center, 13.0, DoorArt.OUTLINE_COLOR)
		draw_circle(center, 11.0, color)
		draw_circle(center, 7.0, DoorArt.OUTLINE_COLOR)
		draw_circle(center, 4.0, color)
		return
	var fill := ON_COLOR if lit else OFF_COLOR
	var points := PackedVector2Array(
		[Vector2(0.0, -30.0), Vector2(11.0, -14.0), Vector2(0.0, 0.0), Vector2(-11.0, -14.0)]
	)
	for i: int in points.size():
		points[i] += shake
	draw_colored_polygon(points, fill)
	draw_polyline(points + PackedVector2Array([points[0]]), DoorArt.OUTLINE_COLOR, 2.0)
	draw_line(points[0], points[2], Color(1.0, 1.0, 1.0, 0.5), 1.0)
