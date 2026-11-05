class_name Player
extends MomentumBody
## Personagem controlado pelo jogador.
##
## O movimento roda em _physics_process, que o Godot executa em passo fixo
## (60 vezes por segundo, padrão de Physics > Common > Physics Ticks Per Second).
## Assim o movimento é idêntico em qualquer máquina e taxa de quadros, condição
## para que técnicas avançadas de precisão sejam reproduzíveis. Pelo mesmo
## motivo, todos os tempos (duplo toque, equilíbrio, queda) são contados em ticks.
##
## O movimento é sempre em 8 direções, inclusive no analógico.
##
## A origem do nó fica no centro dos pés, e a colisão cobre só essa área.
## O corpo desenhado se estende para cima, o que permite passar por trás de
## objetos na perspectiva 3/4.
##
## Batidas seguem a física de MomentumBody. Uma batida forte, como correr
## contra uma parede, arremessa o personagem para trás, e ele só recupera o
## controle quando o atrito reduz a velocidade abaixo de recover_speed.
##
## O jogo é feito para o controle, com a espada e cada ferramenta no seu
## próprio botão, definidos no mapa de entrada do projeto. O botão de uma
## ferramenta não faz nada antes de o personagem tê-la. A chama e a bomba têm
## cargas, que voltam todas juntas depois de um tempo sem uso (ver
## player/tool_charges.gd). A espada e a mola não têm limite. A mola dá um pulo
## vertical: o personagem sobe no eixo da câmera, cresce na tela e mantém o
## mesmo controle do chão, sem ganhar distância. Com ela, ele sobe degraus altos
## (ver obstacles/ledge.gd).
##
## A espada pode ficar travada por um tempo, como faz a granada do ugly. Uma
## barra magenta acima da cabeça mostra quanto falta, e as ferramentas seguem
## funcionando.
##
## Os parâmetros exportados podem ser ajustados com o jogo rodando, pela aba
## Remoto da árvore de cena, e o efeito é imediato.

signal respawned

enum State { WALK, RUN, WOBBLE, FALLEN, KNOCKBACK }

## Tons sobre o desenho do Giorgio em cada estado. Acima de 1, o tom clareia.
const RUN_TINT := Color(1.0, 0.82, 0.62, 1.0)
const WOBBLE_TINT := Color(1.0, 0.35, 0.35, 1.0)
const FALLEN_TINT := Color(0.8, 0.78, 0.8, 1.0)
const KNOCKBACK_TINT := Color(1.8, 1.8, 1.8, 1.0)
## Desenhos do Giorgio, nesta ordem: de frente, de costas e de lado, cada um
## com o segundo passo logo depois. O de lado olha para a direita, e o jogo
## espelha para a esquerda. Andando, ele fica de pé, com a espada e os itens na
## pata. Correndo, desce para as 4 patas, e atacar o põe de pé de novo.
const ART_STANDING := [
	preload("res://art/giorgio_stand_down.svg"),
	preload("res://art/giorgio_stand_down_step.svg"),
	preload("res://art/giorgio_stand_up.svg"),
	preload("res://art/giorgio_stand_up_step.svg"),
	preload("res://art/giorgio_stand_side.svg"),
	preload("res://art/giorgio_stand_side_step.svg"),
]
const ART_ON_ALL_FOURS := [
	preload("res://art/giorgio_down.svg"),
	preload("res://art/giorgio_down_step.svg"),
	preload("res://art/giorgio_up.svg"),
	preload("res://art/giorgio_up_step.svg"),
	preload("res://art/giorgio_side.svg"),
	preload("res://art/giorgio_side_step.svg"),
]
const ART_FALLEN := preload("res://art/giorgio_fallen.svg")
## Quanto o desenho desce abaixo da origem, nos pés, em pixels.
const ART_BELOW_FEET := 4.0
## Ticks de cada passo, andando e correndo.
const WALK_STEP_TICKS := 10
const RUN_STEP_TICKS := 6
## Cor da espada travada. A granada do ugly usa a mesma cor.
const SWORD_LOCK_COLOR := Color(0.95, 0.35, 0.85, 1.0)
## Cor da barra da trava ao apertar o ataque com a espada travada.
const SWORD_DENIED_COLOR := Color(1.0, 1.0, 1.0, 1.0)
## Ticks em que a barra da trava fica branca depois de um aperto sem efeito.
const SWORD_DENIED_TICKS := 6
const BOMB_SCENE := preload("res://items/bomb.tscn")
const FIREBALL_SCENE := preload("res://items/fireball.tscn")
## Desvios laterais, em pixels, tentados ao cruzar um degrau desalinhado.
const LEDGE_SEARCH := [0, -1, 1, -2, 2, -3, 3, -4, 4, -5, 5, -6, 6]
## Quanto o desenho alcança a posição real por tick depois de cruzar um degrau.
const VISUAL_CATCH_UP := 1.5

