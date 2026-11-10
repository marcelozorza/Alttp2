class_name MapScreen
extends CanvasLayer
## Tela do mapa da dungeon (pedido de Marcelo em 2026-11-07). Abre com o botão
## de mapa (Back no controle de Xbox, Select no de SNES, M ou Tab no teclado)
## e para o jogo enquanto está aberta. O mesmo botão, ou o de pausa, fecha.
## O botão de pausa abre a mesma tela como pausa (pedido de Marcelo em
## 2026-11-08, "redesenhar o menu para caber junto na tela de pause com o
## mapa"): o mapa à esquerda e, no painel da direita, o título "Pausa", o modo
## de jogo, a seed, os botões Continuar e Sair e a legenda. Aberta pelo botão
## de mapa, o painel mostra só o título "Mapa", o modo e a legenda.
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

## Margem em volta do mapa e largura do painel da direita, em pixels.
const MARGIN := 8.0
const PANEL_WIDTH := 168.0
const PANEL_COLOR := Color(0.09, 0.09, 0.13, 1.0)
const LEGEND_LINE := 15.0
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
const CHEST_OPEN_COLOR := Color(0.47, 0.31, 0.06, 1.0)
const CHEST_EDGE := Color(0.16, 0.07, 0.03, 1.0)
const LOCKED_COLOR := Color(0.8, 0.16, 0.14, 1.0)
const BOSS_DOOR_COLOR := Color(0.55, 0.25, 0.75, 1.0)
const CRACKED_COLOR := Color(0.78, 0.5, 0.3, 1.0)
const ICE_COLOR := Color(0.5, 0.69, 0.86, 1.0)
const THICK_ICE_COLOR := Color(0.25, 0.48, 0.72, 1.0)
const LEDGE_COLOR := Color(0.34, 0.31, 0.24, 1.0)
const GATE_COLOR := Color(0.43, 0.42, 0.47, 1.0)
const SKULL_COLOR := Color(0.95, 0.93, 0.85, 1.0)
const SKULL_EDGE := Color(0.1, 0.08, 0.1, 1.0)
const PLAYER_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const PLAYER_EDGE := Color(0.0, 0.0, 0.0, 1.0)
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
## Aberto pelo botão de pausa: o painel mostra os botões do menu.
var _as_pause := false
## Menu de pausa da cena, dono da ação de sair.
var _pause_menu: CanvasLayer
var _buttons: VBoxContainer
var _seed_label: Label
## Onde a legenda começa, abaixo do texto e dos botões do painel.
var _legend_top := 0.0


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
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 6)
	_buttons.position = Vector2(SCREEN.x - PANEL_WIDTH + MARGIN, 76.0)
	_buttons.size = Vector2(PANEL_WIDTH - 2.0 * MARGIN, 0.0)
	add_child(_buttons)
	_seed_label = MenuKit.label("", LABEL_FONT_SIZE)
	_seed_label.position = Vector2(SCREEN.x - PANEL_WIDTH, 48.0)
	_seed_label.size = Vector2(PANEL_WIDTH, 20.0)
	add_child(_seed_label)


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


## Abre o mapa e para o jogo. Com pause_menu, é a tela de pausa: o painel
## ganha os botões Continuar e o de sair do menu de pausa.
func open(pause_menu: CanvasLayer = null) -> void:
	_as_pause = pause_menu != null
	_pause_menu = pause_menu
	if not get_tree().paused:
		get_tree().paused = true
		Music.set_paused(true)
	_build_buttons()
	visible = true
	Sfx.play(&"menu_confirm")


func close() -> void:
	visible = false
	_as_pause = false
	_pause_menu = null
	Music.set_paused(false)
	get_tree().paused = false


