class_name HudLayout
## Onde cada peça do HUD e dos controles de toque fica, nas faixas dos lados
## do quadro de jogo (GameView), pela largura da tela. Num celular deitado de
## 1080 linhas a tela tem 800x360 e cada faixa tem 160 pixels. No computador,
## em 16:9, 640x360 e faixas de 80. Abaixo de MIN_SIDE (tablet 4:3), a faixa
## fica com MIN_SIDE e cobre a borda do jogo, meio transparente.
##
## Faixa esquerda: corações, chaves e minimapa no alto, direcional embaixo.
## Faixa direita: mapa e pausa no alto, o tempo, e os quatro botões embaixo.

const MIN_SIDE := 80.0
## Raio dos botões de face: o dobro do antigo (16) quando a faixa permite
## (pedido de Marcelo em 2026-11-14), e nunca menos que o antigo.
const BUTTON_RADIUS_MIN := 16.0
const BUTTON_RADIUS_MAX := 32.0
## Distância do centro de cada botão ao centro do losango, em raios.
const BUTTON_SPREAD := 1.45
## Posição de cada botão no losango, pelo índice do Godot, que segue a posição
## física do botão: 0 embaixo, 1 à direita, 2 à esquerda e 3 em cima.
const FACE_DIRECTIONS: Array[Vector2] = [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP]
## Cores dos botões do Super Famicom, na mesma posição física: B amarelo
## embaixo, A vermelho à direita, Y verde à esquerda e X azul em cima.
const FACE_COLORS: Array[Color] = [
	Color("e8b730"), Color("d23c3c"), Color("3f9e4d"), Color("3a5fc8")
]
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


static func button_radius(screen: Vector2) -> float:
	var fit := (side_width(screen) - 2.0 * MARGIN) / (2.0 * BUTTON_SPREAD + 2.0)
	return clampf(floorf(fit), BUTTON_RADIUS_MIN, BUTTON_RADIUS_MAX)


## Centro do losango dos botões, embaixo na faixa direita.
static func buttons_center(screen: Vector2) -> Vector2:
	var side := right_side(screen)
	var reach := button_radius(screen) * (BUTTON_SPREAD + 1.0)
	return Vector2(side.get_center().x, screen.y - MARGIN - reach)


static func button_center(screen: Vector2, index: int) -> Vector2:
	var offset := FACE_DIRECTIONS[index] * button_radius(screen) * BUTTON_SPREAD
	return buttons_center(screen) + offset.round()


## Raio do direcional fixo: do mesmo alcance do losango dos botões.
static func dpad_radius(screen: Vector2) -> float:
	return button_radius(screen) * (BUTTON_SPREAD + 1.0)


## Centro do direcional, embaixo na faixa esquerda, na altura dos botões.
static func dpad_center(screen: Vector2) -> Vector2:
	return Vector2(left_side(screen).get_center().x, buttons_center(screen).y)


static func map_rect(screen: Vector2) -> Rect2:
	var side := right_side(screen)
	return Rect2(Vector2(side.position.x + MARGIN, MARGIN), SMALL_BUTTON)


static func pause_rect(screen: Vector2) -> Rect2:
	var side := right_side(screen)
	return Rect2(Vector2(side.end.x - MARGIN - SMALL_BUTTON.x, MARGIN), SMALL_BUTTON)
