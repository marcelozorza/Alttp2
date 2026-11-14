class_name FirePatch
extends Node2D
## Chama no chão deixada pelo rastro (mechanics/trail.gd). Fica alguns segundos,
## fere o personagem que pisa nela e some. Pular por cima não fere. Fica com
## os efeitos do chão, que somem ao trocar de sala. Arte provisória.

const LIFE_TICKS := 170
const RADIUS := 13.0
const DAMAGE := 1
const COLOR := Color(1.0, 0.55, 0.15, 0.85)
const CORE_COLOR := Color(1.0, 0.9, 0.5, 0.9)

var _born_tick := 0


func _ready() -> void:
	_born_tick = Clock.tick


func _physics_process(_delta: float) -> void:
	var age := Clock.tick - _born_tick
	if age >= LIFE_TICKS:
		queue_free()
		return
	queue_redraw()
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player or player.is_airborne():
		return
	if player.global_position.distance_to(global_position) <= RADIUS:
		player.take_hit(DAMAGE, Vector2.ZERO, Hit.Kind.FIRE)


func _draw() -> void:
	var left := 1.0 - float(Clock.tick - _born_tick) / LIFE_TICKS
	var flicker := 1.0 if posmod(Clock.tick, 8) < 4 else 0.8
	draw_circle(Vector2.ZERO, RADIUS * flicker * (0.5 + 0.5 * left), COLOR)
	draw_circle(Vector2(0.0, -2.0), RADIUS * 0.45 * flicker * left, CORE_COLOR)
