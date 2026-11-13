class_name PowerField
extends Node2D
## Eletricidade do laboratório. A corrente sai de cada fonte e anda pelos
## fios do chão, de casa em casa. Onde o fio tem uma falha, um bloco de metal
## (o bloco solto condutor) empurrado para a casa fecha o circuito. Quando a
## corrente chega a um receptor, a porta elétrica da sala abre, e fecha de
## novo se o circuito for cortado. Arte provisória.
##
## Um só nó cuida de todos os fios do capítulo, na camada do chão. A corrente
## só é calculada na sala em que o personagem está.

const WIRE_COLOR := Color(0.35, 0.3, 0.2)
const LIVE_COLOR := Color(1.0, 0.9, 0.3)
const SOURCE_COLOR := Color(1.0, 0.75, 0.2)

## Casas de fio e de fonte, as chaves de dicionários de Vector2i.
var wires := {}
var sources := {}
## Receptor de cada casa.
var receptors := {}

## Casas com corrente agora.
var _live := {}


func _physics_process(_delta: float) -> void:
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	if not chapter:
		return
	var room := chapter.current_room()
	var metal := {}
	for block: FreeBlock in get_tree().get_nodes_in_group("metal_blocks"):
		if not block.is_tumbling():
			metal[block.cell()] = true
	var live := {}
	var frontier: Array[Vector2i] = []
	for cell: Vector2i in sources:
		if chapter.rooms.of_cell(cell) == room:
			live[cell] = true
			frontier.append(cell)
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step: Vector2i in ChapterMap.STEPS:
			var next := cell + step
			if live.has(next):
				continue
			if wires.has(next) or metal.has(next) or receptors.has(next):
				live[next] = true
				if not receptors.has(next):
					frontier.append(next)
	for cell: Vector2i in receptors:
		if chapter.rooms.of_cell(cell) == room:
			(receptors[cell] as BeamReceptor).set_lit(live.has(cell))
	if live.size() != _live.size() or Clock.tick % 10 == 0:
		queue_redraw()
	_live = live


func _draw() -> void:
	var tile := float(ChapterMap.TILE)
	var half := Vector2(tile, tile) / 2.0
	var known := wires.merged(sources).merged(receptors)
	for cell: Vector2i in wires:
		var center := Vector2(cell) * tile + half
		var color := WIRE_COLOR
		if _live.has(cell):
			color = LIVE_COLOR if Clock.tick % 20 < 10 else LIVE_COLOR.darkened(0.2)
		draw_circle(center, 3.0, color)
		for step: Vector2i in ChapterMap.STEPS:
			if known.has(cell + step):
				draw_line(center, center + Vector2(step) * tile / 2.0, color, 3.0)
	for cell: Vector2i in sources:
		var center := Vector2(cell) * tile + half
		draw_rect(Rect2(center - Vector2(10.0, 10.0), Vector2(20.0, 20.0)), DoorArt.OUTLINE_COLOR)
		draw_rect(Rect2(center - Vector2(8.0, 8.0), Vector2(16.0, 16.0)), SOURCE_COLOR)
		draw_line(
			center + Vector2(2.0, -6.0), center + Vector2(-3.0, 1.0), DoorArt.OUTLINE_COLOR, 2.0
		)
		draw_line(
			center + Vector2(-3.0, 1.0), center + Vector2(3.0, 0.0), DoorArt.OUTLINE_COLOR, 2.0
		)
		draw_line(
			center + Vector2(3.0, 0.0), center + Vector2(-2.0, 6.0), DoorArt.OUTLINE_COLOR, 2.0
		)
