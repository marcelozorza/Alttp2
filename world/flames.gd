class_name Flames
extends Node2D
## Chamas das tochas de uma dungeon, piscando. O MapView desenha o mapa uma
## vez só, então as chamas, que mudam a cada instante, ficam neste nó à parte,
## por cima dele. Cada chama alterna entre dois quadros, e as vizinhas ficam
## fora de fase, para não piscarem juntas.

## Quadros de tela que cada quadro da chama dura.
const FLICKER_FRAMES := 7

var frames: Array[Texture2D] = []
var positions: Array[Vector2] = []


func _process(_delta: float) -> void:
	if not positions.is_empty():
		queue_redraw()


func _draw() -> void:
	if frames.is_empty():
		return
	var step := floori(Engine.get_process_frames() / float(FLICKER_FRAMES))
	for i: int in positions.size():
		draw_texture(frames[(step + i) % frames.size()], positions[i])
