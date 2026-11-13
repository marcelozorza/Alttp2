class_name Pit
extends Node2D
## Buraco no chão do laboratório. Arte provisória.
##
## Pisar nele derruba o personagem: ele perde vida e volta ao ponto em que
## entrou na sala. No ar, ele passa por cima, então a mola pula o buraco
## (PIT, de até 2 casas) e a mola forte com corrida pula o largo (WIDE_PIT,
## de 5 casas). O buraco de ponte (GAP) se cruza empurrando um bloco solto
## para dentro dele: o bloco afunda e a casa vira chão.
##
## A origem fica no canto superior esquerdo, e o construtor do mapa define o
## tamanho, como nos outros bloqueios. Os inimigos ainda passam por cima.

## Quanto os pés podem entrar na borda sem cair, em pixels.
const EDGE_MARGIN := 6.0
const DAMAGE := 1
const DEPTH_COLOR := Color(0.05, 0.04, 0.08)
const RIM_COLOR := Color(0.16, 0.13, 0.2)
const FILL_COLOR := Color(0.5, 0.5, 0.56)

@export var size := Vector2(32.0, 32.0)

## Tipo do bloqueio, um ChapterMap.Block.
var kind := ChapterMap.Block.PIT
## Casas já tampadas por um bloco, as chaves de um dicionário de Vector2i.
var filled := {}


func _ready() -> void:
	add_to_group("pits")


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player or player.is_dead() or player.is_airborne():
		return
	var point := player.global_position
	if not Rect2(global_position, size).grow(-EDGE_MARGIN).has_point(point):
		return
	if filled.has(cell_of(point)):
		return
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	var back := chapter.room_entry_point if chapter else point
	player.fall_into_pit(back, DAMAGE)


## Casa do mapa de um ponto do mundo.
static func cell_of(point: Vector2) -> Vector2i:
	return Vector2i((point / float(ChapterMap.TILE)).floor())


## Diz se a casa é deste buraco e ainda está aberta.
func is_open_at(cell: Vector2i) -> bool:
	var center := (Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE
	return Rect2(global_position, size).has_point(center) and not filled.has(cell)


## Tampa uma casa do buraco: ali o chão volta.
func fill(cell: Vector2i) -> void:
	filled[cell] = true
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), RIM_COLOR)
	draw_rect(Rect2(Vector2(3.0, 6.0), size - Vector2(6.0, 9.0)), DEPTH_COLOR)
	var tile := float(ChapterMap.TILE)
	for cell: Vector2i in filled:
		var corner := Vector2(cell) * tile - global_position
		draw_rect(Rect2(corner, Vector2(tile, tile)), DoorArt.OUTLINE_COLOR)
		draw_rect(Rect2(corner + Vector2(2.0, 2.0), Vector2(tile - 4.0, tile - 4.0)), FILL_COLOR)
