class_name LockedDoor
extends StaticBody2D
## Porta trancada. Abre quando o personagem encosta nela com a chave certa.
##
## A porta comum gasta uma chave pequena. A porta do chefe pede a chave grande,
## que nunca se gasta. Sem a chave, encostar só faz a porta tremer, como os
## outros bloqueios fazem com o golpe errado.
##
## A origem fica no canto superior esquerdo. O construtor do mapa define o
## tamanho antes de adicionar a porta à cena.

const SHAKE_TICKS := 8
## Ticks entre duas tremidas, para a porta não tremer sem parar com o
## personagem encostado.
const SHAKE_COOLDOWN_TICKS := 30
## Ticks da animação de abrir.
const OPEN_TICKS := 12
## Quanto a área de toque passa da porta, em pixels.
const TOUCH_MARGIN := 2.0
const DOOR_TEXTURE := preload("res://art/locked_door.svg")
const BOSS_DOOR_TEXTURE := preload("res://art/boss_door.svg")

## Tamanho em pixels.
@export var size := Vector2(16.0, 16.0)
## Ligado, é a porta do chefe, que pede a chave grande.
@export var needs_boss_key := false

var opened := false

var _shape := CollisionShape2D.new()
var _touch := Area2D.new()
var _shake_tick := -1000
var _open_tick := -1000


func _ready() -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	_shape.shape = rectangle
	_shape.position = size / 2.0
	add_child(_shape)
	var touch_shape := CollisionShape2D.new()
	var touch_rectangle := RectangleShape2D.new()
	touch_rectangle.size = size + Vector2.ONE * TOUCH_MARGIN * 2.0
	touch_shape.shape = touch_rectangle
	touch_shape.position = size / 2.0
	_touch.add_child(touch_shape)
	_touch.monitorable = false
	add_child(_touch)


func _physics_process(_delta: float) -> void:
	var now := Engine.get_physics_frames()
	if not opened:
		for body: Node2D in _touch.get_overlapping_bodies():
			var player := body as Player
			if player:
				_try_open(player, now)
	var shaking := now - _shake_tick <= SHAKE_TICKS
	if shaking or (opened and now - _open_tick <= OPEN_TICKS):
		queue_redraw()


func _try_open(player: Player, now: int) -> void:
	var unlocked := false
	if needs_boss_key:
		unlocked = player.has_tool(Item.Id.BOSS_KEY)
	else:
		unlocked = player.use_key()
	if unlocked:
		opened = true
		_open_tick = now
		_shape.set_deferred("disabled", true)
		Sfx.play(&"door_unlock")
	elif now - _shake_tick > SHAKE_COOLDOWN_TICKS:
		_shake_tick = now
		Sfx.play(&"door_locked")


## Desenha a porta casa por casa. Ao abrir, ela afunda no chão.
func _draw() -> void:
	var texture := BOSS_DOOR_TEXTURE if needs_boss_key else DOOR_TEXTURE
	var sink := 1.0
	if opened:
		sink = 1.0 - float(Engine.get_physics_frames() - _open_tick) / OPEN_TICKS
		if sink <= 0.0:
			return
	var offset := Vector2.ZERO
	var elapsed := Engine.get_physics_frames() - _shake_tick
	if elapsed < SHAKE_TICKS:
		offset.x = 1.0 if posmod(elapsed, 4) < 2 else -1.0
	var tile := float(ChapterMap.TILE)
	for y: int in int(size.y / tile):
		for x: int in int(size.x / tile):
			var cell := Vector2(x, y) * tile + offset
			var visible_height := tile * sink
			var source := Rect2(0.0, 0.0, tile, visible_height)
			var target := Rect2(cell + Vector2(0.0, tile - visible_height), source.size)
			draw_texture_rect_region(texture, target, source)
