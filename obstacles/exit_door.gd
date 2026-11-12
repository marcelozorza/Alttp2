class_name ExitDoor
extends Node2D
## Porta de saída da dungeon: um vão na parede de baixo da primeira sala, com
## a grama do mundo à vista. O personagem sai ao andar para baixo contra ela,
## e a saída vale o mesmo que "Sair" na pausa. Sem porta, o jogador não
## pensava em sair para procurar um item em outra dungeon (Marcelo,
## 2026-11-12). A parede continua sólida: a porta só percebe o toque.

signal used

const TEXTURE := preload("res://art/exit_door.svg")
const SIZE := Vector2(64.0, 32.0)
## Vão da porta dentro do desenho.
const OPENING := Rect2(14.0, 0.0, 36.0, 32.0)
const TOUCH_MARGIN := 4.0
## Luz de fora no chão da sala, diante da porta.
const LIGHT_COLOR := Color(1.0, 0.95, 0.66, 0.1)
const LIGHT_DEPTH := 26.0

var _touch := Area2D.new()
var _used := false
## Só vale depois de o jogador soltar a direção para baixo uma vez, para não
## sair da dungeon no instante em que entra.
var _armed := false


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(OPENING.size.x, SIZE.y + TOUCH_MARGIN)
	shape.shape = rectangle
	shape.position = Vector2(SIZE.x / 2.0, (SIZE.y - TOUCH_MARGIN) / 2.0)
	_touch.add_child(shape)
	_touch.monitorable = false
	add_child(_touch)


func _physics_process(_delta: float) -> void:
	if not Input.is_action_pressed("move_down"):
		_armed = true
		return
	if _used or not _armed:
		return
	for body: Node2D in _touch.get_overlapping_bodies():
		var player := body as Player
		if player and player.facing == Vector2.DOWN:
			_used = true
			Sfx.play(&"door_unlock")
			used.emit()
			return


func _draw() -> void:
	var left := OPENING.position.x
	var right := OPENING.end.x
	var light := PackedVector2Array(
		[
			Vector2(left, 0.0),
			Vector2(right, 0.0),
			Vector2(right + 8.0, -LIGHT_DEPTH),
			Vector2(left - 8.0, -LIGHT_DEPTH)
		]
	)
	draw_colored_polygon(light, LIGHT_COLOR)
	draw_texture(TEXTURE, Vector2.ZERO)
