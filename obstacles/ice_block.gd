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


func _draw() -> void:
	_draw_shadow()
	var height := size.y
	if cleared:
		height = size.y * (1.0 - float(_ticks_since_clear()) / _melt_ticks())
		if height <= 0.0:
			return
	# Derretendo, cada bloco de 16 pixels afunda no chão: some a parte de cima.
	var offset := _shake_offset()
	var visible_part := height / size.y
	var rows := int(size.y / 16.0)
	for y: int in rows:
		var texture := _front_texture() if y == rows - 1 else _top_texture()
		for x: int in int(size.x / 16.0):
			var cell_height := 16.0 * visible_part
			var origin := offset + Vector2(x, y) * 16.0 + Vector2(0.0, 16.0 - cell_height)
			var source := Rect2(0.0, 16.0 - cell_height, 16.0, cell_height)
			draw_texture_rect_region(texture, Rect2(origin, source.size), source)
