class_name Grenade
extends Node2D
## Granada que o ugly joga de longe. Ela voa em arco até o centro de uma casa e
## estoura numa área de 3 por 3 casas. A área aparece no chão assim que a
## granada sai da mão, e um quadrado cresce dentro dela até o estouro, como
## aviso. Quem estiver com os pés na área no estouro fica com a espada travada.
## A granada não causa dano, não empurra e só afeta o personagem.
##
## Com o nó Blob (a cena da granada), ela é uma bola de gosma magenta: voa
## mudando de forma, a marca do alvo é a borda pontilhada da poça, o estouro é
## um respingo e a poça pegajosa fica no chão um pouco e some. A poça é só
## desenho: o efeito acontece todo no estouro. Pedido de Marcelo em 2026-11-08.
## Desenhos em tools/goo_art.py.
##
## A pedra do atirador (enemies/rock.tscn) é a mesma cena com outros valores:
## cai numa casa só, causa dano em vez de travar a espada e tem a cor da pedra.

## Tamanho do desenho da granada, em pixels.
const BALL_SIZE := Vector2(12.0, 12.0)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
## Ticks em que o estouro fica visível.
const BURST_TICKS := 12
## Ticks de cada quarto de volta do projétil desenhado.
const ART_TURN_TICKS := 5
const GOO_BLOB: Array[Texture2D] = [
	preload("res://art/goo_blob_1.svg"),
	preload("res://art/goo_blob_2.svg"),
]
const GOO_SPLASH: Array[Texture2D] = [
	preload("res://art/goo_splash_1.svg"),
	preload("res://art/goo_splash_2.svg"),
	preload("res://art/goo_splash_3.svg"),
]
const GOO_PUDDLE := preload("res://art/goo_puddle.svg")
const GOO_TARGET := preload("res://art/goo_target.svg")
## Ticks de cada forma da bola de gosma no voo.
const GOO_BLOB_TICKS := 6
## Ticks de cada quadro do respingo.
const GOO_SPLASH_TICKS := 4
## Ticks em que a poça fica no chão depois do respingo, e quantos deles são
## de sumir aos poucos.
const GOO_PUDDLE_TICKS := 90
const GOO_FADE_TICKS := 30

## Segundos no ar, da mão até o chão. É o tempo para sair da área.
@export_range(0.1, 2.0, 0.05) var flight_time := 0.7
## Lado da área do estouro, em casas.
@export_range(1, 7, 1) var area_tiles := 3
## Altura extra do arco, em pixels, além da altura da mão.
@export_range(0.0, 128.0, 1.0) var arc_height := 40.0
## Segundos com a espada travada para quem estiver na área. Zero não trava.
@export_range(0.0, 10.0, 0.5) var sword_lock_time := 3.0
## Dano em quem estiver na área. Zero não machuca.
@export_range(0, 10, 1) var damage := 0
## Cor da bola e da área no chão.
@export var color := Color(0.95, 0.35, 0.85, 1.0)
## Desenho do projétil no ar, no lugar do quadrado de cor: o coco do macaco.
@export var ball_texture: Texture2D

var _from := Vector2.ZERO
var _from_height := 0.0
var _launch_tick := 0
var _burst_tick := -1
var _area_shape := RectangleShape2D.new()
var _art: Sprite2D

@onready var _ball: ColorRect = $Ball
@onready var _blob := get_node_or_null("Blob") as Sprite2D


func _ready() -> void:
	_ball.color = color
	if _blob:
		_ball.visible = false
	if ball_texture:
		_ball.visible = false
		_art = Sprite2D.new()
		_art.texture = ball_texture
		_art.z_index = 1
		add_child(_art)


## Lança a granada. Ela sai de from, os pés de quem joga, à altura from_height,
## e cai no centro da casa de target. Chamar depois de entrar na árvore.
func launch(from: Vector2, from_height: float, target: Vector2) -> void:
	var tile := float(ChapterMap.TILE)
	global_position = ((target / tile).floor() + Vector2(0.5, 0.5)) * tile
	_from = from
	_from_height = from_height
	_launch_tick = Clock.tick
	_update_ball()


func _physics_process(_delta: float) -> void:
	if _burst_tick >= 0:
		if Clock.tick - _burst_tick >= _burst_ticks():
			queue_free()
	elif _progress() >= 1.0:
		_burst()
	else:
		_update_ball()
	queue_redraw()


