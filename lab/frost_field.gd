class_name FrostField
extends Node2D
## Lago que congela do laboratório: as casas "≋" do mapa. Líquido, o lago é
## fundo e ninguém anda nele. Um golpe no cristal da sala o congela por
## alguns segundos: enquanto isso ele é gelo liso (lab/ice_field.gd), e o
## personagem desliza reto até bater em algo. Outro golpe renova o prazo.
## Nos últimos segundos a borda pisca. Quem está no lago quando ele derrete
## perde vida e volta à entrada da sala. Arte provisória.
##
## Um só nó cuida de todos os lagos do capítulo. Cada sala tem o seu prazo e
## um corpo de colisão, sólido só com o lago líquido.

## Segundos congelado depois de cada golpe no cristal.
const FREEZE_TIME := 8.0
## Segundos finais em que a borda pisca.
const WARN_TIME := 2.0
const DAMAGE := 1
const WATER_COLOR := Color(0.16, 0.36, 0.72, 0.92)
const WAVE_COLOR := Color(0.6, 0.8, 1.0, 0.8)
const WARN_COLOR := Color(1.0, 1.0, 1.0, 0.9)

## Casas de lago, as chaves de um dicionário de Vector2i.
var cells := {}
## Campo de gelo liso do capítulo: recebe as casas enquanto estão congeladas.
var ice: IceField

## Tick em que o lago de cada sala derrete. Sem a sala, está líquido.
var _melt_tick := {}
## Corpo de cada sala.
var _bodies := {}


func _ready() -> void:
	_build.call_deferred()


## O cristal da sala foi golpeado: o lago congela, ou renova o prazo.
func freeze(room: Rect2i) -> void:
	if not _bodies.has(room):
		return
	_melt_tick[room] = Clock.tick + GameMath.ticks(FREEZE_TIME)
	_set_frozen(room, true)
	Sfx.play(&"ice_melt")


func is_frozen(room: Rect2i) -> bool:
	return _melt_tick.has(room)


func _physics_process(_delta: float) -> void:
	if _melt_tick.is_empty():
		if Clock.tick % 20 == 0:
			queue_redraw()
		return
	queue_redraw()
	for room: Rect2i in _melt_tick.keys():
		if Clock.tick >= _melt_tick[room]:
			_melt_tick.erase(room)
			_set_frozen(room, false)
			_drop_player(room)


func _set_frozen(room: Rect2i, frozen: bool) -> void:
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	(_bodies[room] as StaticBody2D).collision_layer = 0 if frozen else Layers.SCENERY
	for cell: Vector2i in cells:
		if chapter.rooms.of_cell(cell) != room:
			continue
		if frozen:
			ice.cells[cell] = true
		else:
			ice.cells.erase(cell)
	ice.queue_redraw()
	queue_redraw()


## O lago derreteu: quem estava nele é levado.
func _drop_player(room: Rect2i) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	if not player or not chapter:
		return
	var cell := Pit.cell_of(player.global_position)
	if cells.has(cell) and chapter.rooms.of_cell(cell) == room and not player.is_airborne():
		player.fall_into_pit(chapter.room_entry_point, DAMAGE)


## Monta o corpo de cada sala, depois que o mapa inteiro foi lido.
func _build() -> void:
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	var tile := float(ChapterMap.TILE)
	for cell: Vector2i in cells:
		var room := chapter.rooms.of_cell(cell)
		if not _bodies.has(room):
			var body := StaticBody2D.new()
			body.collision_layer = Layers.SCENERY
			add_child(body)
			_bodies[room] = body
		WaterField.add_box(_bodies[room], Rect2(Vector2(cell) * tile, Vector2(tile, tile)))


func _draw() -> void:
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	if not chapter:
		return
	var tile := float(ChapterMap.TILE)
	var size := Vector2(tile, tile)
	for cell: Vector2i in cells:
		var corner := Vector2(cell) * tile
		var room := chapter.rooms.of_cell(cell)
		if not _melt_tick.has(room):
			draw_rect(Rect2(corner, size), WATER_COLOR)
			var shift := 6.0 if (Clock.tick / 20 + cell.y) % 2 == 0 else 0.0
			var from := corner + Vector2(6.0 + shift, 18.0)
			draw_line(from, from + Vector2(10.0, 0.0), WAVE_COLOR, 2.0)
			continue
		var left: int = _melt_tick[room] - Clock.tick
		if left <= GameMath.ticks(WARN_TIME) and posmod(left, 12) < 6:
			draw_rect(Rect2(corner + Vector2.ONE, size - Vector2(2.0, 2.0)), WARN_COLOR, false, 2.0)
