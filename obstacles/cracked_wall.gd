class_name CrackedWall
extends Obstacle
## Parede rachada. Só a explosão da bomba abre a passagem. As rachaduras claras
## são a marca que o jogador aprende a procurar.

const WALL_COLOR := Color(0.17, 0.17, 0.22, 1.0)
const CRACK_COLOR := Color(0.66, 0.64, 0.6, 1.0)
const DEBRIS_COLOR := Color(0.5, 0.47, 0.42, 1.0)
## Rachadura desenhada em cada bloco de 16 pixels.
const CRACK := [Vector2(3, 1), Vector2(7, 5), Vector2(5, 9), Vector2(10, 12), Vector2(12, 15)]
const BRANCH := [Vector2(7, 5), Vector2(12, 3)]
## Ticks em que os destroços aparecem depois da explosão.
const DEBRIS_TICKS := 20


func _draw() -> void:
	if cleared:
		_draw_debris()
		return
	var offset := _shake_offset()
	draw_rect(Rect2(offset, size), WALL_COLOR)
	for y: int in int(size.y / 16.0):
		for x: int in int(size.x / 16.0):
			var origin := offset + Vector2(x, y) * 16.0
			draw_polyline(_translated(CRACK, origin), CRACK_COLOR, 1.0)
			draw_polyline(_translated(BRANCH, origin), CRACK_COLOR, 1.0)


func _draw_debris() -> void:
	var elapsed := _ticks_since_clear()
	if elapsed >= DEBRIS_TICKS:
		return
	var color := Color(DEBRIS_COLOR, 1.0 - float(elapsed) / DEBRIS_TICKS)
	for i: int in 8:
		var angle := TAU * i / 8.0
		var center := size / 2.0 + Vector2(cos(angle), sin(angle)) * (4.0 + elapsed * 0.6)
		draw_rect(Rect2(center - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), color)


static func _translated(points: Array, origin: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		result.append(origin + point)
	return result