@export_group("Andar")
## Velocidade máxima, em pixels por segundo.
@export_range(10.0, 300.0, 1.0) var walk_speed := 90.0
## Segundos para ir do repouso à velocidade máxima. Zero é arranque instantâneo.
@export_range(0.0, 1.0, 0.01) var acceleration_time := 0.0
## Segundos para parar a partir da velocidade máxima. Zero é parada instantânea.
@export_range(0.0, 1.0, 0.01) var deceleration_time := 0.0

@export_group("Correr")
## Velocidade da corrida, em pixels por segundo.
@export_range(10.0, 400.0, 1.0) var run_speed := 150.0
## Tempo máximo, em segundos, entre os dois toques na mesma direção para
## começar a correr. A corrida dura enquanto a direção estiver pressionada.
@export_range(0.1, 0.5, 0.01) var double_tap_window := 0.25
## Ligado, dá para mudar de direção correndo, para os lados ou em diagonal.
## Desligado, a corrida é em linha reta e termina ao mudar de direção. Em
## qualquer caso, apertar uma direção com componente para trás cancela a
## corrida, como uma freada.
@export var run_can_steer := true
## Segundos de corrida contínua até o personagem perder o equilíbrio. Zero
## desliga o tropeço.
@export_range(0.0, 5.0, 0.05) var balance_time := 0.4
## Segundos de desequilíbrio para reagir antes de cair. Para se equilibrar,
## aperte a direção oposta à da corrida.
@export_range(0.05, 2.0, 0.05) var wobble_time := 0.5
## Tempo mínimo caído, em segundos. Ele só se levanta depois disso e depois
## de parar de se arrastar.
@export_range(0.0, 3.0, 0.05) var fall_time := 0.8
## Desaceleração do personagem caído, que se arrasta pelo chão sem controle,
## em pixels por segundo ao quadrado. Quanto menor, mais longe ele vai.
@export_range(0.0, 3000.0, 10.0) var fall_friction := 400.0

@export_group("Batidas")
## Velocidade, em pixels por segundo, abaixo da qual o personagem recupera o
## controle depois de arremessado.
@export_range(0.0, 200.0, 1.0) var recover_speed := 30.0

@export_group("Ataque")
## Segundos em que o personagem fica parado a cada golpe. Zero permite andar
## enquanto ataca.
@export_range(0.0, 0.5, 0.01) var attack_freeze_time := 0.1

@export_group("Vida")
## Pontos de vida.
@export_range(1, 20, 1) var max_health := 6
## Segundos de invencibilidade depois de tomar dano, com o personagem piscando.
@export_range(0.0, 3.0, 0.05) var invincibility_time := 1.0

@export_group("Ferramentas")
## Altura do pulo da mola, em pixels. Com o passo fixo, o pico real fica um
## pouco abaixo (20,5 px para 22). Precisa passar da altura dos degraus, que é
## de 16 pixels.
@export_range(8.0, 48.0, 1.0) var jump_height := 22.0
## Tempo no ar do pulo, em segundos.
@export_range(0.2, 1.5, 0.05) var jump_time := 0.5
## Quanto o personagem cresce no alto do pulo, por estar mais perto da câmera.
@export_range(0.0, 1.0, 0.05) var jump_growth := 0.25
## Bolas de fogo seguidas antes de a chama precisar recarregar.
@export_range(1, 10, 1) var fire_charges := 5
## Segundos sem usar a chama até todas as cargas voltarem.
@export_range(0.5, 10.0, 0.5) var fire_recharge_time := 3.0
## Bombas seguidas antes de a bomba precisar recarregar.
@export_range(1, 10, 1) var bomb_charges := 2
## Segundos sem usar a bomba até todas as cargas voltarem.
@export_range(0.5, 10.0, 0.5) var bomb_recharge_time := 3.0
## Bombas no chão ao mesmo tempo, além do limite das cargas.
@export_range(1, 5, 1) var max_bombs := 2
## Pontos de vida ganhos com cada coração.
@export_range(1, 6, 1) var heart_bonus := 2
## Ferramentas desde o início. Útil na sala de teste.
@export_flags("Bomba", "Chama", "Mola") var starting_tools := 0

