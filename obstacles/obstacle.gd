class_name Obstacle
extends StaticBody2D
## Bloqueio do mapa que só um tipo de golpe remove. Os outros golpes só fazem
## o bloqueio tremer, para mostrar que ali falta outra ferramenta.
##
## A origem fica no canto superior esquerdo. O construtor do mapa define o
## tamanho antes de adicionar o bloqueio à cena. Como as paredes, o bloqueio
## projeta uma sombra curta no chão ao sul.

## Ticks em que o bloqueio treme ao receber um golpe que não o afeta.
const SHAKE_TICKS := 8
## Ticks de animação depois que o bloqueio é removido.
const CLEAR_ANIMATION_TICKS := 30
## Sombra no chão ao sul, a mesma das paredes.
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.3)
const SHADOW_HEIGHT := 3.0

## Tamanho em pixels.
@export var size := Vector2(16.0, 16.0)

var cleared := false

var _shape := CollisionShape2D.new()
var _opened := false
var _shake_tick := -1000
var _clear_tick := -1000


func _ready() -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	_shape.shape = rectangle
	_shape.position = size / 2.0
	add_child(_shape)


## Recebe um golpe. Só o golpe certo remove o bloqueio.
func take_hit(_amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if cleared:
		return
	if _opens_with(kind):
		cleared = true
		_clear_tick = Engine.get_physics_frames()
		Sfx.play(_clear_sound())
	else:
		_shake_tick = Engine.get_physics_frames()
		Sfx.play(&"deny")
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if cleared and not _opened and _ticks_since_clear() >= _open_delay():
		_opened = true
		_shape.set_deferred("disabled", true)
	var shaking := Engine.get_physics_frames() - _shake_tick <= SHAKE_TICKS
	if shaking or (cleared and _ticks_since_clear() <= CLEAR_ANIMATION_TICKS):
		queue_redraw()


## Diz se o golpe remove o bloqueio.
func _opens_with(kind: Hit.Kind) -> bool:
	return kind == Hit.Kind.BLAST


## Som do golpe certo.
func _clear_sound() -> StringName:
	return &"wall_break"


## Ticks entre o golpe certo e a passagem abrir.
func _open_delay() -> int:
	return 0


## Deslocamento do tremor, para os desenhos das subclasses.
func _shake_offset() -> Vector2:
	var elapsed := Engine.get_physics_frames() - _shake_tick
	if elapsed >= SHAKE_TICKS:
		return Vector2.ZERO
	return Vector2(1.0 if posmod(elapsed, 4) < 2 else -1.0, 0.0)


func _ticks_since_clear() -> int:
	return Engine.get_physics_frames() - _clear_tick


## Sombra no chão logo ao sul do bloqueio, enquanto ele está de pé.
func _draw_shadow() -> void:
	if cleared:
		return
	draw_rect(Rect2(Vector2(0.0, size.y), Vector2(size.x, SHADOW_HEIGHT)), SHADOW_COLOR)
