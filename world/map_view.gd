class_name MapView
extends Node2D
## Desenha o chão e as paredes de um ChapterMap com os tiles de art/. O
## desenho é feito uma vez e fica guardado, como o mapa de tiles na memória de
## vídeo do Super Nintendo. Os bloqueios e os objetos se desenham sozinhos por
## cima.
##
## A parede com chão logo ao sul usa o tile com a face de tijolos, que dá o
## volume da perspectiva 3/4. O chão alterna entre duas variações, como um
## tabuleiro, para quebrar a repetição.
##
## A luz vem do alto à esquerda, então toda parede projeta uma sombra curta no
## chão ao sul e no chão a leste. É a sombra que faz a parede ser lida como
## volume, e não como uma faixa de outra cor. O chão alto é a beira de um
## desnível: a face do degrau (obstacles/ledge.gd) projeta a sombra dele.

const FLOOR := preload("res://art/floor.svg")
const FLOOR_ALT := preload("res://art/floor_alt.svg")
const HIGH_FLOOR := preload("res://art/high_floor.svg")
const HIGH_FLOOR_ALT := preload("res://art/high_floor_alt.svg")
const WALL := preload("res://art/wall.svg")
const WALL_FACE := preload("res://art/wall_face.svg")
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.3)
## Largura da sombra das paredes no chão, em pixels.
const SHADOW_SIZE := 3.0

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
			var origin := Vector2(cell) * tile
			if character == "#":
				var below := map.tile(cell + Vector2i.DOWN)
				var faces_floor := below != "#" and below != " "
				draw_texture(WALL_FACE if faces_floor else WALL, origin)
				continue
			var alternate := (x + y) % 2 == 0
			if map.is_high(cell):
				draw_texture(HIGH_FLOOR_ALT if alternate else HIGH_FLOOR, origin)
			else:
				draw_texture(FLOOR_ALT if alternate else FLOOR, origin)
			_draw_wall_shadows(cell, origin)


## Sombra no chão junto de uma parede ao norte ou a oeste.
func _draw_wall_shadows(cell: Vector2i, origin: Vector2) -> void:
	var tile := float(ChapterMap.TILE)
	if map.tile(cell + Vector2i.UP) == "#":
		draw_rect(Rect2(origin, Vector2(tile, SHADOW_SIZE)), SHADOW_COLOR)
	if map.tile(cell + Vector2i.LEFT) == "#":
		var top := SHADOW_SIZE if map.tile(cell + Vector2i.UP) == "#" else 0.0
		draw_rect(Rect2(origin + Vector2(0.0, top), Vector2(SHADOW_SIZE, tile - top)), SHADOW_COLOR)