@export_group("Quinas")
## Distância máxima, em pixels, para escorregar pela quina ao esbarrar numa
## parede andando em linha reta. Zero desliga.
@export_range(0, 12, 1) var corner_tolerance := 6

## Direção para onde o personagem olha, sempre uma das 4 direções retas.
## Define para onde vão o golpe, a chama e a bomba. Segurar a ação
## lock_facing mantém a frente, o que permite andar de lado.
var facing := Vector2.DOWN
var health := 0
## Chaves pequenas guardadas. Cada porta trancada gasta uma.
var keys := 0
## Onde o personagem reaparece ao perder toda a vida.
var spawn_position := Vector2.ZERO

var _state := State.WALK
var _state_tick := 0
var _run_direction := Vector2.ZERO
var _previous_direction := Vector2.ZERO
var _last_press_direction := Vector2.ZERO
var _last_press_tick := 0
var _freeze_until_tick := 0
var _invincible_until_tick := 0
var _tools := 0
var _z := 0.0
var _z_velocity := 0.0
var _visual_offset := 0.0
var _drawn_height := 0.0
var _sword_lock_until_tick := 0
var _sword_lock_ticks := 1
var _sword_denied_tick := -1000
var _fire_charges := ToolCharges.new()
var _bomb_charges := ToolCharges.new()
## Passo mostrado no último tick, para o som de cada passo tocar uma vez.
var _last_step := 0

@onready var _visual: Node2D = $Visual
@onready var _art: Sprite2D = $Visual/Art
@onready var _sword: Sword = $Visual/Sword
@onready var _sword_lock_bar: ColorRect = $Visual/SwordLock
@onready var _sword_lock_width: float = _sword_lock_bar.size.x
@onready var _shadow: ColorRect = $Shadow
@onready var _feet: CollisionShape2D = $Feet


func _ready() -> void:
	add_to_group("player")
	health = max_health
	spawn_position = global_position
	_tools = starting_tools << 1


func _physics_process(delta: float) -> void:
	_recharge_tools()
	var direction := _read_direction()
	_update_state(direction)
	var in_control := _state == State.WALK or _state == State.RUN
	if in_control:
		# A frente se atualiza antes do golpe, para que direção e ataque
		# apertados no mesmo tick golpeiem na nova direção.
		_update_facing(direction)
		if Input.is_action_just_pressed("attack"):
			_attack()
		_use_tools()
	if _state == State.KNOCKBACK:
		# Arremessado, sem controle, até o atrito parar o personagem.
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	elif _state == State.FALLEN:
		# Caído, se arrasta pelo chão com o embalo da corrida.
		velocity = velocity.move_toward(Vector2.ZERO, fall_friction * delta)
	else:
		_steer(direction, delta)
	_try_ledge(direction, delta)
	move_with_impacts()
	_update_height(delta)
	_update_visuals()


## Diz se o personagem tem a ferramenta. Recebe um Item.Id.
func has_tool(id: int) -> bool:
	return Item.has(_tools, id)


## Cargas que restam da ferramenta, ou -1 se ela não usa cargas. Recebe um
## Item.Id.
func charges_left(id: int) -> int:
	match id:
		Item.Id.FIRE:
			return _fire_charges.left(fire_charges)
		Item.Id.BOMB:
			return _bomb_charges.left(bomb_charges)
	return -1


## Cargas da ferramenta cheia, ou 0 se ela não usa cargas. Recebe um Item.Id.
func max_charges(id: int) -> int:
	match id:
		Item.Id.FIRE:
			return fire_charges
		Item.Id.BOMB:
			return bomb_charges
	return 0


