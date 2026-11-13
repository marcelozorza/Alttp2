class_name Blower
extends Enemy
## Soprador do laboratório: inimigo parado que sopra vento numa das quatro
## direções retas, a do personagem na hora em que começa. O vento (lab/wind.gd)
## empurra o personagem ao longo de uma faixa, sem ferir: o perigo é ser
## jogado num buraco. Ele sopra por um tempo e descansa, e morre com a espada. Arte
## provisória.

## Segundos soprando e segundos de descanso.
const BLOW_TIME := 2.2
const REST_TIME := 1.4
var _cycle_tick := 0
var _blow_direction := Vector2.ZERO


func reset() -> void:
	super()
	_cycle_tick = Clock.tick
	_blow_direction = Vector2.ZERO


func _physics_process(delta: float) -> void:
	super(delta)
	if is_dead():
		return
	var elapsed := Clock.tick - _cycle_tick
	var player := get_tree().get_first_node_in_group("player") as Player
	if _blow_direction == Vector2.ZERO:
		if elapsed >= GameMath.ticks(REST_TIME) and player:
			_blow_direction = GameMath.snap_4(player.global_position - global_position)
			_cycle_tick = Clock.tick
			Sfx.play(&"enemy_windup")
		return
	queue_redraw()
	if elapsed >= GameMath.ticks(BLOW_TIME):
		_blow_direction = Vector2.ZERO
		_cycle_tick = Clock.tick
		queue_redraw()
		return
	Wind.push(get_tree(), global_position, _blow_direction, delta)


func _draw() -> void:
	super()
	if is_dead() or _blow_direction == Vector2.ZERO:
		return
	Wind.draw(self, _blow_direction)
