class_name DoorArt
## Desenho compartilhado das portas e dos bloqueios: o tremor do golpe errado
## e a porta que afunda no chão casa por casa, usados pela porta trancada, pela
## grade e pelos bloqueios de parede.

## Ticks em que um bloqueio treme ao receber um golpe que não o afeta.
const SHAKE_TICKS := 8


## Deslocamento do tremor, contado do tick do golpe. Zero depois do tremor.
static func shake_offset(shake_tick: int) -> Vector2:
	var elapsed := Clock.tick - shake_tick
	if elapsed < 0 or elapsed >= SHAKE_TICKS:
		return Vector2.ZERO
	return Vector2(1.0 if posmod(elapsed, 4) < 2 else -1.0, 0.0)


## Desenha a textura de uma casa repetida por toda a área, mostrando só a
## fração de cima dada por height, de 0 a 1, como se o resto estivesse
## afundado no chão.
static func draw_sunk(
	canvas: CanvasItem, texture: Texture2D, size: Vector2, height: float, offset: Vector2
) -> void:
	if height <= 0.0:
		return
	var tile := float(ChapterMap.TILE)
	var visible_height := tile * minf(height, 1.0)
	var source := Rect2(0.0, 0.0, tile, visible_height)
	for y: int in int(size.y / tile):
		for x: int in int(size.x / tile):
			var cell := Vector2(x, y) * tile + offset
			var target := Rect2(cell + Vector2(0.0, tile - visible_height), source.size)
			canvas.draw_texture_rect_region(texture, target, source)
