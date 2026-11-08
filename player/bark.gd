class_name Bark
extends Node2D
## Latido, o ataque do botão de ataque (decisão de Marcelo em 2026-11-07, no
## lugar da espada: ele achou que uma mordida o tempo todo deixaria o cachorro
## antipático). Sai do focinho na direção da frente e cobre a casa à frente.
##
## Cada aperto do botão entrega o golpe no mesmo tick. Um novo aperto late de
## novo, sem esperar a onda sumir. Cada latido acerta cada alvo uma vez, causa
## dano em quem tem take_hit e empurra corpos com massa, como a espada fazia.
##
## Com um baú fechado na casa à frente, o mesmo botão estica a pata e abre o
## baú, sem latir ("ele abre o baú com a pata", Marcelo). O latido não abre
## baú.
##
## O dano é calculado no plano do chão, a partir dos pés de quem late. Assim
## o latido acerta o que está encostado e não muda durante o pulo, quando o
## desenho sobe junto com o corpo. As ondas e a pata são desenhadas viradas
## para a direita e giradas para a direção do golpe.

enum Action { NONE, BARK, PAW }

## Centro e meia extensão do corpo desenhado do personagem, a partir da origem
## nos pés. As ondas e a pata saem da borda do corpo.
const BODY_CENTER := Vector2(0.0, -8.0)
const BODY_HALF_EXTENTS := Vector2(12.0, 16.0)
## Meia extensão dos pés, a colisão do personagem.
const FEET_HALF_EXTENTS := Vector2(12.0, 8.0)
const WAVE_TEXTURES: Array[Texture2D] = [
	preload("res://art/bark_1.svg"),
	preload("res://art/bark_2.svg"),
]
const PAW_TEXTURE := preload("res://art/paw.svg")
## Ticks depois do aperto em que a pata chega ao baú e ele abre.
const PAW_OPEN_TICKS := 4
## Altura, a partir dos pés, de onde saem as ondas e a pata quando o golpe é
## para o lado: a boca e o ombro do desenho de perfil.
const MOUTH_HEIGHT := -32.0
const SHOULDER_HEIGHT := -20.0

## Alcance do latido para fora do corpo, em pixels: uma casa.
@export_range(8.0, 80.0, 1.0) var reach := 32.0
## Largura da área de dano, em pixels.
@export_range(4.0, 48.0, 1.0) var hit_width := 32.0
## Dano por latido.
@export_range(1, 10, 1) var damage := 1
## Empurrão no alvo, em pixels por segundo para massa 1. Alvos mais pesados
## são empurrados menos.
@export_range(0.0, 1200.0, 10.0) var impulse := 200.0
## Segundos em que o latido causa dano.
@export_range(0.0, 0.5, 0.01) var active_time := 0.1
## Segundos em que as ondas ainda aparecem depois do dano.
@export_range(0.0, 0.5, 0.01) var fade_time := 0.08
## Segundos em que a pata fica esticada.
@export_range(0.05, 1.0, 0.01) var paw_time := 0.25

var _direction := Vector2.DOWN
var _action := Action.NONE
var _action_tick := -1000
var _chest: Chest
var _already_hit: Array[Object] = []
var _hit_shape := RectangleShape2D.new()

@onready var _wielder := owner as CollisionObject2D


## Late na direção dada, uma das 4 direções retas.
func bark(direction: Vector2) -> void:
	_direction = direction
	_action = Action.BARK
	_action_tick = Clock.tick
	_already_hit.clear()
	_apply_hits()
	queue_redraw()


## Estica a pata na direção dada e abre o baú quando ela chega.
func paw(direction: Vector2, chest: Chest) -> void:
	_direction = direction
	_action = Action.PAW
	_action_tick = Clock.tick
	_chest = chest
	queue_redraw()


## Baú fechado na área à frente, ou null.
func chest_ahead(direction: Vector2) -> Chest:
	for target: Object in _targets_ahead(direction):
		var chest := target as Chest
		if chest and not chest.is_open:
			return chest
	return null


func _physics_process(_delta: float) -> void:
	match _action:
		Action.BARK:
			if _elapsed() < GameMath.ticks(active_time):
				_apply_hits()
			elif _elapsed() >= GameMath.ticks(active_time) + GameMath.ticks(fade_time):
				_action = Action.NONE
		Action.PAW:
			if _chest and _elapsed() >= PAW_OPEN_TICKS:
				if is_instance_valid(_chest):
					_chest.open_by_paw()
				_chest = null
			if _elapsed() >= GameMath.ticks(paw_time):
				_action = Action.NONE
	queue_redraw()


func _elapsed() -> int:
	return Clock.tick - _action_tick


func _apply_hits() -> void:
	for target: Object in _targets_ahead(_direction):
		if target in _already_hit:
			continue
		_already_hit.append(target)
		if target.has_method("take_hit"):
			target.call("take_hit", damage, _direction, Hit.Kind.BARK)
		var body := target as MomentumBody
		if body:
			body.add_impact_velocity(_direction * impulse / body.mass)


## Tudo o que está na área à frente, no plano do chão.
func _targets_ahead(direction: Vector2) -> Array[Object]:
	var area := _hit_rect(direction)
	_hit_shape.size = area.size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _hit_shape
	query.transform = Transform2D(0.0, _wielder.global_position + area.get_center())
	var excluded: Array[RID] = [_wielder.get_rid()]
	query.exclude = excluded
	query.collide_with_areas = true
	var targets: Array[Object] = []
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		targets.append(result["collider"])
	return targets


func _draw() -> void:
	var elapsed := _elapsed()
	match _action:
		Action.BARK:
			var shown := GameMath.ticks(active_time) + GameMath.ticks(fade_time)
			if elapsed < shown:
				var frame := 0 if elapsed * 2 < shown else 1
				_draw_ahead(WAVE_TEXTURES[frame], MOUTH_HEIGHT)
		Action.PAW:
			if elapsed < GameMath.ticks(paw_time):
				_draw_ahead(PAW_TEXTURE, SHOULDER_HEIGHT)


## Desenha a textura, feita virada para a direita, saindo da borda do corpo
## na direção do golpe. Para o lado, sai na altura dada; para cima e para
## baixo, do alto ou da base do corpo.
func _draw_ahead(texture: Texture2D, side_height: float) -> void:
	var start := BODY_CENTER + _direction * BODY_HALF_EXTENTS.y
	if _direction.x != 0.0:
		start = Vector2(_direction.x * BODY_HALF_EXTENTS.x, side_height)
	draw_set_transform(start, _direction.angle())
	draw_texture(texture, Vector2(0.0, -texture.get_height() / 2.0))
	draw_set_transform(Vector2.ZERO)


## Área de dano no chão, relativa aos pés. Vai da borda dos pés até o fim do
## alcance. Para cima, o latido sai do alto do corpo, então a área também
## cobre o trecho entre os pés e a cabeça.
func _hit_rect(direction: Vector2) -> Rect2:
	var horizontal := direction.x != 0.0
	var edge := BODY_HALF_EXTENTS.x if horizontal else BODY_HALF_EXTENTS.y
	var tip := BODY_CENTER + direction * (edge + reach)
	var near := direction * (FEET_HALF_EXTENTS.x if horizontal else FEET_HALF_EXTENTS.y)
	if horizontal:
		return Rect2(minf(near.x, tip.x), -hit_width / 2.0, absf(tip.x - near.x), hit_width)
	return Rect2(-hit_width / 2.0, minf(near.y, tip.y), hit_width, absf(tip.y - near.y))
