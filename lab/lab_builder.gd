class_name LabBuilder
extends RefCounted
## Monta os objetos do laboratório a partir dos caracteres do mapa
## (MapLegend.LAB) e liga cada um ao mecanismo da sala dele
## (lab/room_mechanisms.gd). A cena do capítulo chama add() para cada casa
## que ela mesma não conhece. Os campos de chão (gelo, esteira, piso
## quebradiço e feixes de luz) são um nó só por capítulo, criado na primeira
## casa que precisa dele.

const FREE_BLOCK_SCENE := preload("res://lab/free_block.tscn")
## Segundos que a tocha com tempo fica acesa.
const TORCH_BURN_TIME := 7.0
## Deslocamento do centro da casa até a base de um objeto de pé.
const BASE_OFFSET := Vector2(0.0, 8.0)
const DIRECTIONS := {
	"right": Vector2.RIGHT,
	"left": Vector2.LEFT,
	"up": Vector2.UP,
	"down": Vector2.DOWN,
}

var _chapter: Chapter
## Camada do chão (interruptores) e camada dos objetos de pé.
var _ground: Node2D
var _objects: Node2D
var _ice: IceField
var _conveyors: ConveyorField
var _crumble: CrumbleField
var _beams: BeamField


func _init(chapter: Chapter, ground: Node2D, objects: Node2D) -> void:
	_chapter = chapter
	_ground = ground
	_objects = objects


## Cria o objeto de um caractere do laboratório. Devolve se o caractere era
## do laboratório.
func add(character: String, cell: Vector2i) -> bool:
	if not MapLegend.LAB.has(character):
		return false
	var entry: Array = MapLegend.LAB[character]
	var kind: StringName = entry[0]
	var room := _chapter.rooms.of_cell(cell)
	var center := (Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE
	var mechanisms := _chapter.mechanisms
	match kind:
		&"crystal":
			var crystal := Crystal.new()
			_stand(crystal, center)
			mechanisms.add_crystal(crystal, room)
		&"target":
			var target := Crystal.new()
			target.blast_only = true
			_stand(target, center)
			mechanisms.add_target(target, room)
		&"plate":
			var plate := TimedPlate.new()
			plate.hold_time = entry[1]
			plate.position = center
			_ground.add_child(plate)
			mechanisms.add_plate(plate, room)
		&"torch":
			var torch := LabTorch.new()
			torch.burn_time = TORCH_BURN_TIME if entry[1] < 0 else 0.0
			torch.order = maxi(entry[1], 0)
			_stand(torch, center)
			mechanisms.add_torch(torch, room)
		&"free_block":
			var block := FREE_BLOCK_SCENE.instantiate() as FreeBlock
			block.position = center + FloorSwitch.BLOCK_OFFSET
			_objects.add_child(block)
			_chapter.rooms.register(block, cell)
		&"turret":
			var turret := Turret.new()
			_stand(turret, center)
			_chapter.rooms.register(turret, cell)
		&"fan":
			var fan := Fan.new()
			fan.direction = DIRECTIONS[entry[1]]
			_stand(fan, center)
			_chapter.rooms.register(fan, cell)
		&"statue":
			var statue := MirrorStatue.new()
			_stand(statue, center)
			_chapter.rooms.register(statue, cell)
		&"chaser":
			var chaser := Chaser.new()
			chaser.arena = _chapter.rooms.interior(room)
			chaser.position = center
			_ground.add_child(chaser)
			_chapter.rooms.register(chaser, cell)
		&"spawn":
			mechanisms.add_spawn_point(center + BASE_OFFSET, room)
		&"teleporter", &"teleporter_exit":
			var portal := Teleporter.new()
			portal.pair = entry[1]
			portal.exit_only = kind == &"teleporter_exit"
			portal.position = center
			_ground.add_child(portal)
		&"ice":
			if not _ice:
				_ice = IceField.new()
				_ground.add_child(_ice)
			_ice.cells[cell] = true
		&"conveyor":
			if not _conveyors:
				_conveyors = ConveyorField.new()
				_ground.add_child(_conveyors)
			_conveyors.cells[cell] = DIRECTIONS[entry[1]]
		&"crumble":
			if not _crumble:
				_crumble = CrumbleField.new()
				_ground.add_child(_crumble)
			_crumble.cells[cell] = CrumbleField.State.WHOLE
		&"emitter":
			var emitter := BeamReceptor.new()
			emitter.emitter = true
			emitter.position = center
			_objects.add_child(emitter)
			_beam_field().emitters[cell] = Vector2i(DIRECTIONS[entry[1]])
		&"mirror":
			var mirror := BeamMirror.new()
			mirror.rising = entry[1]
			mirror.position = center
			_objects.add_child(mirror)
			_beam_field().mirrors[cell] = mirror
		&"receptor":
			var receptor := BeamReceptor.new()
			receptor.position = center
			_objects.add_child(receptor)
			_beam_field().receptors[cell] = receptor
			mechanisms.add_receptor(receptor, room)
	return true


## Põe um objeto de pé na casa, com a origem na base.
func _stand(node: Node2D, center: Vector2) -> void:
	node.position = center + BASE_OFFSET
	_objects.add_child(node)


## Os feixes ficam por cima dos objetos, para o feixe aparecer inteiro.
func _beam_field() -> BeamField:
	if not _beams:
		_beams = BeamField.new()
		_beams.map = _chapter.map
		_beams.z_index = 1
		_chapter.add_child(_beams)
	return _beams
