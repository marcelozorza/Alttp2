class_name Enemy
extends MomentumBody
## Inimigo com um padrão de ataque legível.
##
## Encostar no inimigo não causa dano. Ele só machuca durante o bote. O ciclo
## é: percebe o personagem, se aproxima, prepara o bote (pisca em amarelo e
## treme, com a direção já travada), dá o bote em linha reta e fica um tempo
## parado e vulnerável. Quem desvia durante a preparação escapa.
##
## Quem tem granada também ataca de longe. Com o personagem longe do alcance do
## bote, ele para, ergue a granada acima da cabeça piscando em amarelo e joga
## onde o personagem está. Depois de jogar, espera um tempo até a próxima.
##
## Três jeitos mudam o padrão sem mudar o ciclo: quem voa (hover) sobe e
## desce no ar com a sombra no chão, quem tem vaivém (weave) se aproxima em
## ziguezague, e quem tem raiz (rooted) não sai do lugar, morde quem chega
## perto e volta ao ponto inicial.
##
## A massa decide o resto pela física. O ugly arremessa o personagem no bote e
## quase não se move com a espada. O minion voa longe com a espada e empurra
## pouco.
##
## Cada tipo de golpe tem um multiplicador de dano, que é a parte de pedra,
## papel e tesoura do combate. Multiplicador zero torna o inimigo imune: o
## golpe só o empurra, e ele pisca em cinza. A chama forte tem o próprio
## multiplicador, para que o gelo grosso ceda só a ela.

## Emitido ao morrer, com o próprio inimigo, para o capítulo contar as mortes.
signal died(enemy: Enemy)

enum State { IDLE, APPROACH, WINDUP, LUNGE, RECOVER, THROW_WINDUP, THROW_RECOVER, STAGGER, DEAD }

## Cores provisórias dos estados.
const WINDUP_COLOR := Color(1.0, 0.85, 0.2, 1.0)
const LUNGE_COLOR := Color(1.0, 0.2, 0.2, 1.0)
const HIT_COLOR := Color(1.0, 0.25, 0.25, 1.0)
const IMMUNE_COLOR := Color(0.55, 0.55, 0.6, 1.0)
## Tons sobre o desenho do inimigo, quando a cena tem um. Acima de 1, o tom
## clareia.
const RECOVER_TINT := Color(0.6, 0.6, 0.65, 1.0)
## Golpe recebido: o desenho pisca em vermelho (pedido de Marcelo em
## 2026-11-11). O vermelho passa de 1 para aparecer também no pelo escuro.
const HIT_TINT := Color(3.0, 0.45, 0.45, 1.0)
## Velocidade angular do vaivém, em radianos por tick.
const WEAVE_RATE := 0.2
## Quanto da distância até o ponto inicial o inimigo com raiz recupera por
## segundo.
const ROOT_PULL := 16.0
## Ticks de cada passo da caminhada, quando há quadros de passo.
const WALK_FRAME_TICKS := 8
## Ticks de cada passo do bote, mais rápido que andar.
const LUNGE_FRAME_TICKS := 4

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
## Multiplicador do dano da chama forte. Em geral o dobro do fogo comum. Um
## inimigo de gelo grosso tem fogo comum zero e chama forte maior que zero.
@export_range(0, 20, 1) var strong_fire_factor := 2
## Multiplicador do dano da explosão.
@export_range(0, 10, 1) var blast_factor := 1

