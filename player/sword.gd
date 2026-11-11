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
##
## A espada não tem desenho próprio. Ela faz parte dos desenhos do Giorgino:
## fica na pata em todas as poses, e os quadros de golpe (giorgino_thrust_*)
## mostram o braço estendido com a lâmina sobre a área de dano. O personagem
## pergunta a is_out() e a direction qual quadro mostrar (pedido de Marcelo em
## 2026-11-10: a espada desenhada junto do corpo, e não saindo da cabeça).

## Centro e meia extensão do corpo desenhado do personagem, a partir da origem
## nos pés. A área de dano sai da borda do corpo.
const BODY_CENTER := Vector2(0.0, -8.0)
const BODY_HALF_EXTENTS := Vector2(12.0, 16.0)
## Meia extensão dos pés, a colisão do personagem.
const FEET_HALF_EXTENTS := Vector2(12.0, 8.0)
## Ticks em que o desenho volta à espada recolhida quando um golpe sai com a
## espada ainda estendida. Sem isso, apertar o botão bem rápido deixava o
## quadro de golpe parado na tela (pedido de Marcelo em 2026-11-11: um
## piscar a cada aperto). Só o desenho recolhe: o dano sai no mesmo tick.
const RESTART_TICKS := 2
## Tick de um golpe que nunca aconteceu.
const NEVER := -1000

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
## Segundos em que o quadro de golpe continua à vista depois disso, sem dano.
@export_range(0.0, 0.5, 0.01) var retract_time := 0.08

## Direção do último golpe, uma das 4 direções retas.
var direction := Vector2.DOWN

var _attack_tick := NEVER
var _restart_tick := NEVER
var _already_hit: Array[Object] = []
var _hit_shape := RectangleShape2D.new()

@onready var _wielder := owner as CollisionObject2D


## Golpeia na direção dada, uma das 4 direções retas.
func attack(toward: Vector2) -> void:
	# Um golpe que sai com a espada ainda estendida recolhe o desenho por um
	# instante, para cada aperto aparecer (ver RESTART_TICKS).
	_restart_tick = Clock.tick if is_out() else NEVER
	direction = toward
	_attack_tick = Clock.tick
	_already_hit.clear()
	_apply_hits()


## Verdadeiro enquanto a espada está estendida ou recolhendo. É quando o
## personagem mostra o quadro de golpe.
func is_out() -> bool:
	if Clock.tick - _restart_tick < RESTART_TICKS:
		return false
	return _elapsed() < GameMath.ticks(active_time) + GameMath.ticks(retract_time)


func _physics_process(_delta: float) -> void:
	if _elapsed() < GameMath.ticks(active_time):
		_apply_hits()


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
			target.call("take_hit", damage, direction, Hit.Kind.SWORD)
		var body := target as MomentumBody
		if body:
			body.add_impact_velocity(direction * impulse / body.mass)


## Área de dano no chão, relativa aos pés. Vai da borda dos pés até a ponta da
## lâmina. Para cima, a lâmina sai do alto do corpo, então a área também cobre
## o trecho entre os pés e a cabeça.
func _hit_rect() -> Rect2:
	var horizontal := direction.x != 0.0
	var edge := BODY_HALF_EXTENTS.x if horizontal else BODY_HALF_EXTENTS.y
	var tip := BODY_CENTER + direction * (edge + reach)
	var near := direction * (FEET_HALF_EXTENTS.x if horizontal else FEET_HALF_EXTENTS.y)
	if horizontal:
		return Rect2(minf(near.x, tip.x), -hit_width / 2.0, absf(tip.x - near.x), hit_width)
	return Rect2(-hit_width / 2.0, minf(near.y, tip.y), hit_width, absf(tip.y - near.y))
