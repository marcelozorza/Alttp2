class_name MapScreen
extends CanvasLayer
## Tela do mapa da dungeon (pedido de Marcelo em 2026-11-07). Abre com o botão
## de mapa (Back no controle de Xbox, Select no de SNES, M ou Tab no teclado)
## ou pelo botão Mapa do menu de pausa, e para o jogo enquanto está aberta. O
## mesmo botão, ou o de pausa, fecha: aberta pelo menu de pausa, volta a ele.
##
## O mapa inteiro é desenhado casa por casa, ampliado o máximo que cabe na
## tela. Nas salas em que o personagem já esteve aparece o detalhe: o chão em
## três tons pela altura, as paredes, os baús fechados em dourado e os abertos
## vazados, as portas trancadas, a porta do chefe, as paredes rachadas, o gelo e
## o gelo grosso, os degraus e as grades, nas cores que têm no jogo. Um
## bloqueio já removido vira chão. As salas não vistas são blocos sombreados,
## sem nada dentro. O chefe aparece com uma caveira desde o começo, como no
## mapa do Link to the Past, e o personagem é um ponto que pisca. A legenda
## fica embaixo.

## Altura reservada ao título, no alto, e à legenda, embaixo, em pixels.
const TITLE_HEIGHT := 32.0
const LEGEND_HEIGHT := 40.0
const MARGIN := 8.0
const SCREEN := Vector2(640.0, 360.0)
const TITLE_FONT_SIZE := 20
const LABEL_FONT_SIZE := 16
const LEGEND_FONT_SIZE := 12
## Pixels por casa, no mínimo e no máximo.
const MIN_SCALE := 2
const MAX_SCALE := 8
## Lado da caveira do chefe, em casas.
const SKULL_CELLS := 3.0

const BACKGROUND := Color(0.05, 0.05, 0.08, 1.0)
const TEXT_COLOR := Color(0.92, 0.9, 0.82, 1.0)
## Chão comum, chão alto e chão mais alto.
const FLOOR_COLORS: Array[Color] = [
	Color(0.68, 0.63, 0.5, 1.0),
	Color(0.8, 0.76, 0.64, 1.0),
	Color(0.92, 0.9, 0.8, 1.0),
]
const WALL_COLOR := Color(0.2, 0.2, 0.26, 1.0)
const UNSEEN_COLOR := Color(0.3, 0.29, 0.34, 1.0)
const UNSEEN_EDGE := Color(0.17, 0.16, 0.2, 1.0)
const CHEST_COLOR := Color(0.88, 0.63, 0.13, 1.0)
const CHEST_EDGE := Color(0.16, 0.07, 0.03, 1.0)
const LOCKED_COLOR := Color(0.73, 0.75, 0.8, 1.0)
const BOSS_DOOR_COLOR := Color(0.66, 0.22, 0.24, 1.0)
const CRACKED_COLOR := Color(0.78, 0.5, 0.3, 1.0)
const ICE_COLOR := Color(0.5, 0.69, 0.86, 1.0)
const THICK_ICE_COLOR := Color(0.25, 0.48, 0.72, 1.0)
const LEDGE_COLOR := Color(0.34, 0.31, 0.24, 1.0)
const GATE_COLOR := Color(0.43, 0.42, 0.47, 1.0)
const SKULL_COLOR := Color(0.95, 0.93, 0.85, 1.0)
const SKULL_EDGE := Color(0.1, 0.08, 0.1, 1.0)
const PLAYER_COLOR := Color(0.9, 0.2, 0.25, 1.0)
const PLAYER_EDGE := Color(1.0, 0.95, 0.9, 1.0)
const NOTHING := Color(0.0, 0.0, 0.0, 0.0)
const BOSS_CHARACTERS := ["*", "&", "%", "$"]
## Itens da legenda: texto e o que a amostra mostra.
const LEGEND := [
	["Baú", "chest"],
	["Baú aberto", "open_chest"],
	["Porta trancada", "locked"],
	["Porta do chefe", "boss_door"],
	["Chefe", "skull"],
	["Parede rachada", "cracked"],
	["Gelo", "ice"],
	["Gelo grosso", "thick_ice"],
	["Degrau", "ledge"],
	["Grade", "gate"],
	["Chão alto", "high"],
	["Giorgino", "player"],
]

