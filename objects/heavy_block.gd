class_name HeavyBlock
extends Pushable
## Bloco pesado: tomba de casa em casa, como um dado, dentro de um trilho
## rebaixado no chão que vai do lugar dele até o interruptor
## (objects/floor_switch.gd). O personagem empurra andando contra ele: depois
## de um pequeno esforço, o bloco levanta devagar sobre a aresta, cai na casa
## seguinte com um baque e para. Empurrar de novo repete o ciclo. Fora do
## trilho ele não anda, então não há como prendê-lo num canto (pedidos de
## Marcelo em 2026-11-12, depois de um amigo dele encostar o bloco na parede
## e não saber que ele voltava ao lugar ao sair da sala). Em cima do
## interruptor, trava e vira parte do chão. Enquanto não travou, volta ao
## lugar inicial sempre que o personagem entra de novo na sala.
##
## A origem fica no centro da base, para a ordenação por profundidade.

## Massa do bloco, que nenhuma batida move: só o tombo o desloca.
const LOCKED_MASS := 1000.0
## Ticks de esforço, empurrando sem parar, antes de o bloco começar a tombar.
const EFFORT_TICKS := 14
## Ticks do tombo, do levantar ao baque.
const TUMBLE_TICKS := 22
## Ticks do tremor do baque.
const THUD_TICKS := 6
## Metade da largura do bloco e a altura do centro acima da origem.
const HALF := 16.0
const CENTER_HEIGHT := 12.0
## Distância entre o centro do bloco e o do personagem encostado nele, de
## lado e de cima ou de baixo, a folga dessa medida, e quanto ele pode estar
## fora do eixo do empurrão.
const TOUCH_DISTANCE := Vector2(28.0, 20.0)
const PUSH_REACH := 4.0
const PUSH_SIDE := 12.0
## Quanto o desenho sobe e achata no tombo para cima ou para baixo.
const HOP_HEIGHT := 7.0
const SQUASH := 0.35

var locked := false
## Casas do trilho, as chaves de um dicionário de Vector2i. Vazio, o bloco
## não anda. Quem monta a sala preenche (Chapter._add_rails).
var rail := {}
## Lado de uma casa do trilho, em pixels.
var tile := 32.0

var _effort := 0
var _effort_direction := Vector2.ZERO
var _tumble_tick := -1
var _tumble_from := Vector2.ZERO
var _tumble_direction := Vector2.ZERO
var _thud_tick := -1000

@onready var _home := global_position
@onready var _art: Sprite2D = $Art


func _ready() -> void:
	super()
	mass = LOCKED_MASS


## Liga ou desliga com a sala. Ao entrar na sala, o bloco solto volta ao
## lugar inicial.
func set_active(active: bool) -> void:
	if active and not locked:
		reset()


func reset() -> void:
	global_position = _home
	velocity = Vector2.ZERO
	_stop_tumble()
	_effort = 0


## Trava o bloco em cima do interruptor.
func lock_at(point: Vector2) -> void:
	locked = true
	global_position = point
	velocity = Vector2.ZERO
	_stop_tumble()


func is_tumbling() -> bool:
	return _tumble_tick >= 0


func add_impact_velocity(_delta_velocity: Vector2) -> void:
	pass


func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO
	if Clock.tick - _thud_tick <= THUD_TICKS:
		_art.position = Vector2(0.0, 1.0 if (Clock.tick - _thud_tick) % 4 < 2 else 0.0)
	if locked:
		return
	if is_tumbling():
		_advance_tumble()
		return
	var direction := _push_direction()
	if direction == Vector2.ZERO or direction != _effort_direction:
		_effort = 0
	_effort_direction = direction
	if direction == Vector2.ZERO:
		return
	if _effort == 0:
		Sfx.play(&"block_drag")
	_effort += 1
	if _effort >= EFFORT_TICKS:
		_effort = 0
		_start_tumble(direction)


## Direção em que o personagem empurra o bloco agora, ou zero: ele tem de
## estar encostado numa face, virado para o bloco e andando contra ele, e a
## casa seguinte tem de ser do trilho.
func _push_direction() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player or player.is_airborne():
		return Vector2.ZERO
	var direction := player.facing
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.dot(direction) < 0.5:
		return Vector2.ZERO
	var center := global_position + Vector2(0.0, -CENTER_HEIGHT)
	var offset := player.global_position - center
	var touch := TOUCH_DISTANCE.x if direction.x != 0.0 else TOUCH_DISTANCE.y
	var behind := offset.dot(-direction) - touch
	var aside := absf(offset.dot(Vector2(direction.y, direction.x)))
	if absf(behind) > PUSH_REACH or aside > PUSH_SIDE:
		return Vector2.ZERO
	if not _can_move_to(_cell() + Vector2i(direction)):
		return Vector2.ZERO
	return direction


## Diz se o bloco pode tombar para a casa: só dentro do trilho.
func _can_move_to(cell: Vector2i) -> bool:
	return rail.has(cell)


## Chamado quando o bloco para na casa nova, depois do baque.
func _on_landed() -> void:
	pass


## Casa do trilho em que o bloco está.
func _cell() -> Vector2i:
	var center := global_position + Vector2(0.0, -CENTER_HEIGHT)
	return Vector2i((center / tile).floor())


func _start_tumble(direction: Vector2) -> void:
	_tumble_tick = 0
	_tumble_from = global_position
	_tumble_direction = direction


## O tombo começa devagar, o esforço de levantar o bloco sobre a aresta, e
## acelera até o baque.
func _advance_tumble() -> void:
	_tumble_tick += 1
	var linear := float(_tumble_tick) / TUMBLE_TICKS
	var progress := linear * linear
	if _tumble_tick >= TUMBLE_TICKS:
		global_position = _tumble_from + _tumble_direction * tile
		_stop_tumble()
		_thud_tick = Clock.tick
		Sfx.play(&"bump")
		_on_landed()
		return
	global_position = _tumble_from + _tumble_direction * tile * progress
	if _tumble_direction.x != 0.0:
		# Gira sobre a aresta de baixo do lado para onde tomba. O corpo anda em
		# linha reta, e o desenho é posto em relação a ele.
		var pivot := Vector2(_tumble_direction.x * HALF, 0.0)
		var angle := progress * PI / 2.0 * _tumble_direction.x
		_art.rotation = angle
		_art.position = _tumble_from + pivot - pivot.rotated(angle) - global_position
	else:
		var arc := sin(progress * PI)
		_art.position = Vector2(0.0, -HOP_HEIGHT * arc)
		_art.scale = Vector2(1.0, 1.0 - SQUASH * arc)


func _stop_tumble() -> void:
	_tumble_tick = -1
	if _art:
		_art.rotation = 0.0
		_art.position = Vector2.ZERO
		_art.scale = Vector2.ONE