@export_group("Desenhos")
## Quadros opcionais do desenho (nó Art). Com eles, o desenho acompanha o
## estado: os passos alternam ao andar, e cada ataque tem o seu quadro. O
## primeiro passo é também o quadro parado. Sem quadros, o desenho fica fixo.
## Primeiro inimigo com quadros: o minion, desenhado por Marcelo em
## 2026-11-06.
@export var walk_frames: Array[Texture2D] = []
## Quadros de costas, usados ao andar para cima. Vazio usa os de frente.
@export var back_frames: Array[Texture2D] = []
## Preparando o bote.
@export var windup_frame: Texture2D
## No bote.
@export var lunge_frame: Texture2D
## Recuperando depois do bote.
@export var recover_frame: Texture2D
## Atordoado por um golpe.
@export var hit_frame: Texture2D
## Quadros de lado, virados para a direita, usados ao andar para os lados. O
## desenho espelha para a esquerda. Vazio usa os de frente.
@export var side_frames: Array[Texture2D] = []
## Passos do bote por direção: de frente, de costas e de lado (para a
## direita). Com eles, o bote alterna os passos na direção do salto, a
## preparação usa o primeiro passo e lunge_frame fica sem uso.
@export var lunge_frames: Array[Texture2D] = []
@export var lunge_back_frames: Array[Texture2D] = []
@export var lunge_side_frames: Array[Texture2D] = []
## Erguendo a granada. Com ele, a granada não é desenhada à parte, porque já
## está na mão do desenho.
@export var throw_windup_frame: Texture2D
## Logo depois de jogar a granada. Vazio usa recover_frame.
@export var throw_recover_frame: Texture2D
## Erguendo e logo depois de jogar, por direção: de frente, de costas e de
## lado (para a direita). Com três quadros, valem no lugar dos dois acima.
@export var throw_windup_frames: Array[Texture2D] = []
@export var throw_recover_frames: Array[Texture2D] = []
## Ligado, cada quadro tem o próprio tamanho e é desenhado centrado nos pés,
## com a base do desenho feet_offset pixels abaixo da origem. Desligado, vale
## o offset do nó Art. O lobo (ugly) usa, desde 2026-11-08.
@export var anchor_feet := false
@export_range(-16, 16, 1) var feet_offset := 2

@export_group("Comportamento")
## Distância, em pixels, a partir da qual percebe o personagem.
@export_range(0.0, 800.0, 1.0) var sight_range := 400.0
## Distância, em pixels, em que para de se aproximar e prepara o bote.
@export_range(0.0, 400.0, 1.0) var attack_range := 88.0
## Velocidade de aproximação, em pixels por segundo.
@export_range(0.0, 400.0, 1.0) var walk_speed := 80.0
## Segundos preparando o bote. É o aviso para o jogador.
@export_range(0.0, 3.0, 0.05) var windup_time := 0.6
## Velocidade do bote, em pixels por segundo.
@export_range(0.0, 1200.0, 1.0) var lunge_speed := 360.0
## Duração do bote, em segundos.
@export_range(0.0, 1.0, 0.01) var lunge_time := 0.25
## Segundos parado e vulnerável depois do bote.
@export_range(0.0, 3.0, 0.05) var recover_time := 0.8
## Dano do bote.
@export_range(1, 10, 1) var damage := 1
## Ligado, voa: o desenho sobe e desce no ar, com a sombra no chão.
@export var hover := false
## Vaivém lateral ao se aproximar, em pixels por segundo. Zero anda reto.
@export_range(0.0, 400.0, 1.0) var weave := 0.0
## Ligado, tem raiz: não sai do lugar, ataca quem chega perto e volta ao
## ponto inicial depois do bote.
@export var rooted := false
## Ligado, não dá o bote: avança devagar e sem parar, e machuca ao encostar.
## Pedido de Marcelo em 2026-11-06 para o tatu de pedra.
@export var contact_damage := false

@export_group("Granada")
## Granada que ele joga de longe. Vazio, ele não joga nada.
@export var grenade_scene: PackedScene
## Distância mínima, em pixels, para jogar a granada. Mais perto, ele segue se
## aproximando para o bote.
@export_range(0.0, 800.0, 1.0) var throw_min_range := 128.0
## Distância máxima, em pixels, para jogar a granada.
@export_range(0.0, 800.0, 1.0) var throw_max_range := 320.0
## Segundos com a granada erguida antes de jogar. É o aviso para o jogador.
@export_range(0.0, 3.0, 0.05) var throw_windup_time := 0.6
## Segundos parado depois de jogar.
@export_range(0.0, 3.0, 0.05) var throw_recover_time := 0.5
## Segundos entre uma granada e a próxima, contados de quando ela sai da mão.
@export_range(0.0, 10.0, 0.1) var throw_cooldown := 2.5
## Segundos até poder jogar a primeira, contados de quando ele volta ao ponto
## inicial, por exemplo quando o personagem entra na sala.
@export_range(0.0, 10.0, 0.1) var first_throw_delay := 1.0

var health := 0

var _state := State.IDLE
var _state_tick := 0
var _approach_direction := Vector2.ZERO
var _lunge_direction := Vector2.ZERO
var _look_direction := Vector2.DOWN
var _lunge_landed := false
var _hit_tick := -1000
var _immune_tick := -1000
var _next_throw_tick := 0
var _hurt_shape := RectangleShape2D.new()

