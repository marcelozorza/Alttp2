class_name Minimap
extends RefCounted
## Minimapa do HUD (pedido de Marcelo em 2026-11-07): no canto inferior
## direito, só as salas em que o personagem já esteve, um bloco por sala de
## uma tela, com a sala atual piscando. Fora de um capítulo não há mapa. O
## mapa inteiro, casa por casa, é a tela de mapa (ui/map_screen.gd).
##
## As funções estáticas desenham em qualquer CanvasItem.

const VISITED_COLOR := Color(0.85, 0.82, 0.7, 1.0)
const CURRENT_COLOR := Color(1.0, 1.0, 0.95, 1.0)
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