## Recebe o item de um baú. Uma ferramenta passa a funcionar no seu botão, um
## coração aumenta a vida máxima e enche a vida, a chave pequena vai para o
## chaveiro e a chave grande fica para sempre, como uma ferramenta sem botão.
func give_item(id: int) -> void:
	if id == Item.Id.HEART:
		max_health += heart_bonus
		health = max_health
		Sfx.play(&"item_heart")
	elif id == Item.Id.KEY:
		keys += 1
		Sfx.play(&"item_key")
	elif id in Item.PERMANENT:
		_tools |= Item.bit(id)
		Sfx.play(&"item_tool")


## Gasta uma chave pequena, se houver. Diz se gastou.
func use_key() -> bool:
	if keys <= 0:
		return false
	keys -= 1
	return true


## Altura dos pés acima do chão, em pixels.
func get_height() -> float:
	return _z


func is_airborne() -> bool:
	return _z > 0.0 or _z_velocity > 0.0


## Recebe a batida de outro corpo. Uma batida forte arremessa o personagem,
## a menos que ele esteja caído, caso em que só muda de embalo.
func add_impact_velocity(delta_velocity: Vector2) -> void:
	velocity += delta_velocity
	if delta_velocity.length() > recover_speed and _state != State.FALLEN:
		_enter(State.KNOCKBACK)


func _on_impacts(new_velocity: Vector2, rebound: float) -> void:
	velocity = new_velocity
	if rebound > recover_speed and _state != State.FALLEN:
		_enter(State.KNOCKBACK)


## Recebe um ataque. Durante a invencibilidade, ataques são ignorados. O
## empurrão vem separado, pela física da batida.
func take_hit(amount: int, _direction: Vector2, _kind := Hit.Kind.SWORD) -> void:
	if Engine.get_physics_frames() < _invincible_until_tick:
		return
	health -= amount
	_invincible_until_tick = Engine.get_physics_frames() + GameMath.ticks(invincibility_time)
	if health <= 0:
		Sfx.play(&"down")
		_respawn()
	else:
		Sfx.play(&"hurt")


## Trava a espada por alguns segundos. Durante a invencibilidade, nada
## acontece. Uma trava nova nunca encurta a que já existe.
func lock_sword(seconds: float) -> void:
	var now := Engine.get_physics_frames()
	if now < _invincible_until_tick:
		return
	var until := now + GameMath.ticks(seconds)
	if until > _sword_lock_until_tick:
		_sword_lock_until_tick = until
		_sword_lock_ticks = maxi(until - now, 1)
		Sfx.play(&"sword_lock")


func is_sword_locked() -> bool:
	return Engine.get_physics_frames() < _sword_lock_until_tick


## Golpe de espada na direção da frente. Correr e atacar encerra a corrida.
## Com a espada travada, o aperto só faz a barra da trava piscar.
func _attack() -> void:
	if is_sword_locked():
		_sword_denied_tick = Engine.get_physics_frames()
		Sfx.play(&"sword_denied")
		return
	if _state == State.RUN:
		_enter(State.WALK)
	_sword.attack(facing)
	Sfx.play(&"sword_swing")
	_freeze_until_tick = Engine.get_physics_frames() + GameMath.ticks(attack_freeze_time)


## Protótipo: sem tela de derrota, o personagem volta ao ponto de reaparecer
## com a vida cheia e as cargas cheias, e mantém as ferramentas.
func _respawn() -> void:
	health = max_health
	_fire_charges.refill()
	_bomb_charges.refill()
	global_position = spawn_position
	velocity = Vector2.ZERO
	_z = 0.0
	_z_velocity = 0.0
	_visual_offset = 0.0
	_drawn_height = 0.0
	_sword_lock_until_tick = 0
	_enter(State.WALK)
	respawned.emit()


func _recharge_tools() -> void:
	var now := Engine.get_physics_frames()
	_fire_charges.recharge(now, GameMath.ticks(fire_recharge_time))
	_bomb_charges.recharge(now, GameMath.ticks(bomb_recharge_time))


