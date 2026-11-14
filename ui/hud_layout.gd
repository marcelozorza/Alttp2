class_name HudLayout
## Onde cada peça do HUD e dos controles de toque fica, nas faixas dos lados
## do quadro de jogo (GameView), pela largura da tela. Num celular deitado de
## 1080 linhas a tela tem 800x360 e cada faixa tem 160 pixels. No computador,
## em 16:9, 640x360 e faixas de 80. Abaixo de MIN_SIDE (tablet 4:3), a faixa
## fica com MIN_SIDE e cobre a borda do jogo, meio transparente.
##
## Faixa esquerda: corações, chaves e minimapa no alto, direcional embaixo.
## Faixa direita: mapa e pausa no alto, o tempo, e a coluna dos quatro botões.

const MIN_SIDE := 80.0
## Botões de ação numa coluna na faixa direita (pedido de Marcelo em
## 2026-11-14, depois de jogar o losango: área de toque maior, só o ícone,
## sem as cores do Super Famicom). Cada botão é uma fileira inteira da coluna,
## e a área de toque vai da borda da tela até um pouco dentro do jogo.
## Ordem de cima para baixo, pelo índice do Godot do botão: bomba (3), chama
## (2), pulo (1) e espada (0), embaixo, onde o polegar descansa.
const COLUMN_ORDER: Array[int] = [3, 2, 1, 0]
## Onde a coluna começa, abaixo de mapa, pausa e tempo.
const COLUMN_TOP := 84.0
## Quanto a área de toque de cada fileira entra no quadro de jogo.
const TOUCH_INTO_GAME := 24.0
const BUTTON_RADIUS_MAX := 30.0
## Raio do direcional que nasce onde o dedo encosta.
const STICK_RADIUS := 30.0
## Folga entre a borda da tela e as peças.
const MARGIN := 6.0
## Botões pequenos de mapa e pausa, no alto da faixa direita.
const SMALL_BUTTON := Vector2(34.0, 26.0)


## Largura de cada faixa lateral.
static func side_width(screen: Vector2) -> float:
	return maxf(MIN_SIDE, floorf((screen.x - GameView.SIZE.x) / 2.0))


## A faixa cobre parte do quadro de jogo (tela estreita).
static func overlaps(screen: Vector2) -> bool:
	return (screen.x - GameView.SIZE.x) / 2.0 < MIN_SIDE


static func left_side(screen: Vector2) -> Rect2:
	return Rect2(0.0, 0.0, side_width(screen), screen.y)


static func right_side(screen: Vector2) -> Rect2:
	var width := side_width(screen)
	return Rect2(screen.x - width, 0.0, width, screen.y)


## Altura de cada fileira da coluna de botões.
static func row_height(screen: Vector2) -> float:
	return floorf((screen.y - COLUMN_TOP - MARGIN) / COLUMN_ORDER.size())


static func button_radius(screen: Vector2) -> float:
	var fit := minf(side_width(screen) / 2.0, row_height(screen) / 2.0) - 4.0
	return minf(BUTTON_RADIUS_MAX, floorf(fit))


## Centro do botão de índice index (0 embaixo no controle, a espada).
static func button_center(screen: Vector2, index: int) -> Vector2:
	var row := COLUMN_ORDER.find(index)
	var side := right_side(screen)
	var height := row_height(screen)
	return Vector2(side.get_center().x, COLUMN_TOP + (row + 0.5) * height).floor()


## Botão sob o ponto, pela fileira, ou -1 fora da coluna.
static func button_at(screen: Vector2, point: Vector2) -> int:
	var side := right_side(screen)
	if point.x < side.position.x - TOUCH_INTO_GAME or point.y < COLUMN_TOP - MARGIN:
		return -1
	var row := clampi(floori((point.y - COLUMN_TOP) / row_height(screen)), 0, 3)
	return COLUMN_ORDER[row]


## Área em que um dedo faz nascer o direcional: a metade esquerda da tela.
static func stick_area(screen: Vector2) -> Rect2:
	return Rect2(0.0, 0.0, floorf(screen.x / 2.0), screen.y)


## Onde o direcional aparece, apagado, enquanto ninguém toca: embaixo, no meio
## da faixa esquerda.
static func stick_home(screen: Vector2) -> Vector2:
	var side := left_side(screen)
	return Vector2(side.get_center().x, screen.y - MARGIN - 2.0 * STICK_RADIUS).floor()


static func map_rect(screen: Vector2) -> Rect2:
	var side := right_side(screen)
	return Rect2(Vector2(side.position.x + MARGIN, MARGIN), SMALL_BUTTON)


static func pause_rect(screen: Vector2) -> Rect2:
	var side := right_side(screen)
	return Rect2(Vector2(side.end.x - MARGIN - SMALL_BUTTON.x, MARGIN), SMALL_BUTTON)
