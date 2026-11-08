class_name Boss
extends MomentumBody
## Chefe do tutorial, o antigo capítulo 1: o guardião de gelo. É o exame das três ferramentas.
##
## Coberto pela casca de gelo, ele ignora latido e bomba: só a chama quebra a
## casca, que volta depois de shell_regrow_time. Sem a casca, o núcleo apanha
## do latido e mais ainda da bomba. Os ataques são sempre avisados, piscando em
## amarelo. A pancada no chão solta uma onda que só se evita no ar, com a mola.
## A investida corre em linha reta na direção travada durante o aviso.
##
## Com thick_shell ligado, ele é o guardião antigo, o chefe do capítulo 3: a
## casca é de gelo grosso, na paleta do gelo grosso, e só a chama forte a
## quebra. A chama comum só o faz piscar em cinza, como o gelo grosso do mapa.
##
## Com stone_shell e tall_waves ligados, ele é o colosso, o chefe do capítulo
## 4: a casca é de pedra rachada e só a bomba a abre, e a pancada solta a onda
## alta, que só o pulo da mola forte passa. É o exame da mola forte.
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
const SHELL_TEXTURE := preload("res://art/guardian_shell.svg")
const THICK_SHELL_TEXTURE := preload("res://art/guardian_thick_shell.svg")
const CORE_TEXTURE := preload("res://art/guardian_core.svg")
const COLOSSUS_SHELL_TEXTURE := preload("res://art/colossus_shell.svg")
const COLOSSUS_CORE_TEXTURE := preload("res://art/colossus_core.svg")
## Quanto o desenho desce abaixo da origem, nos pés.
const ART_BELOW_FEET := 0.0
## Tons sobre o desenho. Acima de 1, o tom clareia.
const RECOVER_TINT := Color(0.65, 0.65, 0.7, 1.0)
const HIT_TINT := Color(2.0, 2.0, 2.0, 1.0)
const WINDUP_COLOR := Color(1.0, 0.85, 0.2, 1.0)
const IMMUNE_COLOR := Color(0.55, 0.55, 0.6, 1.0)
const HEALTH_COLOR := Color(0.9, 0.3, 0.35, 1.0)
## Segundos antes de a casca voltar em que ela pisca, como aviso.
const REGROW_WARNING_TIME := 1.0
## Ticks do brilho de dano e de imunidade.
const FLASH_TICKS := 6

@export_group("Vida")
## Pontos de vida do núcleo.
@export_range(1, 60, 1) var max_health := 12
## Segundos até a casca de gelo voltar depois de quebrada.
@export_range(0.5, 20.0, 0.5) var shell_regrow_time := 6.0
## Ligado, a casca é de gelo grosso e só a chama forte a quebra.
@export var thick_shell := false
## Ligado, a casca é de pedra rachada e só a explosão da bomba a abre. É o
## colosso, o chefe do capítulo 3, a pedreira.
@export var stone_shell := false
## Ligada, a pancada solta a onda alta, que só o pulo da mola forte passa.
@export var tall_waves := false
## Multiplicador do dano do latido, sem a casca.
@export_range(0, 10, 1) var bark_factor := 1
## Multiplicador do dano do fogo, sem a casca.
@export_range(0, 10, 1) var fire_factor := 1
## Multiplicador do dano da chama forte, sem a casca.
@export_range(0, 20, 1) var strong_fire_factor := 2
## Multiplicador do dano da explosão, sem a casca.
@export_range(0, 10, 1) var blast_factor := 3

@export_group("Comportamento")
## Segundos parado depois que o personagem entra na sala.
@export_range(0.0, 3.0, 0.1) var wake_time := 1.0
## Velocidade de aproximação, em pixels por segundo.
@export_range(0.0, 400.0, 1.0) var walk_speed := 56.0
## Segundos se aproximando entre um ataque e outro.
@export_range(0.1, 5.0, 0.1) var approach_time := 1.6
## Segundos de aviso antes da pancada no chão.
@export_range(0.1, 3.0, 0.05) var slam_windup_time := 0.9
## Segundos parado depois da pancada.
@export_range(0.1, 5.0, 0.1) var slam_recover_time := 1.4
## Segundos de aviso antes da investida, com a direção já travada.
@export_range(0.1, 3.0, 0.05) var charge_windup_time := 0.7
## Velocidade da investida, em pixels por segundo.
@export_range(0.0, 1200.0, 1.0) var charge_speed := 420.0
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
	# Um chefe é sólido também para o personagem no ar.
	collision_layer = Layers.SCENERY
	collision_mask = Layers.SCENERY | Layers.ENEMY | Layers.AIR
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
func take_hit(amount: int, _direction: Vector2, kind := Hit.Kind.BARK) -> void:
	if _state == State.DEAD:
		return
	var now := Clock.tick
	if _shell:
		if _breaks_shell(kind):
			_shell = false
			_shell_break_tick = now
			_hit_tick = now
			Sfx.play(&"armor_break" if stone_shell else &"shell_break")
		else:
			_immune_tick = now
			Sfx.play(&"immune")
		return
	_take_damage(amount, kind)


