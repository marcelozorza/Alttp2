class_name CrackedWall
extends Obstacle
## Parede rachada. Só a explosão da bomba abre a passagem. As rachaduras claras
## são a marca que o jogador aprende a procurar.

## Uma textura por tema de dungeon, com o tijolo da parede dele.
const TEXTURES := {
	"stone": preload("res://art/cracked_wall.svg"),
	"castle": preload("res://art/cracked_wall_castle.svg"),
	"ice": preload("res://art/cracked_wall_ice.svg"),
	"moss": preload("res://art/cracked_wall_moss.svg"),
}
const DEBRIS_COLOR := Color(0.5, 0.47, 0.42, 1.0)
## Ticks em que os destroços aparecem depois da explosão.
const DEBRIS_TICKS := 20

## Nome do tema da sala, dado pelo capítulo ao criar a parede.
var theme_name := "stone"


func _draw() -> void:
	if cleared:
		_draw_debris()
		return
	_draw_shadow()
	var offset := _shake_offset()
	for y: int in int(size.y / 32.0):
		for x: int in int(size.x / 32.0):
			draw_texture(TEXTURES.get(theme_name, TEXTURES["stone"]), offset + Vector2(x, y) * 32.0)


func _draw_debris() -> void:
	var elapsed := _ticks_since_clear()
	if elapsed >= DEBRIS_TICKS:
		return
	var color := Color(DEBRIS_COLOR, 1.0 - float(elapsed) / DEBRIS_TICKS)
	for i: int in 8:
		var angle := TAU * i / 8.0
		var center := size / 2.0 + Vector2(cos(angle), sin(angle)) * (8.0 + elapsed * 1.2)
		draw_rect(Rect2(center - Vector2(3.0, 3.0), Vector2(6.0, 6.0)), color)
