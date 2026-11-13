class_name Teleporter
extends Area2D
## Portal do laboratório: um disco no chão ligado a outro da mesma cor. Pisar
## num leva ao outro. O portal de chegada só volta a funcionar depois que o
## personagem sai de cima dele, para não levá-lo de volta na hora. Pular por
## cima não aciona. Arte provisória.
##
## A origem fica no centro da casa, na camada dos interruptores.

const COLORS: Array[Color] = [
	Color(0.4, 0.8, 1.0), Color(1.0, 0.5, 0.8), Color(0.6, 1.0, 0.5), Color(1.0, 0.85, 0.4)
]

## Número do par. Dois portais com o mesmo número se ligam.
var pair := 0
## Ligado, é só chegada: pisar nele não leva a lugar nenhum. Serve para a
## volta de mão única.
var exit_only := false

## Desligado enquanto o personagem que acabou de chegar ainda está em cima.
var _armed := true


func _ready() -> void:
	add_to_group("teleporters")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)
	monitorable = false


func _physics_process(_delta: float) -> void:
	queue_redraw()
	var player: Player = null
	for body: Node2D in get_overlapping_bodies():
		if body is Player:
			player = body as Player
	if not player:
		_armed = true
		return
	if not _armed or exit_only or player.is_airborne():
		return
	for other: Teleporter in get_tree().get_nodes_in_group("teleporters"):
		if other != self and other.pair == pair:
			other._armed = false
			player.global_position = other.global_position
			player.velocity = Vector2.ZERO
			Sfx.play(&"relic")
			return


func _draw() -> void:
	var color := COLORS[pair % COLORS.size()]
	draw_circle(Vector2.ZERO, 14.0, DoorArt.OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, 12.0, color.darkened(0.5))
	if exit_only:
		draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 20, color.darkened(0.2), 1.0)
		return
	var pulse := 4.0 + 6.0 * absf(sin(Clock.tick * 0.08))
	draw_arc(Vector2.ZERO, pulse, 0.0, TAU, 20, color, 2.0)
