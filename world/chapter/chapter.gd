class_name Chapter
extends Node2D
## Cena de qualquer capítulo. Lê os dados do capítulo escolhido no menu, monta
## o mapa, põe em cada baú o item dele, move a câmera de sala em sala e
## encerra o capítulo quando o personagem toca a relíquia que o chefe deixa.
## Os dados de cada capítulo ficam em world/<capítulo>/ (ver
## progression/chapter_data.gd).
##
## Esta cena monta o mapa e liga as partes. O resto fica em arquivos ao lado:
## - chapter_rooms.gd: as salas, a sala atual, as visitadas, as limpas e os
##   atores de cada uma.
## - gate_mechanism.gd: o bloco pesado, o interruptor, a grade e os trilhos.
## - dungeon_state.gd: o estado da dungeon guardado ao sair, no modo
##   randomizado.
## - progression/map_legend.gd: a cena de cada inimigo e chefe, pelo caractere.
## - lab/: as mecânicas do laboratório. lab_builder.gd monta os objetos e
##   room_mechanisms.gd decide quando cada porta de mecanismo abre.
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
## No jogo contínuo (Progress.active), o personagem chega com as ferramentas
## e a vida máxima salvas, os baús de coração e de ferramenta de um capítulo
## já vencido começam abertos, e tocar a relíquia grava o progresso. No
## treino, ele chega com as ferramentas dos dados do capítulo. A dungeon de
## teste, mesmo aberta pelo mundo, é sempre um treino (Progress.practice).

## Distância máxima, em casas, do início até a parede da porta de saída.
const EXIT_DOOR_REACH := 4
## Altura da barra do HUD no alto da tela. A sala aparece logo abaixo dela.
const HUD_HEIGHT := 40.0
## Metade da tela, em pixels.
const HALF_SCREEN := Vector2(320.0, 180.0)
const PLAYER_SCENE := preload("res://player/player.tscn")
const BONE_DROP_SCENE := preload("res://items/bone_drop.tscn")
const CHEST_SCENE := preload("res://items/chest.tscn")
const RELIC_SCENE := preload("res://items/relic.tscn")
const LEDGE_SCENE := preload("res://obstacles/ledge.tscn")
const MECH_DOOR_SCENE := preload("res://lab/mech_door.tscn")
const PIT_SCENE := preload("res://lab/pit.tscn")
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
	ChapterMap.Block.SHUTTER: MECH_DOOR_SCENE,
	ChapterMap.Block.BARRIER: MECH_DOOR_SCENE,
	ChapterMap.Block.BARRIER_ALT: MECH_DOOR_SCENE,
	ChapterMap.Block.TORCH_DOOR: MECH_DOOR_SCENE,
	ChapterMap.Block.BLAST_DOOR: MECH_DOOR_SCENE,
	ChapterMap.Block.TIMED_GATE: MECH_DOOR_SCENE,
	ChapterMap.Block.BEAM_DOOR: MECH_DOOR_SCENE,
	ChapterMap.Block.PIT: PIT_SCENE,
	ChapterMap.Block.WIDE_PIT: PIT_SCENE,
	ChapterMap.Block.GAP: PIT_SCENE,
	ChapterMap.Block.WEB: preload("res://lab/web.tscn"),
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

## Salas do capítulo e mecanismo das grades.
var rooms: ChapterRooms
var gates := GateMechanism.new()
## Mecanismos de sala do laboratório (lab/room_mechanisms.gd).
var mechanisms: RoomMechanisms
## Ponto em que o personagem entrou na sala atual: é para onde ele volta ao
## cair num buraco.
var room_entry_point := Vector2.ZERO

var _player: Player
var _chests: Array[Chest] = []
## Bloqueio de cada vaga do mapa, para a tela de mapa saber o que já saiu.
var _obstacle_by_slot := {}
## Nos tipos em que a mesma vaga serve a vários bloqueios (ChapterMap.SHARED),
## o bloqueio de cada casa.
var _obstacle_by_cell := {}
var _lab: LabBuilder

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
	rooms = ChapterRooms.new(data.rooms)
	mechanisms = RoomMechanisms.new(rooms, data.waves, _spawn_wave_enemy)
	_lab = LabBuilder.new(self, _switches, _objects)
	_map_view.map = map
	_map_view.theme = DungeonTheme.for_chapter(data.number)
	for screen: Vector2i in data.room_themes:
		_map_view.room_themes[screen] = DungeonTheme.by_name(data.room_themes[screen])
	_map_view.queue_redraw()
	MapWalls.build(map, _walls)
	Progress.practice = Progress.active and data.number == ChapterData.TUTORIAL
	_build_cells()
	_add_darkness()
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
		DungeonState.apply(self, Progress.dungeon_state(data.number))
	_player.invulnerable = data.no_damage
	_player.damage_scale = DAMAGE_SCALE.get(RunSettings.chapter, 1.0)
	_camera.make_current()
	_enter_room(rooms.of_point(_player.global_position))
	_camera.reset_smoothing()


