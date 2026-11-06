class_name Shockwave
extends Node2D
## Onda de choque que corre pelo chão a partir da pancada do chefe. Só machuca
## quem está no chão: no ar, com o pulo da mola, ela passa por baixo.
##
## A onda alta, do colosso, é mais grossa e sobe mais: o pulo comum não passa
## dela, só o pulo da mola forte. É o exame da melhoria, como a onda comum é o
## exame da mola.

const COLOR := Color(0.95, 0.95, 1.0, 1.0)
const TALL_COLOR := Color(0.95, 0.8, 0.55, 1.0)
## Altura dos pés que a onda alta exige, acima do pico do pulo comum.
const TALL_CLEARANCE := 26.0
const TALL_THICKNESS := 14.0

## Velocidade da frente da onda, em pixels por segundo.
@export_range(10.0, 400.0, 1.0) var speed := 120.0
## Raio em que a onda some, em pixels.
@export_range(16.0, 400.0, 1.0) var max_radius := 190.0
## Espessura da frente da onda, em pixels.
@export_range(2.0, 20.0, 1.0) var thickness := 8.0
## Dano em quem estiver no chão.
@export_range(1, 10, 1) var damage := 2
## Empurrão para fora, em pixels por segundo para massa 1.
@export_range(0.0, 600.0, 10.0) var impulse := 160.0
## Altura dos pés, em pixels, a partir da qual a onda passa por baixo.
@export_range(0.0, 20.0, 1.0) var clearance := 4.0
## Ligada, a onda é alta: só o pulo da mola forte passa.
@export var tall := false

var _radius := 0.0
var _hit := false


func _ready() -> void:
	if tall:
		clearance = TALL_CLEARANCE
		thickness = TALL_THICKNESS


func _physics_process(delta: float) -> void:
	_radius += speed * delta
	if _radius > max_radius:
		queue_free()
		return
	if not _hit:
		_check_player()
	queue_redraw()


func _check_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player or player.get_height() >= clearance:
		return
	var away := player.global_position - global_position
	if absf(away.length() - _radius) > thickness / 2.0 + 4.0:
		return
	_hit = true
	var direction := away.normalized() if away != Vector2.ZERO else Vector2.DOWN
	player.take_hit(damage, direction, Hit.Kind.SHOCKWAVE)
	player.add_impact_velocity(direction * impulse)


func _draw() -> void:
	var alpha := 1.0 - _radius / max_radius
	var color := TALL_COLOR if tall else COLOR
	var width := 4.0 if tall else 2.0
	draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 64, Color(color, alpha), width)
	var inner := maxf(_radius - (8.0 if tall else 4.0), 0.0)
	draw_arc(Vector2.ZERO, inner, 0.0, TAU, 64, Color(color, alpha * 0.4), width / 2.0)
	if tall:
		var crest := maxf(_radius - 3.0, 0.0)
		draw_arc(Vector2.ZERO, crest, 0.0, TAU, 64, Color(color, alpha * 0.7), 1.0)