## A casca comum cede a qualquer fogo. A casca grossa, só à chama forte. A
## casca de pedra, só à explosão.
func _breaks_shell(kind: Hit.Kind) -> bool:
	if stone_shell:
		return kind == Hit.Kind.BLAST
	if thick_shell:
		return kind == Hit.Kind.STRONG_FIRE
	return Hit.is_fire(kind)


## Dano no chefe já sem proteção, conforme o multiplicador de cada golpe.
func _take_damage(amount: int, kind: Hit.Kind) -> void:
	var now := Clock.tick
	var factor := _factor(kind)
	if factor == 0:
		_immune_tick = now
		Sfx.play(&"immune")
		return
	health -= amount * factor
	_hit_tick = now
	if health <= 0:
		Sfx.play(&"boss_die")
		_die()
	else:
		Sfx.play(&"boss_hit")


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
	var now := Clock.tick
	if not _shell and now - _shell_break_tick >= GameMath.ticks(shell_regrow_time):
		_shell = true
		Sfx.play(&"shell_regrow")
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
	Sfx.play(&"boss_slam")
	var wave := SHOCKWAVE_SCENE.instantiate() as Shockwave
	wave.tall = tall_waves
	var layer := get_tree().get_first_node_in_group("floor_effects")
	if layer:
		layer.add_child(wave)
	else:
		get_parent().add_child(wave)
	wave.global_position = global_position


## Durante a investida, procura o personagem numa área um pouco maior que a
## base. Uma investida acerta no máximo uma vez.
func _check_charge_hit() -> void:
	var target := Hit.player_in_reach(self, _base, _hurt_shape, false)
	if target:
		target.take_hit(charge_damage, _charge_direction)
		_charge_landed = true


func _factor(kind: Hit.Kind) -> int:
	return Hit.factor(kind, bark_factor, fire_factor, strong_fire_factor, blast_factor)


## Desenho da casca: de gelo comum, de gelo grosso ou de pedra.
func _shell_texture() -> Texture2D:
	if stone_shell:
		return COLOSSUS_SHELL_TEXTURE
	return THICK_SHELL_TEXTURE if thick_shell else SHELL_TEXTURE


## Desenho do núcleo exposto.
func _core_texture() -> Texture2D:
	return COLOSSUS_CORE_TEXTURE if stone_shell else CORE_TEXTURE


## Canto do desenho em relação à origem, nos pés: centrado e terminando um
## pouco abaixo dos pés.
func _texture_offset(texture: Texture2D) -> Vector2:
	return Vector2(-texture.get_width() / 2.0, ART_BELOW_FEET - texture.get_height())


## Verdadeiro para desenhar espelhado, virado para a esquerda. Os chefes de
## frente nunca viram; a sentinela, de perfil, vira para o lado do personagem.
func _faces_left() -> bool:
	return false


## Troca de estado. O despertar, os avisos e a investida têm som.
func _enter(state: State) -> void:
	if state != _state:
		match state:
			State.APPROACH:
				if _state == State.DORMANT:
					Sfx.play(&"boss_wake")
			State.SLAM_WINDUP, State.CHARGE_WINDUP:
				Sfx.play(&"boss_windup")
			State.CHARGE:
				Sfx.play(&"boss_charge")
	_state = state
	_state_tick = Clock.tick


func _die() -> void:
	_defeated = true
	_enter(State.DEAD)
	velocity = Vector2.ZERO
	visible = false
	_base.set_deferred("disabled", true)
	defeated.emit()


## O desenho mostra a casca de gelo ou o núcleo vinho. Amarelo piscando no
## aviso de cada ataque, mais escuro parado depois de atacar, branco ao levar
## dano e cinza quando o golpe não o afeta. A casca pisca antes de voltar.
func _draw() -> void:
	var now := Clock.tick
	var elapsed := now - _state_tick
	var tint := Color.WHITE
	var shake := Vector2.ZERO
	match _state:
		State.SLAM_WINDUP, State.CHARGE_WINDUP:
			var blink := posmod(elapsed, 8) < 4
			shake = Vector2(2.0 if blink else -2.0, 0.0)
			if blink:
				tint = WINDUP_COLOR
		State.SLAM_RECOVER, State.CHARGE_RECOVER:
			tint = RECOVER_TINT
	if now - _hit_tick < FLASH_TICKS:
		tint = HIT_TINT
	elif now - _immune_tick < FLASH_TICKS:
		tint = IMMUNE_COLOR
	var texture := _shell_texture() if _shell else _core_texture()
	if not _shell:
		var regrow_in := GameMath.ticks(shell_regrow_time) - (now - _shell_break_tick)
		if regrow_in <= GameMath.ticks(REGROW_WARNING_TIME) and posmod(regrow_in, 8) < 4:
			texture = _shell_texture()
	var origin := _texture_offset(texture) + shake
	if _faces_left():
		var size := texture.get_size()
		draw_texture_rect(
			texture, Rect2(origin + Vector2(size.x, 0.0), size * Vector2(-1.0, 1.0)), false, tint
		)
	else:
		draw_texture(texture, origin, tint)
	var bar_width := texture.get_width() * float(maxi(health, 0)) / max_health
	draw_rect(Rect2(origin + Vector2(0.0, -8.0), Vector2(bar_width, 4.0)), HEALTH_COLOR)
