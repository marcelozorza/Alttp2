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
## volume, e não como uma faixa de outra cor. O chão alto e o chão mais alto
## são beiras de desnível, cada um mais claro que o de baixo: a face do degrau
## (obstacles/ledge.gd) projeta a sombra deles.
##
## No mundo (outdoor), a parede é a mata, o chão é grama, e há caminho de
## terra e água. A árvore com chão ao sul mostra os troncos, como a parede
## mostra a face. As sombras seguem as mesmas regras.

const FLOOR := preload("res://art/floor.svg")
const FLOOR_ALT := preload("res://art/floor_alt.svg")
const HIGH_FLOOR := preload("res://art/high_floor.svg")
const HIGH_FLOOR_ALT := preload("res://art/high_floor_alt.svg")
const HIGHER_FLOOR := preload("res://art/higher_floor.svg")
const HIGHER_FLOOR_ALT := preload("res://art/higher_floor_alt.svg")
const WALL := preload("res://art/wall.svg")
const WALL_FACE := preload("res://art/wall_face.svg")
const GRASS := preload("res://art/grass.svg")
const GRASS_ALT := preload("res://art/grass_alt.svg")
const PATH := preload("res://art/path.svg")
const WATER := preload("res://art/water.svg")
const TREE := preload("res://art/tree.svg")
const TREE_FACE := preload("res://art/tree_face.svg")
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.3)
## Largura da sombra das paredes no chão, em pixels.
const SHADOW_SIZE := 3.0

## Ligado, desenha o mundo: mata, grama, caminho e água.
@export var outdoor := false

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
			if outdoor:
				_draw_outdoor(cell, character, origin)
				continue
			if character == "#":
				var below := map.tile(cell + Vector2i.DOWN)
				var faces_floor := below != "#" and below != " "
				draw_texture(WALL_FACE if faces_floor else WALL, origin)
				continue
			var alternate := (x + y) % 2 == 0
			match map.height_level(cell):
				2:
					draw_texture(HIGHER_FLOOR_ALT if alternate else HIGHER_FLOOR, origin)
				1:
					draw_texture(HIGH_FLOOR_ALT if alternate else HIGH_FLOOR, origin)
				_:
					draw_texture(FLOOR_ALT if alternate else FLOOR, origin)
			_draw_wall_shadows(cell, origin)


## Casa do mundo. A mata é a parede, e o resto é chão de grama, caminho ou
## água, com a sombra da mata vizinha.
func _draw_outdoor(cell: Vector2i, character: String, origin: Vector2) -> void:
	match character:
		"#":
			var below := map.tile(cell + Vector2i.DOWN)
			var faces_floor := below != "#" and below != " "
			draw_texture(TREE_FACE if faces_floor else TREE, origin)
			return
		"~":
			draw_texture(WATER, origin)
		",":
			draw_texture(PATH, origin)
		_:
			var alternate := (cell.x + cell.y) % 2 == 0
			draw_texture(GRASS_ALT if alternate else GRASS, origin)
	_draw_wall_shadows(cell, origin)


## Sombra no chão junto de uma parede ao norte ou a oeste.
func _draw_wall_shadows(cell: Vector2i, origin: Vector2) -> void:
	var tile := float(ChapterMap.TILE)
	if map.tile(cell + Vector2i.UP) == "#":
		draw_rect(Rect2(origin, Vector2(tile, SHADOW_SIZE)), SHADOW_COLOR)
	if map.tile(cell + Vector2i.LEFT) == "#":
		var top := SHADOW_SIZE if map.tile(cell + Vector2i.UP) == "#" else 0.0
		draw_rect(Rect2(origin + Vector2(0.0, top), Vector2(SHADOW_SIZE, tile - top)), SHADOW_COLOR)
