class_name GateMechanism
extends RefCounted
## Mecanismo da grade: o bloco pesado ("0"), o interruptor ("=") e a grade
## (bloqueio GATE). A grade de uma sala abre enquanto um interruptor da sala
## está pressionado, e de vez quando um bloco trava num interruptor. O bloco
## só tomba dentro do trilho que vai dele ao interruptor (build_rails), e um
## bloco solto volta ao lugar quando o personagem entra de novo na sala.

## Interruptores e grades de cada sala.
var room_switches := {}
var room_gates := {}

## Casa de cada bloco pesado e as casas dos interruptores, para os trilhos.
var _block_cells := {}
var _switch_cells: Array[Vector2i] = []


func add_switch(switch: FloorSwitch, cell: Vector2i, room: Rect2i) -> void:
	switch.changed.connect(_on_switch_changed.bind(room))
	var switches: Array = room_switches.get(room, [])
	switches.append(switch)
	room_switches[room] = switches
	_switch_cells.append(cell)


func add_gate(gate: SwitchDoor, room: Rect2i) -> void:
	var gates: Array = room_gates.get(room, [])
	gates.append(gate)
	room_gates[room] = gates


func add_block(block: HeavyBlock, cell: Vector2i) -> void:
	_block_cells[block] = cell


## Blocos travados num interruptor, como [casa x, casa y, x, y] de cada um,
## em valores simples, para o estado guardado da dungeon.
func locked_blocks() -> Array:
	var blocks: Array = []
	for block: HeavyBlock in _block_cells:
		if block.locked:
			var cell: Vector2i = _block_cells[block]
			blocks.append([cell.x, cell.y, block.global_position.x, block.global_position.y])
	return blocks


## Trava de novo os blocos de um estado guardado (ver locked_blocks).
func lock_blocks(entries: Variant) -> void:
	if not entries is Array:
		return
	for entry in entries:
		if not entry is Array or entry.size() < 4:
			continue
		var cell := Vector2i(int(entry[0]), int(entry[1]))
		for block: HeavyBlock in _block_cells:
			if _block_cells[block] == cell:
				block.lock_at(Vector2(float(entry[2]), float(entry[3])))


## Trilho de cada bloco pesado: as casas do bloco até o interruptor mais
## próximo da mesma sala, em linha reta ou com uma curva. O bloco só tomba
## dentro dele. Um bloco sem caminho de chão até um interruptor fica sem
## trilho e não anda. Devolve o desenho dos trilhos.
func build_rails(map: ChapterMap, rooms: ChapterRooms) -> RailView:
	var view := RailView.new()
	view.tile = ChapterMap.TILE
	for block: HeavyBlock in _block_cells:
		var from: Vector2i = _block_cells[block]
		var path: Array = []
		var best := -1
		for to: Vector2i in _switch_cells:
			if rooms.of_cell(to) != rooms.of_cell(from):
				continue
			var distance := absi(to.x - from.x) + absi(to.y - from.y)
			if best >= 0 and distance >= best:
				continue
			var found := _rail_path(map, from, to, true)
			if found.is_empty():
				found = _rail_path(map, from, to, false)
			if not found.is_empty():
				path = found
				best = distance
		block.tile = ChapterMap.TILE
		for cell: Vector2i in path:
			block.rail[cell] = true
			view.cells[cell] = true
	return view


## As grades de uma sala abrem enquanto algum interruptor dela está
## pressionado.
func _on_switch_changed(_pressed: bool, room: Rect2i) -> void:
	FloorSwitch.sync_gates(room_switches.get(room, []), room_gates.get(room, []))


## Casas de from a to, primeiro na horizontal ou primeiro na vertical. Vazio
## se alguma casa do caminho não for chão no nível do bloco.
static func _rail_path(
	map: ChapterMap, from: Vector2i, to: Vector2i, horizontal_first: bool
) -> Array:
	var corner := Vector2i(to.x, from.y) if horizontal_first else Vector2i(from.x, to.y)
	var path: Array = [from]
	for target: Vector2i in [corner, to]:
		while path.back() != target:
			var last: Vector2i = path.back()
			var cell: Vector2i = last + (target - last).sign()
			if not ".=0".contains(map.tile(cell)) or map.height_level(cell) != 0:
				return []
			path.append(cell)
	return path
