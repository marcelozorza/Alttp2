class_name Grenade
extends Node2D
## Granada que o ugly joga de longe. Ela voa em arco até o centro de uma casa e
## estoura numa área de 3 por 3 casas. A área aparece no chão assim que a
## granada sai da mão, e um quadrado cresce dentro dela até o estouro, como
## aviso. Quem estiver com os pés na área no estouro fica com a espada travada.
## A granada não causa dano, não empurra e só afeta o personagem.

## Tamanho do desenho da granada, em pixels.
const BALL_SIZE := Vector2(6.0, 6.0)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
## Ticks em que o estouro fica visível.
const BURST_TICKS := 12

## Segundos no ar, da mão até o chão. É o tempo para sair da área.
@export_range(0.1, 2.0, 0.05) var flight_time := 0.7
## Lado da área do estouro, em casas.
@export_range(1, 7, 1) var area_tiles := 3
## Altura extra do arco, em pixels, além da altura da mão.
@export_range(0.0, 64.0, 1.0) var arc_height := 20.0
## Segundos com a espada travada para quem estiver na área.
@export_range(0.0, 10.0, 0.5) var sword_lock_time := 3.0

var _from := Vector2.ZERO
var _from_height := 0.0
var _launch_tick := 0
var _burst_tick := -1
var _area_shape := RectangleShape2D.new()

@onready var _ball: ColorRect = $Ball


func _ready() -> void:
	_ball.color = Player.SWORD_LOCK_COLOR


## Lança a granada. Ela sai de from, os pés de quem joga, à altura from_height,
## e cai no centro da casa de target. Chamar depois de entrar na árvore.
func launch(from: Vector2, from_height: float, target: Vector2) -> void:
	var tile := float(ChapterMap.TILE)
	global_position = ((target / tile).floor() + Vector2(0.5, 0.5)) * tile
	_from = from
	_from_height = from_height
	_launch_tick = Engine.get_physics_frames()
	_update_ball()


func _physics_process(_delta: float) -> void:
	if _burst_tick >= 0:
		if Engine.get_physics_frames() - _burst_tick >= BURST_TICKS:
			queue_free()
	elif _progress() >= 1.0:
		_burst()
	else:
		_update_ball()
	queue_redraw()


## Fração do voo já percorrida, de 0 a 1.
func _progress() -> float:
	var flight := maxi(GameMath.ticks(flight_time), 1)
	return minf(float(Engine.get_physics_frames() - _launch_tick) / flight, 1.0)


## Posição da granada no chão, relativa ao centro da área. É onde fica a sombra.
func _ground_offset() -> Vector2:
	return (_from - global_position) * (1.0 - _progress())


## A granada segue em linha reta no chão e sobe e desce num arco.
func _update_ball() -> void:
	var t := _progress()
	var height := _from_height * (1.0 - t) + arc_height * 4.0 * t * (1.0 - t)
	_ball.position = _ground_offset() - Vector2(0.0, height) - BALL_SIZE / 2.0


## Área do estouro, relativa ao centro.
func _area() -> Rect2:
	var side := float(area_tiles * ChapterMap.TILE)
	return Rect2(-Vector2(side, side) / 2.0, Vector2(side, side))


func _burst() -> void:
	_burst_tick = Engine.get_physics_frames()
	_ball.visible = false
	_area_shape.size = _area().size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _area_shape
	query.transform = Transform2D(0.0, global_position)
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var player := result["collider"] as Player
		if player:
			player.lock_sword(sword_lock_time)


## Visual provisório: a área no chão com borda, o quadrado que cresce do centro
## até a borda durante o voo e a sombra da granada. No estouro, a área toda
## brilha e some.
func _draw() -> void:
	var area := _area()
	var color := Player.SWORD_LOCK_COLOR
	if _burst_tick >= 0:
		var fade := 1.0 - float(Engine.get_physics_frames() - _burst_tick) / BURST_TICKS
		draw_rect(area, Color(color, 0.7 * fade))
		return
	draw_rect(area, Color(color, 0.12))
	draw_rect(area.grow(-0.5), Color(color, 0.8), false, 1.0)
	var filled := area.size * _progress()
	draw_rect(Rect2(-filled / 2.0, filled), Color(color, 0.2))
	draw_rect(Rect2(_ground_offset() - Vector2(3.0, 1.0), Vector2(6.0, 2.0)), SHADOW_COLOR)
