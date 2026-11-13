class_name RoomMechanisms
extends RefCounted
## Mecanismos de sala do laboratório. Cada sala junta os objetos e as portas
## de mecanismo dela (lab/mech_door.gd), e este arquivo decide quando cada
## porta abre:
##
## - Sala de combate: as portas vermelhas fecham quando o personagem entra
##   numa sala com inimigos vivos e passa das portas, e abrem quando o último
##   inimigo morre. Com levas (WAVES nos dados do capítulo), cada leva nasce
##   nos marcadores da sala quando a anterior acaba, e as portas só abrem
##   depois da última.
## - Cristal: cada golpe troca o estado da sala. As barreiras azuis abrem
##   num estado e as laranja no outro.
## - Tochas: com todas acesas, as portas amarelas abrem de vez.
## - Alvo de explosão: atingido, abre de vez as portas roxas.
## - Placa de pressão: as portas verdes abrem enquanto alguma placa da sala
##   está ligada, por tempo ou de vez.
## - Tochas em sequência: acesa fora da vez, todas apagam.
## - Receptor de luz: atingido pelo feixe, abre de vez as portas brancas.
## - Receptor de eletricidade: com corrente, abre as portas elétricas, e sem
##   corrente elas fecham.
## - O cristal também troca o nível da água da sala (lab/water_field.gd) e
##   congela o lago dela (lab/frost_field.gd).
## - Torretas: com todas as da sala desligadas pelo próprio disparo, rebatido
##   com a espada, as portas do rebate abrem de vez.
##
## As três dungeons não usam nada disto: sem objetos registrados, nada age.

## Emitido quando o cristal de uma sala troca de estado.
signal crystal_toggled(room: Rect2i)

## Casas da borda da sala em que o personagem ainda não passou das portas.
const ENTRY_TILES := 2

var _rooms: ChapterRooms
## Cria um inimigo de leva: recebe o caractere, a posição e a sala.
var _spawn: Callable
## Portas de cada sala, por tipo: sala -> { tipo -> [MechDoor] }.
var _doors := {}
var _crystals := {}
var _torches := {}
var _targets := {}
var _plates := {}
var _turrets := {}
## Estado do cristal de cada sala.
var _crystal_on := {}
## Marcadores de nascimento e levas de cada sala, e a próxima leva.
var _spawn_points := {}
var _waves := {}
var _next_wave := {}
## Sala que vai trancar quando o personagem passar das portas.
var _pending := {}


func _init(rooms: ChapterRooms, waves: Dictionary, spawn: Callable) -> void:
	_rooms = rooms
	_spawn = spawn
	for screen: Vector2i in waves:
		_waves[rooms.room_at(screen)] = waves[screen]


func add_door(door: MechDoor, room: Rect2i) -> void:
	var by_kind: Dictionary = _doors.get(room, {})
	var doors: Array = by_kind.get(door.kind, [])
	doors.append(door)
	by_kind[door.kind] = doors
	_doors[room] = by_kind
	# Começam abertas a porta de combate e a barreira laranja.
	if door.kind == ChapterMap.Block.SHUTTER or door.kind == ChapterMap.Block.BARRIER_ALT:
		door.open_silently.call_deferred()


func add_crystal(crystal: Crystal, room: Rect2i) -> void:
	_append(_crystals, room, crystal)
	crystal.struck.connect(_on_crystal_struck.bind(room))


func add_target(target: Crystal, room: Rect2i) -> void:
	_append(_targets, room, target)
	target.struck.connect(_on_target_struck.bind(target, room))


func add_torch(torch: LabTorch, room: Rect2i) -> void:
	_append(_torches, room, torch)
	torch.changed.connect(_on_torch_changed.bind(room))


func add_receptor(receptor: BeamReceptor, room: Rect2i) -> void:
	receptor.changed.connect(_on_receptor_changed.bind(room))


## Receptor de eletricidade: a porta elétrica fica aberta só com corrente.
func add_power_receptor(receptor: BeamReceptor, room: Rect2i) -> void:
	receptor.changed.connect(
		func(lit: bool) -> void: _set_open(room, ChapterMap.Block.POWER_DOOR, lit)
	)


func add_plate(plate: TimedPlate, room: Rect2i) -> void:
	_append(_plates, room, plate)
	plate.changed.connect(_on_plate_changed.bind(room))


func add_turret(turret: Turret, room: Rect2i) -> void:
	_append(_turrets, room, turret)
	turret.shut_down.connect(_on_turret_shut_down.bind(room))


func add_spawn_point(point: Vector2, room: Rect2i) -> void:
	_append(_spawn_points, room, point)


