class_name RailView
extends Node2D
## Trilho do bloco pesado: uma faixa de chão rebaixada e mais escura, com a
## borda de cima em sombra para dar a profundidade e o traço grosso em volta.
## O bloco só tomba dentro dela (objects/heavy_block.gd). É desenhada por cima
## do chão de qualquer tema, escurecendo o que está embaixo, e por baixo dos
## interruptores e dos objetos. Aprovado por Marcelo numa prévia em
## 2026-11-12.

const INK := Color("1e181e")
const OUTLINE := 2.0
## Escurecimento do fundo do trilho e da face de cima, que fica na sombra.
const FLOOR_SHADE := Color(0.06, 0.05, 0.1, 0.42)
const FACE_SHADE := Color(0.04, 0.03, 0.07, 0.5)
const FACE_DEPTH := 8.0
const SIDE_DEPTH := 5.0
## Filete claro na borda de baixo, onde a luz pega o canto.
const LIP := Color(1.0, 1.0, 1.0, 0.16)

## Casas do trilho, as chaves de um dicionário de Vector2i.
var cells := {}
var tile := 32.0


func _draw() -> void:
	for cell: Vector2i in cells:
		draw_rect(Rect2(Vector2(cell) * tile, Vector2(tile, tile)), FLOOR_SHADE)
	for cell: Vector2i in cells:
		var origin := Vector2(cell) * tile
		if not cells.has(cell + Vector2i.UP):
			draw_rect(Rect2(origin, Vector2(tile, FACE_DEPTH)), FACE_SHADE)
			draw_rect(Rect2(origin, Vector2(tile, OUTLINE)), INK)
		if not cells.has(cell + Vector2i.LEFT):
			draw_rect(Rect2(origin, Vector2(SIDE_DEPTH, tile)), FACE_SHADE)
			draw_rect(Rect2(origin, Vector2(OUTLINE, tile)), INK)
		if not cells.has(cell + Vector2i.RIGHT):
			draw_rect(Rect2(origin + Vector2(tile - OUTLINE, 0.0), Vector2(OUTLINE, tile)), INK)
		if not cells.has(cell + Vector2i.DOWN):
			draw_rect(Rect2(origin + Vector2(0.0, tile - OUTLINE), Vector2(tile, OUTLINE)), INK)
			draw_rect(
				Rect2(origin + Vector2(OUTLINE, tile - OUTLINE - 1.0), Vector2(tile - 4.0, 1.0)),
				LIP
			)