## Fração do voo já percorrida, de 0 a 1.
func _progress() -> float:
	var flight := maxi(GameMath.ticks(flight_time), 1)
	return minf(float(Clock.tick - _launch_tick) / flight, 1.0)


## Posição da granada no chão, relativa ao centro da área. É onde fica a sombra.
func _ground_offset() -> Vector2:
	return (_from - global_position) * (1.0 - _progress())


## A granada segue em linha reta no chão e sobe e desce num arco.
func _update_ball() -> void:
	var t := _progress()
	var height := _from_height * (1.0 - t) + arc_height * 4.0 * t * (1.0 - t)
	_ball.position = _ground_offset() - Vector2(0.0, height) - BALL_SIZE / 2.0
	if _art:
		# Gira aos quartos de volta, para os pixels não borrarem.
		_art.position = (_ball.position + BALL_SIZE / 2.0).round()
		_art.rotation = floorf(float(Clock.tick - _launch_tick) / ART_TURN_TICKS) * PI / 2.0
	if _blob:
		_blob.position = _ball.position + BALL_SIZE / 2.0
		var shape := floori(float(Clock.tick - _launch_tick) / GOO_BLOB_TICKS) % GOO_BLOB.size()
		_blob.texture = GOO_BLOB[shape]


## Ticks entre o estouro e o fim, com o respingo e a poça na gosma.
func _burst_ticks() -> int:
	if _blob:
		return GOO_SPLASH_TICKS * GOO_SPLASH.size() + GOO_PUDDLE_TICKS
	return BURST_TICKS


## Área do estouro, relativa ao centro.
func _area() -> Rect2:
	var side := float(area_tiles * ChapterMap.TILE)
	return Rect2(-Vector2(side, side) / 2.0, Vector2(side, side))


func _burst() -> void:
	_burst_tick = Clock.tick
	Sfx.play(&"grenade_burst")
	_ball.visible = false
	if _blob:
		_blob.visible = false
	if _art:
		_art.visible = false
	_area_shape.size = _area().size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _area_shape
	query.transform = Transform2D(0.0, global_position)
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var player := result["collider"] as Player
		if not player:
			continue
		if sword_lock_time > 0.0:
			player.lock_sword(sword_lock_time)
		if damage > 0:
			var away := player.global_position - global_position
			var direction := away.normalized() if away != Vector2.ZERO else Vector2.DOWN
			player.take_hit(damage, direction)


## Visual provisório: a área no chão com borda, o quadrado que cresce do centro
## até a borda durante o voo e a sombra da granada. No estouro, a área toda
## brilha e some.
func _draw() -> void:
	if _blob:
		_draw_goo()
		return
	var area := _area()
	if _burst_tick >= 0:
		var fade := 1.0 - float(Clock.tick - _burst_tick) / BURST_TICKS
		draw_rect(area, Color(color, 0.7 * fade))
		return
	draw_rect(area, Color(color, 0.12))
	draw_rect(area.grow(-1.0), Color(color, 0.8), false, 2.0)
	var filled := area.size * _progress()
	draw_rect(Rect2(-filled / 2.0, filled), Color(color, 0.2))
	draw_rect(Rect2(_ground_offset() - Vector2(6.0, 2.0), Vector2(12.0, 4.0)), SHADOW_COLOR)


## Gosma: antes do estouro, a borda pontilhada da poça, a poça crescendo
## transparente do centro e a sombra da bola. Depois, o respingo e a poça,
## que some aos poucos no fim.
func _draw_goo() -> void:
	if _burst_tick >= 0:
		var elapsed := Clock.tick - _burst_tick
		var splash := elapsed / GOO_SPLASH_TICKS
		if splash < GOO_SPLASH.size():
			_draw_centered(GOO_SPLASH[splash], 1.0, 1.0)
			return
		var left := _burst_ticks() - elapsed
		_draw_centered(GOO_PUDDLE, 1.0, minf(float(left) / GOO_FADE_TICKS, 1.0))
		return
	_draw_centered(GOO_TARGET, 1.0, 0.9)
	_draw_centered(GOO_PUDDLE, _progress(), 0.25)
	draw_rect(Rect2(_ground_offset() - Vector2(6.0, 2.0), Vector2(12.0, 4.0)), SHADOW_COLOR)


## Desenha a textura centrada na área, na escala e transparência dadas.
func _draw_centered(texture: Texture2D, scale_factor: float, alpha: float) -> void:
	var size := texture.get_size() * scale_factor
	draw_texture_rect(texture, Rect2(-size / 2.0, size), false, Color(1.0, 1.0, 1.0, alpha))
