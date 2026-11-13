class_name TimedPlate
extends Area2D
## Placa de pressão do laboratório. Pisada, fica ligada por hold_time
## segundos e abre as portas verdes da sala enquanto isso. O anel em volta
## mostra o tempo que resta. Com hold_time zero ela é permanente: afunda e
## trava ligada na primeira pisada. A estátua espelhada e o clone também a
## pressionam (grupo plate_weights), e qualquer inimigo vivo em cima dela.
## Pular por cima não a liga. Arte provisória.
##
## A origem fica no centro da casa, na camada dos interruptores.

signal changed(active: bool)

const SIZE := Vector2(24.0, 24.0)
const IDLE_COLOR := Color(0.3, 0.55, 0.35)
const ACTIVE_COLOR := Color(0.5, 1.0, 0.6)

## Segundos ligada depois de pisada. Zero, fica ligada para sempre.
var hold_time := 4.0
var active := false

var _press_tick := -100000
var _pressed_once := false


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	add_child(shape)
	monitorable = false
	# Além do personagem, os inimigos pesam na placa.
	collision_mask = Layers.SCENERY | Layers.ENEMY


func _physics_process(_delta: float) -> void:
	for body: Node2D in get_overlapping_bodies():
		var player := body as Player
		var enemy := body as Enemy
		var weighs := enemy and not enemy.is_dead()
		if (player and not player.is_airborne()) or weighs:
			_press_tick = Clock.tick
			_pressed_once = true
	# A estátua e o clone pesam pela posição: o clone não tem corpo.
	for weight: Node2D in get_tree().get_nodes_in_group("plate_weights"):
		var offset := (weight.global_position - global_position).abs()
		if offset.x <= SIZE.x / 2.0 and offset.y <= SIZE.y / 2.0:
			_press_tick = Clock.tick
			_pressed_once = true
	var now_active := Clock.tick - _press_tick < GameMath.ticks(hold_time)
	if hold_time <= 0.0:
		now_active = _pressed_once
	if now_active != active:
		active = now_active
		Sfx.play(&"switch_press" if active else &"switch_release")
		changed.emit(active)
	if active:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-14.0, -14.0, 28.0, 28.0), DoorArt.OUTLINE_COLOR)
	draw_rect(Rect2(-12.0, -12.0, 24.0, 24.0), ACTIVE_COLOR if active else IDLE_COLOR)
	draw_circle(Vector2.ZERO, 6.0, DoorArt.OUTLINE_COLOR)
	if not active or hold_time <= 0.0:
		return
	var left := 1.0 - float(Clock.tick - _press_tick) / GameMath.ticks(hold_time)
	draw_arc(Vector2.ZERO, 9.0, -PI / 2.0, -PI / 2.0 + TAU * left, 24, Color.WHITE, 3.0)
