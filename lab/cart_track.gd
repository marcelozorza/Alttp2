class_name CartTrack
extends Node2D
## Trilhos do carrinho do laboratório (lab/cart.gd). Há dois tipos de casa:
## o trilho no chão, em que se anda normalmente, e o trilho sobre o vazio,
## uma ponte só de trilhos. A pé, o trilho sobre o vazio não segura: quem
## pisa nele cai, perde vida e volta à entrada da sala. Só o carrinho
## atravessa. Arte provisória.
##
## Um só nó cuida de todos os trilhos do capítulo, na camada dos
## interruptores, acima do chão.

const DAMAGE := 1
const VOID_COLOR := Color(0.05, 0.04, 0.08)
const RAIL_COLOR := Color(0.72, 0.72, 0.78)
const TIE_COLOR := Color(0.45, 0.32, 0.2)
## Grupo em que o personagem fica enquanto anda de carrinho.
const RIDERS := &"cart_riders"

## Casas de trilho no chão e sobre o vazio, as chaves de dicionários de
## Vector2i.
var rails := {}
var trestles := {}


func has(cell: Vector2i) -> bool:
	return rails.has(cell) or trestles.has(cell)


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	if not player or not chapter or player.is_dead():
		return
	if player.is_airborne() or player.is_in_group(RIDERS):
		return
	if trestles.has(Pit.cell_of(player.global_position)):
		player.fall_into_pit(chapter.room_entry_point, DAMAGE)


func _draw() -> void:
	var tile := float(ChapterMap.TILE)
	for cell: Vector2i in trestles:
		draw_rect(Rect2(Vector2(cell) * tile, Vector2(tile, tile)), VOID_COLOR)
	for cell: Vector2i in rails.keys() + trestles.keys():
		var center := (Vector2(cell) + Vector2(0.5, 0.5)) * tile
		for step: Vector2i in ChapterMap.STEPS:
			if not has(cell + step):
				continue
			var along := Vector2(step) * tile / 2.0
			var across := Vector2(step.y, step.x) * 7.0
			draw_line(
				center + along / 2.0 - across * 1.4,
				center + along / 2.0 + across * 1.4,
				TIE_COLOR,
				4.0
			)
			draw_line(center - across, center + along - across, RAIL_COLOR, 2.0)
			draw_line(center + across, center + along + across, RAIL_COLOR, 2.0)
