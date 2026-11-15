class_name TitleArt
extends Control
## Arte da tela de título: o logotipo no alto e, embaixo, uma faixa do mundo
## de chegada com o Giorgino entre as árvores, tudo com os desenhos do jogo.

const SKY := Color("1b1926")
const LOGO := preload("res://art/logo.svg")
const PAW := preload("res://art/title_paw.svg")
## Retrato do Jorginho, grande, no meio do céu, saindo de trás da grama
## (montagem que Marcelo mandou em 2026-11-13). A grama cobre a base dele.
const PORTRAIT := preload("res://art/title_portrait.svg")
const PORTRAIT_SINK := 8.0
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


## Desvio que centraliza a arte, feita para 640 de largura, numa tela mais
## larga (celular deitado). A grama vai de uma borda à outra.
static func shift(screen_width: float) -> float:
	return maxf(0.0, floorf((screen_width - SCREEN.x) / 2.0))


func _draw() -> void:
	var dx := shift(size.x)
	draw_set_transform(Vector2(dx, 0.0))
	for i: int in STARS.size():
		var color := Color("a9aac2") if i % 3 else Color("f7c53a")
		draw_rect(Rect2(STARS[i], Vector2(2.0, 2.0) if i % 4 == 0 else Vector2.ONE), color)
	var logo_size := LOGO.get_size()
	var left := floorf((SCREEN.x - logo_size.x - PAW_GAP - PAW.get_width()) / 2.0)
	draw_texture(LOGO, Vector2(left, 22.0))
	var paw_top := 22.0 + floorf((logo_size.y - PAW.get_height()) / 2.0)
	draw_texture(PAW, Vector2(left + logo_size.x + PAW_GAP, paw_top))
	var top := SCREEN.y - TILE * 2.0
	var portrait_size := PORTRAIT.get_size()
	var portrait_left := floorf((SCREEN.x - portrait_size.x) / 2.0)
	draw_texture(PORTRAIT, Vector2(portrait_left, top + PORTRAIT_SINK - portrait_size.y))
	var first := -ceili(dx / TILE)
	for column: int in range(first, 20 - first):
		for row: int in 2:
			var origin := Vector2(column * TILE, top + row * TILE)
			draw_texture(GRASS[posmod(column * 7 + row * 3, GRASS.size())], origin)
		# A beira de cima da grama, serrilhada contra o céu.
		draw_set_transform(Vector2(dx + column * TILE, top) + Vector2(TILE, 0.0), PI)
		draw_texture(FRINGE, Vector2.ZERO)
		draw_set_transform(Vector2(dx, 0.0))
		if not column in CLEARING:
			continue
		draw_texture(TREES[column % 2], Vector2(column * TILE, top - 6.0))
		draw_texture(TREES[(column + 1) % 2], Vector2(column * TILE, top + TILE - 2.0))
	draw_texture(HERO, Vector2(194.0, SCREEN.y - 58.0))
	draw_set_transform(Vector2.ZERO)