var _canvas: Control
## Menu que abriu o mapa e volta quando ele fecha, ou nulo.
var _return_to: CanvasLayer


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var fill := ColorRect.new()
	fill.color = BACKGROUND
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fill)
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_map)
	add_child(_canvas)


func _process(_delta: float) -> void:
	if visible:
		_canvas.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if visible:
		if event.is_action_pressed("map") or event.is_action_pressed("pause"):
			close()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("map") and not get_tree().paused and not _player_is_dead():
		open()
		get_viewport().set_input_as_handled()


## Abre o mapa e para o jogo. Com return_to, o menu que chamou volta ao fechar,
## e o jogo já estava parado por ele.
func open(return_to: CanvasLayer = null) -> void:
	_return_to = return_to
	if not get_tree().paused:
		get_tree().paused = true
		Music.set_paused(true)
	visible = true
	Sfx.play(&"menu_confirm")


func close() -> void:
	visible = false
	if _return_to:
		_return_to.visible = true
		_return_to.call("refocus")
		_return_to = null
	else:
		Music.set_paused(false)
		get_tree().paused = false


func _player_is_dead() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	return player != null and player.is_dead()


func _chapter() -> Node:
	return get_tree().get_first_node_in_group("chapter")


## Pixels por casa: o maior inteiro com que o mapa inteiro cabe na área entre
## o título e a legenda.
static func scale_for(map: ChapterMap) -> int:
	var area := SCREEN - Vector2(2.0 * MARGIN, TITLE_HEIGHT + LEGEND_HEIGHT)
	var fit := minf(area.x / maxi(map.width, 1), area.y / maxi(map.height, 1))
	return clampi(floori(fit), MIN_SCALE, MAX_SCALE)


func _draw_map() -> void:
	var font := ThemeDB.fallback_font
	_canvas.draw_string(
		font,
		Vector2(0.0, 24.0),
		"Mapa",
		HORIZONTAL_ALIGNMENT_CENTER,
		SCREEN.x,
		TITLE_FONT_SIZE,
		TEXT_COLOR
	)
	var chapter := _chapter()
	if chapter == null:
		return
	_canvas.draw_string(
		font,
		Vector2(0.0, 24.0),
		chapter.call("mode_text"),
		HORIZONTAL_ALIGNMENT_RIGHT,
		SCREEN.x - MARGIN,
		LABEL_FONT_SIZE,
		TEXT_COLOR
	)
	var map: ChapterMap = chapter.get("map")
	var room_tiles: Vector2i = chapter.call("room_tiles")
	var scale := scale_for(map)
	var size := Vector2(map.width, map.height) * scale
	var area := Rect2(
		Vector2(MARGIN, TITLE_HEIGHT), SCREEN - Vector2(2.0 * MARGIN, TITLE_HEIGHT + LEGEND_HEIGHT)
	)
	var origin := (area.position + (area.size - size) / 2.0).floor()
	var visited := {}
	for room: Rect2i in chapter.call("visited_rooms"):
		visited[room] = true
	var drawn := {}
	var columns := ceili(float(map.width) / room_tiles.x)
	var rows := ceili(float(map.height) / room_tiles.y)
	for sy: int in rows:
		for sx: int in columns:
			var room: Rect2i = chapter.call("room_at", Vector2i(sx, sy))
			if drawn.has(room) or not _room_exists(map, room, room_tiles):
				continue
			drawn[room] = true
			if visited.has(room):
				_draw_room(chapter, map, room, room_tiles, origin, scale)
			else:
				var rect := Rect2(
					origin + Vector2(room.position * room_tiles) * scale,
					Vector2(room.size * room_tiles) * scale
				)
				_canvas.draw_rect(rect, UNSEEN_EDGE)
				_canvas.draw_rect(rect.grow(-scale), UNSEEN_COLOR)
	for character: String in BOSS_CHARACTERS:
		var cell := map.find(character)
		if cell != ChapterMap.NO_CELL:
			var side := SKULL_CELLS * scale
			var corner := (
				origin + (Vector2(cell) + Vector2(0.5, 0.5)) * scale - Vector2(side, side) / 2.0
			)
			_draw_skull(corner.floor(), side)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and Minimap.blink_on():
		var cell := (player.global_position / float(ChapterMap.TILE)).floor()
		var dot := Rect2(origin + cell * scale, Vector2.ONE * scale).grow(1.0)
		_canvas.draw_rect(dot, PLAYER_EDGE)
		_canvas.draw_rect(dot.grow(-1.0), PLAYER_COLOR)
	_draw_legend(font)


