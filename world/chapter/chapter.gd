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
## está pressionado, e de vez quando um bloco trava num interruptor. O bloco
## só tomba dentro do trilho que vai dele ao interruptor (_add_rails), e um
## bloco solto volta ao lugar quando o personagem entra de novo na sala.
##
## No jogo contínuo (Progress.active), o personagem chega com as ferramentas
## e a vida máxima salvas, os baús de coração e de ferramenta de um capítulo
## já vencido começam abertos, e tocar a relíquia grava o progresso. No
## treino, ele chega com as ferramentas dos dados do capítulo. A dungeon de
## teste, mesmo aberta pelo mundo, é sempre um treino (Progress.practice).

## Distância máxima, em casas, do início até a parede da porta de saída.
const EXIT_DOOR_REACH := 4
## Tamanho de uma sala de uma tela, em casas.
const ROOM_TILES := Vector2i(20, 10)
## Altura da barra do HUD no alto da tela. A sala aparece logo abaixo dela.
const HUD_HEIGHT := 40.0
## Metade da tela, em pixels.
const HALF_SCREEN := Vector2(320.0, 180.0)
const PLAYER_SCENE := preload("res://player/player.tscn")
const BONE_DROP_SCENE := preload("res://items/bone_drop.tscn")
const CHEST_SCENE := preload("res://items/chest.tscn")
const RELIC_SCENE := preload("res://items/relic.tscn")
const LEDGE_SCENE := preload("res://obstacles/ledge.tscn")
## Cena de cada tipo de bloqueio. O degrau duplo é a mesma face do degrau,
## com duas casas de altura.
const OBSTACLE_SCENES := {
	ChapterMap.Block.CRACKED: preload("res://obstacles/cracked_wall.tscn"),
	ChapterMap.Block.BOARDED: preload("res://obstacles/boarded_wall.tscn"),
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
const MESSAGE_PLATE_SCENE := preload("res://objects/message_plate.tscn")
## Dano dos inimigos por dungeon: uma vez e meia na 2 e o dobro na 3, sempre
## arredondado para cima (pedido de Marcelo em 2026-11-13).
const DAMAGE_SCALE := {2: 1.5, 3: 2.0}

## Chance, em cem, de um inimigo morto deixar um ossinho que recupera vida
## (pedido de Marcelo em 2026-11-07, para a morte não ficar dura demais). É
## sorteio, e não a cada tantos inimigos, para às vezes surpreender e às vezes
## demorar, como ele pediu ao jogar. Zero desliga.
@export_range(0, 100, 1) var bone_drop_chance := 30
## Com esta vida ou menos, todo inimigo morto deixa um ossinho (pedido dele em
## 2026-11-07).
@export_range(0, 40, 1) var bone_drop_sure_health := 3

## Ticks de jogo desde o início do capítulo, para o cronômetro.
var elapsed_ticks := 0
var finished := false
var data: ChapterData
var map: ChapterMap

var _player: Player
## Sala atual, em unidades de sala de uma tela.
var _room := Rect2i(-1000, -1000, 1, 1)
## Salas em que o personagem já esteve, para o minimapa.
var _visited := {}
## Sala maior de cada tela que faz parte de uma. As outras telas são salas.
var _room_rects := {}
var _room_actors := {}
## Salas em que todos os inimigos foram derrotados. Eles não voltam mais.
var _cleared_rooms := {}
## Interruptores e grades de cada sala.
var _room_switches := {}
var _room_gates := {}
var _chests: Array[Chest] = []
## Bloqueio de cada vaga do mapa, para a tela de mapa saber o que já saiu.
var _obstacle_by_slot := {}
## Casa de cada bloco pesado e as casas dos interruptores, para os trilhos.
var _block_cells := {}
var _switch_cells: Array[Vector2i] = []

@onready var _map_view: MapView = $MapView
@onready var _walls: StaticBody2D = $Walls
@onready var _obstacles: Node2D = $Obstacles
@onready var _switches: Node2D = $Switches
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
	_map_view.theme = DungeonTheme.for_chapter(data.number)
	for screen: Vector2i in data.room_themes:
		_map_view.room_themes[screen] = DungeonTheme.by_name(data.room_themes[screen])
	_map_view.queue_redraw()
	MapWalls.build(map, _walls)
	Progress.practice = Progress.active and data.number == ChapterData.TUTORIAL
	_build_cells()
	if _keeps_progress():
		_player.restore(Progress.tools, Progress.max_health)
		for chest: Chest in _chests:
			if Progress.was_opened(data.number, chest.location_id):
				chest.open_silently()
	else:
		var tools := 0
		for id: int in data.starting_tools:
			tools |= Item.bit(id)
		_player.restore(tools, _player.max_health)
	if _keeps_dungeon():
		_restore_dungeon(Progress.dungeon_state(data.number))
	_player.invulnerable = data.no_damage
	_player.damage_scale = DAMAGE_SCALE.get(RunSettings.chapter, 1.0)
	_camera.make_current()
	_enter_room(_room_of(_player.global_position))
	_camera.reset_smoothing()


func _physics_process(_delta: float) -> void:
	if finished:
		return
	elapsed_ticks += 1
	if Progress.active:
		Progress.run_ticks += 1
	var room := _room_of(_player.global_position)
	if room != _room:
		_enter_room(room)
	else:
		_camera.position = _camera_target(true)


## Jogo contínuo fora da dungeon de teste: o que acontece no capítulo vale
## para o resto do jogo.
func _keeps_progress() -> bool:
	return Progress.active and not Progress.practice


## No modo randomizado, a dungeon fica como o jogador a deixou ao sair e
## voltar. No modo original, sair no meio perde o que foi feito nela.
func _keeps_dungeon() -> bool:
	return _keeps_progress() and Progress.seed != 0


## Ao sair da cena com o personagem vivo, guarda como a dungeon ficou. Morto,
## o modo randomizado já recomeçou a partida, e nada é guardado.
func _exit_tree() -> void:
	if _keeps_dungeon() and _player and _player.health > 0:
		Progress.record_dungeon(data.number, _dungeon_state())


## Como a dungeon está agora, em valores que cabem no arquivo JSON: letras
## dos baús abertos, vagas dos bloqueios removidos, posição dos blocos
## travados, salas limpas e visitadas, chaves pequenas e a chave grande.
func _dungeon_state() -> Dictionary:
	var chests := ""
	for chest: Chest in _chests:
		if chest.is_open:
			chests += chest.location_id
	var slots := ""
	for slot: String in _obstacle_by_slot:
		var obstacle: Node = _obstacle_by_slot[slot]
		if not obstacle is SwitchDoor and block_cleared(slot):
			slots += slot
	var blocks: Array = []
	for block: HeavyBlock in _block_cells:
		if block.locked:
			var cell: Vector2i = _block_cells[block]
			blocks.append([cell.x, cell.y, block.global_position.x, block.global_position.y])
	return {
		"chests": chests,
		"slots": slots,
		"blocks": blocks,
		"cleared": _rooms_to_lists(_cleared_rooms),
		"visited": _rooms_to_lists(_visited),
		"keys": _player.keys,
		"boss_key": _player.has_tool(Item.Id.BOSS_KEY),
	}


## Põe a dungeon como estava no estado guardado. Vazio, não muda nada.
func _restore_dungeon(state: Dictionary) -> void:
	if state.is_empty():
		return
	var chests: String = str(state.get("chests", ""))
	for chest: Chest in _chests:
		if chests.contains(chest.location_id):
			chest.open_silently()
	for slot: String in str(state.get("slots", "")):
		var obstacle: Node = _obstacle_by_slot.get(slot)
		if obstacle is LockedDoor:
			(obstacle as LockedDoor).open_silently()
		elif obstacle is Obstacle and not obstacle is SwitchDoor:
			(obstacle as Obstacle).clear_silently()
	var saved_blocks = state.get("blocks", [])
	if saved_blocks is Array:
		for entry in saved_blocks:
			if not entry is Array or entry.size() < 4:
				continue
			var cell := Vector2i(int(entry[0]), int(entry[1]))
			for block: HeavyBlock in _block_cells:
				if _block_cells[block] == cell:
					block.lock_at(Vector2(float(entry[2]), float(entry[3])))
	_lists_to_rooms(state.get("cleared", []), _cleared_rooms)
	_lists_to_rooms(state.get("visited", []), _visited)
	_player.keys = int(state.get("keys", 0))
	if state.get("boss_key", false):
		_player.restore(_player.tool_bits() | Item.bit(Item.Id.BOSS_KEY), _player.max_health)


static func _rooms_to_lists(rooms: Dictionary) -> Array:
	var lists: Array = []
	for room: Rect2i in rooms:
		lists.append([room.position.x, room.position.y, room.size.x, room.size.y])
	return lists


static func _lists_to_rooms(lists: Variant, rooms: Dictionary) -> void:
	if not lists is Array:
		return
	for entry in lists:
		if entry is Array and entry.size() >= 4:
			var corner := Vector2i(int(entry[0]), int(entry[1]))
			rooms[Rect2i(corner, Vector2i(int(entry[2]), int(entry[3])))] = true


## Nome do capítulo, para o HUD e para a tela de fim.
func mode_text() -> String:
	if data.number == ChapterData.TUTORIAL:
		return "Dungeon de teste"
	if data.number == ChapterData.GALLERY:
		return "Playtest"
	return "Cap. %d" % data.number


## Cronômetro do capítulo no formato minutos:segundos.centésimos.
func time_text() -> String:
	return GameMath.time_text(elapsed_ticks)


## Salas em que o personagem já esteve, em unidades de sala, para o minimapa.
func visited_rooms() -> Array:
	return _visited.keys()


func current_room() -> Rect2i:
	return _room


func room_tiles() -> Vector2i:
	return ROOM_TILES


## Sala de uma tela, em unidades de sala: a sala maior que a contém, ou a
## própria tela.
func room_at(screen: Vector2i) -> Rect2i:
	return _room_rects.get(screen, Rect2i(screen, Vector2i.ONE))


## Se o baú de um local já foi aberto, para a tela de mapa.
func chest_is_open(location: String) -> bool:
	for chest: Chest in _chests:
		if chest.location_id == location:
			return chest.is_open
	return false


## Se o bloqueio de uma vaga já saiu do caminho: parede quebrada, gelo
## derretido, porta destrancada ou grade aberta. Um degrau nunca sai.
func block_cleared(slot: String) -> bool:
	var obstacle: Node = _obstacle_by_slot.get(slot)
	if obstacle is SwitchDoor:
		return (obstacle as SwitchDoor).open
	if obstacle is Obstacle:
		return (obstacle as Obstacle).cleared
	if obstacle is LockedDoor:
		return (obstacle as LockedDoor).opened
	return false


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
	_add_exit_door()
	_add_rails()


## Trilho de cada bloco pesado: as casas do bloco até o interruptor mais
## próximo da mesma sala, em linha reta ou com uma curva. O bloco só tomba
## dentro dele. Um bloco sem caminho de chão até um interruptor fica sem
## trilho e não anda.
func _add_rails() -> void:
	var view := RailView.new()
	view.tile = ChapterMap.TILE
	for block: HeavyBlock in _block_cells:
		var from: Vector2i = _block_cells[block]
		var path: Array = []
		var best := -1
		for to: Vector2i in _switch_cells:
			if _room_of_cell(to) != _room_of_cell(from):
				continue
			var distance := absi(to.x - from.x) + absi(to.y - from.y)
			if best >= 0 and distance >= best:
				continue
			var found := _rail_path(from, to, true)
			if found.is_empty():
				found = _rail_path(from, to, false)
			if not found.is_empty():
				path = found
				best = distance
		block.tile = ChapterMap.TILE
		for cell: Vector2i in path:
			block.rail[cell] = true
			view.cells[cell] = true
	_switches.add_child(view)
	_switches.move_child(view, 0)


## Casas de from a to, primeiro na horizontal ou primeiro na vertical. Vazio
## se alguma casa do caminho não for chão no nível do bloco.
func _rail_path(from: Vector2i, to: Vector2i, horizontal_first: bool) -> Array:
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


## Porta de saída na parede de baixo, diante do início do personagem. Só
## entra quando a parede está a até EXIT_DOOR_REACH casas do início, com chão
## livre no caminho, o que deixa a Galeria sem porta.
func _add_exit_door() -> void:
	var cell := map.find("@")
	if cell == ChapterMap.NO_CELL:
		return
	for step: int in EXIT_DOOR_REACH:
		cell += Vector2i.DOWN
		if map.tile(cell) == "#":
			break
		if map.tile(cell) != ".":
			return
	for side: int in range(-1, 2):
		if map.tile(cell + Vector2i(side, 0)) != "#":
			return
	var door := ExitDoor.new()
	var center_x := (cell.x + 0.5) * ChapterMap.TILE
	door.position = Vector2(center_x - ExitDoor.SIZE.x / 2.0, cell.y * ChapterMap.TILE)
	door.used.connect(_on_exit_door_used)
	_obstacles.add_child(door)


func _on_exit_door_used() -> void:
	if not finished:
		Flow.leave_chapter(get_tree())


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
		crate.position = center + Vector2(0.0, 10.0)
		_objects.add_child(crate)
	elif character == "0":
		var block := HEAVY_BLOCK_SCENE.instantiate() as HeavyBlock
		block.position = center + FloorSwitch.BLOCK_OFFSET
		_objects.add_child(block)
		_register(block, cell)
		_block_cells[block] = cell
	elif character == "?":
		var plate := MESSAGE_PLATE_SCENE.instantiate() as MessagePlate
		plate.position = center
		plate.text = data.messages.get(cell, "")
		_switches.add_child(plate)
	elif character == "=":
		var switch := FLOOR_SWITCH_SCENE.instantiate() as FloorSwitch
		switch.position = center
		var room := _room_of_cell(cell)
		switch.changed.connect(_on_switch_changed.bind(room))
		_switches.add_child(switch)
		var switches: Array = _room_switches.get(room, [])
		switches.append(switch)
		_room_switches[room] = switches
		_switch_cells.append(cell)


## O chefe nasce desligado, preso à sala dele. Todo chefe tem a propriedade
## arena, o sinal defeated e a função set_active.
func _add_boss(scene: PackedScene, cell: Vector2i) -> void:
	var boss := scene.instantiate() as Node2D
	var room := _room_of_cell(cell)
	boss.position = _cell_center(cell) + Vector2(0.0, 12.0)
	boss.set("arena", _room_interior(room))
	boss.connect("defeated", _on_boss_defeated.bind(room))
	_objects.add_child(boss)
	boss.call("set_active", false)
	_register(boss, cell)


## Os inimigos nascem desligados. Só a sala do personagem fica ligada.
func _add_enemy(scene: PackedScene, cell: Vector2i) -> void:
	var enemy := scene.instantiate() as Enemy
	enemy.position = _cell_center(cell) + Vector2(0.0, 8.0)
	enemy.respawn_time = 0.0
	enemy.died.connect(_on_enemy_died)
	_objects.add_child(enemy)
	enemy.set_active(false)
	_register(enemy, cell)


func _add_chest(location: String, cell: Vector2i) -> void:
	var chest := CHEST_SCENE.instantiate() as Chest
	chest.location_id = location
	chest.item = Progress.item_at(data.number, location, data.items.get(location, Item.Id.NONE))
	chest.position = Vector2(cell * ChapterMap.TILE) + Vector2(16.0, 26.0)
	chest.opened.connect(_on_chest_opened)
	_objects.add_child(chest)
	_chests.append(chest)


## No modo randomizado, o baú aberto fica gravado na hora.
func _on_chest_opened(chest: Chest) -> void:
	if _keeps_progress() and Progress.seed != 0:
		Progress.record_chest(data.number, chest, _player)


func _add_obstacle(slot: String, area: Rect2i) -> void:
	var scene: PackedScene = OBSTACLE_SCENES.get(map.block_type(slot))
	if not scene:
		push_error("Vaga %s sem tipo de bloqueio." % slot)
		return
	var obstacle := scene.instantiate() as Node2D
	obstacle.position = Vector2(area.position * ChapterMap.TILE)
	obstacle.set("size", Vector2(area.size * ChapterMap.TILE))
	if obstacle is CrackedWall:
		(obstacle as CrackedWall).theme_name = _map_view.theme_name_at(area.position)
	_obstacles.add_child(obstacle)
	_obstacle_by_slot[slot] = obstacle
	if obstacle is SwitchDoor:
		var room := _room_of_cell(area.position)
		var gates: Array = _room_gates.get(room, [])
		gates.append(obstacle)
		_room_gates[room] = gates


## As grades de uma sala abrem enquanto algum interruptor dela está
## pressionado.
func _on_switch_changed(_pressed: bool, room: Rect2i) -> void:
	FloorSwitch.sync_gates(_room_switches.get(room, []), _room_gates.get(room, []))


func _register(actor: Node, cell: Vector2i) -> void:
	var room := _room_of_cell(cell)
	var actors: Array = _room_actors.get(room, [])
	actors.append(actor)
	_room_actors[room] = actors


## Troca de sala: a câmera desliza até a nova sala, os inimigos da anterior
## voltam ao início e se desligam, e os da nova se ligam.
func _enter_room(room: Rect2i) -> void:
	var previous := _room
	_room = room
	_visited[room] = true
	_camera.position = _camera_target()
	_clear_floor_effects()
	_activate_room.call_deferred(previous, false)
	_activate_room.call_deferred(room, true)


## Numa sala limpa, os inimigos ficam desligados para sempre. Numa sala em
## que sobrou algum, todos voltam quando o personagem sai e entra de novo.
func _activate_room(room: Rect2i, active: bool) -> void:
	var cleared := _cleared_rooms.has(room)
	for actor: Node in _room_actors.get(room, []):
		actor.call("set_active", active and not (cleared and actor is Enemy))


## Apaga as marcas no chão, como a área da granada.
func _clear_floor_effects() -> void:
	for effect: Node in _floor_effects.get_children():
		effect.queue_free()


func _on_boss_defeated(room: Rect2i) -> void:
	_spawn_relic.call_deferred(room)


## Sorteia um ossinho onde o inimigo caiu, sempre quando a vida está baixa. O
## ossinho fica com os efeitos do chão e some ao trocar de sala.
func _on_enemy_died(enemy: Enemy) -> void:
	_check_room_cleared(enemy)
	if not _drops_bone():
		return
	var bone := BONE_DROP_SCENE.instantiate() as BoneDrop
	bone.position = enemy.global_position
	_floor_effects.add_child(bone)


## A sala fica limpa quando o último inimigo dela é derrotado (pedido de
## Marcelo em 2026-11-11). Vale até sair da dungeon.
func _check_room_cleared(defeated: Enemy) -> void:
	for room: Rect2i in _room_actors:
		var actors: Array = _room_actors[room]
		if defeated not in actors:
			continue
		for actor: Node in actors:
			var enemy := actor as Enemy
			if enemy and not enemy.is_dead():
				return
		_cleared_rooms[room] = true
		return


func _drops_bone() -> bool:
	if _player and _player.health <= bone_drop_sure_health:
		return true
	return randi_range(1, 100) <= bone_drop_chance


func _spawn_relic(room: Rect2i) -> void:
	var relic := RELIC_SCENE.instantiate() as Relic
	relic.position = _room_pixels(room).get_center()
	relic.collected.connect(_finish, CONNECT_DEFERRED)
	_objects.add_child(relic)


func _finish() -> void:
	finished = true
	get_tree().paused = true
	if Progress.practice:
		Progress.record_practice()
	elif Progress.active:
		Progress.record_chapter(data.number, _player, _chests)
	var opened := 0
	for chest: Chest in _chests:
		if chest.is_open:
			opened += 1
	var chests_text := "%d/%d" % [opened, _chests.size()]
	if _keeps_progress() and Progress.all_done():
		_end_screen.show_victory(
			GameMath.time_text(Progress.run_ticks), time_text(), chests_text, Progress.seed
		)
	else:
		_end_screen.show_results(time_text(), mode_text(), chests_text)


## Sala de uma casa do mapa: a sala maior que contém a tela dela, ou a própria
## tela.
func _room_of_cell(cell: Vector2i) -> Rect2i:
	return room_at(
		Vector2i(floori(float(cell.x) / ROOM_TILES.x), floori(float(cell.y) / ROOM_TILES.y))
	)


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
## cima pela barra do HUD. Numa sala maior, a câmera segue o personagem com
## zona morta (CameraFollow), presa aos limites da sala, para nunca mostrar a
## sala vizinha. Ao entrar na sala, a câmera parte centrada no personagem.
func _camera_target(pushed := false) -> Vector2:
	var pixels := _room_pixels(_room)
	var low := pixels.position + Vector2(HALF_SCREEN.x, HALF_SCREEN.y - HUD_HEIGHT)
	var high := pixels.end - HALF_SCREEN
	var target := _player.global_position
	if pushed:
		return CameraFollow.pushed(_camera.position, target, low, high, HUD_HEIGHT)
	return CameraFollow.centered(target, low, high)


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE
