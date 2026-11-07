class_name MapView
extends Node2D
## Desenha o chão e as paredes de um ChapterMap com os tiles de art/. O
## desenho é feito uma vez e fica guardado, como o mapa de tiles na memória de
## vídeo do Super Nintendo. Os bloqueios e os objetos se desenham sozinhos por
## cima.
##
## Toda parede mostra o topo escuro e, de cada lado em que há chão, uma face
## de tijolos iluminada, em perspectiva forçada com a câmera no centro da
## sala, como no castelo de Hyrule do A Link to the Past (pedido de Marcelo em
## 2026-11-07, que via a parede de cima clara e as dos lados escuras). A face
## tem FACE_DEPTH pixels e o resto da casa é topo. Onde duas faces se
## encontram, uma diagonal as separa, da quina do topo à quina do chão. O chão
## alterna entre duas variações, como um tabuleiro, para quebrar a repetição.
##
## A luz vem do alto à esquerda, então toda parede projeta uma sombra curta no
## chão ao sul e no chão a leste. É a sombra que faz a parede ser lida como
## volume, e não como uma faixa de outra cor. O chão alto e o chão mais alto
## são beiras de desnível, cada um mais claro que o de baixo: a face do degrau
## (obstacles/ledge.gd) projeta a sombra deles.
##
## Numa dungeon, os tiles e os adornos vêm do tema (world/dungeon_theme.gd).
## Os adornos são espalhados por um sorteio fixo, calculado da posição de cada
## casa, para a sala ser sempre igual a si mesma: arandelas e peças penduradas
## nas faces das paredes, peças no chão encostado numa parede, manchas no chão,
## estalactites, teias nos cantos internos e um tapete no centro das salas de
## chão liso. Nenhum adorno tem colisão. As chamas das tochas ficam num nó
## filho (world/flames.gd), porque piscam.
##
## No mundo (outdoor), a parede é a mata, o chão é grama, e há caminho de
## terra e água. A árvore com chão ao sul mostra os troncos, como a parede
## mostra a face. As sombras seguem as mesmas regras.

const GRASS := preload("res://art/grass.svg")
const GRASS_ALT := preload("res://art/grass_alt.svg")
const PATH := preload("res://art/path.svg")
const WATER := preload("res://art/water.svg")
const TREE := preload("res://art/tree.svg")
const TREE_FACE := preload("res://art/tree_face.svg")
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.3)
## Largura da sombra das paredes no chão, em pixels.
const SHADOW_SIZE := 6.0
## Caracteres de chão liso, onde os adornos de chão podem ficar.
const PLAIN_FLOOR := ".:^"
## Caracteres sob os quais o tapete pode ficar: chão comum, o início do
## personagem e os inimigos, que andam por cima dele.
const CARPET_FLOOR := ".@muiwsxyz*&%$"
## Tamanho de uma tela de sala, em casas, para o tapete.
const ROOM_TILES := Vector2i(20, 10)
## Tamanho do tapete, em casas, no centro da sala.
const CARPET_TILES := Vector2i(6, 4)
## Distância mínima, em casas, entre dois adornos na mesma fileira de parede.
const WALL_PROP_GAP := 2
## Profundidade da face de uma parede, em pixels. O resto da casa é o topo.
const FACE_DEPTH := 24.0
## Profundidade de cada face quando a parede tem chão dos dois lados.
const HALF_FACE := 16.0
## Os quatro cantos diagonais de uma casa.
const CORNERS := [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]
## Largura das molduras do tapete, em pixels.
const FRAME := 2.0

## Ligado, desenha o mundo: mata, grama, caminho e água.
@export var outdoor := false

var map: ChapterMap
## Tema da dungeon. Sem um, a pedra do tutorial.
var theme: DungeonTheme

var _flames: Flames


func _ready() -> void:
	_flames = Flames.new()
	add_child(_flames)


func _draw() -> void:
	if not map:
		return
	if not theme:
		theme = DungeonTheme.stone()
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
				_draw_wall(cell, origin)
				continue
			var alternate := (x + y) % 2 == 0
			draw_texture(theme.floor_texture(map.height_level(cell), alternate), origin)
			if theme.overlay and _is_plain(cell) and _chance(cell, 4) < theme.overlay_chance:
				draw_texture(theme.overlay, origin)
			_draw_wall_shadows(cell, origin)
	if not outdoor:
		_draw_decor()


## Casa do mundo. A mata é a parede, e o resto é chão de grama, caminho ou
## água, com a sombra da mata vizinha.
func _draw_outdoor(cell: Vector2i, character: String, origin: Vector2) -> void:
	match character:
		"#":
			draw_texture(TREE_FACE if _faces_floor(cell) else TREE, origin)
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


## Parede: o topo e uma face de cada lado em que há chão. Com chão dos dois
## lados opostos, cada face fica com metade da casa. As faces laterais são
## polígonos: onde encostam na face de frente ou na de trás, a diagonal vai da
## quina do topo à quina do chão, e é a lateral que fica do lado do seu eixo,
## como nas ombreiras das portas do A Link to the Past.
func _draw_wall(cell: Vector2i, origin: Vector2) -> void:
	var tile := float(ChapterMap.TILE)
	draw_texture(theme.wall, origin)
	var floor_n := _is_floor(cell + Vector2i.UP)
	var floor_s := _is_floor(cell + Vector2i.DOWN)
	var floor_w := _is_floor(cell + Vector2i.LEFT)
	var floor_e := _is_floor(cell + Vector2i.RIGHT)
	var depth_n := _face_depth(floor_n, floor_s)
	var depth_s := _face_depth(floor_s, floor_n)
	var depth_w := _face_depth(floor_w, floor_e)
	var depth_e := _face_depth(floor_e, floor_w)
	if floor_s:
		var band: Array = [
			Vector2(0.0, tile - depth_s),
			Vector2(tile, tile - depth_s),
			Vector2(tile, tile),
			Vector2(0.0, tile)
		]
		_draw_face(theme.wall_face, origin, band, false, false)
	if floor_n:
		var band: Array = [
			Vector2.ZERO, Vector2(tile, 0.0), Vector2(tile, depth_n), Vector2(0.0, depth_n)
		]
		_draw_face(theme.wall_face, origin, band, false, true)
	if floor_e:
		var band: Array = [
			Vector2(tile - depth_e, depth_n),
			Vector2(tile, 0.0),
			Vector2(tile, tile),
			Vector2(tile - depth_e, tile - depth_s),
		]
		_draw_face(theme.wall_side, origin, band, false, false)
	if floor_w:
		var band: Array = [
			Vector2.ZERO,
			Vector2(depth_w, depth_n),
			Vector2(depth_w, tile - depth_s),
			Vector2(0.0, tile)
		]
		_draw_face(theme.wall_side, origin, band, true, false)
	for corner: Vector2i in CORNERS:
		var orthogonal_floor := (
			_is_floor(cell + Vector2i(corner.x, 0)) or _is_floor(cell + Vector2i(0, corner.y))
		)
		if _is_floor(cell + corner) and not orthogonal_floor:
			_draw_inner_corner(origin, corner)


## Profundidade da face de um lado: nada sem chão ali, metade com chão também
## do lado oposto.
func _face_depth(has_floor: bool, opposite_floor: bool) -> float:
	if not has_floor:
		return 0.0
	return HALF_FACE if opposite_floor else FACE_DEPTH


## Canto de dentro da sala: a casa de parede com chão só na diagonal. A face
## de frente da parede vizinha e a lateral da outra se encontram numa diagonal
## da quina do topo à quina do chão, com a de frente acima dela.
func _draw_inner_corner(origin: Vector2, corner: Vector2i) -> void:
	var tile := float(ChapterMap.TILE)
	var cap := tile - FACE_DEPTH
	var flip_h := corner.x < 0
	var flip_v := corner.y < 0
	var front: Array = [Vector2(cap, cap), Vector2(tile, cap), Vector2(tile, tile)]
	var side: Array = [Vector2(cap, cap), Vector2(tile, tile), Vector2(cap, tile)]
	_draw_face(theme.wall_face, origin, _mirror(front, flip_h, flip_v), false, flip_v)
	_draw_face(theme.wall_side, origin, _mirror(side, flip_h, flip_v), flip_h, false)


## Espelha pontos de uma casa em pixels, no eixo pedido.
func _mirror(points: Array, flip_h: bool, flip_v: bool) -> Array:
	var tile := float(ChapterMap.TILE)
	var result: Array = []
	for point: Vector2 in points:
		result.append(
			Vector2(tile - point.x if flip_h else point.x, tile - point.y if flip_v else point.y)
		)
	return result


## Pedaço de uma textura de parede recortado num polígono, em pixels a partir
## do canto da casa. A textura cobre a casa inteira, espelhada se for o caso,
## então cada ponto lê a textura na mesma posição em que fica na casa.
func _draw_face(
	texture: Texture2D, origin: Vector2, points: Array, flip_h: bool, flip_v: bool
) -> void:
	var tile := float(ChapterMap.TILE)
	var polygon := PackedVector2Array()
	var uvs := PackedVector2Array()
	for point: Vector2 in points:
		if not polygon.is_empty() and polygon[polygon.size() - 1] == origin + point:
			continue
		polygon.append(origin + point)
		var uv := point / tile
		uvs.append(Vector2(1.0 - uv.x if flip_h else uv.x, 1.0 - uv.y if flip_v else uv.y))
	if polygon.size() > 1 and polygon[0] == polygon[polygon.size() - 1]:
		polygon.remove_at(polygon.size() - 1)
		uvs.remove_at(uvs.size() - 1)
	if polygon.size() < 3:
		return
	draw_polygon(polygon, PackedColorArray([Color.WHITE]), uvs, texture)


func _is_floor(cell: Vector2i) -> bool:
	var character := map.tile(cell)
	return character != "#" and character != " "


## Parede com chão logo ao sul, que mostra a face de frente: é nela que ficam
## as arandelas e as peças penduradas.
func _faces_floor(cell: Vector2i) -> bool:
	return _is_floor(cell + Vector2i.DOWN)


func _is_plain(cell: Vector2i) -> bool:
	return PLAIN_FLOOR.contains(map.tile(cell))


## Sorteio fixo de uma casa, de 0 a 99. O sal separa os sorteios de adornos
## diferentes na mesma casa.
static func _chance(cell: Vector2i, salt: int) -> int:
	var h := (cell.x * 73856093) ^ (cell.y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return (h & 0x7fffffff) % 100


## Os adornos do tema, por cima dos tiles e das sombras.
func _draw_decor() -> void:
	_draw_carpets()
	var flame_positions: Array[Vector2] = []
	for y: int in map.height:
		_draw_wall_row(y, flame_positions)
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			if _is_plain(cell):
				_draw_floor_decor(cell)
	_flames.frames = theme.flames
	_flames.positions = flame_positions


## Arandelas, peças penduradas e estalactites nas faces de parede de uma
## fileira, com um vão entre dois adornos.
func _draw_wall_row(y: int, flame_positions: Array[Vector2]) -> void:
	var tile := float(ChapterMap.TILE)
	var last_prop := -WALL_PROP_GAP
	for x: int in map.width:
		var cell := Vector2i(x, y)
		if map.tile(cell) != "#" or not _faces_floor(cell):
			continue
		var origin := Vector2(cell) * tile
		var decorated := false
		if x - last_prop >= WALL_PROP_GAP:
			decorated = _draw_wall_prop(cell, origin, flame_positions)
		if decorated:
			last_prop = x
		elif theme.icicles and _chance(cell, 3) < theme.icicle_chance:
			draw_texture(theme.icicles, origin + Vector2(0.0, tile - FACE_DEPTH))


## Uma arandela ou uma peça pendurada na face, se o sorteio der. Diz se pôs.
func _draw_wall_prop(cell: Vector2i, origin: Vector2, flame_positions: Array[Vector2]) -> bool:
	if theme.sconce and _chance(cell, 1) * theme.sconce_spacing < 100:
		var corner := DungeonTheme.centered(theme.sconce, origin)
		draw_texture(theme.sconce, corner)
		if not theme.flames.is_empty():
			flame_positions.append(corner + theme.flame_offset)
		return true
	if theme.hangings.is_empty() or _chance(cell, 2) >= theme.hanging_chance:
		return false
	var hanging: Texture2D = theme.hangings[_chance(cell, 7) % theme.hangings.size()]
	var corner := DungeonTheme.hanging_origin(hanging, origin)
	if corner.y < origin.y and map.tile(cell + Vector2i.UP) != "#":
		return false
	draw_texture(hanging, corner)
	return true


## Teia num canto interno e peça no chão junto de uma parede.
func _draw_floor_decor(cell: Vector2i) -> void:
	var tile := float(ChapterMap.TILE)
	var origin := Vector2(cell) * tile
	var wall_above := map.tile(cell + Vector2i.UP) == "#"
	var wall_left := map.tile(cell + Vector2i.LEFT) == "#"
	var wall_right := map.tile(cell + Vector2i.RIGHT) == "#"
	if theme.cobweb and wall_above and _chance(cell, 6) < theme.cobweb_chance:
		var size := theme.cobweb.get_size()
		if wall_left:
			draw_texture(theme.cobweb, origin)
			return
		if wall_right:
			var flipped := Rect2(origin + Vector2(tile, 0.0), Vector2(-size.x, size.y))
			draw_texture_rect(theme.cobweb, flipped, false)
			return
	if theme.floor_props.is_empty() or not (wall_above or wall_left or wall_right):
		return
	if _chance(cell, 5) >= theme.floor_prop_chance:
		return
	var prop: Texture2D = theme.floor_props[_chance(cell, 8) % theme.floor_props.size()]
	draw_texture(prop, DungeonTheme.floor_prop_origin(prop, origin))


## Tapete no centro de cada tela de sala cujo centro é chão liso e baixo.
func _draw_carpets() -> void:
	if not theme.carpet:
		return
	var tile := float(ChapterMap.TILE)
	var screens := Vector2i(
		ceili(float(map.width) / ROOM_TILES.x), ceili(float(map.height) / ROOM_TILES.y)
	)
	for sy: int in screens.y:
		for sx: int in screens.x:
			var corner := Vector2i(sx, sy) * ROOM_TILES + (ROOM_TILES - CARPET_TILES) / 2
			var area := Rect2i(corner, CARPET_TILES)
			if not _is_flat(area):
				continue
			for y: int in range(area.position.y, area.end.y):
				for x: int in range(area.position.x, area.end.x):
					draw_texture(theme.carpet, Vector2(x, y) * tile)
			var pixels := Rect2(Vector2(area.position) * tile, Vector2(area.size) * tile)
			_draw_frame(pixels, theme.carpet_edge)
			_draw_frame(pixels.grow(-4.0), theme.carpet_border)


## Área só de chão comum, sem desnível, bloqueio nem baú.
func _is_flat(area: Rect2i) -> bool:
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if not CARPET_FLOOR.contains(map.tile(Vector2i(x, y))):
				return false
	return true


## Moldura de FRAME pixels de largura.
func _draw_frame(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, FRAME)), color)
	draw_rect(
		Rect2(rect.position + Vector2(0.0, rect.size.y - FRAME), Vector2(rect.size.x, FRAME)), color
	)
	draw_rect(Rect2(rect.position, Vector2(FRAME, rect.size.y)), color)
	draw_rect(
		Rect2(rect.position + Vector2(rect.size.x - FRAME, 0.0), Vector2(FRAME, rect.size.y)), color
	)
