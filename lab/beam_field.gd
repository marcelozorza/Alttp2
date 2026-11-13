class_name BeamField
extends Node2D
## Feixes de luz do laboratório. Cada emissor solta um feixe reto, que anda
## de casa em casa até bater numa parede ou em algo sólido. Um espelho
## (lab/beam_mirror.gd) desvia o feixe em 90 graus, e um golpe de espada
## vira o espelho. Um bloco empurrado ou o próprio personagem cortam o
## feixe. Quando o feixe chega a um receptor (lab/beam_receptor.gd), as
## portas brancas da sala abrem de vez. Arte provisória.
##
## Um só nó cuida de todos os feixes do capítulo e os desenha por cima do
## chão. Os feixes só são calculados para a sala em que o personagem está.

const MAX_STEPS := 60
const BEAM_COLOR := Color(1.0, 1.0, 0.75, 0.85)
const GLOW_COLOR := Color(1.0, 0.95, 0.5, 0.3)
## Altura do feixe acima do chão, só no desenho.
const LIFT := Vector2(0.0, -12.0)

## Direção de cada emissor, pela casa: Vector2i para Vector2i.
var emitters := {}
## Espelho e receptor de cada casa.
var mirrors := {}
var receptors := {}
var map: ChapterMap

## Trechos do feixe a desenhar, em pares de pontos do mundo.
var _segments: Array[Vector2] = []
var _probe := RectangleShape2D.new()


func _ready() -> void:
	_probe.size = Vector2(12.0, 12.0)


func _physics_process(_delta: float) -> void:
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	if not chapter or emitters.is_empty():
		return
	_segments.clear()
	var reached := {}
	for cell: Vector2i in emitters:
		if chapter.rooms.of_cell(cell) == chapter.current_room():
			_trace(cell, emitters[cell], reached)
	for cell: Vector2i in receptors:
		var receptor: BeamReceptor = receptors[cell]
		receptor.set_lit(reached.has(cell))
	queue_redraw()


## Anda com o feixe a partir do emissor e anota os receptores atingidos.
func _trace(from: Vector2i, direction: Vector2i, reached: Dictionary) -> void:
	var cell := from
	var start := _center(cell)
	for step: int in MAX_STEPS:
		cell += direction
		var here := _center(cell)
		if receptors.has(cell):
			reached[cell] = true
			_add_segment(start, here)
			return
		if mirrors.has(cell):
			var mirror: BeamMirror = mirrors[cell]
			_add_segment(start, here)
			start = here
			direction = mirror.reflect(direction)
			continue
		if "# ".contains(map.tile(cell)) or _is_blocked(here):
			_add_segment(start, here - Vector2(direction) * 14.0)
			return
	_add_segment(start, _center(cell))


## Diz se há algo sólido no centro da casa: bloco, porta, baú ou personagem.
func _is_blocked(point: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _probe
	query.transform = Transform2D(0.0, point)
	query.collision_mask = Layers.SCENERY
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _add_segment(from: Vector2, to: Vector2) -> void:
	_segments.append(from)
	_segments.append(to)


static func _center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE


func _draw() -> void:
	for i: int in range(0, _segments.size(), 2):
		draw_line(_segments[i] + LIFT, _segments[i + 1] + LIFT, GLOW_COLOR, 8.0)
		draw_line(_segments[i] + LIFT, _segments[i + 1] + LIFT, BEAM_COLOR, 2.0)
