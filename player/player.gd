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
## Os parâmetros exportados podem ser ajustados com o jogo rodando, pela aba
## Remoto da árvore de cena, e o efeito é imediato.

enum State { WALK, RUN, WOBBLE, FALLEN, KNOCKBACK }

## Cores provisórias do corpo em cada estado.
const RUN_COLOR := Color(0.95, 0.62, 0.2, 1.0)
const WOBBLE_COLOR := Color(1.0, 0.15, 0.15, 1.0)
const FALLEN_COLOR := Color(0.45, 0.4, 0.4, 1.0)
const KNOCKBACK_COLOR := Color(1.0, 1.0, 1.0, 1.0)

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
@export_range(0.0, 5.0, 0.05) var balance_time := 0.6
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

@export_group("Quinas")
## Distância máxima, em pixels, para escorregar pela quina ao esbarrar numa
## parede andando em linha reta. Zero desliga.
@export_range(0, 12, 1) var corner_tolerance := 6

## Direção para onde o personagem olha, sempre uma das 4 direções retas.
## Define, no futuro, para onde as ferramentas são usadas. Segurar a ação
## lock_facing mantém a frente, o que permite andar de lado.
var facing := Vector2.DOWN

var _state := State.WALK
var _state_tick := 0
var _run_direction := Vector2.ZERO
var _previous_direction := Vector2.ZERO
var _last_press_direction := Vector2.ZERO
var _last_press_tick := 0

@onready var _body: ColorRect = $Body
@onready var _walk_color: Color = _body.color
@onready var _body_rest_position: Vector2 = _body.position
@onready var _body_rest_size: Vector2 = _body.size
@onready var _facing_marker: ColorRect = $FacingMarker


func _physics_process(delta: float) -> void:
	var direction := _read_direction()
	_update_state(direction)
	if _state == State.KNOCKBACK:
		# Arremessado, sem controle, até o atrito parar o personagem.
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	elif _state == State.FALLEN:
		# Caído, se arrasta pelo chão com o embalo da corrida.
		velocity = velocity.move_toward(Vector2.ZERO, fall_friction * delta)
	else:
		_steer(direction, delta)
	move_with_impacts()
	_update_visuals()


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
	if _state == State.WALK or _state == State.RUN:
		_update_facing(direction)
	_update_velocity(move_direction, speed, delta)
	var nudge := _corner_nudge(move_direction, speed, delta)
	if nudge != Vector2.ZERO:
		velocity = nudge


## Lê a entrada e a reduz a uma das 8 direções, com as diagonais normalizadas.
func _read_direction() -> Vector2:
	var raw := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if raw == Vector2.ZERO:
		return raw
	var angle := snappedf(raw.angle(), PI / 4.0)
	return Vector2(roundf(cos(angle)), roundf(sin(angle))).normalized()


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
				if balance_time > 0.0 and _ticks_in_state() >= _ticks(balance_time):
					_enter(State.WOBBLE)
		State.WOBBLE:
			if direction.dot(_run_direction) < 0.0:
				_enter(State.WALK)
			elif _ticks_in_state() >= _ticks(wobble_time):
				_enter(State.FALLEN)
		State.FALLEN:
			if _ticks_in_state() >= _ticks(fall_time) and velocity == Vector2.ZERO:
				_enter(State.WALK)
		State.KNOCKBACK:
			if velocity.length() <= recover_speed:
				_enter(State.WALK)


## Duas pressões na mesma direção, partindo do neutro, dentro de
## double_tap_window. Depois de reconhecido, o duplo toque é consumido.
func _is_double_tap(direction: Vector2) -> bool:
	var now := Engine.get_physics_frames()
	var window := _ticks(double_tap_window)
	if direction == _last_press_direction and now - _last_press_tick <= window:
		_last_press_direction = Vector2.ZERO
		return true
	_last_press_direction = direction
	_last_press_tick = now
	return false


func _enter(state: State) -> void:
	_state = state
	_state_tick = Engine.get_physics_frames()


func _ticks_in_state() -> int:
	return Engine.get_physics_frames() - _state_tick


func _ticks(seconds: float) -> int:
	return roundi(seconds * Engine.physics_ticks_per_second)


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


## Visual provisório: a cor do corpo indica o estado, o corpo treme no
## desequilíbrio, fica deitado na queda e um quadrado na borda mostra para
## onde o personagem olha.
func _update_visuals() -> void:
	var color := _walk_color
	var shake := Vector2.ZERO
	var body_position := _body_rest_position
	var body_size := _body_rest_size
	match _state:
		State.RUN:
			color = RUN_COLOR
		State.WOBBLE:
			var blink := posmod(_ticks_in_state(), 8) < 4
			color = WOBBLE_COLOR if blink else RUN_COLOR
			shake = Vector2(1.0 if blink else -1.0, 0.0)
		State.FALLEN:
			color = FALLEN_COLOR
			# Deitado: um retângulo baixo e largo na altura dos pés.
			body_position = Vector2(-8.0, -4.0)
			body_size = Vector2(16.0, 8.0)
		State.KNOCKBACK:
			color = KNOCKBACK_COLOR
	_body.color = color
	_body.position = body_position + shake
	_body.size = body_size
	_facing_marker.visible = _state != State.FALLEN
	var body_center := Vector2(0.0, -4.0)
	var center := body_center + facing * Vector2(4.0, 6.0)
	_facing_marker.position = center - _facing_marker.size / 2.0
