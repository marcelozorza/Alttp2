class_name Minimap
extends Control
## Mapa da dungeon (pedido de Marcelo em 2026-11-07). O HUD desenha, no canto
## inferior direito, só as salas em que o personagem já esteve, um bloco por
## sala de uma tela, com a sala atual piscando. O menu de pausa mostra o mapa
## inteiro, com um pixel por casa, as salas já visitadas claras e as outras
## escuras, e o personagem piscando. Fora de um capítulo não há mapa.
##
## As funções estáticas desenham em qualquer CanvasItem. O nó em si é o mapa
## inteiro do menu de pausa, que mede o próprio tamanho pelo capítulo.

const VISITED_COLOR := Color(0.85, 0.82, 0.7, 1.0)
const CURRENT_COLOR := Color(1.0, 1.0, 0.95, 1.0)
const UNSEEN_COLOR := Color(0.36, 0.35, 0.4, 1.0)
const WALL_COLOR := Color(0.2, 0.2, 0.26, 1.0)
const UNSEEN_WALL_COLOR := Color(0.12, 0.12, 0.15, 1.0)
const PLAYER_COLOR := Color(0.9, 0.2, 0.25, 1.0)
const BACKGROUND := Color(0.05, 0.05, 0.08, 0.7)
const NOTHING := Color(0.0, 0.0, 0.0, 0.0)
## Pixels por sala de uma tela no HUD.
const HUD_CELL := Vector2(20.0, 10.0)
## Quadros de cada fase do pisca.
const BLINK_FRAMES := 20

## Quantas vezes o mapa inteiro é ampliado, com um pixel por casa antes disso.
@export_range(1, 8, 1) var full_scale := 4


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	var chapter := _chapter()
	var wanted := Vector2.ZERO
	if chapter:
		var map: ChapterMap = chapter.get("map")
		wanted = Vector2(map.width, map.height) * full_scale
	if custom_minimum_size != wanted:
		custom_minimum_size = wanted
	queue_redraw()


func _draw() -> void:
	var chapter := _chapter()
	if chapter:
		draw_full(self, chapter, Vector2.ZERO, full_scale)


func _chapter() -> Node:
	return get_tree().get_first_node_in_group("chapter")


## Fase do pisca: verdadeiro na metade acesa. Usa os quadros de processamento,
## que seguem contando no menu de pausa.
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


## O mapa inteiro, casa por casa, ampliado scale vezes: paredes escuras, chão
## claro nas salas já visitadas e apagado nas outras, e o personagem piscando.
## Casas vizinhas da mesma cor viram um retângulo só.
static func draw_full(canvas: CanvasItem, chapter: Node, origin: Vector2, scale: int) -> void:
	var map: ChapterMap = chapter.get("map")
	var room_tiles: Vector2i = chapter.call("room_tiles")
	var seen := {}
	for room: Rect2i in chapter.call("visited_rooms"):
		for y: int in range(room.position.y, room.end.y):
			for x: int in range(room.position.x, room.end.x):
				seen[Vector2i(x, y)] = true
	for y: int in map.height:
		var x := 0
		while x < map.width:
			var color := _tile_color(map, Vector2i(x, y), room_tiles, seen)
			var run := 1
			while x + run < map.width:
				if _tile_color(map, Vector2i(x + run, y), room_tiles, seen) != color:
					break
				run += 1
			if color.a > 0.0:
				var rect := Rect2(origin + Vector2(x, y) * scale, Vector2(run, 1) * scale)
				canvas.draw_rect(rect, color)
			x += run
	var player := canvas.get_tree().get_first_node_in_group("player") as Node2D
	if player and blink_on():
		var cell := (player.global_position / float(ChapterMap.TILE)).floor()
		canvas.draw_rect(Rect2(origin + cell * scale, Vector2.ONE * scale), PLAYER_COLOR)


static func _tile_color(
	map: ChapterMap, cell: Vector2i, room_tiles: Vector2i, seen: Dictionary
) -> Color:
	var character := map.tile(cell)
	if character == " ":
		return NOTHING
	var screen := Vector2i(
		floori(float(cell.x) / room_tiles.x), floori(float(cell.y) / room_tiles.y)
	)
	var visited: bool = seen.has(screen)
	if character == "#":
		return WALL_COLOR if visited else UNSEEN_WALL_COLOR
	return VISITED_COLOR if visited else UNSEEN_COLOR
