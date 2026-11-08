class_name Minimap
extends RefCounted
## Minimapa do HUD (pedido de Marcelo em 2026-11-07): no canto inferior
## direito, só as salas em que o personagem já esteve, um bloco por sala de
## uma tela, com a sala atual piscando. Fora de um capítulo não há mapa. O
## mapa inteiro, casa por casa, é a tela de mapa (ui/map_screen.gd).
##
## Desde 2026-11-08 (pedido de Marcelo) cada passagem entre salas aparece como
## uma ligação escura cruzando a divisa, também quando a sala do outro lado
## ainda não foi visitada, para mostrar as saídas. Passagem é um trecho da
## divisa em que as duas casas, uma de cada lado, não são parede, incluindo
## portas trancadas e bloqueios.
##
## As funções estáticas desenham em qualquer CanvasItem.

const VISITED_COLOR := Color(0.85, 0.82, 0.7, 1.0)
const CURRENT_COLOR := Color(1.0, 1.0, 0.95, 1.0)
const LINK_COLOR := Color(0.35, 0.25, 0.16, 1.0)
## Espessura da ligação, em pixels, e quanto ela entra em cada sala.
const LINK_THICKNESS := 2.0
const LINK_REACH := 2.0
const NEIGHBORS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
const BACKGROUND := Color(0.05, 0.05, 0.08, 0.7)
## Pixels por sala de uma tela no HUD.
const HUD_CELL := Vector2(20.0, 10.0)
## Quadros de cada fase do pisca.
const BLINK_FRAMES := 20


## Fase do pisca: verdadeiro na metade acesa. Usa os quadros de processamento,
## que seguem contando com o jogo parado.
static func blink_on() -> bool:
	return floori(Engine.get_process_frames() / float(BLINK_FRAMES)) % 2 == 0


## Tamanho em pixels da grade de salas do capítulo, com cell pixels por sala.
static func rooms_size(chapter: Node, cell: Vector2) -> Vector2:
	var map: ChapterMap = chapter.get("map")
	var room_tiles: Vector2i = chapter.call("room_tiles")
	var columns := ceili(float(map.width) / room_tiles.x)
	var rows := ceili(float(map.height) / room_tiles.y)
	return Vector2(columns, rows) * cell


## As salas já visitadas, um bloco por sala de uma tela a partir de origin, com
## a sala atual piscando.
static func draw_rooms(canvas: CanvasItem, chapter: Node, origin: Vector2, cell: Vector2) -> void:
	var current: Rect2i = chapter.call("current_room")
	for room: Rect2i in chapter.call("visited_rooms"):
		var color := VISITED_COLOR
		if room == current and blink_on():
			color = CURRENT_COLOR
		var corner := origin + Vector2(room.position) * cell
		canvas.draw_rect(Rect2(corner, Vector2(room.size) * cell - Vector2.ONE), color)
	for room: Rect2i in chapter.call("visited_rooms"):
		_draw_links(canvas, chapter, room, origin, cell)


## Ligações da sala para as vizinhas: uma por trecho aberto de cada divisa.
static func _draw_links(
	canvas: CanvasItem, chapter: Node, room: Rect2i, origin: Vector2, cell: Vector2
) -> void:
	var map: ChapterMap = chapter.get("map")
	var room_tiles: Vector2i = chapter.call("room_tiles")
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			var screen := Vector2i(x, y)
			for side: Vector2i in NEIGHBORS:
				if room.has_point(screen + side):
					continue
				for opening: float in _openings(map, room_tiles, screen, side):
					_draw_link(canvas, origin, cell, screen, side, opening)


## Trechos abertos da divisa entre a tela e a vizinha do lado side, como a
## fração do lado (0 a 1) onde fica o meio de cada trecho.
static func _openings(
	map: ChapterMap, room_tiles: Vector2i, screen: Vector2i, side: Vector2i
) -> Array[float]:
	var along := Vector2i(abs(side.y), abs(side.x))
	var length := room_tiles.x if along.x != 0 else room_tiles.y
	var start := screen * room_tiles
	var inner := start
	if side.x > 0:
		inner.x += room_tiles.x - 1
	elif side.y > 0:
		inner.y += room_tiles.y - 1
	var result: Array[float] = []
	var run_start := -1
	for i in range(length + 1):
		var open := false
		if i < length:
			var here := inner + along * i
			open = _passable(map, here) and _passable(map, here + side)
		if open and run_start < 0:
			run_start = i
		elif not open and run_start >= 0:
			result.append((run_start + i) / 2.0 / length)
			run_start = -1
	return result


static func _passable(map: ChapterMap, cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= map.width or cell.y >= map.height:
		return false
	var character := map.tile(cell)
	return character != "#" and character != " "


## Marca escura cruzando a divisa da tela com a vizinha, na fração at do lado.
static func _draw_link(
	canvas: CanvasItem, origin: Vector2, cell: Vector2, screen: Vector2i, side: Vector2i, at: float
) -> void:
	var corner := origin + Vector2(screen) * cell
	var rect: Rect2
	if side.x != 0:
		var edge_x := corner.x + (cell.x if side.x > 0 else 0.0)
		var y := floorf(corner.y + at * cell.y - LINK_THICKNESS / 2.0)
		rect = Rect2(edge_x - LINK_REACH - 1.0, y, 2.0 * LINK_REACH + 1.0, LINK_THICKNESS)
	else:
		var edge_y := corner.y + (cell.y if side.y > 0 else 0.0)
		var x := floorf(corner.x + at * cell.x - LINK_THICKNESS / 2.0)
		rect = Rect2(x, edge_y - LINK_REACH - 1.0, LINK_THICKNESS, 2.0 * LINK_REACH + 1.0)
	canvas.draw_rect(rect, LINK_COLOR)
