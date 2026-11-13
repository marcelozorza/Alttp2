class_name ExitDoor
extends Node2D
## Porta de saída da dungeon: um arco de madeira de pé na parede de baixo da
## primeira sala, com as duas folhas abertas para dentro em perspectiva
## forçada e a luz de fora no vão, como a referência que Marcelo mandou em
## 2026-11-13. O personagem sai ao andar para baixo contra ela,
## e a saída vale o mesmo que "Sair" na pausa. Sem porta, o jogador não
## pensava em sair para procurar um item em outra dungeon (Marcelo,
## 2026-11-12). A parede continua sólida: a porta só percebe o toque.

signal used

const TEXTURE := preload("res://art/exit_door.svg")
## Largura do portão e altura do vão na parede. A origem fica no canto de cima
## do trecho de parede que ele ocupa.
const SIZE := Vector2(128.0, 32.0)
## Quanto o desenho sobe sobre o chão da sala: as folhas abertas.
const ART_ABOVE := 64.0
## Vão livre do portão, entre as bordas soltas das duas folhas.
const OPENING := Rect2(46.0, 0.0, 36.0, 32.0)
## Cada lado do portão, sólido: a perna do arco e a folha aberta.
const LEAF_SIZE := Vector2(46.0, 44.0)
const LEAF_LEFTS := [0.0, 82.0]
const TOUCH_MARGIN := 4.0
## Luz de fora no chão da sala, diante do portão: dois fachos, um dentro do
## outro, para o meio ficar mais claro.
const LIGHT_COLOR := Color(1.0, 0.95, 0.66, 0.13)
const LIGHTS := [Vector2(118.0, 34.0), Vector2(90.0, 16.0)]

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
	var leaves := StaticBody2D.new()
	leaves.collision_layer = Layers.SCENERY
	leaves.collision_mask = 0
	for left: float in LEAF_LEFTS:
		var leaf_shape := CollisionShape2D.new()
		var leaf_rectangle := RectangleShape2D.new()
		leaf_rectangle.size = LEAF_SIZE
		leaf_shape.shape = leaf_rectangle
		leaf_shape.position = Vector2(left + LEAF_SIZE.x / 2.0, -LEAF_SIZE.y / 2.0)
		leaves.add_child(leaf_shape)
	add_child(leaves)


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
	draw_texture(TEXTURE, Vector2(0.0, -ART_ABOVE))
