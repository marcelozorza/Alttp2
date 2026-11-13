class_name BeamMirror
extends StaticBody2D
## Espelho do laboratório: desvia o feixe de luz em 90 graus
## (lab/beam_field.gd). Um golpe de espada vira o espelho para a outra
## diagonal. Arte provisória.
##
## A origem fica no centro da casa.

const SIZE := Vector2(20.0, 20.0)
const FRAME_COLOR := Color(0.5, 0.45, 0.3)
const GLASS_COLOR := Color(0.8, 0.95, 1.0)

## Diagonal do espelho: ligado, sobe da esquerda para a direita ("/").
## Desligado, desce ("\").
var rising := true

var _turn_tick := -1000


func _ready() -> void:
	collision_layer = Layers.SCENERY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	add_child(shape)


func take_hit(_amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if kind != Hit.Kind.SWORD or Clock.tick - _turn_tick < 10:
		return
	_turn_tick = Clock.tick
	rising = not rising
	Sfx.play(&"switch_press")
	queue_redraw()


## Direção do feixe depois de bater no espelho.
func reflect(direction: Vector2i) -> Vector2i:
	if rising:
		return Vector2i(-direction.y, -direction.x)
	return Vector2i(direction.y, direction.x)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 13.0, DoorArt.OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, 11.0, FRAME_COLOR)
	var tip := Vector2(9.0, -9.0) if rising else Vector2(9.0, 9.0)
	draw_line(-tip, tip, DoorArt.OUTLINE_COLOR, 7.0)
	draw_line(-tip, tip, GLASS_COLOR, 3.0)
