extends Node2D
## Cena de qualquer capítulo. Lê os dados do capítulo escolhido no menu, monta
## o mapa, põe em cada baú o item dele, move a câmera de sala em sala e
## encerra o capítulo quando o personagem toca a relíquia que o chefe deixa.
## Os dados de cada capítulo ficam em world/<capítulo>/ (ver
## progression/chapter_data.gd).
##
## O mapa é dividido em salas de uma tela, de 20 por 10 casas. Um capítulo
## pode juntar várias delas numa sala maior (ROOMS nos dados): nela a câmera
## segue o personagem, sem nunca mostrar nada fora da sala, e todos os
## inimigos da sala agem juntos.
##
## Os inimigos só agem na sala em que o personagem está. Ao entrar ou sair de
## uma sala, os inimigos dela voltam ao ponto inicial, e as ondas do chefe que
## ainda correm pelo chão somem. Baús abertos e bloqueios removidos continuam
## assim até o fim do capítulo.
##
## O bloco pesado ("0") e o interruptor ("=") formam o mecanismo da grade
## (bloqueio GATE): a grade de uma sala abre enquanto um interruptor da sala
## está pressionado, e de vez quando um bloco trava num interruptor. Um bloco
## solto volta ao lugar quando o personagem entra de novo na sala.
##
## No jogo contínuo (Progress.active), o personagem chega com as ferramentas
## e a vida máxima salvas, os baús de coração e de ferramenta de um capítulo
## já vencido começam abertos, e tocar a relíquia grava o progresso. No
## treino, ele chega com as ferramentas dos dados do capítulo.

## Tamanho de uma sala de uma tela, em casas.
const ROOM_TILES := Vector2i(20, 10)
## Altura da barra do HUD no alto da tela. A sala aparece logo abaixo dela.
const HUD_HEIGHT := 20.0
## Metade da tela, em pixels.
const HALF_SCREEN := Vector2(160.0, 90.0)
const PLAYER_SCENE := preload("res://player/player.tscn")
const CHEST_SCENE := preload("res://items/chest.tscn")
const RELIC_SCENE := preload("res://items/relic.tscn")
const LEDGE_SCENE := preload("res://obstacles/ledge.tscn")
## Cena de cada tipo de bloqueio. O degrau duplo é a mesma face do degrau,
## com duas casas de altura.
const OBSTACLE_SCENES := {
	ChapterMap.Block.CRACKED: preload("res://obstacles/cracked_wall.tscn"),
	ChapterMap.Block.ICE: preload("res://obstacles/ice_block.tscn"),
	ChapterMap.Block.THICK_ICE: preload("res://obstacles/thick_ice.tscn"),
	ChapterMap.Block.LEDGE: LEDGE_SCENE,
	ChapterMap.Block.TALL_LEDGE: LEDGE_SCENE,
	ChapterMap.Block.LOCKED: preload("res://obstacles/locked_door.tscn"),
	ChapterMap.Block.BOSS_DOOR: preload("res://obstacles/boss_door.tscn"),
	ChapterMap.Block.GATE: preload("res://obstacles/switch_door.tscn"),
}
## Cena de cada inimigo comum, pelo caractere do mapa.
const ENEMY_SCENES := {
	"m": preload("res://enemies/minion.tscn"),
	"u": preload("res://enemies/ugly.tscn"),
	"i": preload("res://enemies/ice_slime.tscn"),
	"w": preload("res://enemies/walrus.tscn"),
	"s": preload("res://enemies/slinger.tscn"),
	"x": preload("res://enemies/armadillo.tscn"),
	"y": preload("res://enemies/bat.tscn"),
	"z": preload("res://enemies/thorn_plant.tscn"),
}
## Cena de cada chefe, pelo caractere do mapa.
const BOSS_SCENES := {
	"*": preload("res://enemies/boss.tscn"),
	"&": preload("res://enemies/sentinel.tscn"),
	"%": preload("res://enemies/elder_guardian.tscn"),
	"$": preload("res://enemies/colossus.tscn"),
}
const LIGHT_CRATE_SCENE := preload("res://objects/light_crate.tscn")
const HEAVY_BLOCK_SCENE := preload("res://objects/heavy_block.tscn")
const FLOOR_SWITCH_SCENE := preload("res://objects/floor_switch.tscn")

## Ticks de jogo desde o início do capítulo, para o cronômetro.
var elapsed_ticks := 0
var finished := false
var data: ChapterData
var map: ChapterMap

var _player: Player
## Sala atual, em unidades de sala de uma tela.
var _room := Rect2i(-1000, -1000, 1, 1)
## Sala maior de cada tela que faz parte de uma. As outras telas são salas.
var _room_rects := {}
var _room_actors := {}
## Interruptores e grades de cada sala.
var _room_switches := {}
var _room_gates := {}
var _chests: Array[Chest] = []

