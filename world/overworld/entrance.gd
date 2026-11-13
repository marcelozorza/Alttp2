class_name DungeonEntrance
extends StaticBody2D
## Entrada de uma dungeon no mundo: uma fachada de duas casas de largura, no
## tema da dungeon, para o jogador saber qual é qual antes de entrar. O
## personagem entra ao encostar nela vindo do sul.
##
## Fechada, tem uma grade de ferro na abertura e treme ao toque, como a porta
## trancada. Vencida, mostra a relíquia do capítulo acima do portal. A
## origem fica no canto superior esquerdo da casa de baixo, e o desenho passa
## uma casa acima dela, sobre a mata.

signal entered(chapter: int)

enum Mode { LOCKED, OPEN, DONE }

## Fachada de cada dungeon, pelo número do capítulo: a de teste, o castelo, a
## geleira e as ruínas.
const TEXTURES: Array[Texture2D] = [
	preload("res://art/entrance_stone.svg"),
	preload("res://art/entrance_castle.svg"),
	preload("res://art/entrance_ice.svg"),
	preload("res://art/entrance_moss.svg"),
]
const GATE_TEXTURE := preload("res://art/gate.svg")
const RELIC_TEXTURE := preload("res://art/relic_small.svg")
const SIZE := Vector2(64.0, 32.0)
## Quanto o desenho sobe acima da origem.
const ART_ABOVE := 32.0
const GATE_OFFSET := Vector2(20.0, 32.0)
const SHAKE_COOLDOWN_TICKS := 30
const TOUCH_MARGIN := 4.0

## Número do capítulo que a entrada abre.
@export var chapter := 1
@export var mode := Mode.LOCKED

var _touch := Area2D.new()
var _shake_tick := -1000
var _used := false


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = SIZE / 2.0
	add_child(shape)
	var touch_shape := CollisionShape2D.new()
	var touch_rectangle := RectangleShape2D.new()
	touch_rectangle.size = SIZE + Vector2.ONE * TOUCH_MARGIN * 2.0
	touch_shape.shape = touch_rectangle
	touch_shape.position = SIZE / 2.0
	_touch.add_child(touch_shape)
	_touch.monitorable = false
	add_child(_touch)


func _physics_process(_delta: float) -> void:
	var now := Clock.tick
	if not _used:
		for body: Node2D in _touch.get_overlapping_bodies():
			if body is Player:
				_touched(now)
	if now - _shake_tick <= DoorArt.SHAKE_TICKS or mode == Mode.DONE:
		queue_redraw()


func _touched(now: int) -> void:
	if mode == Mode.LOCKED:
		if now - _shake_tick > SHAKE_COOLDOWN_TICKS:
			_shake_tick = now
			Sfx.play(&"door_locked")
		return
	_used = true
	Sfx.play(&"door_unlock")
	entered.emit(chapter)


## Centro da casa logo ao sul, onde o personagem aparece ao voltar.
func exit_position() -> Vector2:
	return global_position + Vector2(SIZE.x / 2.0, SIZE.y + 16.0)


func _draw() -> void:
	var offset := Vector2(0.0, -ART_ABOVE) + DoorArt.shake_offset(_shake_tick)
	draw_texture(TEXTURES[clampi(chapter, 0, TEXTURES.size() - 1)], offset)
	if mode == Mode.LOCKED:
		draw_texture(GATE_TEXTURE, offset + GATE_OFFSET)
	elif mode == Mode.DONE:
		var bob := sin(Clock.tick * 0.08) * 3.0
		draw_texture(RELIC_TEXTURE, (Vector2(20.0, -60.0 + bob)).round())
