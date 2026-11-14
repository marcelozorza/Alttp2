class_name Trail
extends Enemy
## Rastro: inimigo que anda devagar atrás do personagem e
## deixa uma trilha de fogo no chão, que fica alguns segundos e fere quem
## pisa. A trilha divide a sala e fecha caminhos por um tempo. Ele morre com
## a espada. Arte provisória.

## Ticks entre uma chama da trilha e a seguinte.
const DROP_TICKS := 12

var _last_drop_tick := 0


func _physics_process(delta: float) -> void:
	super(delta)
	if is_dead() or velocity.length() < 10.0:
		return
	if Clock.tick - _last_drop_tick < DROP_TICKS:
		return
	_last_drop_tick = Clock.tick
	var patch := FirePatch.new()
	patch.position = global_position
	get_tree().get_first_node_in_group("floor_effects").add_child(patch)
