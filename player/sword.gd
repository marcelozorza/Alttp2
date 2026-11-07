class_name Sword
extends Node2D
## Espada de estocada, a primeira arma.
##
## Cada aperto do botão de ataque entrega o golpe no mesmo tick, com a lâmina
## toda estendida na direção da frente. Um novo aperto cancela o recolhimento
## e golpeia de novo, sem esperar a animação. Cada golpe acerta cada alvo uma
## vez, causa dano em quem tem take_hit e empurra corpos com massa.
##
## O dano é calculado no plano do chão, a partir dos pés de quem empunha. Assim
## o golpe acerta o que está encostado e não muda durante o pulo, quando o
## desenho da lâmina sobe junto com o corpo.

## Centro e meia extensão do corpo desenhado do personagem, a partir da origem
## nos pés. A lâmina sai da borda do corpo.
const BODY_CENTER := Vector2(0.0, -8.0)
const BODY_HALF_EXTENTS := Vector2(12.0, 16.0)
## Meia extensão dos pés, a colisão do personagem.
const FEET_HALF_EXTENTS := Vector2(12.0, 8.0)
## Espessura desenhada da lâmina, em pixels.
const BLADE_THICKNESS := 8.0

## Comprimento da lâmina para fora do corpo, em pixels.
@export_range(8.0, 80.0, 1.0) var reach := 24.0
## Largura da área de dano, em pixels. É maior que a lâmina desenhada, para
## perdoar pequenos desalinhamentos.
@export_range(4.0, 48.0, 1.0) var hit_width := 16.0
## Dano por golpe.
@export_range(1, 10, 1) var damage := 1
## Empurrão no alvo, em pixels por segundo para massa 1. Alvos mais pesados
## são empurrados menos.
@export_range(0.0, 1200.0, 10.0) var impulse := 200.0
## Segundos em que a lâmina estendida causa dano.
@export_range(0.0, 0.5, 0.01) var active_time := 0.1
## Segundos da animação de recolher, sem dano.
@export_range(0.0, 0.5, 0.01) var retract_time := 0.08

var _direction := Vector2.DOWN
var _attack_tick := -1000
var _already_hit: Array[Object] = []
var _hit_shape := RectangleShape2D.new()

@onready var _blade: ColorRect = $Blade
@onready var _wielder := owner as CollisionObject2D


## Golpeia na direção dada, uma das 4 direções retas.
func attack(direction: Vector2) -> void:
	_direction = direction
	_attack_tick = Clock.tick
	_already_hit.clear()
	_apply_hits()
	_update_blade()


func _physics_process(_delta: float) -> void:
	if _elapsed() < GameMath.ticks(active_time):
		_apply_hits()
	_update_blade()


func _elapsed() -> int:
	return Clock.tick - _attack_tick


func _apply_hits() -> void:
	var area := _hit_rect()
	_hit_shape.size = area.size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _hit_shape
	query.transform = Transform2D(0.0, _wielder.global_position + area.get_center())
	var excluded: Array[RID] = [_wielder.get_rid()]
	query.exclude = excluded
	query.collide_with_areas = true
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var target: Object = result["collider"]
		if target in _already_hit:
			continue
		_already_hit.append(target)
		if target.has_method("take_hit"):
			target.call("take_hit", damage, _direction, Hit.Kind.SWORD)
		var body := target as MomentumBody
		if body:
			body.add_impact_velocity(_direction * impulse / body.mass)


func _update_blade() -> void:
	var active := GameMath.ticks(active_time)
	var retract := GameMath.ticks(retract_time)
	var elapsed := _elapsed()
	var length := 0.0
	if elapsed < active:
		length = reach
	elif elapsed < active + retract:
		length = reach * (1.0 - float(elapsed - active) / retract)
	_blade.visible = length > 0.0
	if _blade.visible:
		var rect := _blade_rect(length, BLADE_THICKNESS)
		_blade.position = rect.position
		_blade.size = rect.size


## Área de dano no chão, relativa aos pés. Vai da borda dos pés até a ponta da
## lâmina desenhada. Para cima, a lâmina sai do alto do corpo, então a área
## também cobre o trecho entre os pés e a cabeça.
func _hit_rect() -> Rect2:
	var horizontal := _direction.x != 0.0
	var edge := BODY_HALF_EXTENTS.x if horizontal else BODY_HALF_EXTENTS.y
	var tip := BODY_CENTER + _direction * (edge + reach)
	var near := _direction * (FEET_HALF_EXTENTS.x if horizontal else FEET_HALF_EXTENTS.y)
	if horizontal:
		return Rect2(minf(near.x, tip.x), -hit_width / 2.0, absf(tip.x - near.x), hit_width)
	return Rect2(-hit_width / 2.0, minf(near.y, tip.y), hit_width, absf(tip.y - near.y))


## Retângulo da lâmina desenhada, que começa na borda do corpo e se estende na
## direção do golpe.
func _blade_rect(length: float, thickness: float) -> Rect2:
	var horizontal := _direction.x != 0.0
	var edge := BODY_HALF_EXTENTS.x if horizontal else BODY_HALF_EXTENTS.y
	var center := BODY_CENTER + _direction * (edge + length / 2.0)
	var size := Vector2(length, thickness) if horizontal else Vector2(thickness, length)
	return Rect2(center - size / 2.0, size)
