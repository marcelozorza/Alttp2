class_name IceBlock
extends Obstacle
## Bloco de gelo. Só o fogo o derrete. O azul claro é o mesmo do inimigo de
## gelo, que também só cai com fogo.

const TEXTURE := preload("res://art/ice.svg")
## Ticks para derreter. A passagem abre no fim.
const MELT_TICKS := 15


func _weakness() -> Hit.Kind:
	return Hit.Kind.FIRE


func _open_delay() -> int:
	return MELT_TICKS


func _clear_sound() -> StringName:
	return &"ice_melt"


func _draw() -> void:
	var height := size.y
	if cleared:
		height = size.y * (1.0 - float(_ticks_since_clear()) / MELT_TICKS)
		if height <= 0.0:
			return
	# Derretendo, cada bloco de 16 pixels afunda no chão: some a parte de cima.
	var offset := _shake_offset()
	var visible_part := height / size.y
	for y: int in int(size.y / 16.0):
		for x: int in int(size.x / 16.0):
			var cell_height := 16.0 * visible_part
			var origin := offset + Vector2(x, y) * 16.0 + Vector2(0.0, 16.0 - cell_height)
			var source := Rect2(0.0, 16.0 - cell_height, 16.0, cell_height)
			draw_texture_rect_region(TEXTURE, Rect2(origin, source.size), source)
