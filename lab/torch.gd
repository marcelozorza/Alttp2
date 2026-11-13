class_name LabTorch
extends StaticBody2D
## Tocha de chão do laboratório, um braseiro que a chama acende. Arte
## provisória. Com todas as tochas da sala acesas, as portas amarelas abrem
## de vez (lab/room_mechanisms.gd).
##
## Com burn_time maior que zero, a tocha apaga sozinha depois desse tempo, e
## é preciso acender todas antes de a primeira apagar. Depois que a porta
## abre, as tochas ficam acesas (held).
##
## Com order maior que zero, a tocha faz parte de uma sequência: as pedras ao
## pé dela dizem a vez (uma pedra, a primeira). Acesa fora da vez, todas as
## tochas da sala apagam.
##
## A origem fica no centro da base, para a ordenação por profundidade.

signal changed

const SIZE := Vector2(20.0, 14.0)
const BOWL_COLOR := Color(0.45, 0.4, 0.42)
const FLAME_COLOR := Color(1.0, 0.7, 0.2)
const CORE_COLOR := Color(1.0, 0.95, 0.6)

## Segundos acesa. Zero, fica acesa para sempre.
var burn_time := 0.0
var lit := false
## Vez da tocha na sequência da sala, a partir de 1. Zero, sem sequência.
var order := 0
## Ligado quando a porta já abriu: a tocha não apaga mais.
var held := false

var _lit_tick := 0


func _ready() -> void:
	add_to_group("lab_torches")
	collision_layer = Layers.SCENERY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)


func take_hit(_amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if not Hit.is_fire(kind):
		return
	_lit_tick = Clock.tick
	if not lit:
		lit = true
		Sfx.play(&"fire_hit")
		changed.emit()
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not lit:
		return
	queue_redraw()
	if burn_time > 0.0 and not held and Clock.tick - _lit_tick >= GameMath.ticks(burn_time):
		lit = false
		Sfx.play(&"ice_melt")
		changed.emit()


## Apaga a tocha sem avisar a sala, para a sequência errada.
func put_out() -> void:
	lit = false
	queue_redraw()


## Fração do tempo que ainda resta, de 1 a 0. Sempre 1 na tocha sem tempo.
func _remaining() -> float:
	if burn_time <= 0.0 or held:
		return 1.0
	return clampf(1.0 - float(Clock.tick - _lit_tick) / GameMath.ticks(burn_time), 0.0, 1.0)


func _draw() -> void:
	GroundShadow.draw(self, Vector2(0.0, -2.0), 22.0)
	draw_rect(Rect2(-11.0, -16.0, 22.0, 16.0), DoorArt.OUTLINE_COLOR)
	draw_rect(Rect2(-9.0, -14.0, 18.0, 12.0), BOWL_COLOR)
	if burn_time > 0.0:
		# Faixa clara no braseiro: a tocha com tempo.
		draw_rect(Rect2(-9.0, -8.0, 18.0, 2.0), CORE_COLOR)
	for i: int in order:
		draw_circle(Vector2(-10.0 + i * 7.0, 5.0), 3.0, DoorArt.OUTLINE_COLOR)
		draw_circle(Vector2(-10.0 + i * 7.0, 5.0), 2.0, CORE_COLOR)
	if not lit:
		return
	var height := 8.0 + 14.0 * _remaining()
	var sway := 2.0 if posmod(Clock.tick, 12) < 6 else -2.0
	var flame := PackedVector2Array(
		[Vector2(-8.0, -14.0), Vector2(sway, -14.0 - height), Vector2(8.0, -14.0)]
	)
	draw_colored_polygon(flame, FLAME_COLOR)
	var core := PackedVector2Array(
		[Vector2(-4.0, -14.0), Vector2(sway / 2.0, -14.0 - height / 2.0), Vector2(4.0, -14.0)]
	)
	draw_colored_polygon(core, CORE_COLOR)