@onready var _home := global_position
@onready var _base: CollisionShape2D = $Base
@onready var _body: ColorRect = $Body
@onready var _body_color: Color = _body.color
@onready var _body_rest_position: Vector2 = _body.position
@onready var _eye: ColorRect = $Eye
@onready var _health_bar: ColorRect = $HealthBar
@onready var _health_bar_width: float = _health_bar.size.x
## Desenho do inimigo, opcional. Sem ele, o corpo e o olho provisórios
## aparecem no lugar.
@onready var _art: Sprite2D = get_node_or_null("Art")


func _ready() -> void:
	# Camada dos inimigos comuns, por cima da qual o personagem pula.
	collision_layer = Layers.ENEMY
	collision_mask = Layers.SCENERY | Layers.ENEMY
	health = max_health
	_next_throw_tick = Clock.tick + GameMath.ticks(first_throw_delay)


## Recebe um golpe. O empurrão vem separado, pela física.
func take_hit(amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if _state == State.DEAD:
		return
	var factor := _factor(kind)
	if factor == 0:
		_immune_tick = Clock.tick
		Sfx.play(&"immune")
		return
	health -= amount * factor
	_hit_tick = Clock.tick
	if health <= 0:
		Sfx.play(&"enemy_die")
		_die()
		return
	Sfx.play(&"enemy_hit")
	if stagger_time > 0.0:
		_enter(State.STAGGER)


## Volta ao ponto inicial, com a vida cheia e parado.
func reset() -> void:
	queue_redraw()
	health = max_health
	global_position = _home
	velocity = Vector2.ZERO
	visible = true
	_base.set_deferred("disabled", false)
	_next_throw_tick = Clock.tick + GameMath.ticks(first_throw_delay)
	_enter(State.IDLE)


## Derrotado, à espera de reaparecer ou de a sala ser reposta.
func is_dead() -> bool:
	return _state == State.DEAD


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
				velocity = _approach_direction * walk_speed + _weave_velocity()
			State.LUNGE:
				# O bote segue pela física: só batidas mudam a velocidade.
				pass
			_:
				velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if rooted and _state != State.LUNGE:
			velocity = (_home - global_position) * ROOT_PULL
		move_with_impacts()
		if _state == State.LUNGE and not _lunge_landed:
			_check_lunge_hit()
		elif _state == State.APPROACH and contact_damage:
			_check_contact_hit()
	_update_visuals()


func _update_state() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var to_player := (player.global_position - global_position) if player else Vector2.ZERO
	var in_sight := player != null and to_player.length() <= sight_range
	var elapsed := Clock.tick - _state_tick
	match _state:
		State.IDLE:
			if in_sight:
				_enter(State.APPROACH)
		State.APPROACH:
			_approach_direction = GameMath.snap_8(to_player)
			_look_direction = _approach_direction
			if not in_sight:
				_enter(State.IDLE)
			elif to_player.length() <= attack_range and not contact_damage:
				_lunge_direction = GameMath.snap_8(to_player)
				_look_direction = _lunge_direction
				_enter(State.WINDUP)
			elif _can_throw(to_player.length()):
				_enter(State.THROW_WINDUP)
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
		State.THROW_WINDUP:
			_look_direction = GameMath.snap_8(to_player)
			if elapsed >= GameMath.ticks(throw_windup_time):
				if player:
					_throw(player.global_position)
				_enter(State.THROW_RECOVER)
		State.THROW_RECOVER:
			if elapsed >= GameMath.ticks(throw_recover_time):
				_enter(State.APPROACH)
		State.STAGGER:
			if elapsed >= GameMath.ticks(stagger_time):
				_enter(State.APPROACH)
		State.DEAD:
			if respawn_time > 0.0 and elapsed >= GameMath.ticks(respawn_time):
				reset()


## Vaivém perpendicular à aproximação, para o inimigo que voa em ziguezague.
func _weave_velocity() -> Vector2:
	if weave <= 0.0:
		return Vector2.ZERO
	return _approach_direction.orthogonal() * sin(Clock.tick * WEAVE_RATE) * weave


## Altura do desenho acima dos pés, para quem voa.
func _hover_height() -> float:
	if not hover:
		return 0.0
	return 6.0 + sin(Clock.tick * 0.15) * 4.0


## Durante o bote, procura o personagem numa área um pouco maior que a base.
## Um bote acerta no máximo uma vez.
func _check_lunge_hit() -> void:
	var target := Hit.player_in_reach(self, _base, _hurt_shape)
	if target:
		target.take_hit(damage, _lunge_direction)
		_lunge_landed = true


## Quem machuca ao encostar acerta sempre que toca o personagem. A
## invencibilidade depois do dano é o que espaça os golpes.
func _check_contact_hit() -> void:
	var target := Hit.player_in_reach(self, _base, _hurt_shape)
	if target:
		target.take_hit(damage, _approach_direction)


## Joga só quem tem granada, depois da espera desde a última, longe o bastante
## para não preferir o bote e perto o bastante para alcançar.
func _can_throw(distance: float) -> bool:
	return (
		grenade_scene != null
		and Clock.tick >= _next_throw_tick
		and distance >= throw_min_range
		and distance <= throw_max_range
	)


## A granada sai da mão, acima da cabeça, e cai onde o personagem está agora.
## Ela fica com os efeitos do chão, que somem ao trocar de sala.
func _throw(target: Vector2) -> void:
	_next_throw_tick = Clock.tick + GameMath.ticks(throw_cooldown)
	Sfx.play(&"grenade_throw")
	var grenade := grenade_scene.instantiate() as Grenade
	var layer := get_tree().get_first_node_in_group("floor_effects")
	if layer:
		layer.add_child(grenade)
	else:
		get_parent().add_child(grenade)
	grenade.launch(global_position, -_held_grenade_rect().get_center().y, target)


## Granada erguida acima da cabeça, sem o tremor, relativa à origem nos pés.
func _held_grenade_rect() -> Rect2:
	var size := Grenade.BALL_SIZE
	var center_x := _body_rest_position.x + _body.size.x / 2.0
	var bottom := _health_bar.position.y - 4.0
	return Rect2(Vector2(center_x - size.x / 2.0, bottom - size.y), size)


## Troca de estado. A preparação do bote e da granada e o bote têm som, para
## o jogador ouvir o aviso mesmo olhando para outro lado.
func _enter(state: State) -> void:
	if state != _state:
		match state:
			State.WINDUP, State.THROW_WINDUP:
				Sfx.play(&"enemy_windup")
			State.LUNGE:
				Sfx.play(&"enemy_lunge")
	_state = state
	_state_tick = Clock.tick


func _die() -> void:
	_enter(State.DEAD)
	queue_redraw()
	velocity = Vector2.ZERO
	# O inimigo some na hora, e a nuvem fica no lugar dele.
	if _art:
		DeathPuff.spawn(self, _art.texture, _art.position + _art.offset, _art.flip_h)
	else:
		DeathPuff.spawn(self, null, Vector2.ZERO, false)
	visible = false
	_base.set_deferred("disabled", true)
	died.emit(self)


func _factor(kind: Hit.Kind) -> int:
	return Hit.factor(kind, sword_factor, fire_factor, strong_fire_factor, blast_factor)


## Amarelo piscando na preparação do bote e da granada, vermelho no bote, mais
## escuro parado depois de atacar, branco ao ser atingido e cinza quando o golpe
## não o afeta. Com desenho, as cores viram tons sobre ele. Sem desenho, o
## corpo provisório muda de cor e o olho mostra para onde ele vai. A barra
## acima mostra a vida.
func _update_visuals() -> void:
	var elapsed := Clock.tick - _state_tick
	var color := _body_color
	var tint := Color.WHITE
	var shake := Vector2.ZERO
	match _state:
		State.WINDUP, State.THROW_WINDUP:
			var blink := posmod(elapsed, 8) < 4
			color = WINDUP_COLOR if blink else _body_color
			tint = WINDUP_COLOR if blink else Color.WHITE
			shake = Vector2(2.0 if blink else -2.0, 0.0)
		State.LUNGE:
			color = LUNGE_COLOR
			tint = LUNGE_COLOR
		State.RECOVER, State.THROW_RECOVER:
			color = _body_color.darkened(0.35)
			tint = RECOVER_TINT
	if Clock.tick - _hit_tick < GameMath.ticks(hit_flash_time):
		color = HIT_COLOR
		tint = HIT_TINT
	elif Clock.tick - _immune_tick < GameMath.ticks(hit_flash_time):
		color = IMMUNE_COLOR
		tint = IMMUNE_COLOR
	if _art:
		_body.visible = false
		_eye.visible = false
		_art.modulate = tint
		_art.position = shake + Vector2(0.0, -_hover_height()).round()
		var frame := _frame_for_state()
		if frame:
			_art.texture = frame
			_art.flip_h = _uses_side_frame() and _look_direction.x < 0.0
			if anchor_feet:
				var size := frame.get_size()
				_art.offset = Vector2(-floorf(size.x / 2.0), feet_offset - size.y)
	_body.color = color
	_body.position = _body_rest_position + shake
	var half := (_body.size - _eye.size) / 2.0
	var body_center := _body.position + _body.size / 2.0
	_eye.position = body_center + _look_direction * half - _eye.size / 2.0
	_health_bar.size.x = _health_bar_width * float(maxi(health, 0)) / max_health
	if grenade_scene or hover:
		queue_redraw()


## Escolhe o quadro do desenho pelo estado. Sem quadros, devolve nulo e o
## desenho fica como está. Andando, alterna os passos. De costas quando olha
## para cima e há quadros de costas, e de lado quando olha mais para o lado e
## há quadros de lado.
func _frame_for_state() -> Texture2D:
	if walk_frames.is_empty():
		return null
	var special := _state_frame()
	if special:
		return special
	var frames := _directional(walk_frames, back_frames, side_frames)
	var step := 0
	if _state == State.APPROACH and velocity.length() > 2.0:
		step = posmod(floori(float(Clock.tick) / WALK_FRAME_TICKS), frames.size())
	return frames[step]


## Quadro próprio do estado de ataque ou de golpe, ou nulo para andar.
func _state_frame() -> Texture2D:
	var frame: Texture2D = null
	match _state:
		State.STAGGER:
			frame = hit_frame
		State.WINDUP:
			frame = windup_frame
			if not lunge_frames.is_empty():
				frame = _directional(lunge_frames, lunge_back_frames, lunge_side_frames)[0]
		State.THROW_WINDUP:
			frame = throw_windup_frame if throw_windup_frame else windup_frame
			if throw_windup_frames.size() == 3:
				frame = throw_windup_frames[_direction_index()]
		State.LUNGE:
			frame = lunge_frame
			if not lunge_frames.is_empty():
				var lunge := _directional(lunge_frames, lunge_back_frames, lunge_side_frames)
				var lunge_step := floori(float(Clock.tick - _state_tick) / LUNGE_FRAME_TICKS)
				frame = lunge[posmod(lunge_step, lunge.size())]
		State.THROW_RECOVER:
			frame = throw_recover_frame if throw_recover_frame else recover_frame
			if throw_recover_frames.size() == 3:
				frame = throw_recover_frames[_direction_index()]
		State.RECOVER:
			frame = recover_frame
	return frame


## Quadros para a direção do olhar: de lado quando olha mais para o lado, de
## costas quando olha para cima, de frente no resto. Lista vazia cai na de
## frente.
func _directional(
	front: Array[Texture2D], back: Array[Texture2D], side: Array[Texture2D]
) -> Array[Texture2D]:
	if not side.is_empty() and absf(_look_direction.x) > absf(_look_direction.y):
		return side
	if not back.is_empty() and _look_direction.y < 0.0:
		return back
	return front


## Índice da direção do olhar numa lista de frente, de costas e de lado.
func _direction_index() -> int:
	if absf(_look_direction.x) > absf(_look_direction.y):
		return 2
	return 1 if _look_direction.y < 0.0 else 0


## O quadro de agora é de lado, e por isso espelha quando olha para a esquerda.
func _uses_side_frame() -> bool:
	if absf(_look_direction.x) <= absf(_look_direction.y):
		return false
	match _state:
		State.APPROACH, State.IDLE:
			return not side_frames.is_empty()
		State.WINDUP, State.LUNGE:
			return not lunge_side_frames.is_empty()
		State.THROW_WINDUP:
			return throw_windup_frames.size() == 3
		State.THROW_RECOVER:
			return throw_recover_frames.size() == 3
	return false


## A sombra de quem voa fica no chão, e a granada erguida aparece durante o
## aviso e treme junto com o corpo.
func _draw() -> void:
	if _state != State.DEAD:
		var width := _body.size.x
		var center := Vector2.ZERO
		if _art and _art.texture:
			var used := GroundShadow.used_rect(_art.texture)
			var middle := used.position.x + used.size.x / 2.0
			if _art.flip_h:
				middle = _art.texture.get_width() - middle
			width = used.size.x
			center = Vector2(_art.offset.x + middle, _art.offset.y + used.end.y - 3.0)
		GroundShadow.draw(self, center, width)
	if (
		_state != State.THROW_WINDUP
		or (_art and (throw_windup_frame or not throw_windup_frames.is_empty()))
	):
		return
	var rect := _held_grenade_rect()
	rect.position += _body.position - _body_rest_position
	draw_rect(rect, Player.SWORD_LOCK_COLOR)
