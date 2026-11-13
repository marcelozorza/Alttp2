class_name Turret
extends StaticBody2D
## Torreta do laboratório: um pilar que não se move nem morre e dispara nas
## quatro direções retas em intervalo fixo, piscando em amarelo antes. O
## desafio é de ambiente: atravessar as linhas de tiro no ritmo, pular o
## disparo ou empurrar um bloco para tampar a linha. Arte provisória.
##
## Só age com o personagem na sala (set_active). A origem fica no centro da
## base, para a ordenação por profundidade.

const SIZE := Vector2(24.0, 16.0)
const BODY_COLOR := Color(0.4, 0.42, 0.5)
const EYE_COLOR := Color(1.0, 0.35, 0.3)
const DIRECTIONS: Array[Vector2] = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

## Segundos entre um disparo e o seguinte.
var period := 1.8
## Segundos de aviso antes do disparo.
var warning := 0.5

var _active := false
var _cycle_tick := 0


func _ready() -> void:
	collision_layer = Layers.SCENERY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)


func set_active(active: bool) -> void:
	_active = active
	_cycle_tick = Clock.tick
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	queue_redraw()
	if Clock.tick - _cycle_tick < GameMath.ticks(period):
		return
	_cycle_tick = Clock.tick
	Sfx.play(&"fire_shoot")
	var effects := get_tree().get_first_node_in_group("floor_effects")
	for direction: Vector2 in DIRECTIONS:
		var bolt := Bolt.new()
		bolt.direction = direction
		bolt.shooter = self
		bolt.position = global_position + Vector2(0.0, -SIZE.y / 2.0) + direction * 20.0
		effects.add_child(bolt)


func _warning_now() -> bool:
	var left := GameMath.ticks(period) - (Clock.tick - _cycle_tick)
	return _active and left <= GameMath.ticks(warning) and posmod(left, 8) < 4


func _draw() -> void:
	GroundShadow.draw(self, Vector2(0.0, -2.0), 28.0)
	draw_rect(Rect2(-14.0, -34.0, 28.0, 34.0), DoorArt.OUTLINE_COLOR)
	draw_rect(Rect2(-12.0, -32.0, 24.0, 30.0), Hit.WINDUP_COLOR if _warning_now() else BODY_COLOR)
	draw_rect(Rect2(-5.0, -24.0, 10.0, 10.0), EYE_COLOR)
