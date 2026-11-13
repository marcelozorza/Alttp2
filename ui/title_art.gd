class_name TitleArt
extends Control
## Arte da tela de título: o logotipo no alto e, embaixo, uma faixa do mundo
## de chegada com o Giorgino entre as árvores, tudo com os desenhos do jogo.

const SKY := Color("1b1926")
const LOGO := preload("res://art/logo.svg")
const PAW := preload("res://art/title_paw.svg")
## Retrato do Jorginho, à direita do menu (pedido de Marcelo em 2026-11-13).
const PORTRAIT := preload("res://art/title_portrait.svg")
const PORTRAIT_CORNER := Vector2(486.0, 92.0)
## Espaço entre o logotipo e a patinha à direita dele.
const PAW_GAP := 10.0
const GRASS: Array[Texture2D] = [
	preload("res://art/grass_1.svg"),
	preload("res://art/grass_2.svg"),
	preload("res://art/grass_3.svg"),
	preload("res://art/grass_4.svg"),
]
const TREES: Array[Texture2D] = [preload("res://art/tree_1.svg"), preload("res://art/tree_2.svg")]
const HERO := preload("res://art/giorgino_stand_down.svg")
const FRINGE := preload("res://art/grass_fringe.svg")
const TILE := 32.0
const SCREEN := Vector2(640.0, 360.0)
## Casas da faixa de grama que ficam sem árvore, de cada lado do meio.
const CLEARING := [2, 3, 4, 15, 16, 17]
const STARS := [
	Vector2(40.0, 30.0),
	Vector2(118.0, 70.0),
	Vector2(200.0, 22.0),
	Vector2(86.0, 150.0),
	Vector2(470.0, 26.0),
	Vector2(560.0, 84.0),
	Vector2(610.0, 30.0),
	Vector2(520.0, 160.0),
	Vector2(30.0, 220.0),
	Vector2(600.0, 230.0),
	Vector2(150.0, 250.0),
	Vector2(480.0, 262.0),
]  # gdlint: ignore=max-line-length


func _draw() -> void:
	for i: int in STARS.size():
		var color := Color("a9aac2") if i % 3 else Color("f7c53a")
		draw_rect(Rect2(STARS[i], Vector2(2.0, 2.0) if i % 4 == 0 else Vector2.ONE), color)
	var logo_size := LOGO.get_size()
	var left := floorf((SCREEN.x - logo_size.x - PAW_GAP - PAW.get_width()) / 2.0)
	draw_texture(LOGO, Vector2(left, 22.0))
	var paw_top := 22.0 + floorf((logo_size.y - PAW.get_height()) / 2.0)
	draw_texture(PAW, Vector2(left + logo_size.x + PAW_GAP, paw_top))
	var top := SCREEN.y - TILE * 2.0
	for column: int in 20:
		for row: int in 2:
			var origin := Vector2(column * TILE, top + row * TILE)
			draw_texture(GRASS[(column * 7 + row * 3) % GRASS.size()], origin)
		# A beira de cima da grama, serrilhada contra o céu.
		draw_set_transform(Vector2(column * TILE, top) + Vector2(TILE, 0.0), PI)
		draw_texture(FRINGE, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
		if not column in CLEARING:
			continue
		draw_texture(TREES[column % 2], Vector2(column * TILE, top - 6.0))
		draw_texture(TREES[(column + 1) % 2], Vector2(column * TILE, top + TILE - 2.0))
	draw_texture(HERO, Vector2(194.0, SCREEN.y - 58.0))
	draw_texture(PORTRAIT, PORTRAIT_CORNER)