## Cada ferramenta responde ao seu botão. No ar, só a espada funciona.
func _use_tools() -> void:
	if is_airborne():
		return
	if Input.is_action_just_pressed("use_fire") and has_tool(Item.Id.FIRE):
		_shoot_fire()
	if Input.is_action_just_pressed("use_bomb") and has_tool(Item.Id.BOMB):
		_place_bomb()
	if Input.is_action_just_pressed("jump") and has_tool(Item.Id.SPRING):
		_z_velocity = 4.0 * jump_height / jump_time
		Sfx.play(&"jump")


## Solta uma bomba aos pés, um pouco à frente, se houver carga. O personagem
## atravessa as próprias bombas, mas pode empurrá-las com a espada.
func _place_bomb() -> void:
	if _bomb_charges.left(bomb_charges) <= 0:
		return
	if get_tree().get_nodes_in_group("bombs").size() >= max_bombs:
		return
	var bomb := BOMB_SCENE.instantiate() as Bomb
	bomb.position = position + facing * 6.0
	get_parent().add_child(bomb)
	bomb.add_collision_exception_with(self)
	add_collision_exception_with(bomb)
	_bomb_charges.spend(Engine.get_physics_frames())
	Sfx.play(&"bomb_place")


## Lança uma bola de fogo na direção da frente, se houver carga. Uma de cada
## vez: a próxima só sai depois que a anterior some.
func _shoot_fire() -> void:
	if _fire_charges.left(fire_charges) <= 0:
		return
	if not get_tree().get_nodes_in_group("fireballs").is_empty():
		return
	var fireball := FIREBALL_SCENE.instantiate() as Fireball
	fireball.direction = facing
	fireball.shooter = self
	fireball.position = position + facing * 9.0
	get_parent().add_child(fireball)
	_fire_charges.spend(Engine.get_physics_frames())
	Sfx.play(&"fire_shoot")


## Gravidade do pulo, calculada para que a altura e o tempo no ar sejam os
## exportados.
func _update_height(delta: float) -> void:
	if not is_airborne():
		return
	_z_velocity -= 8.0 * jump_height / (jump_time * jump_time) * delta
	_z += _z_velocity * delta
	if _z <= 0.0:
		_z = 0.0
		_z_velocity = 0.0
		Sfx.play(&"land")


## Degraus altos. Encostado na face vindo do sul, com a mola e alto o bastante,
## o personagem sobe. Encostado vindo do norte, ele desce num salto. Nos dois
## casos ele cruza a face de uma vez, trocando posição por altura, e o desenho
## alcança a nova posição em poucos ticks.
func _try_ledge(direction: Vector2, delta: float) -> void:
	if direction.y == 0.0:
		return
	var vertical := Vector2(0.0, signf(direction.y))
	var probe := vertical * maxf(2.0, absf(velocity.y) * delta + 1.0)
	var collision := KinematicCollision2D.new()
	if not test_move(global_transform, probe, collision):
		return
	var ledge := collision.get_collider() as Ledge
	if not ledge:
		return
	var feet_half := (_feet.shape as RectangleShape2D).size.y / 2.0
	if vertical.y < 0.0:
		if has_tool(Item.Id.SPRING) and _z >= ledge.step_height():
			_cross_ledge(ledge.top() - feet_half - 1.0, -ledge.step_height())
	else:
		_cross_ledge(ledge.bottom() + feet_half + 1.0, ledge.step_height())


func _cross_ledge(target_y: float, height_change: float) -> void:
	for offset: int in LEDGE_SEARCH:
		var target := Vector2(global_position.x + offset, target_y)
		if _is_free_at(target):
			var drawn_before := global_position.y - _z
			global_position = target
			_z = maxf(_z + height_change, 0.0)
			_visual_offset = drawn_before - (global_position.y - _z)
			if height_change > 0.0:
				Sfx.play(&"ledge_drop")
			return


