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
## Poça desenhada, uma por casa: cheia, secando e as últimas gotas.
const PUDDLES: Array[Texture2D] = [
	preload("res://art/puddle_1.svg"),
	preload("res://art/puddle_2.svg"),
	preload("res://art/puddle_3.svg"),
]
## Ticks em que a poça fica no chão depois de o gelo sumir: cheia no começo,
## e os últimos PUDDLE_DRY_TICKS secando em dois passos.
const PUDDLE_TICKS := 90
const PUDDLE_DRY_TICKS := 40
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
## abrir (pedido de Marcelo em 2026-11-08), e deixa uma poça desenhada que
## cresce enquanto ele afunda e depois seca. Gotas saltam das bordas no derretimento.
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
	if not cleared:
		DoorArt.draw_outline(self, Rect2(offset, size))
	if cleared:
		_draw_drops(elapsed)


## Poça no chão de cada casa onde estava o gelo. É desenho, sem
## transparência (pedido de Marcelo em 2026-11-11): cresce em dois passos
## enquanto o gelo afunda, fica cheia e seca encolhendo.
func _draw_puddle(elapsed: int) -> void:
	var left := _melt_ticks() + PUDDLE_TICKS - elapsed
	if left <= 0:
		return
	var grow := float(elapsed) / _melt_ticks()
	var stage := 0
	if grow < 0.35 or left <= PUDDLE_DRY_TICKS / 2:
		stage = 2
	elif grow < 0.7 or left <= PUDDLE_DRY_TICKS:
		stage = 1
	var tile := 32.0
	for y: int in int(size.y / tile):
		for x: int in int(size.x / tile):
			# Casas vizinhas alternam o lado, para não parecerem carimbo.
			var flip := (x + y) % 2 == 1
			var target := Rect2(Vector2(x, y) * tile, Vector2(tile, tile))
			if flip:
				target = Rect2(target.position + Vector2(tile, 0.0), Vector2(-tile, tile))
			draw_texture_rect(PUDDLES[stage], target, false)


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
