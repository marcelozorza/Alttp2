class_name Web
extends Obstacle
## Teia do laboratório: barreira que só o fogo remove. A espada e a bomba só
## a fazem tremer. É o bloqueio de "queimar o que tampa a passagem", parente
## do gelo, que derrete. Arte provisória.

const STRAND_COLOR := Color(0.92, 0.92, 0.96, 0.9)
const BURN_COLOR := Color(1.0, 0.6, 0.2, 0.9)


func _opens_with(kind: Hit.Kind) -> bool:
	return Hit.is_fire(kind)


func _clear_sound() -> StringName:
	return &"fire_hit"


func _draw() -> void:
	var burning := cleared and _ticks_since_clear() <= _clear_animation_ticks()
	if cleared and not burning:
		return
	var color := BURN_COLOR if burning else STRAND_COLOR
	if burning:
		color.a *= 1.0 - float(_ticks_since_clear()) / _clear_animation_ticks()
	var shake := _shake_offset()
	var step := 8.0
	var x := 0.0
	while x <= size.x:
		draw_line(Vector2(x, 0.0) + shake, Vector2(size.x - x, size.y) + shake, color, 1.0)
		x += step
	var y := 0.0
	while y <= size.y:
		draw_line(Vector2(0.0, y) + shake, Vector2(size.x, size.y - y) + shake, color, 1.0)
		y += step
	draw_rect(Rect2(shake, size), color, false, 2.0)
