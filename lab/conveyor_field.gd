class_name ConveyorField
extends Node2D
## Esteiras do laboratório: casas que carregam o personagem numa direção
## enquanto ele está no chão. A esteira é mais lenta que o andar, então dá
## para ir contra ela devagar, e pular passa por cima. Arte provisória.
##
## Um só nó cuida de todas as esteiras do capítulo, na camada dos
## interruptores, acima do chão.

## Velocidade da esteira, em pixels por segundo.
const SPEED := 120.0
const BELT_COLOR := Color(0.25, 0.25, 0.3, 0.9)
const ARROW_COLOR := Color(0.95, 0.85, 0.4)

## Direção de cada casa de esteira: Vector2i para Vector2.
var cells := {}


func _physics_process(delta: float) -> void:
	queue_redraw()
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player or player.is_airborne():
		return
	var direction: Vector2 = cells.get(Pit.cell_of(player.global_position), Vector2.ZERO)
	if direction != Vector2.ZERO:
		player.shove(direction * SPEED * delta)


func _draw() -> void:
	var tile := float(ChapterMap.TILE)
	var slide := float(posmod(Clock.tick, 32)) / 32.0 * tile
	for cell: Vector2i in cells:
		var direction: Vector2 = cells[cell]
		var corner := Vector2(cell) * tile
		draw_rect(Rect2(corner + Vector2.ONE, Vector2(tile - 2.0, tile - 2.0)), BELT_COLOR)
		var center := corner + Vector2(tile, tile) / 2.0
		# A seta corre pela casa no sentido da esteira.
		var tip := center + direction * (fposmod(slide + 16.0, tile) - 16.0) * 0.6
		var side := direction.orthogonal() * 7.0
		draw_line(tip - direction * 7.0 + side, tip, ARROW_COLOR, 2.0)
		draw_line(tip - direction * 7.0 - side, tip, ARROW_COLOR, 2.0)
