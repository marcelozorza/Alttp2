class_name ExitDoor
extends Node2D
## Porta de saída da dungeon: um vão aberto na parede de baixo da primeira
## sala, com a luz de fora entrando, sem folhas nem colunas (quarta versão,
## pedida por Marcelo em 2026-11-13). O personagem sai ao andar para baixo
## contra ela, e a saída vale o mesmo que "Sair" na pausa. Sem porta, o
## jogador não pensava em sair para procurar um item em outra dungeon
## (Marcelo, 2026-11-12). A parede continua sólida: a porta só percebe o toque.

signal used

const TEXTURE := preload("res://art/exit_door.svg")
## Tamanho do desenho, que cobre o trecho de parede. A origem fica no canto
## de cima desse trecho.
const SIZE := Vector2(72.0, 32.0)
## Vão livre, por dentro da moldura.
const OPENING := Rect2(8.0, 0.0, 56.0, 32.0)
const TOUCH_MARGIN := 4.0
## Luz de fora no chão da sala, diante do portão: dois fachos, um dentro do
## outro, para o meio ficar mais claro.
const LIGHT_COLOR := Color(1.0, 0.95, 0.66, 0.13)
const LIGHTS := [Vector2(70.0, 20.0), Vector2(46.0, 10.0)]

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
	for light: Vector2 in LIGHTS:
		var beam := PackedVector2Array(
			[
				Vector2(left, 0.0),
				Vector2(right, 0.0),
				Vector2(right + light.y, -light.x),
				Vector2(left - light.y, -light.x)
			]
		)
		draw_colored_polygon(beam, LIGHT_COLOR)
	draw_texture(TEXTURE, Vector2.ZERO)
