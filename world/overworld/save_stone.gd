class_name SaveStone
extends StaticBody2D
## Pedra de salvamento. Encostar nela grava o progresso e enche a vida. O
## losango gravado acende por um instante, e um anel se abre no chão.
##
## A origem fica no centro da base, para a ordenação por profundidade.

const TEXTURE := preload("res://art/save_stone.svg")
const LIT_TEXTURE := preload("res://art/save_stone_lit.svg")
const TEXTURE_OFFSET := Vector2(-16.0, -38.0)
const SIZE := Vector2(24.0, 12.0)
const TOUCH_MARGIN := 6.0
const LIT_TICKS := 60
const RING_COLOR := Color(0.95, 0.8, 0.35, 0.7)

var _touch := Area2D.new()
var _lit_tick := -1000


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)
	var touch_shape := CollisionShape2D.new()
	var touch_rectangle := RectangleShape2D.new()
	touch_rectangle.size = SIZE + Vector2.ONE * TOUCH_MARGIN * 2.0
	touch_shape.shape = touch_rectangle
	touch_shape.position = Vector2(0.0, -SIZE.y / 2.0)
	_touch.add_child(touch_shape)
	_touch.monitorable = false
	_touch.body_entered.connect(_on_body_entered)
	add_child(_touch)


func _physics_process(_delta: float) -> void:
	if Clock.tick - _lit_tick <= LIT_TICKS + 1:
		queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if not player:
		return
	player.health = player.max_health
	Progress.save()
	Sfx.play(&"save")
	_lit_tick = Clock.tick


func _draw() -> void:
	var elapsed := Clock.tick - _lit_tick
	var lit := elapsed <= LIT_TICKS
	if lit:
		var progress := float(elapsed) / LIT_TICKS
		var color := RING_COLOR
		color.a *= 1.0 - progress
		draw_arc(Vector2(0.0, -6.0), 8.0 + progress * 28.0, 0.0, TAU, 24, color, 2.0)
	draw_texture(LIT_TEXTURE if lit else TEXTURE, TEXTURE_OFFSET)