## Diz se os pés caberiam na posição, sem encostar em nada.
func _is_free_at(target: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _feet.shape
	query.transform = Transform2D(0.0, target + _feet.position)
	query.collision_mask = collision_mask
	var excluded: Array[RID] = [get_rid()]
	query.exclude = excluded
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _steer(direction: Vector2, delta: float) -> void:
	var move_direction := direction
	var speed := walk_speed
	match _state:
		State.RUN:
			speed = run_speed
		State.WOBBLE:
			# Desequilibrado, segue em frente sem controle.
			move_direction = _run_direction
			speed = run_speed
	if Engine.get_physics_frames() < _freeze_until_tick:
		# Parado durante o golpe, mas ainda pode virar para o próximo.
		move_direction = Vector2.ZERO
	_update_velocity(move_direction, speed, delta)
	var nudge := _corner_nudge(move_direction, speed, delta)
	if nudge != Vector2.ZERO:
		velocity = nudge


## Lê a entrada e a reduz a uma das 8 direções, com as diagonais normalizadas.
func _read_direction() -> Vector2:
	var raw := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return GameMath.snap_8(raw)


## Andar vira corrida com o duplo toque. A corrida longa demais leva ao
## desequilíbrio, e o desequilíbrio sem reação leva à queda. O arremesso por
## batida interrompe qualquer estado e termina em andar.
func _update_state(direction: Vector2) -> void:
	var pressed := _previous_direction == Vector2.ZERO and direction != Vector2.ZERO
	_previous_direction = direction
	match _state:
		State.WALK:
			if pressed and _is_double_tap(direction):
				_run_direction = direction
				_enter(State.RUN)
		State.RUN:
			if (
				direction == Vector2.ZERO
				or direction.dot(_run_direction) < 0.0
				or (direction != _run_direction and not run_can_steer)
			):
				_enter(State.WALK)
			else:
				_run_direction = direction
				if balance_time > 0.0 and _ticks_in_state() >= GameMath.ticks(balance_time):
					_enter(State.WOBBLE)
		State.WOBBLE:
			if direction.dot(_run_direction) < 0.0:
				_enter(State.WALK)
			elif _ticks_in_state() >= GameMath.ticks(wobble_time):
				_enter(State.FALLEN)
		State.FALLEN:
			if _ticks_in_state() >= GameMath.ticks(fall_time) and velocity == Vector2.ZERO:
				_enter(State.WALK)
		State.KNOCKBACK:
			if velocity.length() <= recover_speed:
				_enter(State.WALK)


## Duas pressões na mesma direção, partindo do neutro, dentro de
## double_tap_window. Depois de reconhecido, o duplo toque é consumido.
func _is_double_tap(direction: Vector2) -> bool:
	var now := Engine.get_physics_frames()
	var window := GameMath.ticks(double_tap_window)
	if direction == _last_press_direction and now - _last_press_tick <= window:
		_last_press_direction = Vector2.ZERO
		return true
	_last_press_direction = direction
	_last_press_tick = now
	return false


## Troca de estado. A corrida, o desequilíbrio e a queda têm som próprio.
func _enter(state: State) -> void:
	if state != _state:
		match state:
			State.RUN:
				Sfx.play(&"dash")
			State.WOBBLE:
				Sfx.play(&"wobble")
			State.FALLEN:
				Sfx.play(&"fall")
	_state = state
	_state_tick = Engine.get_physics_frames()


func _ticks_in_state() -> int:
	return Engine.get_physics_frames() - _state_tick


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO or Input.is_action_pressed("lock_facing"):
		return
	var horizontal := Vector2(signf(direction.x), 0.0)
	var vertical := Vector2(0.0, signf(direction.y))
	if direction.x != 0.0 and direction.y != 0.0:
		# Na diagonal, mantém a frente atual se ela fizer parte da diagonal.
		if facing == horizontal or facing == vertical:
			return
		facing = vertical
	else:
		facing = horizontal if direction.x != 0.0 else vertical


func _update_velocity(direction: Vector2, speed: float, delta: float) -> void:
	var target := direction * speed
	var time_to_full := acceleration_time if direction != Vector2.ZERO else deceleration_time
	if time_to_full <= 0.0:
		velocity = target
	else:
		velocity = velocity.move_toward(target, speed / time_to_full * delta)


## Ao esbarrar numa parede andando em linha reta, procura a abertura mais
## próxima dentro de corner_tolerance pixels para cada lado. Se achar, devolve
## a velocidade que empurra o personagem até ela, limitada para não passar do
## ponto quando falta menos de um passo.
func _corner_nudge(direction: Vector2, speed: float, delta: float) -> Vector2:
	if corner_tolerance <= 0 or direction == Vector2.ZERO:
		return Vector2.ZERO
	if direction.x != 0.0 and direction.y != 0.0:
		return Vector2.ZERO
	var forward := direction * speed * delta
	if not test_move(global_transform, forward):
		return Vector2.ZERO
	var perpendicular := Vector2.DOWN if direction.y == 0.0 else Vector2.RIGHT
	for offset: int in range(1, corner_tolerance + 1):
		for side: float in [-1.0, 1.0]:
			var shift := perpendicular * side * offset
			if test_move(global_transform, shift):
				continue
			if not test_move(global_transform.translated(shift), forward):
				return perpendicular * side * minf(speed, offset / delta)
	return Vector2.ZERO


## O desenho do Giorgio segue a frente, e um tom sobre ele indica o estado: o
## corpo treme no desequilíbrio e fica deitado na queda. Com a espada travada,
## uma barra acima da cabeça encolhe até a trava acabar.
func _update_visuals() -> void:
	var tint := Color.WHITE
	var shake := Vector2.ZERO
	match _state:
		State.RUN:
			tint = RUN_TINT
		State.WOBBLE:
			var blink := posmod(_ticks_in_state(), 8) < 4
			tint = WOBBLE_TINT if blink else RUN_TINT
			shake = Vector2(1.0 if blink else -1.0, 0.0)
		State.FALLEN:
			tint = FALLEN_TINT
		State.KNOCKBACK:
			tint = KNOCKBACK_TINT
	_update_art(shake)
	_art.modulate = tint
	var invincible := Engine.get_physics_frames() < _invincible_until_tick
	var flicker := posmod(Engine.get_physics_frames(), 6) < 3
	modulate.a = 0.3 if invincible and flicker else 1.0
	# No ar, o corpo sobe e cresce, e a sombra fica no chão.
	_visual_offset = move_toward(_visual_offset, 0.0, VISUAL_CATCH_UP)
	_drawn_height = move_toward(_drawn_height, _z, 4.0)
	_visual.position = Vector2(0.0, _visual_offset - _z)
	_visual.scale = Vector2.ONE * (1.0 + jump_growth * _drawn_height / jump_height)
	_shadow.visible = is_airborne()
	_update_sword_lock_bar()


## Escolhe o desenho pela postura e pela frente. Correndo e desequilibrado,
## ele está nas 4 patas, caído, deitado, e no resto, de pé. Andando ou
## correndo, alterna os dois passos, mais rápido na corrida. O desenho sempre
## termina ART_BELOW_FEET abaixo dos pés, qualquer que seja a altura.
func _update_art(shake: Vector2) -> void:
	var on_all_fours := _state == State.RUN or _state == State.WOBBLE
	var moving := (_state == State.WALK or _state == State.RUN) and velocity.length() > 1.0
	var step_ticks := RUN_STEP_TICKS if on_all_fours else WALK_STEP_TICKS
	var step := 0
	if moving and posmod(floori(float(Engine.get_physics_frames()) / step_ticks), 2) == 1:
		step = 1
	# Um passo soa a cada troca de pata, quando o segundo passo aparece.
	if step == 1 and _last_step == 0 and not is_airborne():
		Sfx.play(&"step")
	_last_step = step
	var direction := 2
	if facing.y > 0.0:
		direction = 0
	elif facing.y < 0.0:
		direction = 1
	var frames: Array = ART_ON_ALL_FOURS if on_all_fours else ART_STANDING
	var texture: Texture2D = frames[direction * 2 + step]
	if _state == State.FALLEN:
		texture = ART_FALLEN
	_art.texture = texture
	_art.flip_h = facing.x < 0.0 and (direction == 2 or _state == State.FALLEN)
	_art.offset = Vector2(-texture.get_width() / 2.0, ART_BELOW_FEET - texture.get_height())
	_art.position = shake


func _update_sword_lock_bar() -> void:
	var now := Engine.get_physics_frames()
	var left := _sword_lock_until_tick - now
	_sword_lock_bar.visible = left > 0
	if left <= 0:
		return
	_sword_lock_bar.size.x = _sword_lock_width * left / _sword_lock_ticks
	_sword_lock_bar.position.x = -_sword_lock_bar.size.x / 2.0
	var denied := now - _sword_denied_tick < SWORD_DENIED_TICKS
	_sword_lock_bar.color = SWORD_DENIED_COLOR if denied else SWORD_LOCK_COLOR