func _physics_process(_delta: float) -> void:
	if finished:
		return
	elapsed_ticks += 1
	if Progress.active:
		Progress.run_ticks += 1
	var room := rooms.of_point(_player.global_position)
	if room != rooms.current:
		_enter_room(room)
	else:
		_camera.position = _camera_target(true)
	mechanisms.tick(_player.global_position)


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
		Progress.record_dungeon(data.number, DungeonState.capture(self))


## Nome do capítulo, para o HUD e para a tela de fim.
func mode_text() -> String:
	if data.number == ChapterData.TUTORIAL:
		return "Dungeon de teste"
	if data.number == ChapterData.GALLERY:
		return "Playtest"
	if data.number == ChapterData.LAB:
		return "Laboratório"
	return "Cap. %d" % data.number


## Cronômetro do capítulo no formato minutos:segundos.centésimos.
func time_text() -> String:
	return GameMath.time_text(elapsed_ticks)


## Salas em que o personagem já esteve, em unidades de sala, para o minimapa.
func visited_rooms() -> Array:
	return rooms.visited.keys()


func current_room() -> Rect2i:
	return rooms.current


func room_tiles() -> Vector2i:
	return ChapterRooms.ROOM_TILES


## Sala de uma tela, em unidades de sala: a sala maior que a contém, ou a
## própria tela.
func room_at(screen: Vector2i) -> Rect2i:
	return rooms.room_at(screen)


func player() -> Player:
	return _player


func chests() -> Array[Chest]:
	return _chests


## Vagas de bloqueio que existem no mapa.
func obstacle_slots() -> Array:
	return _obstacle_by_slot.keys()


## Bloqueio de uma vaga, ou null.
func obstacle_at(slot: String) -> Node:
	return _obstacle_by_slot.get(slot)


## Se o baú de um local já foi aberto, para a tela de mapa.
func chest_is_open(location: String) -> bool:
	for chest: Chest in _chests:
		if chest.location_id == location:
			return chest.is_open
	return false


## Se o bloqueio de uma vaga já saiu do caminho: parede quebrada, gelo
## derretido, porta destrancada ou grade aberta. Um degrau nunca sai. Com a
## casa, vale o bloqueio daquela casa, nos tipos em que a vaga é de vários.
func block_cleared(slot: String, cell := ChapterMap.NO_CELL) -> bool:
	var obstacle: Node = _obstacle_by_cell.get(cell, _obstacle_by_slot.get(slot))
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
		if map.block_type(slot) in ChapterMap.SHARED:
			for area: Rect2i in map.slot_groups(slot):
				_add_obstacle(slot, area)
		else:
			_add_obstacle(slot, slots[slot])
	_add_exit_door()
	var rails := gates.build_rails(map, rooms)
	_switches.add_child(rails)
	_switches.move_child(rails, 0)


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
	if MapLegend.ENEMIES.has(character):
		_add_enemy(MapLegend.ENEMIES[character], cell)
	elif MapLegend.BOSSES.has(character):
		_add_boss(MapLegend.BOSSES[character], cell)
	elif character == MapLegend.PLAYER:
		_player = PLAYER_SCENE.instantiate() as Player
		_player.position = center
		_objects.add_child(_player)
	elif character == MapLegend.LIGHT_CRATE:
		var crate := LIGHT_CRATE_SCENE.instantiate() as Node2D
		crate.position = center + Vector2(0.0, 10.0)
		_objects.add_child(crate)
	elif character == MapLegend.HEAVY_BLOCK:
		var block := HEAVY_BLOCK_SCENE.instantiate() as HeavyBlock
		block.position = center + FloorSwitch.BLOCK_OFFSET
		_objects.add_child(block)
		rooms.register(block, cell)
		gates.add_block(block, cell)
	elif character == MapLegend.MESSAGE:
		var plate := MESSAGE_PLATE_SCENE.instantiate() as MessagePlate
		plate.position = center
		plate.text = data.messages.get(cell, "")
		_switches.add_child(plate)
	elif character == MapLegend.FLOOR_SWITCH:
		var switch := FLOOR_SWITCH_SCENE.instantiate() as FloorSwitch
		switch.position = center
		_switches.add_child(switch)
		gates.add_switch(switch, cell, rooms.of_cell(cell))
	elif not _lab.add(character, cell) and not ".:^# ".contains(character):
		push_error("Caractere %s sem legenda, na casa %s." % [character, cell])


## O chefe nasce desligado, preso à sala dele.
func _add_boss(scene: PackedScene, cell: Vector2i) -> void:
	var boss := scene.instantiate() as Boss
	var room := rooms.of_cell(cell)
	boss.position = _cell_center(cell) + Vector2(0.0, 12.0)
	boss.arena = rooms.interior(room)
	boss.defeated.connect(_on_boss_defeated.bind(room))
	_objects.add_child(boss)
	boss.set_active(false)
	rooms.register(boss, cell)


## Os inimigos nascem desligados. Só a sala do personagem fica ligada.
func _add_enemy(scene: PackedScene, cell: Vector2i) -> Enemy:
	var enemy := scene.instantiate() as Enemy
	enemy.position = _cell_center(cell) + Vector2(0.0, 8.0)
	enemy.respawn_time = 0.0
	enemy.died.connect(_on_enemy_died)
	_objects.add_child(enemy)
	enemy.set_active(false)
	rooms.register(enemy, cell)
	return enemy


## Inimigo de uma leva do laboratório: nasce ligado, no marcador da sala.
func _spawn_wave_enemy(character: String, point: Vector2, _room: Rect2i) -> void:
	if not MapLegend.ENEMIES.has(character):
		push_error("Leva com inimigo sem legenda: %s." % character)
		return
	var cell := Pit.cell_of(point)
	_add_enemy(MapLegend.ENEMIES[character], cell).set_active(true)


## Escuridão das salas escuras, por baixo do HUD.
func _add_darkness() -> void:
	if data.dark_rooms.is_empty():
		return
	var darkness := Darkness.new()
	for screen: Vector2i in data.dark_rooms:
		darkness.rooms[rooms.room_at(screen)] = true
	add_child(darkness)
	move_child(darkness, $HudLayer.get_index())


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
	# Todo bloqueio tem a propriedade size, mas não há uma classe mãe comum.
	obstacle.set("size", Vector2(area.size * ChapterMap.TILE))
	if obstacle is CrackedWall:
		(obstacle as CrackedWall).theme_name = _map_view.theme_name_at(area.position)
	# No laboratório, a cena é a mesma para vários tipos, e o tipo decide.
	if obstacle is MechDoor or obstacle is Pit:
		obstacle.set("kind", map.block_type(slot))
	_obstacles.add_child(obstacle)
	_obstacle_by_slot[slot] = obstacle
	if map.block_type(slot) in ChapterMap.SHARED:
		for y: int in area.size.y:
			for x: int in area.size.x:
				_obstacle_by_cell[area.position + Vector2i(x, y)] = obstacle
	if obstacle is MechDoor:
		mechanisms.add_door(obstacle as MechDoor, rooms.of_cell(area.position))
	elif obstacle is SwitchDoor:
		gates.add_gate(obstacle as SwitchDoor, rooms.of_cell(area.position))


## Troca de sala: a câmera desliza até a nova sala, os inimigos da anterior
## voltam ao início e se desligam, e os da nova se ligam.
func _enter_room(room: Rect2i) -> void:
	var previous := rooms.current
	rooms.current = room
	rooms.visited[room] = true
	room_entry_point = _player.global_position
	mechanisms.room_entered(room)
	_camera.position = _camera_target()
	_clear_floor_effects()
	rooms.activate.call_deferred(previous, false)
	rooms.activate.call_deferred(room, true)


## Apaga as marcas no chão, como a área da granada.
func _clear_floor_effects() -> void:
	for effect: Node in _floor_effects.get_children():
		effect.queue_free()


func _on_boss_defeated(room: Rect2i) -> void:
	_spawn_relic.call_deferred(room)


## Sorteia um ossinho onde o inimigo caiu, sempre quando a vida está baixa. O
## ossinho fica com os efeitos do chão e some ao trocar de sala.
func _on_enemy_died(enemy: Enemy) -> void:
	var room := rooms.of_point(enemy.global_position)
	mechanisms.enemy_died(room)
	if rooms.mark_cleared_by(enemy):
		mechanisms.room_cleared(room)
	if not _drops_bone():
		return
	var bone := BONE_DROP_SCENE.instantiate() as BoneDrop
	bone.position = enemy.global_position
	_floor_effects.add_child(bone)


func _drops_bone() -> bool:
	if _player and _player.health <= bone_drop_sure_health:
		return true
	return randi_range(1, 100) <= bone_drop_chance


func _spawn_relic(room: Rect2i) -> void:
	var relic := RELIC_SCENE.instantiate() as Relic
	relic.position = rooms.pixels(room).get_center()
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


## Centro da câmera. Numa sala de uma tela, é o centro dela, deslocado para
## cima pela barra do HUD. Numa sala maior, a câmera segue o personagem com
## zona morta (CameraFollow), presa aos limites da sala, para nunca mostrar a
## sala vizinha. Ao entrar na sala, a câmera parte centrada no personagem.
func _camera_target(pushed := false) -> Vector2:
	var pixels := rooms.pixels(rooms.current)
	var low := pixels.position + Vector2(HALF_SCREEN.x, HALF_SCREEN.y - HUD_HEIGHT)
	var high := pixels.end - HALF_SCREEN
	var target := _player.global_position
	if pushed:
		return CameraFollow.pushed(_camera.position, target, low, high, HUD_HEIGHT)
	return CameraFollow.centered(target, low, high)


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE
