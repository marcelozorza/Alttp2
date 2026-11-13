class_name WaterField
extends Node2D
## Nível de água do laboratório. As casas de água de uma sala têm dois
## estados, trocados pelo cristal da sala:
##
## - Cheia: a água é funda e ninguém anda nela, mas as balsas boiam na
##   altura da margem e servem de ponte.
## - Vazia: o leito seco vira chão, só que mais baixo que a margem. Só se
##   entra e sai do leito pelas rampas.
##
## Quem está no leito quando a água volta é levado: perde vida e volta à
## entrada da sala. Arte provisória.
##
## Um só nó cuida de toda a água do capítulo. Cada sala tem o seu estado e
## dois corpos de colisão, um para cada estado.

const WATER_COLOR := Color(0.2, 0.45, 0.85, 0.9)
const WAVE_COLOR := Color(0.6, 0.8, 1.0, 0.8)
const BED_COLOR := Color(0.2, 0.2, 0.28, 0.75)
const RAFT_COLOR := Color(0.6, 0.42, 0.25)
const RAMP_COLOR := Color(0.75, 0.7, 0.6)
const EDGE_COLOR := Color(0.1, 0.1, 0.16)
## Espessura da borda da margem que segura quem está no leito, em pixels.
const EDGE := 4.0
const DAMAGE := 1

## Casas de água, de balsa (que também são de água) e de rampa (na margem),
## as chaves de dicionários de Vector2i.
var water := {}
var rafts := {}
var ramps := {}
var map: ChapterMap

## Estado de cada sala: sala para vazia (bool).
var _drained := {}
## Corpos de cada sala: sala para [corpo da água cheia, corpo das bordas].
var _bodies := {}


func _ready() -> void:
	_build.call_deferred()


## O cristal da sala foi golpeado: a água troca de nível.
func toggle(room: Rect2i) -> void:
	if not _bodies.has(room):
		return
	_set_drained(room, not _drained.get(room, false))
	Sfx.play(&"ice_melt")
	var player := get_tree().get_first_node_in_group("player") as Player
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	if not player or not chapter or _drained[room]:
		return
	var cell := Pit.cell_of(player.global_position)
	if water.has(cell) and not rafts.has(cell) and not player.is_airborne():
		player.fall_into_pit(chapter.room_entry_point, DAMAGE)


func is_drained(room: Rect2i) -> bool:
	return _drained.get(room, false)


func _set_drained(room: Rect2i, drained: bool) -> void:
	_drained[room] = drained
	var pair: Array = _bodies[room]
	(pair[0] as StaticBody2D).collision_layer = 0 if drained else Layers.SCENERY
	(pair[1] as StaticBody2D).collision_layer = Layers.SCENERY if drained else 0
	queue_redraw()


## Monta os dois corpos de cada sala, depois que o mapa inteiro foi lido.
func _build() -> void:
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	var tile := float(ChapterMap.TILE)
	for cell: Vector2i in water:
		var room := chapter.rooms.of_cell(cell)
		if not _bodies.has(room):
			var flood := StaticBody2D.new()
			var banks := StaticBody2D.new()
			add_child(flood)
			add_child(banks)
			_bodies[room] = [flood, banks]
		var pair: Array = _bodies[room]
		var corner := Vector2(cell) * tile
		if not rafts.has(cell):
			add_box(pair[0], Rect2(corner, Vector2(tile, tile)))
		for step: Vector2i in ChapterMap.STEPS:
			var next := cell + step
			if water.has(next) or ramps.has(next) or "# ".contains(map.tile(next)):
				continue
			add_box(pair[1], _edge(corner, step, tile))
	for room: Rect2i in _bodies:
		_set_drained(room, false)


## Faixa fina na beira da casa, do lado do passo dado.
static func _edge(corner: Vector2, step: Vector2i, tile: float) -> Rect2:
	if step == Vector2i.UP:
		return Rect2(corner, Vector2(tile, EDGE))
	if step == Vector2i.DOWN:
		return Rect2(corner + Vector2(0.0, tile - EDGE), Vector2(tile, EDGE))
	if step == Vector2i.LEFT:
		return Rect2(corner, Vector2(EDGE, tile))
	return Rect2(corner + Vector2(tile - EDGE, 0.0), Vector2(EDGE, tile))


static func add_box(body: StaticBody2D, area: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = area.size
	shape.shape = rectangle
	shape.position = area.get_center()
	body.add_child(shape)


func _physics_process(_delta: float) -> void:
	if Clock.tick % 20 == 0:
		queue_redraw()


func _draw() -> void:
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	if not chapter:
		return
	var tile := float(ChapterMap.TILE)
	var size := Vector2(tile, tile)
	for cell: Vector2i in ramps:
		var corner := Vector2(cell) * tile
		draw_rect(Rect2(corner + Vector2(4.0, 4.0), size - Vector2(8.0, 8.0)), RAMP_COLOR)
	for cell: Vector2i in water:
		var corner := Vector2(cell) * tile
		var drained: bool = _drained.get(chapter.rooms.of_cell(cell), false)
		draw_rect(Rect2(corner, size), BED_COLOR if drained else WATER_COLOR)
		if drained:
			for step: Vector2i in ChapterMap.STEPS:
				var next := cell + step
				if not water.has(next) and not ramps.has(next):
					draw_rect(_edge(corner, step, tile), EDGE_COLOR)
		elif not rafts.has(cell):
			var shift := 6.0 if (Clock.tick / 20 + cell.x) % 2 == 0 else 0.0
			var from := corner + Vector2(6.0 + shift, 12.0)
			draw_line(from, from + Vector2(10.0, 0.0), WAVE_COLOR, 2.0)
		if rafts.has(cell):
			var lift := Vector2.ZERO if not drained else Vector2(0.0, 3.0)
			draw_rect(
				Rect2(corner + Vector2(2.0, 2.0) + lift, size - Vector2(4.0, 4.0)), RAFT_COLOR
			)
			for plank: int in 3:
				var y := 9.0 + plank * 8.0
				draw_line(
					corner + Vector2(2.0, y) + lift,
					corner + Vector2(tile - 2.0, y) + lift,
					EDGE_COLOR,
					1.0
				)
