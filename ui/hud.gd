extends Control
## Mostra a vida do personagem no canto da tela, um quadrado por ponto de vida.

const PIP_SIZE := Vector2(6.0, 6.0)
const PIP_GAP := 2.0
const FULL_COLOR := Color(0.9, 0.2, 0.25, 1.0)
const EMPTY_COLOR := Color(0.25, 0.1, 0.12, 1.0)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	for i: int in player.max_health:
		var pip_position := Vector2(i * (PIP_SIZE.x + PIP_GAP), 0.0)
		draw_rect(Rect2(pip_position, PIP_SIZE), FULL_COLOR if i < player.health else EMPTY_COLOR)
