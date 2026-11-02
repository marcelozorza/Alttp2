class_name MapView
extends Node2D
## Desenha o chão e as paredes de um ChapterMap. O desenho é feito uma vez e
## fica guardado. Os bloqueios e os objetos se desenham sozinhos por cima.

const FLOOR_COLOR := Color(0.33, 0.35, 0.3, 1.0)
const FLOOR_ALT_COLOR := Color(0.31, 0.33, 0.28, 1.0)
const HIGH_COLOR := Color(0.48, 0.5, 0.42, 1.0)
const HIGH_ALT_COLOR := Color(0.46, 0.48, 0.4, 1.0)
const WALL_COLOR := Color(0.17, 0.17, 0.22, 1.0)
const WALL_FACE_COLOR := Color(0.25, 0.25, 0.31, 1.0)
## Altura da faixa clara da parede onde ela encontra o chão ao sul, que dá o
## volume da perspectiva 3/4.
const WALL_FACE_HEIGHT := 4.0

var map: ChapterMap


func _draw() -> void:
	if not map:
		return
	var tile := float(ChapterMap.TILE)
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			var character := map.tile(cell)
			if character == " ":
				continue
			var rect := Rect2(Vector2(cell) * tile, Vector2(tile, tile))
			if character == "#":
				draw_rect(rect, WALL_COLOR)
				var below := map.tile(cell + Vector2i.DOWN)
				if below != "#" and below != " ":
					var face_position := rect.position + Vector2(0.0, tile - WALL_FACE_HEIGHT)
					draw_rect(
						Rect2(face_position, Vector2(tile, WALL_FACE_HEIGHT)), WALL_FACE_COLOR
					)
				continue
			var alternate := (x + y) % 2 == 0
			if map.is_high(cell):
				draw_rect(rect, HIGH_ALT_COLOR if alternate else HIGH_COLOR)
			else:
				draw_rect(rect, FLOOR_ALT_COLOR if alternate else FLOOR_COLOR)
