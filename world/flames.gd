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

## Fase desenhada por último. As chamas só são redesenhadas quando ela muda,
## e não a cada quadro (lag no PC, 2026-11-20).
var _step := -1


func _process(_delta: float) -> void:
	if positions.is_empty():
		return
	var step := _current_step()
	if step != _step:
		_step = step
		queue_redraw()


func _current_step() -> int:
	return floori(Engine.get_process_frames() / float(FLICKER_FRAMES))


func _draw() -> void:
	if frames.is_empty():
		return
	var step := _current_step()
	for i: int in positions.size():
		draw_texture(frames[(step + i) % frames.size()], positions[i])
