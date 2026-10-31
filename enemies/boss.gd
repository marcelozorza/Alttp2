class_name Boss
extends MomentumBody
## Chefe do capítulo 1, o guardião de gelo. É o exame das três ferramentas.
##
## Coberto pela casca de gelo, ele ignora espada e bomba: só a chama quebra a
## casca, que volta depois de shell_regrow_time. Sem a casca, o núcleo apanha
## da espada e mais ainda da bomba. Os ataques são sempre avisados, piscando em
## amarelo. A pancada no chão solta uma onda que só se evita no ar, com a mola.
## A investida corre em linha reta na direção travada durante o aviso.
##
## Não há dano por contato. Encostar nele só troca momento pela física, e ele
## é muito mais pesado que o personagem.

signal defeated

enum State {
	DORMANT,
	APPROACH,
	SLAM_WINDUP,
	SLAM_RECOVER,
	CHARGE_WINDUP,
	CHARGE,
	CHARGE_RECOVER,
	DEAD,
}

const SHOCKWAVE_SCENE := preload("res://enemies/shockwave.tscn")
const SHELL_COLOR := Color(0.62, 0.86, 1.0, 1.0)
const SHINE_COLOR := Color(0.92, 0.98, 1.0, 1.0)
const CORE_COLOR := Color(0.6, 0.2, 0.3, 1.0)
const WINDUP_COLOR := Color(1.0, 0.85, 0.2, 1.0)
const HIT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const IMMUNE_COLOR := Color(0.55, 0.55, 0.6, 1.0)
const EYE_COLOR := Color(0.1, 0.1, 0.15, 1.0)
const HEALTH_COLOR := Color(0.9, 0.3, 0.35, 1.0)
const BODY_SIZE := Vector2(28.0, 26.0)
## Segundos antes de a casca voltar em que ela pisca, como aviso.
const REGROW_WARNING_TIME := 1.0
## Ticks do brilho de dano e de imunidade.
const FLASH_TICKS := 6

@export_group("Vida")
## Pontos de vida do núcleo.
@export_range(1, 60, 1) var max_health := 12
## Segundos até a casca de gelo voltar depois de quebrada.
@export_range(0.5, 20.0, 0.5) var shell_regrow_time := 6.0
## Multiplicador do dano da espada, sem a casca.
@export_range(0, 10, 1) var sword_factor := 1
## Multiplicador do dano do fogo, sem a casca.
@export_range(0, 10, 1) var fire_factor := 1
## Multiplicador do dano da explosão, sem a casca.
@export_range(0, 10, 1) var blast_factor := 3

@export_group("Comportamento")
## Segundos parado depois que o personagem entra na sala.
@export_range(0.0, 3.0, 0.1) var wake_time := 1.0
## Velocidade de aproximação, em pixels por segundo.
@export_range(0.0, 200.0, 1.0) var walk_speed := 28.0
## Segundos se aproximando entre um ataque e outro.
@export_range(0.1, 5.0, 0.1) var approach_time := 1.6
## Segundos de aviso antes da pancada no chão.
@export_range(0.1, 3.0, 0.05) var slam_windup_time := 0.9
## Segundos parado depois da pancada.
@export_range(0.1, 5.0, 0.1) var slam_recover_time := 1.4
## Segundos de aviso antes da investida, com a direção já travada.
@export_range(0.1, 3.0, 0.05) var charge_windup_time := 0.7
## Velocidade da investida, em pixels por segundo.
@export_range(0.0, 600.0, 1.0) var charge_speed := 210.0
## Duração da investida, em segundos.
@export_range(0.05, 2.0, 0.05) var charge_time := 0.45
## Segundos parado depois da investida.
@export_range(0.1, 5.0, 0.1) var charge_recover_time := 1.0
## Dano da investida.
@export_range(1, 10, 1) var charge_damage := 2

var health := 0
## Interior da sala, em coordenadas globais. A base do chefe nunca sai dele,
## nem pela porta. Vazio, sem limite.
var arena := Rect2()

var _state := State.DORMANT
var _state_tick := 0
var _shell := true
var _shell_break_tick := -100000
var _hit_tick := -1000
var _immune_tick := -1000
var _next_is_slam := true
var _charge_direction := Vector2.DOWN
var _charge_landed := false
var _defeated := false
var _look := Vector2.DOWN
var _hurt_shape := RectangleShape2D.new()

@onready var _home := global_position
@onready var _base: CollisionShape2D = $Base


func _ready() -> void:
	health = max_health


## Volta ao ponto inicial com vida e casca, a menos que já tenha sido derrotado.
func reset() -> void:
	if _defeated:
		return
	health = max_health
	global_position = _home
	velocity = Vector2.ZERO
	_shell = true
	_next_is_slam = true
	_enter(State.DORMANT)


## Liga ou desliga o chefe quando o personagem entra ou sai da sala.
## Desligado, ele não bloqueia nada.
func set_active(active: bool) -> void:
	reset()
	var running := active and not _defeated
	visible = running
	process_mode = Node.PROCESS_MODE_INHERIT if running else Node.PROCESS_MODE_DISABLED
	_base.set_deferred("disabled", not running)


## Com a casca, só o fogo tem efeito, e ele quebra a casca. Sem a casca, cada
## tipo de golpe causa dano conforme o multiplicador.
func take_hit(amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if _state == State.DEAD:
		return
	var now := Engine.get_physics_frames()
	if _shell:
		if kind == Hit.Kind.FIRE:
			_shell = false
			_shell_break_tick = now
			_hit_tick = now
		else:
			_immune_tick = now
		return
	var factor := _factor(kind)
	if factor == 0:
		_immune_tick = now
		return
	health -= amount * factor
	_hit_tick = now
	if health <= 0:
		_die()


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	_update_state()
	match _state:
		State.APPROACH:
			velocity = _look * walk_speed
		State.CHARGE:
			# A investida segue pela física: só batidas mudam a velocidade.
			pass
		_:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_with_impacts()
	_keep_in_arena()
	if _state == State.CHARGE and not _charge_landed:
		_check_charge_hit()
	queue_redraw()


func _update_state() -> void:
	var now := Engine.get_physics_frames()
	if not _shell and now - _shell_break_tick >= GameMath.ticks(shell_regrow_time):
		_shell = true
	var to_player := _to_player()
	if to_player != Vector2.ZERO:
		_look = GameMath.snap_8(to_player)
	var elapsed := now - _state_tick
	match _state:
		State.DORMANT:
			if elapsed >= GameMath.ticks(wake_time):
				_enter(State.APPROACH)
		State.APPROACH:
			if elapsed >= GameMath.ticks(approach_time):
				_charge_direction = _look
				_enter(State.SLAM_WINDUP if _next_is_slam else State.CHARGE_WINDUP)
				_next_is_slam = not _next_is_slam
		State.SLAM_WINDUP:
			if elapsed >= GameMath.ticks(slam_windup_time):
				_slam()
				_enter(State.SLAM_RECOVER)
		State.SLAM_RECOVER:
			if elapsed >= GameMath.ticks(slam_recover_time):
				_enter(State.APPROACH)
		State.CHARGE_WINDUP:
			if elapsed >= GameMath.ticks(charge_windup_time):
				_charge_landed = false
				velocity = _charge_direction * charge_speed
				_enter(State.CHARGE)
		State.CHARGE:
			if elapsed >= GameMath.ticks(charge_time):
				_enter(State.CHARGE_RECOVER)
		State.CHARGE_RECOVER:
			if elapsed >= GameMath.ticks(charge_recover_time):
				_enter(State.APPROACH)


## Segura a base dentro da arena. As paredes já fazem isso, então na prática
## só a porta muda alguma coisa: o chefe não sai da sala atrás do personagem.
func _keep_in_arena() -> void:
	if not arena.has_area():
		return
	var half := (_base.shape as RectangleShape2D).size / 2.0
	var low := arena.position + half - _base.position
	var high := arena.end - half - _base.position
	global_position = global_position.clamp(low, high)


func _to_player() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	return (player.global_position - global_position) if player else Vector2.ZERO


## Pancada no chão: a onda nasce nos pés do chefe e corre pela sala.
func _slam() -> void:
	var wave := SHOCKWAVE_SCENE.instantiate() as Shockwave
	var layer := get_tree().get_first_node_in_group("floor_effects")
	if layer:
		layer.add_child(wave)
	else:
		get_parent().add_child(wave)
	wave.global_position = global_position


## Durante a investida, procura o personagem numa área um pouco maior que a
## base. Uma investida acerta no máximo uma vez.
func _check_charge_hit() -> void:
	var base_shape := _base.shape as RectangleShape2D
	_hurt_shape.size = base_shape.size + Vector2(4.0, 4.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _hurt_shape
	query.transform = Transform2D(0.0, _base.global_position)
	var excluded: Array[RID] = [get_rid()]
	query.exclude = excluded
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var target := result["collider"] as Player
		if target:
			target.take_hit(charge_damage, _charge_direction)
			_charge_landed = true


func _factor(kind: Hit.Kind) -> int:
	match kind:
		Hit.Kind.FIRE:
			return fire_factor
		Hit.Kind.BLAST:
			return blast_factor
		Hit.Kind.SHOCKWAVE:
			return 0
	return sword_factor


func _enter(state: State) -> void:
	_state = state
	_state_tick = Engine.get_physics_frames()


func _die() -> void:
	_defeated = true
	_enter(State.DEAD)
	velocity = Vector2.ZERO
	visible = false
	_base.set_deferred("disabled", true)
	defeated.emit()


## Visual provisório: azul claro com a casca, vinho sem ela. Amarelo piscando
## no aviso de cada ataque, mais escuro parado depois de atacar, branco ao
## levar dano e cinza quando o golpe não o afeta. A casca pisca antes de voltar.
func _draw() -> void:
	var now := Engine.get_physics_frames()
	var elapsed := now - _state_tick
	var color := SHELL_COLOR if _shell else CORE_COLOR
	var shake := Vector2.ZERO
	match _state:
		State.SLAM_WINDUP, State.CHARGE_WINDUP:
			var blink := posmod(elapsed, 8) < 4
			shake = Vector2(1.0 if blink else -1.0, 0.0)
			if blink:
				color = WINDUP_COLOR
		State.SLAM_RECOVER, State.CHARGE_RECOVER:
			color = color.darkened(0.3)
	if now - _hit_tick < FLASH_TICKS:
		color = HIT_COLOR
	elif now - _immune_tick < FLASH_TICKS:
		color = IMMUNE_COLOR
	var body := Rect2(Vector2(-BODY_SIZE.x / 2.0, -BODY_SIZE.y) + shake, BODY_SIZE)
	draw_rect(body, color)
	if _shell:
		draw_rect(Rect2(body.position + Vector2(4.0, 4.0), Vector2(3.0, 9.0)), SHINE_COLOR)
		draw_rect(Rect2(body.position + Vector2(9.0, 4.0), Vector2(2.0, 4.0)), SHINE_COLOR)
	else:
		var regrow_in := GameMath.ticks(shell_regrow_time) - (now - _shell_break_tick)
		if regrow_in <= GameMath.ticks(REGROW_WARNING_TIME) and posmod(regrow_in, 8) < 4:
			draw_rect(body, SHELL_COLOR, false, 2.0)
	var looking := _charge_direction if _state == State.CHARGE_WINDUP else _look
	var eyes := body.get_center() + Vector2(0.0, -4.0) + looking * 3.0
	for side: float in [-1.0, 1.0]:
		draw_rect(Rect2(eyes + Vector2(side * 5.0 - 1.5, -1.5), Vector2(3.0, 3.0)), EYE_COLOR)
	var bar_width := BODY_SIZE.x * float(maxi(health, 0)) / max_health
	draw_rect(Rect2(body.position + Vector2(0.0, -4.0), Vector2(bar_width, 2.0)), HEALTH_COLOR)
