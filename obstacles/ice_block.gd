class_name IceBlock
extends Obstacle
## Bloco de gelo. Só o fogo o derrete. O azul claro é o mesmo do inimigo de
## gelo, que também só cai com fogo.

const ICE_COLOR := Color(0.62, 0.86, 1.0, 1.0)
const EDGE_COLOR := Color(0.4, 0.66, 0.85, 1.0)
const SHINE_COLOR := Color(0.92, 0.98, 1.0, 1.0)
## Ticks para derreter. A passagem abre no fim.
const MELT_TICKS := 15


func _weakness() -> Hit.Kind:
	return Hit.Kind.FIRE


func _open_delay() -> int:
	return MELT_TICKS


func _draw() -> void:
	var height := size.y
	if cleared:
		height = size.y * (1.0 - float(_ticks_since_clear()) / MELT_TICKS)
		if height <= 0.0:
			return
	var offset := _shake_offset()
	var rect := Rect2(offset + Vector2(0.0, size.y - height), Vector2(size.x, height))
	draw_rect(rect, ICE_COLOR)
	draw_rect(rect, EDGE_COLOR, false, 1.0)
	if cleared:
		return
	for y: int in int(size.y / 16.0):
		for x: int in int(size.x / 16.0):
			var origin := offset + Vector2(x, y) * 16.0
			draw_rect(Rect2(origin + Vector2(3.0, 3.0), Vector2(2.0, 6.0)), SHINE_COLOR)
			draw_rect(Rect2(origin + Vector2(6.0, 3.0), Vector2(1.0, 3.0)), SHINE_COLOR)