## Se a sala tem alguma casa no mapa. Telas vazias da grade não são salas.
static func _room_exists(map: ChapterMap, room: Rect2i, room_tiles: Vector2i) -> bool:
	var cells := Rect2i(room.position * room_tiles, room.size * room_tiles)
	for y: int in range(cells.position.y, cells.end.y):
		for x: int in range(cells.position.x, cells.end.x):
			if map.tile(Vector2i(x, y)) != " ":
				return true
	return false


## Uma sala já vista, casa por casa. Casas vizinhas da mesma cor viram um
## retângulo só, e os baús ganham a marca por cima.
func _draw_room(
	chapter: Node, map: ChapterMap, room: Rect2i, room_tiles: Vector2i, origin: Vector2, scale: int
) -> void:
	var cells := Rect2i(room.position * room_tiles, room.size * room_tiles)
	var chests: Array[Vector2i] = []
	for y: int in range(cells.position.y, cells.end.y):
		var x := cells.position.x
		while x < cells.end.x:
			var color := _cell_color(chapter, map, Vector2i(x, y))
			var run := 1
			while x + run < cells.end.x:
				if _cell_color(chapter, map, Vector2i(x + run, y)) != color:
					break
				run += 1
			if color.a > 0.0:
				var rect := Rect2(origin + Vector2(x, y) * scale, Vector2(run, 1) * scale)
				_canvas.draw_rect(rect, color)
			for i: int in run:
				if ChapterMap.is_location(map.tile(Vector2i(x + i, y))):
					chests.append(Vector2i(x + i, y))
			x += run
	for cell: Vector2i in chests:
		var is_open: bool = chapter.call("chest_is_open", map.tile(cell))
		_draw_chest(Rect2(origin + Vector2(cell) * scale, Vector2.ONE * scale), is_open)


## Cor de uma casa de sala já vista: parede, bloqueio ainda no lugar pelo tipo,
## ou chão pelo nível. Um baú ou um inimigo é desenhado como o chão dele.
static func _cell_color(chapter: Node, map: ChapterMap, cell: Vector2i) -> Color:
	var character := map.tile(cell)
	if character == " ":
		return NOTHING
	if character == "#":
		return WALL_COLOR
	if ChapterMap.is_slot(character) and not chapter.call("block_cleared", character):
		match map.block_type(character):
			ChapterMap.Block.CRACKED:
				return CRACKED_COLOR
			ChapterMap.Block.ICE:
				return ICE_COLOR
			ChapterMap.Block.THICK_ICE:
				return THICK_ICE_COLOR
			ChapterMap.Block.LEDGE, ChapterMap.Block.TALL_LEDGE:
				return LEDGE_COLOR
			ChapterMap.Block.LOCKED:
				return LOCKED_COLOR
			ChapterMap.Block.BOSS_DOOR:
				return BOSS_DOOR_COLOR
			ChapterMap.Block.GATE:
				return GATE_COLOR
	return FLOOR_COLORS[map.height_level(cell)]