## Botões do painel, refeitos a cada abertura: só na pausa.
func _build_buttons() -> void:
	for child: Node in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	_seed_label.text = ""
	if Progress.active and Progress.seed != 0:
		_seed_label.text = "Semente %06d" % Progress.seed
	var top := 76.0 if _seed_label.text != "" else 58.0
	_buttons.position.y = top
	_legend_top = top
	if not _as_pause:
		return
	var resume := MenuKit.button("Continuar", close)
	_buttons.add_child(resume)
	_buttons.add_child(MenuKit.button(_pause_menu.get("exit_text"), _on_exit))
	_legend_top = top + 2.0 * 34.0 + 12.0
	resume.grab_focus()


func _on_exit() -> void:
	var menu := _pause_menu
	visible = false
	_as_pause = false
	_pause_menu = null
	menu.call("leave")


func _player_is_dead() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Player
	return player != null and player.is_dead()


func _chapter() -> Node:
	return get_tree().get_first_node_in_group("chapter")


## Área do mapa: a tela à esquerda do painel, com margem.
static func map_area() -> Rect2:
	return Rect2(
		Vector2(MARGIN, MARGIN), SCREEN - Vector2(PANEL_WIDTH + 2.0 * MARGIN, 2.0 * MARGIN)
	)


## Pixels por casa: o maior inteiro com que o mapa inteiro cabe na área à
## esquerda do painel.
static func scale_for(map: ChapterMap) -> int:
	var area := map_area().size
	var fit := minf(area.x / maxi(map.width, 1), area.y / maxi(map.height, 1))
	return clampi(floori(fit), MIN_SCALE, MAX_SCALE)


func _draw_map() -> void:
	var font := ThemeDB.fallback_font
	var panel := Rect2(SCREEN.x - PANEL_WIDTH, 0.0, PANEL_WIDTH, SCREEN.y)
	_canvas.draw_rect(panel, PANEL_COLOR)
	_canvas.draw_string(
		font,
		Vector2(panel.position.x, 26.0),
		"Pausa" if _as_pause else "Mapa",
		HORIZONTAL_ALIGNMENT_CENTER,
		PANEL_WIDTH,
		TITLE_FONT_SIZE,
		TEXT_COLOR
	)
	var chapter := _chapter()
	if chapter == null:
		return
	_canvas.draw_string(
		font,
		Vector2(panel.position.x, 46.0),
		chapter.call("mode_text"),
		HORIZONTAL_ALIGNMENT_CENTER,
		PANEL_WIDTH,
		LABEL_FONT_SIZE,
		TEXT_COLOR
	)
	var map: ChapterMap = chapter.get("map")
	var room_tiles: Vector2i = chapter.call("room_tiles")
	var scale := scale_for(map)
	var size := Vector2(map.width, map.height) * scale
	var area := map_area()
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


## Baú fechado: quadrado dourado com borda escura. Aberto: o mesmo dourado bem
## mais escuro, pedido de Marcelo, para não se confundir com o chão.
func _draw_chest(rect: Rect2, is_open: bool) -> void:
	var fill := CHEST_OPEN_COLOR if is_open else CHEST_COLOR
	if rect.size.x < 4.0:
		_canvas.draw_rect(rect, fill)
		return
	_canvas.draw_rect(rect, CHEST_EDGE)
	_canvas.draw_rect(rect.grow(-1.0), fill)


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


## Legenda no painel da direita, um item por linha, abaixo dos botões.
func _draw_legend(font: Font) -> void:
	var swatch := 10.0
	var x := SCREEN.x - PANEL_WIDTH + 2.0 * MARGIN
	for i: int in LEGEND.size():
		var item: Array = LEGEND[i]
		var y := _legend_top + i * LEGEND_LINE
		_draw_swatch(item[1], Rect2(Vector2(x, y), Vector2(swatch, swatch)))
		_canvas.draw_string(
			font,
			Vector2(x + swatch + 6.0, y + swatch),
			item[0],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			LEGEND_FONT_SIZE,
			TEXT_COLOR
		)


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
