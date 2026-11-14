class_name IceField
extends Node2D
## Chão de gelo: as casas "~" do mapa. Nele o personagem escorrega: demora
## a ganhar velocidade, demora a parar e faz curvas abertas, mas o jogador
## não perde o controle (player.gd, on_ice). No ar, o gelo não age. Arte
## provisória.
##
## Um só nó cuida de todas as casas de gelo do capítulo, na camada dos
## interruptores, acima do chão.

const ICE_COLOR := Color(0.72, 0.9, 1.0, 0.85)
const SHINE_COLOR := Color(1.0, 1.0, 1.0, 0.55)

## Casas de gelo, as chaves de um dicionário de Vector2i.
var cells := {}


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		var cell := ChapterMap.cell_of(player.global_position)
		player.on_ice = cells.has(cell) and not player.is_airborne()


func _draw() -> void:
	var tile := float(ChapterMap.TILE)
	for cell: Vector2i in cells:
		var corner := Vector2(cell) * tile
		draw_rect(Rect2(corner, Vector2(tile, tile)), ICE_COLOR)
		draw_line(corner + Vector2(6.0, 22.0), corner + Vector2(18.0, 8.0), SHINE_COLOR, 2.0)
		draw_line(corner + Vector2(16.0, 26.0), corner + Vector2(24.0, 16.0), SHINE_COLOR, 1.0)