## Baú fechado: quadrado dourado com borda escura. Aberto: só a borda, com o
## chão aparecendo dentro, para ficar claramente diferente.
func _draw_chest(rect: Rect2, is_open: bool) -> void:
	if rect.size.x < 4.0:
		_canvas.draw_rect(rect, CHEST_EDGE if is_open else CHEST_COLOR)
		return
	_canvas.draw_rect(rect, CHEST_EDGE)
	if not is_open:
		_canvas.draw_rect(rect.grow(-1.0), CHEST_COLOR)
	else:
		_canvas.draw_rect(rect.grow(-1.0), FLOOR_COLORS[0])


## Caveira do chefe num quadrado de lado side: crânio, mandíbula e dois olhos.
func _draw_skull(corner: Vector2, side: float) -> void:
	var head := Rect2(
		(corner + Vector2(0.2, 0.07) * side).round(), (Vector2(0.6, 0.53) * side).round()
	)
	var jaw := Rect2(
		(corner + Vector2(0.3, 0.6) * side).round(), (Vector2(0.4, 0.27) * side).round()
	)
	_canvas.draw_rect(head.grow(1.0), SKULL_EDGE)
	_canvas.draw_rect(jaw.grow(1.0), SKULL_EDGE)
	_canvas.draw_rect(head, SKULL_COLOR)
	_canvas.draw_rect(jaw, SKULL_COLOR)
	var eye := Vector2.ONE * maxf(roundf(0.14 * side), 1.0)
	_canvas.draw_rect(Rect2((corner + Vector2(0.3, 0.27) * side).round(), eye), SKULL_EDGE)
	_canvas.draw_rect(Rect2((corner + Vector2(0.56, 0.27) * side).round(), eye), SKULL_EDGE)


## Legenda centralizada embaixo, em quantas linhas precisar.
func _draw_legend(font: Font) -> void:
	var swatch := 10.0
	var gap := 14.0
	var line_height := 16.0
	var rows: Array = [[]]
	var widths: Array = [0.0]
	for item: Array in LEGEND:
		var text_width := (
			font.get_string_size(item[0], HORIZONTAL_ALIGNMENT_LEFT, -1, LEGEND_FONT_SIZE).x
		)
		var width := swatch + 4.0 + text_width
		if widths[-1] + width + gap > SCREEN.x - 2.0 * MARGIN and not rows[-1].is_empty():
			rows.append([])
			widths.append(0.0)
		rows[-1].append([item, width])
		widths[-1] += width + gap
	var top := SCREEN.y - LEGEND_HEIGHT + 4.0
	for i: int in rows.size():
		var x := floorf((SCREEN.x - (widths[i] - gap)) / 2.0)
		var y := top + i * line_height
		for entry: Array in rows[i]:
			_draw_swatch(entry[0][1], Rect2(Vector2(x, y), Vector2(swatch, swatch)))
			_canvas.draw_string(
				font,
				Vector2(x + swatch + 4.0, y + swatch),
				entry[0][0],
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				LEGEND_FONT_SIZE,
				TEXT_COLOR
			)
			x += entry[1] + gap


func _draw_swatch(kind: String, rect: Rect2) -> void:
	match kind:
		"chest":
			_draw_chest(rect, false)
		"open_chest":
			_draw_chest(rect, true)
		"skull":
			_draw_skull(rect.position, rect.size.x)
		"player":
			_canvas.draw_rect(rect, PLAYER_EDGE)
			_canvas.draw_rect(rect.grow(-1.0), PLAYER_COLOR)
		"high":
			_canvas.draw_rect(rect, FLOOR_COLORS[1])
		"locked":
			_canvas.draw_rect(rect, LOCKED_COLOR)
		"boss_door":
			_canvas.draw_rect(rect, BOSS_DOOR_COLOR)
		"cracked":
			_canvas.draw_rect(rect, CRACKED_COLOR)
		"ice":
			_canvas.draw_rect(rect, ICE_COLOR)
		"thick_ice":
			_canvas.draw_rect(rect, THICK_ICE_COLOR)
		"ledge":
			_canvas.draw_rect(rect, LEDGE_COLOR)
		"gate":
			_canvas.draw_rect(rect, GATE_COLOR)
