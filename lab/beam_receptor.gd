class_name BeamReceptor
extends StaticBody2D
## Receptor de luz do laboratório: um olho de cristal que acende quando o
## feixe chega nele (lab/beam_field.gd) e abre de vez as portas brancas da
## sala. O emissor usa o mesmo desenho, em amarelo, e não reage a nada. Arte
## provisória.
##
## A origem fica no centro da casa.

signal changed(lit: bool)

const SIZE := Vector2(22.0, 22.0)
const OFF_COLOR := Color(0.35, 0.35, 0.45)
const ON_COLOR := Color(1.0, 1.0, 0.8)
const EMITTER_COLOR := Color(1.0, 0.85, 0.3)

## Ligado, é um emissor: só o desenho muda.
var emitter := false
var lit := false


func _ready() -> void:
	collision_layer = Layers.SCENERY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	add_child(shape)


func set_lit(value: bool) -> void:
	if value == lit:
		return
	lit = value
	if lit:
		Sfx.play(&"relic")
	queue_redraw()
	changed.emit(lit)


func _draw() -> void:
	draw_rect(Rect2(-13.0, -13.0, 26.0, 26.0), DoorArt.OUTLINE_COLOR)
	draw_rect(Rect2(-11.0, -11.0, 22.0, 22.0), Color(0.3, 0.28, 0.35))
	var color := EMITTER_COLOR if emitter else (ON_COLOR if lit else OFF_COLOR)
	draw_circle(Vector2.ZERO, 8.0, DoorArt.OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, 6.0, color)
