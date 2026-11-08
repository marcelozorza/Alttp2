class_name HeavyBlock
extends Pushable
## Bloco pesado: anda devagar quando empurrado e trava ao parar em cima de um
## interruptor (objects/floor_switch.gd), onde vira parte do chão e não se
## move mais. Enquanto não travou, volta ao lugar inicial sempre que o
## personagem entra de novo na sala, para um bloco empurrado para um canto
## não prender o jogador.
##
## A origem fica no centro da base, para a ordenação por profundidade.

## Massa do bloco travado, que nenhuma batida move.
const LOCKED_MASS := 1000.0

var locked := false

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
