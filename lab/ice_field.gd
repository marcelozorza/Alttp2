class_name IceField
extends Node2D
## Chão de gelo liso do laboratório: as casas "~" do mapa. Nele o personagem
## não anda: escolhe uma das quatro direções e desliza reto até bater em
## algo ou sair do gelo. Parado numa batida, escolhe a direção seguinte. É o
## quebra-cabeça de deslizar até a saída. No ar, o gelo não age. Arte
## provisória.
##
## Um só nó cuida de todas as casas de gelo do capítulo, na camada dos
## interruptores, acima do chão.

const ICE_COLOR := Color(0.72, 0.9, 1.0, 0.85)
const SHINE_COLOR := Color(1.0, 1.0, 1.0, 0.55)
## Folga, em pixels, do teste de batida na direção da deslizada.
const PROBE := 2.0

## Casas de gelo, as chaves de um dicionário de Vector2i.
var cells := {}


func _ready() -> void:
	add_to_group("ice_field")


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	if not cells.has(Pit.cell_of(player.global_position)) or player.is_airborne():
		player.slide_direction = Vector2.ZERO
		return
	var sliding := player.slide_direction
	if sliding != Vector2.ZERO and not player.test_move(player.global_transform, sliding * PROBE):
		return
	# Entrando no gelo ou parado numa batida: a direção é a do movimento de
	# agora, ou a que o jogador aperta. Contra o que o parou, ele fica parado.
	var wanted := GameMath.snap_4(
		Input.get_vector("move_left", "move_right", "move_up", "move_down")
	)
	if sliding == Vector2.ZERO and player.velocity.length() > 10.0:
		wanted = GameMath.snap_4(player.velocity)
	if wanted != Vector2.ZERO and player.test_move(player.global_transform, wanted * PROBE):
		wanted = Vector2.ZERO
	if wanted == Vector2.ZERO:
		player.velocity = Vector2.ZERO
	player.slide_direction = wanted


func _draw() -> void:
	var tile := float(ChapterMap.TILE)
	for cell: Vector2i in cells:
		var corner := Vector2(cell) * tile
		draw_rect(Rect2(corner, Vector2(tile, tile)), ICE_COLOR)
		draw_line(corner + Vector2(6.0, 22.0), corner + Vector2(18.0, 8.0), SHINE_COLOR, 2.0)
		draw_line(corner + Vector2(16.0, 26.0), corner + Vector2(24.0, 16.0), SHINE_COLOR, 1.0)
