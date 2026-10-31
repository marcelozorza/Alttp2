class_name Enemy
extends MomentumBody
## Inimigo com um padrão de ataque legível.
##
## Encostar no inimigo não causa dano. Ele só machuca durante o bote. O ciclo
## é: percebe o personagem, se aproxima, prepara o bote (pisca em amarelo e
## treme, com a direção já travada), dá o bote em linha reta e fica um tempo
## parado e vulnerável. Quem desvia durante a preparação escapa.
##
## A massa decide o resto pela física. O inimigo pesado arremessa o personagem
## no bote e quase não se move com a espada. O leve voa longe com a espada e
## empurra pouco.
##
## Cada tipo de golpe tem um multiplicador de dano, que é a parte de pedra,
## papel e tesoura do combate. Multiplicador zero torna o inimigo imune: o
## golpe só o empurra, e ele pisca em cinza.

enum State { IDLE, APPROACH, WINDUP, LUNGE, RECOVER, STAGGER, DEAD }

## Cores provisórias dos estados.
const WINDUP_COLOR := Color(1.0, 0.85, 0.2, 1.0)
const LUNGE_COLOR := Color(1.0, 0.2, 0.2, 1.0)
const HIT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const IMMUNE_COLOR := Color(0.55, 0.55, 0.6, 1.0)

@export_group("Vida")
## Pontos de vida.
@export_range(1, 50, 1) var max_health := 3
## Segundos piscando em branco ao ser atingido.
@export_range(0.0, 0.5, 0.01) var hit_flash_time := 0.1
## Segundos atordoado e sem controle ao ser atingido. Zero significa que o
## golpe não interrompe o que ele estiver fazendo.
@export_range(0.0, 2.0, 0.05) var stagger_time := 0.3
## Segundos até reaparecer no ponto inicial depois de derrotado. Zero desliga.
## No capítulo, os inimigos só voltam quando o personagem entra de novo na sala.
@export_range(0.0, 10.0, 0.1) var respawn_time := 3.0
## Multiplicador do dano da espada.
@export_range(0, 10, 1) var sword_factor := 1
## Multiplicador do dano do fogo.
@export_range(0, 10, 1) var fire_factor := 1
## Multiplicador do dano da explosão.
@export_range(0, 10, 1) var blast_factor := 1

@export_group("Comportamento")
## Distância, em pixels, a partir da qual percebe o personagem.
@export_range(0.0, 400.0, 1.0) var sight_range := 200.0
## Distância, em pixels, em que para de se aproximar e prepara o bote.
@export_range(0.0, 200.0, 1.0) var attack_range := 44.0
## Velocidade de aproximação, em pixels por segundo.
@export_range(0.0, 200.0, 1.0) var walk_speed := 40.0
## Segundos preparando o bote. É o aviso para o jogador.
@export_range(0.0, 3.0, 0.05) var windup_time := 0.6
## Velocidade do bote, em pixels por segundo.
@export_range(0.0, 600.0, 1.0) var lunge_speed := 180.0
## Duração do bote, em segundos.
@export_range(0.0, 1.0, 0.01) var lunge_time := 0.25
## Segundos parado e vulnerável depois do bote.
@export_range(0.0, 3.0, 0.05) var recover_time := 0.8
## Dano do bote.
@export_range(1, 10, 1) var damage := 1

var health := 0

var _state := State.IDLE
var _state_tick := 0
var _approach_direction := Vector2.ZERO
var _lunge_direction := Vector2.ZERO
var _look_direction := Vector2.DOWN
var _lunge_landed := false
var _hit_tick := -1000
var _immune_tick := -1000
var _hurt_shape := RectangleShape2D.new()

@onready var _home := global_position
@onready var _base: CollisionShape2D = $Base
@onready var _body: ColorRect = $Body
@onready var _body_color: Color = _body.color
@onready var _body_rest_position: Vector2 = _body.position
@onready var _eye: ColorRect = $Eye
@onready var _health_bar: ColorRect = $HealthBar
@onready var _health_bar_width: float = _health_bar.size.x


func _ready() -> void:
	health = max_health