## O personagem entrou na sala: se há o que matar, ela tranca assim que ele
## passar das portas (tick).
func room_entered(room: Rect2i) -> void:
	_pending.clear()
	if _rooms.cleared.has(room) or not _has_doors(room, ChapterMap.Block.SHUTTER):
		return
	if _rooms.enemies_alive(room) > 0 or _waves_left(room) > 0:
		_pending[room] = true


## A cada tick, com a posição do personagem.
func tick(player_position: Vector2) -> void:
	var room := _rooms.current
	if not _pending.has(room):
		return
	var inner := _rooms.pixels(room).grow(-float(ENTRY_TILES * ChapterMap.TILE))
	if not inner.has_point(player_position):
		return
	_pending.erase(room)
	_set_open(room, ChapterMap.Block.SHUTTER, false)
	if _rooms.enemies_alive(room) == 0:
		_spawn_wave(room)


## Um inimigo da sala morreu. Sem nenhum vivo e com levas por vir, nasce a
## próxima, antes de a sala ser dada como limpa.
func enemy_died(room: Rect2i) -> void:
	if _rooms.enemies_alive(room) == 0 and _waves_left(room) > 0:
		_spawn_wave(room)


## A sala ficou limpa: as portas de combate abrem.
func room_cleared(room: Rect2i) -> void:
	_set_open(room, ChapterMap.Block.SHUTTER, true)


func _waves_left(room: Rect2i) -> int:
	var waves: Array = _waves.get(room, [])
	return waves.size() - int(_next_wave.get(room, 0))


## Cria os inimigos da próxima leva, um por marcador, em ordem.
func _spawn_wave(room: Rect2i) -> void:
	var waves: Array = _waves.get(room, [])
	var index: int = _next_wave.get(room, 0)
	var points: Array = _spawn_points.get(room, [])
	if index >= waves.size() or points.is_empty():
		return
	_next_wave[room] = index + 1
	var wave: String = waves[index]
	for i: int in wave.length():
		_spawn.call(wave[i], points[i % points.size()], room)
	Sfx.play(&"boss_wake")


func _on_crystal_struck(room: Rect2i) -> void:
	var on: bool = not _crystal_on.get(room, false)
	_crystal_on[room] = on
	for crystal: Crystal in _crystals.get(room, []):
		crystal.lit = on
	_set_open(room, ChapterMap.Block.BARRIER, on)
	_set_open(room, ChapterMap.Block.BARRIER_ALT, not on)
	crystal_toggled.emit(room)


func _on_target_struck(target: Crystal, room: Rect2i) -> void:
	target.lit = true
	_set_open(room, ChapterMap.Block.BLAST_DOOR, true)


func _on_torch_changed(room: Rect2i) -> void:
	var torches: Array = _torches.get(room, [])
	if not _in_order(torches):
		for torch: LabTorch in torches:
			torch.put_out()
		Sfx.play(&"deny")
		return
	for torch: LabTorch in torches:
		if not torch.lit:
			return
	for torch: LabTorch in torches:
		torch.held = true
	_set_open(room, ChapterMap.Block.TORCH_DOOR, true)


## Numa sala de sequência, as tochas acesas têm de ser as primeiras da
## ordem, sem pular nenhuma.
static func _in_order(torches: Array) -> bool:
	var lit := 0
	var highest := 0
	for torch: LabTorch in torches:
		if torch.order > 0 and torch.lit:
			lit += 1
			highest = maxi(highest, torch.order)
	return highest == lit


func _on_receptor_changed(lit: bool, room: Rect2i) -> void:
	if lit:
		_set_open(room, ChapterMap.Block.BEAM_DOOR, true)


func _on_plate_changed(_active: bool, room: Rect2i) -> void:
	var any_active := false
	for plate: TimedPlate in _plates.get(room, []):
		any_active = any_active or plate.active
	_set_open(room, ChapterMap.Block.TIMED_GATE, any_active)


func _on_turret_shut_down(room: Rect2i) -> void:
	var turrets: Array = _turrets.get(room, [])
	for turret: Turret in turrets:
		if not turret.down:
			return
	if not _has_doors(room, ChapterMap.Block.VOLLEY_DOOR):
		return
	for turret: Turret in turrets:
		turret.held = true
	_set_open(room, ChapterMap.Block.VOLLEY_DOOR, true)


func _has_doors(room: Rect2i, kind: ChapterMap.Block) -> bool:
	var by_kind: Dictionary = _doors.get(room, {})
	return by_kind.has(kind)


func _set_open(room: Rect2i, kind: ChapterMap.Block, open: bool) -> void:
	var by_kind: Dictionary = _doors.get(room, {})
	for door: MechDoor in by_kind.get(kind, []):
		door.set_open(open)


static func _append(table: Dictionary, room: Rect2i, item: Variant) -> void:
	var list: Array = table.get(room, [])
	list.append(item)
	table[room] = list
