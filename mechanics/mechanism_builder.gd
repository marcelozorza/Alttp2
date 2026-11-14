class_name MechanismBuilder
extends RefCounted
## Monta os objetos de mecanismo a partir dos caracteres do mapa
## (MapLegend.MECHANISMS) e liga cada um ao mecanismo da sala dele
## (mechanics/room_mechanisms.gd). A cena do capítulo chama add() para cada
## casa que ela mesma não conhece. O chão de gelo é um nó só por capítulo,
## criado na primeira casa de gelo.

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


func _init(chapter: Chapter, ground: Node2D, objects: Node2D) -> void:
	_chapter = chapter
	_ground = ground
	_objects = objects


## Cria o objeto de um caractere de mecanismo. Devolve se o caractere era de
## mecanismo.
func add(character: String, cell: Vector2i) -> bool:
	if not MapLegend.MECHANISMS.has(character):
		return false
	var entry: Array = MapLegend.MECHANISMS[character]
	var room := _chapter.rooms.of_cell(cell)
	var center := (Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE
	var mechanisms := _chapter.mechanisms
	match entry[0]:
		&"crystal":
			var crystal := Crystal.new()
			_stand(crystal, center)
			mechanisms.add_crystal(crystal, room)
		&"plate":
			var plate := TimedPlate.new()
			plate.position = center
			_ground.add_child(plate)
			mechanisms.add_plate(plate, room)
		&"torch":
			var torch := TimedTorch.new()
			_stand(torch, center)
			mechanisms.add_torch(torch, room)
		&"fan":
			var fan := Fan.new()
			fan.direction = DIRECTIONS[entry[1]]
			_stand(fan, center)
			_chapter.rooms.register(fan, cell)
		&"spawn":
			mechanisms.add_spawn_point(center + BASE_OFFSET, room)
		&"ice":
			if not _ice:
				_ice = IceField.new()
				_ground.add_child(_ice)
			_ice.cells[cell] = true
	return true


## Põe um objeto de pé na casa, com a origem na base.
func _stand(node: Node2D, center: Vector2) -> void:
	node.position = center + BASE_OFFSET
	_objects.add_child(node)
