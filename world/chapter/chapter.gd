extends Node2D
## Cena de qualquer capítulo. Lê os dados do capítulo escolhido no menu, monta
## o mapa, distribui os itens pela seed, move a câmera de sala em sala e
## encerra o capítulo quando o personagem toca a relíquia que o chefe deixa.
## Os dados de cada capítulo ficam em world/<capítulo>/ (ver
## progression/chapter_data.gd).
##
## Os inimigos só agem na sala em que o personagem está. Ao entrar ou sair de
## uma sala, os inimigos dela voltam ao ponto inicial, e as ondas do chefe que
## ainda correm pelo chão somem. Baús abertos e bloqueios removidos continuam
## assim até o fim do capítulo.

const TITLE_SCENE := "res://ui/title_screen.tscn"
## Tamanho de uma sala, em casas.
const ROOM_TILES := Vector2i(20, 10)
## Altura da barra do HUD no alto da tela. A sala aparece logo abaixo dela.
const HUD_HEIGHT := 20.0
const PLAYER_SCENE := preload("res://player/player.tscn")
const CHEST_SCENE := preload("res://items/chest.tscn")
const RELIC_SCENE := preload("res://items/relic.tscn")
const CRACKED_WALL_SCENE := preload("res://obstacles/cracked_wall.tscn")
const ICE_BLOCK_SCENE := preload("res://obstacles/ice_block.tscn")
const LOCKED_DOOR_SCENE := preload("res://obstacles/locked_door.tscn")
const BOSS_DOOR_SCENE := preload("res://obstacles/boss_door.tscn")
const LEDGE_SCENE := preload("res://obstacles/ledge.tscn")
const MINION_SCENE := preload("res://enemies/minion.tscn")
const UGLY_SCENE := preload("res://enemies/ugly.tscn")
const ICE_SLIME_SCENE := preload("res://enemies/ice_slime.tscn")
const BOSS_SCENE := preload("res://enemies/boss.tscn")
const SENTINEL_SCENE := preload("res://enemies/sentinel.tscn")
const LIGHT_CRATE_SCENE := preload("res://objects/light_crate.tscn")

## Ticks de jogo desde o início do capítulo, para o cronômetro.
var elapsed_ticks := 0
var finished := false
var data: ChapterData
var map: ChapterMap
## Item de cada baú nesta partida.
var distribution := {}

var _player: Player
var _room := Vector2i(-1000, -1000)
var _room_actors := {}
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
	distribution = data.linear
	if RunSettings.randomized:
		distribution = Randomizer.shuffled(
			map, data.linear, RunSettings.run_seed, data.goal, data.goal_tools
		)
	_map_view.map = map
	_map_view.queue_redraw()
	_build_walls()
	_build_cells()
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("back_to_menu"):
		get_tree().paused = false
		get_tree().change_scene_to_file(TITLE_SCENE)


## Texto do modo da partida, para o HUD e para a tela de fim.
func mode_text() -> String:
	var mode := "Seed %d" % RunSettings.run_seed if RunSettings.randomized else "Linear"
	return "Cap. %d  %s" % [data.number, mode]


## Cronômetro no formato minutos:segundos.centésimos.
func time_text() -> String:
	var seconds := float(elapsed_ticks) / Engine.physics_ticks_per_second
	var minutes := floori(seconds / 60.0)
	return "%02d:%05.2f" % [minutes, seconds - minutes * 60.0]


## Junta as paredes de cada linha em trechos contínuos, uma forma de colisão
## por trecho.
func _build_walls() -> void:
	var tile := float(ChapterMap.TILE)
	for y: int in map.height:
		var x := 0
		while x < map.width:
			if map.tile(Vector2i(x, y)) != "#":
				x += 1
				continue
			var start := x
			while x < map.width and map.tile(Vector2i(x, y)) == "#":
				x += 1
			var rectangle := RectangleShape2D.new()
			rectangle.size = Vector2((x - start) * tile, tile)
			var shape := CollisionShape2D.new()
			shape.shape = rectangle
			shape.position = Vector2((start + x) * tile / 2.0, (y + 0.5) * tile)
			_walls.add_child(shape)


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
	match character:
		"@":
			_player = PLAYER_SCENE.instantiate() as Player
			_player.position = center
			_objects.add_child(_player)
		"m":
			_add_enemy(MINION_SCENE, cell)
		"u":
			_add_enemy(UGLY_SCENE, cell)
		"i":
			_add_enemy(ICE_SLIME_SCENE, cell)
		"*":
			_add_boss(BOSS_SCENE, cell)
		"&":
			_add_boss(SENTINEL_SCENE, cell)
		"c":
			var crate := LIGHT_CRATE_SCENE.instantiate() as Node2D
			crate.position = center + Vector2(0.0, 5.0)
			_objects.add_child(crate)


## O chefe nasce desligado, preso à sala dele. Todo chefe tem a propriedade
## arena, o sinal defeated e a função set_active.
func _add_boss(scene: PackedScene, cell: Vector2i) -> void:
	var boss := scene.instantiate() as Node2D
	boss.position = _cell_center(cell) + Vector2(0.0, 6.0)
	boss.set("arena", _room_interior(_room_of_cell(cell)))
	boss.connect("defeated", _on_boss_defeated.bind(_room_of_cell(cell)))
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
	chest.item = distribution.get(location, Item.Id.NONE)
	chest.position = Vector2(cell * ChapterMap.TILE) + Vector2(8.0, 13.0)
	_objects.add_child(chest)
	_chests.append(chest)


func _add_obstacle(slot: String, area: Rect2i) -> void:
	var scene: PackedScene
	match map.block_type(slot):
		ChapterMap.Block.CRACKED:
			scene = CRACKED_WALL_SCENE
		ChapterMap.Block.ICE:
			scene = ICE_BLOCK_SCENE
		ChapterMap.Block.LEDGE:
			scene = LEDGE_SCENE
		ChapterMap.Block.LOCKED:
			scene = LOCKED_DOOR_SCENE
		ChapterMap.Block.BOSS_DOOR:
			scene = BOSS_DOOR_SCENE
		_:
			push_error("Vaga %s sem tipo de bloqueio." % slot)
			return
	var obstacle := scene.instantiate() as Node2D
	obstacle.position = Vector2(area.position * ChapterMap.TILE)
	obstacle.set("size", Vector2(area.size * ChapterMap.TILE))
	_obstacles.add_child(obstacle)


func _register(actor: Node, cell: Vector2i) -> void:
	var room := _room_of_cell(cell)
	var actors: Array = _room_actors.get(room, [])
	actors.append(actor)
	_room_actors[room] = actors


## Troca de sala: a câmera desliza até a nova sala, os inimigos da anterior
## voltam ao início e se desligam, e os da nova se ligam. O personagem passa a
## reaparecer na entrada da sala.
func _enter_room(room: Vector2i) -> void:
	var previous := _room
	_room = room
	_player.spawn_position = _player.global_position
	_camera.position = _room_center(room)
	_clear_floor_effects()
	_activate_room.call_deferred(previous, false)
	_activate_room.call_deferred(room, true)


func _activate_room(room: Vector2i, active: bool) -> void:
	for actor: Node in _room_actors.get(room, []):
		actor.call("set_active", active)


func _clear_floor_effects() -> void:
	for effect: Node in _floor_effects.get_children():
		effect.queue_free()


func _on_player_respawned() -> void:
	_clear_floor_effects()
	_activate_room.call_deferred(_room, true)


func _on_boss_defeated(room: Vector2i) -> void:
	_spawn_relic.call_deferred(room)


func _spawn_relic(room: Vector2i) -> void:
	var relic := RELIC_SCENE.instantiate() as Relic
	relic.position = Vector2(room * ROOM_TILES * ChapterMap.TILE) + _room_size() / 2.0
	relic.collected.connect(_finish, CONNECT_DEFERRED)
	_objects.add_child(relic)


func _finish() -> void:
	finished = true
	get_tree().paused = true
	var opened := 0
	for chest: Chest in _chests:
		if chest.is_open:
			opened += 1
	_end_screen.show_results(time_text(), mode_text(), "%d/%d" % [opened, _chests.size()])


func _room_size() -> Vector2:
	return Vector2(ROOM_TILES * ChapterMap.TILE)


## Área da sala sem as paredes em volta, em pixels.
func _room_interior(room: Vector2i) -> Rect2:
	var tile := float(ChapterMap.TILE)
	var origin := Vector2(room * ROOM_TILES * ChapterMap.TILE)
	return Rect2(origin + Vector2(tile, tile), _room_size() - Vector2(tile, tile) * 2.0)


func _room_of(point: Vector2) -> Vector2i:
	var size := _room_size()
	return Vector2i(floori(point.x / size.x), floori(point.y / size.y))


func _room_of_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x) / ROOM_TILES.x), floori(float(cell.y) / ROOM_TILES.y))


## Centro da câmera para a sala, deslocado para cima pela barra do HUD.
func _room_center(room: Vector2i) -> Vector2:
	var size := _room_size()
	return Vector2((room.x + 0.5) * size.x, (room.y + 0.5) * size.y - HUD_HEIGHT / 2.0)


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE
