class_name FloorSwitch
extends Area2D
## Interruptor no chão. Fica pressionado enquanto o personagem está em cima,
## o que abre a grade da sala só enquanto ele fica ali, e de vez quando um
## bloco pesado para em cima dele: o bloco trava no lugar e o losango acende.
## É o mecanismo do bloco pesado sobre o interruptor.
##
## A origem fica no centro da casa. Ele fica na camada dos efeitos do chão
## (FloorEffects), acima do chão e abaixo dos objetos.

signal changed(pressed: bool)

const TEXTURE := preload("res://art/floor_switch.svg")
const PRESSED_TEXTURE := preload("res://art/floor_switch_pressed.svg")
const SIZE := Vector2(12.0, 12.0)
## Distância, em pixels, do centro do bloco ao lugar certo para ele travar.
const SNAP_DISTANCE := 6.0
## Onde fica a origem de um bloco em cima do interruptor, relativa à do
## interruptor: no centro da base do bloco, embaixo da casa.
const BLOCK_OFFSET := Vector2(0.0, 8.0)

var pressed := false


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	add_child(shape)
	monitorable = false


func _physics_process(_delta: float) -> void:
	var now_pressed := false
	for body: Node2D in get_overlapping_bodies():
		if body is Player:
			now_pressed = true
		elif body is HeavyBlock:
			var block := body as HeavyBlock
			var seat := global_position + BLOCK_OFFSET
			if not block.locked and block.global_position.distance_to(seat) <= SNAP_DISTANCE:
				block.lock_at(seat)
			if block.locked:
				now_pressed = true
	if now_pressed != pressed:
		pressed = now_pressed
		Sfx.play(&"switch_press" if pressed else &"switch_release")
		queue_redraw()
		changed.emit(pressed)


func _draw() -> void:
	draw_texture(PRESSED_TEXTURE if pressed else TEXTURE, Vector2(-8.0, -8.0))