@onready var _map_view: MapView = $MapView
@onready var _walls: StaticBody2D = $Walls
@onready var _obstacles: Node2D = $Obstacles
@onready var _floor_effects: Node2D = $FloorEffects
@onready var _objects: Node2D = $Objects
@onready var _camera: Camera2D = $Camera
@onready var _end_screen: EndScreen = $EndScreen


func _ready() -> void:
	add_to_group("chapter")
	data = ChapterData.load_number(RunSettings.chapter)
	map = ChapterMap.new(data.rows, data.blocks)
	for rect: Rect2i in data.rooms:
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				_room_rects[Vector2i(x, y)] = rect
	_map_view.map = map
	_map_view.queue_redraw()
	MapWalls.build(map, _walls)
	_build_cells()
	if Progress.active:
		_player.restore(Progress.tools, Progress.max_health)
		for chest: Chest in _chests:
			if Progress.was_opened(data.number, chest.location_id):
				chest.open_silently()
	else:
		for id: int in data.starting_tools:
			_player.give_item(id)
	_player.respawned.connect(_on_player_respawned)
	_camera.make_current()
	_enter_room(_room_of(_player.global_position))
	_camera.reset_smoothing()


func _physics_process(_delta: float) -> void:
	if finished:
		return
	elapsed_ticks += 1
	var room := _room_of(_player.global_position)
	if room != _room:
		_enter_room(room)
	_camera.position = _camera_target()


## Nome do capítulo, para o HUD e para a tela de fim.
func mode_text() -> String:
	return "Cap. %d" % data.number


## Cronômetro no formato minutos:segundos.centésimos.
func time_text() -> String:
	var seconds := float(elapsed_ticks) / Engine.physics_ticks_per_second
	var minutes := floori(seconds / 60.0)
	return "%02d:%05.2f" % [minutes, seconds - minutes * 60.0]


## Cria o personagem, os baús, os inimigos e os bloqueios de cada casa do mapa.
func _build_cells() -> void:
	var slots := {}
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			var character := map.tile(cell)
			if ChapterMap.is_slot(character):
				var area := Rect2i(cell, Vector2i.ONE)
				if slots.has(character):
					var known: Rect2i = slots[character]
					area = known.merge(area)
				slots[character] = area
			elif ChapterMap.is_location(character):
				_add_chest(character, cell)
			else:
				_add_actor(character, cell)
	for slot: String in slots:
		_add_obstacle(slot, slots[slot])


func _add_actor(character: String, cell: Vector2i) -> void:
	var center := _cell_center(cell)
	if ENEMY_SCENES.has(character):
		_add_enemy(ENEMY_SCENES[character], cell)
	elif BOSS_SCENES.has(character):
		_add_boss(BOSS_SCENES[character], cell)
	elif character == "@":
		_player = PLAYER_SCENE.instantiate() as Player
		_player.position = center
		_objects.add_child(_player)
	elif character == "c":
		var crate := LIGHT_CRATE_SCENE.instantiate() as Node2D
		crate.position = center + Vector2(0.0, 5.0)
		_objects.add_child(crate)
	elif character == "0":
		var block := HEAVY_BLOCK_SCENE.instantiate() as HeavyBlock
		block.position = center + FloorSwitch.BLOCK_OFFSET
		_objects.add_child(block)
		_register(block, cell)
	elif character == "=":
		var switch := FLOOR_SWITCH_SCENE.instantiate() as FloorSwitch
		switch.position = center
		var room := _room_of_cell(cell)
		switch.changed.connect(_on_switch_changed.bind(room))
		_floor_effects.add_child(switch)
		var switches: Array = _room_switches.get(room, [])
		switches.append(switch)
		_room_switches[room] = switches


## O chefe nasce desligado, preso à sala dele. Todo chefe tem a propriedade
## arena, o sinal defeated e a função set_active.
func _add_boss(scene: PackedScene, cell: Vector2i) -> void:
	var boss := scene.instantiate() as Node2D
	var room := _room_of_cell(cell)
	boss.position = _cell_center(cell) + Vector2(0.0, 6.0)
	boss.set("arena", _room_interior(room))
	boss.connect("defeated", _on_boss_defeated.bind(room))
	_objects.add_child(boss)
	boss.call("set_active", false)
	_register(boss, cell)


## Os inimigos nascem desligados. Só a sala do personagem fica ligada.
func _add_enemy(scene: PackedScene, cell: Vector2i) -> void:
	var enemy := scene.instantiate() as Enemy
	enemy.position = _cell_center(cell) + Vector2(0.0, 4.0)
	enemy.respawn_time = 0.0
	_objects.add_child(enemy)
	enemy.set_active(false)
	_register(enemy, cell)


func _add_chest(location: String, cell: Vector2i) -> void:
	var chest := CHEST_SCENE.instantiate() as Chest
	chest.location_id = location
	chest.item = data.items.get(location, Item.Id.NONE)
	chest.position = Vector2(cell * ChapterMap.TILE) + Vector2(8.0, 13.0)
	_objects.add_child(chest)
	_chests.append(chest)


func _add_obstacle(slot: String, area: Rect2i) -> void:
	var scene: PackedScene = OBSTACLE_SCENES.get(map.block_type(slot))
	if not scene:
		push_error("Vaga %s sem tipo de bloqueio." % slot)
		return
	var obstacle := scene.instantiate() as Node2D
	obstacle.position = Vector2(area.position * ChapterMap.TILE)
	obstacle.set("size", Vector2(area.size * ChapterMap.TILE))
	_obstacles.add_child(obstacle)
	if obstacle is SwitchDoor:
		var room := _room_of_cell(area.position)
		var gates: Array = _room_gates.get(room, [])
		gates.append(obstacle)
		_room_gates[room] = gates


## As grades de uma sala abrem enquanto algum interruptor dela está
## pressionado.
func _on_switch_changed(_pressed: bool, room: Rect2i) -> void:
	var any_pressed := false
	for switch: FloorSwitch in _room_switches.get(room, []):
		any_pressed = any_pressed or switch.pressed
	for gate: SwitchDoor in _room_gates.get(room, []):
		gate.set_open(any_pressed)


func _register(actor: Node, cell: Vector2i) -> void:
	var room := _room_of_cell(cell)
	var actors: Array = _room_actors.get(room, [])
	actors.append(actor)
	_room_actors[room] = actors


## Troca de sala: a câmera desliza até a nova sala, os inimigos da anterior
## voltam ao início e se desligam, e os da nova se ligam. O personagem passa a
## reaparecer na entrada da sala.
func _enter_room(room: Rect2i) -> void:
	var previous := _room
	_room = room
	_player.spawn_position = _player.global_position
	_camera.position = _camera_target()
	_clear_floor_effects()
	_activate_room.call_deferred(previous, false)
	_activate_room.call_deferred(room, true)


func _activate_room(room: Rect2i, active: bool) -> void:
	for actor: Node in _room_actors.get(room, []):
		actor.call("set_active", active)


## Apaga as marcas no chão, como a área da granada. Os interruptores ficam.
func _clear_floor_effects() -> void:
	for effect: Node in _floor_effects.get_children():
		if not effect is FloorSwitch:
			effect.queue_free()


func _on_player_respawned() -> void:
	_clear_floor_effects()
	_activate_room.call_deferred(_room, true)


func _on_boss_defeated(room: Rect2i) -> void:
	_spawn_relic.call_deferred(room)


func _spawn_relic(room: Rect2i) -> void:
	var relic := RELIC_SCENE.instantiate() as Relic
	relic.position = _room_pixels(room).get_center()
	relic.collected.connect(_finish, CONNECT_DEFERRED)
	_objects.add_child(relic)


func _finish() -> void:
	finished = true
	get_tree().paused = true
	if Progress.active:
		Progress.record_chapter(data.number, _player, _chests)
	var opened := 0
	for chest: Chest in _chests:
		if chest.is_open:
			opened += 1
	_end_screen.show_results(time_text(), mode_text(), "%d/%d" % [opened, _chests.size()])


## Sala de uma casa do mapa: a sala maior que contém a tela dela, ou a própria
## tela.
func _room_of_cell(cell: Vector2i) -> Rect2i:
	var screen := Vector2i(
		floori(float(cell.x) / ROOM_TILES.x), floori(float(cell.y) / ROOM_TILES.y)
	)
	return _room_rects.get(screen, Rect2i(screen, Vector2i.ONE))


func _room_of(point: Vector2) -> Rect2i:
	return _room_of_cell(Vector2i((point / float(ChapterMap.TILE)).floor()))


## Área da sala em pixels, com as paredes em volta.
func _room_pixels(room: Rect2i) -> Rect2:
	var tile := float(ChapterMap.TILE)
	return Rect2(Vector2(room.position * ROOM_TILES) * tile, Vector2(room.size * ROOM_TILES) * tile)


## Área da sala sem as paredes em volta, em pixels.
func _room_interior(room: Rect2i) -> Rect2:
	return _room_pixels(room).grow(-float(ChapterMap.TILE))


## Centro da câmera. Numa sala de uma tela, é o centro dela, deslocado para
## cima pela barra do HUD. Numa sala maior, a câmera segue o personagem, presa
## aos limites da sala, para nunca mostrar a sala vizinha.
func _camera_target() -> Vector2:
	var pixels := _room_pixels(_room)
	var low := pixels.position + Vector2(HALF_SCREEN.x, HALF_SCREEN.y - HUD_HEIGHT)
	var high := pixels.end - HALF_SCREEN
	return _player.global_position.clamp(low, high)


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE
