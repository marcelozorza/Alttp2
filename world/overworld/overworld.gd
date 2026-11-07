extends Node2D
## O mundo que liga os capítulos: uma clareira na mata com a entrada de cada
## dungeon e a pedra de salvamento. O mapa fica em overworld_data.gd, na
## mesma legenda dos capítulos, e a câmera segue o personagem pelo mapa
## inteiro, presa às bordas dele.
##
## Cada entrada abre quando o capítulo anterior foi vencido, e a entrada de
## um capítulo vencido mostra a relíquia dele. Ao voltar de um capítulo, o
## personagem aparece na entrada dele. Ao continuar um jogo salvo, aparece
## na pedra de salvamento.

const HUD_HEIGHT := 20.0
const HALF_SCREEN := Vector2(160.0, 90.0)
## Casas entre o personagem e a borda da tela a partir das quais a câmera anda
## no mundo: 6 na horizontal, onde Marcelo marcou o ponto jogando (2026-11-07),
## e 4 na vertical, o mais perto de 6 que a tela de 10 casas de altura permite
## sem perder a zona morta.
const EDGE_TILES := Vector2i(6, 4)
const SOLID := "#~"
const PLAYER_SCENE := preload("res://player/player.tscn")
const ENTRANCE_SCENE := preload("res://world/overworld/entrance.tscn")
const SAVE_STONE_SCENE := preload("res://world/overworld/save_stone.tscn")

var map: ChapterMap

var _player: Player
var _entrances: Array[DungeonEntrance] = []

@onready var _map_view: MapView = $MapView
@onready var _walls: StaticBody2D = $Walls
@onready var _objects: Node2D = $Objects
@onready var _camera: Camera2D = $Camera


func _ready() -> void:
	map = ChapterMap.new(OverworldData.MAP, {})
	_map_view.map = map
	_map_view.queue_redraw()
	MapWalls.build(map, _walls, SOLID)
	_build_cells()
	_player.restore(Progress.tools, Progress.max_health)
	_place_player()
	_camera.make_current()
	_camera.position = _camera_target()
	_camera.reset_smoothing()


func _physics_process(_delta: float) -> void:
	if Progress.active:
		Progress.run_ticks += 1
	_camera.position = _camera_target(true)


func _build_cells() -> void:
	var entrances := {}
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			var character := map.tile(cell)
			if character == "@":
				_player = PLAYER_SCENE.instantiate() as Player
				_player.position = _cell_center(cell)
				_objects.add_child(_player)
			elif character == "S":
				var stone := SAVE_STONE_SCENE.instantiate() as SaveStone
				stone.position = _cell_center(cell) + Vector2(0.0, 6.0)
				_objects.add_child(stone)
			elif character.is_valid_int() and not entrances.has(character):
				entrances[character] = cell
	for character: String in entrances:
		_add_entrance(int(character), entrances[character])


func _add_entrance(chapter: int, cell: Vector2i) -> void:
	var entrance := ENTRANCE_SCENE.instantiate() as DungeonEntrance
	entrance.chapter = chapter
	entrance.position = Vector2(cell * ChapterMap.TILE)
	if Progress.is_done(chapter):
		entrance.mode = DungeonEntrance.Mode.DONE
	elif Progress.is_open(chapter):
		entrance.mode = DungeonEntrance.Mode.OPEN
	else:
		entrance.mode = DungeonEntrance.Mode.LOCKED
	entrance.entered.connect(_on_entrance_entered)
	_objects.add_child(entrance)
	_entrances.append(entrance)


## Ao voltar de um capítulo, o personagem aparece na entrada dele.
func _place_player() -> void:
	for entrance: DungeonEntrance in _entrances:
		if entrance.chapter == Progress.return_entrance:
			_player.global_position = entrance.exit_position()
	Progress.return_entrance = 0


func _on_entrance_entered(chapter: int) -> void:
	RunSettings.chapter = chapter
	get_tree().change_scene_to_file.call_deferred(Flow.CHAPTER_SCENE)


## A câmera segue o personagem com zona morta (CameraFollow), presa às bordas
## do mapa, com a barra do HUD descontada no alto. No primeiro quadro, parte
## centrada no personagem.
func _camera_target(pushed := false) -> Vector2:
	var tile := float(ChapterMap.TILE)
	var low := Vector2(HALF_SCREEN.x, HALF_SCREEN.y - HUD_HEIGHT)
	var high := Vector2(map.width, map.height) * tile - HALF_SCREEN
	var target := _player.global_position
	if pushed:
		return CameraFollow.pushed(_camera.position, target, low, high, HUD_HEIGHT, EDGE_TILES)
	return CameraFollow.centered(target, low, high)


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE
