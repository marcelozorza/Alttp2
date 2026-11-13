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
## No mundo (outdoor), cada casa de mata é uma árvore, o chão é grama, e o
## caminho de terra, a água e os chãos das entradas ganham uma franja de
## grama nas bordas. A água ondula em dois quadros.

const GRASS: Array[Texture2D] = [
	preload("res://art/grass_1.svg"),
	preload("res://art/grass_2.svg"),
	preload("res://art/grass_3.svg"),
	preload("res://art/grass_4.svg"),
]
## Chão do mundo por caractere: duas variações de cada, ou dois quadros no
## caso da água.
const GROUNDS := {
	",": [preload("res://art/path_1.svg"), preload("res://art/path_2.svg")],
	"~": [preload("res://art/water_1.svg"), preload("res://art/water_2.svg")],
	"*": [preload("res://art/snow_1.svg"), preload("res://art/snow_2.svg")],
	"=": [preload("res://art/paving_1.svg"), preload("res://art/paving_2.svg")],
	";": [preload("res://art/rubble_1.svg"), preload("res://art/rubble_2.svg")],
}
const TREES: Array[Texture2D] = [preload("res://art/tree_1.svg"), preload("res://art/tree_2.svg")]
const GRASS_FRINGE := preload("res://art/grass_fringe.svg")
const GRASS_CORNER := preload("res://art/grass_corner.svg")
## Chão escuro no meio da mata, onde nenhuma casa vizinha é clareira.
const FOREST_FLOOR := Color("12332f")
## Ticks entre um quadro e outro da água.
const WATER_TICKS := 40
## Os oito vizinhos de uma casa.
const AROUND := [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
]
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
## Tema da dungeon. Sem um, a pedra do tutorial. Enquanto desenha, aponta
## para o tema da casa em questão (ver room_themes).
var theme: DungeonTheme
## Tema por sala de uma tela (Vector2i para DungeonTheme), para um capítulo
## que mistura temas, como a galeria. As salas fora do dicionário usam theme.
var room_themes := {}

var _default_theme: DungeonTheme
## Quadro da água do mundo, 0 ou 1.
var _water_frame := 0
## Um nó de chamas por tema, porque cada tema tem a sua chama.
var _flames_by_theme := {}


func _physics_process(_delta: float) -> void:
	if not outdoor:
		return
	var frame := (Clock.tick / WATER_TICKS) % 2
	if frame != _water_frame:
		_water_frame = frame
		queue_redraw()


func _draw() -> void:
	if not map:
		return
	if not theme:
		theme = DungeonTheme.stone()
	_default_theme = theme
	var tile := float(ChapterMap.TILE)
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			var character := map.tile(cell)
			if character == " ":
				continue
			theme = _theme_at(cell)
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
		_draw_wall_outlines()
		_draw_decor()
	theme = _default_theme


## Nome do tema da casa, para os bloqueios que mudam de desenho com ele.
func theme_name_at(cell: Vector2i) -> String:
	var base := _default_theme if _default_theme else theme
	var found: DungeonTheme = room_themes.get(
		Vector2i(floori(float(cell.x) / ROOM_TILES.x), floori(float(cell.y) / ROOM_TILES.y)), base
	)
	return found.name if found else "stone"


## Tema da casa: o da sala de uma tela em que ela está, ou o padrão.
func _theme_at(cell: Vector2i) -> DungeonTheme:
	var screen := Vector2i(
		floori(float(cell.x) / ROOM_TILES.x), floori(float(cell.y) / ROOM_TILES.y)
	)
	return room_themes.get(screen, _default_theme)


## Casa do mundo. A grama é a base. O caminho, a água, a neve, a calçada e
## as lajes ganham uma franja de grama em cada lado que encosta nela, e um
## canto arredondado onde dois lados se encontram. Cada casa de mata é uma
## árvore, sobre a grama na beira da clareira e sobre o chão escuro no meio.
func _draw_outdoor(cell: Vector2i, character: String, origin: Vector2) -> void:
	var tile := float(ChapterMap.TILE)
	if character == "#":
		if _near_clearing(cell):
			draw_texture(GRASS[0], origin)
		else:
			draw_rect(Rect2(origin, Vector2(tile, tile)), FOREST_FLOOR)
		draw_texture(TREES[_chance(cell, 11) % TREES.size()], origin)
		return
	var ground := _ground_of(cell)
	if ground == ".":
		draw_texture(_grass_at(cell), origin)
		return
	var textures: Array = GROUNDS[ground]
	var index := (cell.x + cell.y) % 2
	if ground == "~":
		index = (index + _water_frame) % 2
	draw_texture(textures[index], origin)
	var center := origin + Vector2(tile, tile) / 2.0
	var grassy: Array[bool] = []
	for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		grassy.append(_is_grassy(cell + step))
	for side: int in 4:
		if grassy[side]:
			draw_set_transform(center, side * PI / 2.0)
			draw_texture(GRASS_FRINGE, Vector2(-tile, -tile) / 2.0)
	for side: int in 4:
		# Canto entre o lado anterior e este: o primeiro é o de cima à esquerda.
		if grassy[side] and grassy[(side + 3) % 4]:
			draw_set_transform(center, side * PI / 2.0)
			draw_texture(GRASS_CORNER, Vector2(-tile, -tile) / 2.0)
	draw_set_transform(Vector2.ZERO)


## Tipo de chão de uma casa do mundo. O início, a pedra de salvamento e as
## entradas ficam sobre o caminho quando há caminho ao lado, senão na grama.
func _ground_of(cell: Vector2i) -> String:
	var character := map.tile(cell)
	if character == "." or GROUNDS.has(character):
		return character
	for step: Vector2i in ChapterMap.STEPS:
		if map.tile(cell + step) == ",":
			return ","
	return "."


## Grama ou mata: os lados em que outro chão ganha a franja de grama.
func _is_grassy(cell: Vector2i) -> bool:
	var character := map.tile(cell)
	if character == "#" or character == " ":
		return true
	if character.is_valid_int():
		return false
	return _ground_of(cell) == "."


## Variação da grama: quase sempre lisa, às vezes com tufos ou flores.
func _grass_at(cell: Vector2i) -> Texture2D:
	var roll := _chance(cell, 9)
	if roll < 55:
		return GRASS[0]
	if roll < 80:
		return GRASS[1]
	return GRASS[2] if roll < 91 else GRASS[3]


## Árvore da beira da clareira: alguma das oito casas vizinhas não é mata.
func _near_clearing(cell: Vector2i) -> bool:
	for step: Vector2i in AROUND:
		var character := map.tile(cell + step)
		if character != "#" and character != " ":
			return true
	return false


## Traço grosso na beira das paredes, onde elas encontram o chão: o mesmo
## contorno de fora dos personagens e dos objetos (pedido de Marcelo em
## 2026-11-12). Fica por dentro da casa da parede. Num canto para dentro, um
## quadradinho fecha o encontro dos dois traços.
func _draw_wall_outlines() -> void:
	var tile := float(ChapterMap.TILE)
	var ink := DoorArt.OUTLINE_COLOR
	var width := DoorArt.OUTLINE
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			if map.tile(cell) != "#":
				continue
			var rect := Rect2(Vector2(cell) * tile, Vector2(tile, tile))
			var sides := [
				_is_floor(cell + Vector2i.UP),
				_is_floor(cell + Vector2i.RIGHT),
				_is_floor(cell + Vector2i.DOWN),
				_is_floor(cell + Vector2i.LEFT),
			]
			DoorArt.draw_outline(self, rect, sides)
			for corner: Vector2i in [
				Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)
			]:
				var open_x := _is_floor(cell + Vector2i(corner.x, 0))
				var open_y := _is_floor(cell + Vector2i(0, corner.y))
				if open_x or open_y or not _is_floor(cell + corner):
					continue
				var at := (
					rect.position
					+ Vector2(
						tile - width if corner.x > 0 else 0.0, tile - width if corner.y > 0 else 0.0
					)
				)
				draw_rect(Rect2(at, Vector2(width, width)), ink)


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
	var flame_positions := {}
	for y: int in map.height:
		_draw_wall_row(y, flame_positions)
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			theme = _theme_at(cell)
			if _is_plain(cell):
				_draw_floor_decor(cell)
	for flames: Flames in _flames_by_theme.values():
		flames.positions = []
	for flame_theme: DungeonTheme in flame_positions:
		var flames: Flames = _flames_by_theme.get(flame_theme)
		if not flames:
			flames = Flames.new()
			add_child(flames)
			_flames_by_theme[flame_theme] = flames
		flames.frames = flame_theme.flames
		flames.positions = flame_positions[flame_theme]


## Arandelas, peças penduradas e estalactites nas faces de parede de uma
## fileira, com um vão entre dois adornos.
func _draw_wall_row(y: int, flame_positions: Dictionary) -> void:
	var tile := float(ChapterMap.TILE)
	var last_prop := -WALL_PROP_GAP
	for x: int in map.width:
		var cell := Vector2i(x, y)
		if map.tile(cell) != "#" or not _faces_floor(cell):
			continue
		theme = _theme_at(cell)
		var origin := Vector2(cell) * tile
		var decorated := false
		if x - last_prop >= WALL_PROP_GAP:
			decorated = _draw_wall_prop(cell, origin, flame_positions)
		if decorated:
			last_prop = x
		elif theme.icicles and _chance(cell, 3) < theme.icicle_chance:
			draw_texture(theme.icicles, origin + Vector2(0.0, tile - FACE_DEPTH))


## Uma arandela ou uma peça pendurada na face, se o sorteio der. Diz se pôs.
func _draw_wall_prop(cell: Vector2i, origin: Vector2, flame_positions: Dictionary) -> bool:
	if theme.sconce and _chance(cell, 1) * theme.sconce_spacing < 100:
		var corner := DungeonTheme.centered(theme.sconce, origin)
		draw_texture(theme.sconce, corner)
		if not theme.flames.is_empty():
			var positions: Array[Vector2] = flame_positions.get(theme, [] as Array[Vector2])
			positions.append(corner + theme.flame_offset)
			flame_positions[theme] = positions
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
	var tile := float(ChapterMap.TILE)
	var screens := Vector2i(
		ceili(float(map.width) / ROOM_TILES.x), ceili(float(map.height) / ROOM_TILES.y)
	)
	for sy: int in screens.y:
		for sx: int in screens.x:
			theme = _theme_at(Vector2i(sx, sy) * ROOM_TILES)
			if not theme.carpet:
				continue
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
