class_name FloorText
extends Node2D
## Textos gravados em lajes de pedra no chão, lidos enquanto o personagem
## anda por cima, sem parar o jogo (pedido de Marcelo em 2026-11-10, "como
## Dark Souls"). Cada entrada é o centro da laje, em casas, e o texto.

const FONT := preload("res://ui/font/giorgino.fnt")
const FONT_SIZE := 12
const SLAB := Color("7c7b99")
const SLAB_LIGHT := Color("a9aac2")
const SLAB_DARK := Color("55526f")
const INK := Color("1e181e")
const CARVED := Color("262335")
## Folga da laje em volta do texto, em pixels.
const PADDING := Vector2(7.0, 4.0)
const TEXT_HEIGHT := 9.0

var entries: Array = []


func _draw() -> void:
	for entry: Array in entries:
		var center: Vector2 = (entry[0] as Vector2) * ChapterMap.TILE
		var text: String = entry[1]
		var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var size := Vector2(width, TEXT_HEIGHT) + PADDING * 2.0
		var corner := (center - size / 2.0).round()
		_draw_slab(Rect2(corner, size))
		# A linha de base fica 9 pixels abaixo do alto das maiúsculas.
		var baseline := corner + PADDING + Vector2(0.0, TEXT_HEIGHT - 2.0)
		draw_string(FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, CARVED)


## Laje com contorno, luz em cima e à esquerda e sombra embaixo e à direita.
func _draw_slab(rect: Rect2) -> void:
	draw_rect(rect.grow(1.0), INK)
	draw_rect(rect, SLAB)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1.0)), SLAB_LIGHT)
	draw_rect(Rect2(rect.position, Vector2(1.0, rect.size.y)), SLAB_LIGHT)
	draw_rect(
		Rect2(rect.position + Vector2(0.0, rect.size.y - 1.0), Vector2(rect.size.x, 1.0)), SLAB_DARK
	)
	draw_rect(
		Rect2(rect.position + Vector2(rect.size.x - 1.0, 0.0), Vector2(1.0, rect.size.y)), SLAB_DARK
	)
