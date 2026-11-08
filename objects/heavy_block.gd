class_name HeavyBlock
extends Pushable
## Bloco pesado: anda devagar quando empurrado e trava ao parar em cima de um
## interruptor (objects/floor_switch.gd), onde vira parte do chão e não se
## move mais. Enquanto não travou, volta ao lugar inicial sempre que o
## personagem entra de novo na sala, para um bloco empurrado para um canto
## não prender o jogador.
##
## A origem fica no centro da base, para a ordenação por profundidade.
##
## Enquanto anda, faz barulho de pedra arrastada, um trecho a cada
## DRAG_SOUND_TICKS (pedido de Marcelo em 2026-11-08).

## Massa do bloco travado, que nenhuma batida move.
const LOCKED_MASS := 1000.0
## Ticks entre dois trechos do barulho de arrasto, e a velocidade mínima, em
## pixels por segundo, para soar.
const DRAG_SOUND_TICKS := 12
const DRAG_SOUND_SPEED := 4.0

var locked := false

var _next_drag_tick := 0

@onready var _home := global_position


## Liga ou desliga com a sala. Ao entrar na sala, o bloco solto volta ao
## lugar inicial.
func set_active(active: bool) -> void:
	if active and not locked:
		reset()


func reset() -> void:
	global_position = _home
	velocity = Vector2.ZERO


## Trava o bloco em cima do interruptor.
func lock_at(point: Vector2) -> void:
	locked = true
	global_position = point
	velocity = Vector2.ZERO
	mass = LOCKED_MASS


func add_impact_velocity(delta_velocity: Vector2) -> void:
	if locked:
		return
	super(delta_velocity)


func _physics_process(delta: float) -> void:
	if locked:
		velocity = Vector2.ZERO
		return
	super(delta)
	if velocity.length() > DRAG_SOUND_SPEED and Clock.tick >= _next_drag_tick:
		Sfx.play(&"block_drag")
		_next_drag_tick = Clock.tick + DRAG_SOUND_TICKS