## Recebe um golpe. O empurrão vem separado, pela física.
func take_hit(amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if _state == State.DEAD:
		return
	var factor := _factor(kind)
	if factor == 0:
		_immune_tick = Engine.get_physics_frames()
		return
	health -= amount * factor
	_hit_tick = Engine.get_physics_frames()
	if health <= 0:
		_die()
	elif stagger_time > 0.0:
		_enter(State.STAGGER)


## Volta ao ponto inicial, com a vida cheia e parado.
func reset() -> void:
	health = max_health
	global_position = _home
	velocity = Vector2.ZERO
	visible = true
	_base.set_deferred("disabled", false)
	_enter(State.IDLE)


## Liga ou desliga o inimigo quando o personagem entra ou sai da sala dele.
## Nos dois casos ele volta ao ponto inicial. Desligado, ele não bloqueia nada.
func set_active(active: bool) -> void:
	reset()
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	_base.set_deferred("disabled", not active)


func _physics_process(delta: float) -> void:
	_update_state()
	if _state != State.DEAD:
		match _state:
			State.APPROACH:
				velocity = _approach_direction * walk_speed
			State.LUNGE:
				# O bote segue pela física: só batidas mudam a velocidade.
				pass
			_:
				velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_with_impacts()
		if _state == State.LUNGE and not _lunge_landed:
			_check_lunge_hit()
	_update_visuals()


func _update_state() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var to_player := (player.global_position - global_position) if player else Vector2.ZERO
	var in_sight := player != null and to_player.length() <= sight_range
	var elapsed := Engine.get_physics_frames() - _state_tick
	match _state:
		State.IDLE:
			if in_sight:
				_enter(State.APPROACH)
		State.APPROACH:
			_approach_direction = GameMath.snap_8(to_player)
			_look_direction = _approach_direction
			if not in_sight:
				_enter(State.IDLE)
			elif to_player.length() <= attack_range:
				_lunge_direction = GameMath.snap_8(to_player)
				_look_direction = _lunge_direction
				_enter(State.WINDUP)
		State.WINDUP:
			if elapsed >= GameMath.ticks(windup_time):
				_lunge_landed = false
				velocity = _lunge_direction * lunge_speed
				_enter(State.LUNGE)
		State.LUNGE:
			if elapsed >= GameMath.ticks(lunge_time):
				_enter(State.RECOVER)
		State.RECOVER:
			if elapsed >= GameMath.ticks(recover_time):
				_enter(State.APPROACH)
		State.STAGGER:
			if elapsed >= GameMath.ticks(stagger_time):
				_enter(State.APPROACH)
		State.DEAD:
			if respawn_time > 0.0 and elapsed >= GameMath.ticks(respawn_time):
				reset()


## Durante o bote, procura o personagem numa área um pouco maior que a base.
## Um bote acerta no máximo uma vez.
func _check_lunge_hit() -> void:
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
			target.take_hit(damage, _lunge_direction)
			_lunge_landed = true


func _enter(state: State) -> void:
	_state = state
	_state_tick = Engine.get_physics_frames()


func _die() -> void:
	_enter(State.DEAD)
	velocity = Vector2.ZERO
	visible = false
	_base.set_deferred("disabled", true)


func _factor(kind: Hit.Kind) -> int:
	match kind:
		Hit.Kind.FIRE:
			return fire_factor
		Hit.Kind.BLAST:
			return blast_factor
		Hit.Kind.SHOCKWAVE:
			return 0
	return sword_factor


## Visual provisório: amarelo piscando na preparação, vermelho no bote, mais
## escuro na recuperação, branco ao ser atingido e cinza quando o golpe não o
## afeta. O olho mostra para onde ele vai e a barra acima mostra a vida.
func _update_visuals() -> void:
	var elapsed := Engine.get_physics_frames() - _state_tick
	var color := _body_color
	var shake := Vector2.ZERO
	match _state:
		State.WINDUP:
			var blink := posmod(elapsed, 8) < 4
			color = WINDUP_COLOR if blink else _body_color
			shake = Vector2(1.0 if blink else -1.0, 0.0)
		State.LUNGE:
			color = LUNGE_COLOR
		State.RECOVER:
			color = _body_color.darkened(0.35)
	if Engine.get_physics_frames() - _hit_tick < GameMath.ticks(hit_flash_time):
		color = HIT_COLOR
	elif Engine.get_physics_frames() - _immune_tick < GameMath.ticks(hit_flash_time):
		color = IMMUNE_COLOR
	_body.color = color
	_body.position = _body_rest_position + shake
	var half := (_body.size - _eye.size) / 2.0
	var body_center := _body.position + _body.size / 2.0
	_eye.position = body_center + _look_direction * half - _eye.size / 2.0
	_health_bar.size.x = _health_bar_width * float(maxi(health, 0)) / max_health
