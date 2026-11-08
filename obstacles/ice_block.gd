class_name IceBlock
extends Obstacle
## Parede de gelo. Só o fogo derrete, comum ou forte. O azul claro é o mesmo do
## inimigo de gelo, que também só cai com fogo.
##
## Cada casa é um bloco com o topo claro e a face na frente. Uma casa com outro
## bloco ao sul mostra só o topo, como a parede, para que uma parede de gelo
## com duas casas de fundo pareça um bloco só.

const FRONT_TEXTURE := preload("res://art/ice.svg")
const TOP_TEXTURE := preload("res://art/ice_top.svg")
## Ticks para derreter. A passagem abre no fim.
const MELT_TICKS := 15
## Ticks em que a poça fica no chão depois de o gelo sumir, apagando aos poucos.
const PUDDLE_TICKS := 40
const PUDDLE_COLOR := Color(0.55, 0.78, 0.95, 0.45)
const PUDDLE_SHINE := Color(0.85, 0.95, 1.0, 0.6)
const DROP_COLOR := Color(0.75, 0.9, 1.0, 0.9)


func _opens_with(kind: Hit.Kind) -> bool:
	return Hit.is_fire(kind)


func _open_delay() -> int:
	return MELT_TICKS


func _clear_sound() -> StringName:
	return &"ice_melt"


func _front_texture() -> Texture2D:
	return FRONT_TEXTURE


func _top_texture() -> Texture2D:
	return TOP_TEXTURE


func _melt_ticks() -> int:
	return MELT_TICKS


func _clear_animation_ticks() -> int:
	return _melt_ticks() + PUDDLE_TICKS


## Derretendo, o gelo afunda no chão casa por casa, como a porta trancada ao
## abrir (pedido de Marcelo em 2026-11-08), e deixa uma poça que cresce
## enquanto ele afunda e depois some. Gotas saltam das bordas no derretimento.
func _draw() -> void:
	var sink := 1.0
	var elapsed := _ticks_since_clear()
	if cleared:
		sink = 1.0 - float(elapsed) / _melt_ticks()
		_draw_puddle(elapsed)
	if sink <= 0.0:
		return
	_draw_shadow()
	var offset := _shake_offset()
	var tile := 32.0
	var visible_height := floorf(tile * sink)
	var source := Rect2(0.0, 0.0, tile, visible_height)
	var rows := int(size.y / tile)
	for y: int in rows:
		var texture := _front_texture() if y == rows - 1 else _top_texture()
		for x: int in int(size.x / tile):
			var cell := offset + Vector2(x, y) * tile
			var target := Rect2(cell + Vector2(0.0, tile - visible_height), source.size)
			draw_texture_rect_region(texture, target, source)
	if cleared:
		_draw_drops(elapsed)


## Poça rasa no chão onde estava o gelo: cresce até o gelo sumir e apaga depois.
func _draw_puddle(elapsed: int) -> void:
	var grow := clampf(float(elapsed) / _melt_ticks(), 0.0, 1.0)
	var fade := 1.0 - clampf(float(elapsed - _melt_ticks()) / PUDDLE_TICKS, 0.0, 1.0)
	if fade <= 0.0:
		return
	var inset := floorf(lerpf(12.0, 2.0, grow))
	var rect := Rect2(Vector2(inset, inset + 4.0), size - Vector2(inset, inset + 4.0) * 2.0)
	rect.size.y += 4.0
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	draw_rect(rect, Color(PUDDLE_COLOR, PUDDLE_COLOR.a * fade))
	var shine := Rect2(
		rect.position + Vector2(4.0, 2.0), Vector2(minf(10.0, rect.size.x - 6.0), 2.0)
	)
	if shine.size.x > 0.0:
		draw_rect(shine, Color(PUDDLE_SHINE, PUDDLE_SHINE.a * fade))


## Gotas de 2 pixels que saltam das bordas e caem enquanto o gelo afunda.
func _draw_drops(elapsed: int) -> void:
	if elapsed >= _melt_ticks():
		return
	var t := float(elapsed) / _melt_ticks()
	var columns := maxi(int(size.x / 32.0), 1)
	for i: int in columns * 3:
		var side := -1.0 if i % 2 == 0 else 1.0
		var start_x := 6.0 + float(i * 11 % int(size.x - 8.0))
		var x := start_x + side * 10.0 * t
		var y := size.y - 8.0 - 18.0 * t + 30.0 * t * t - float(i % 3) * 4.0
		draw_rect(Rect2(Vector2(x, y).floor(), Vector2(2.0, 2.0)), DROP_COLOR)
