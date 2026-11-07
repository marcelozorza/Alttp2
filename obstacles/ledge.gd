class_name Ledge
extends StaticBody2D
## Face de um degrau alto, vista de frente. O chão de cima fica ao norte.
##
## Andando, ninguém atravessa a face. O personagem sobe com o pulo da mola, se
## estiver alto o bastante ao encostar nela vindo do sul, e desce num salto ao
## andar contra ela vindo do norte. A travessia fica a cargo do personagem
## (ver player.gd). A face só informa onde ficam as bordas e a altura.
##
## O degrau comum tem 16 pixels. O degrau duplo tem 32, duas casas de face, e
## só o pulo da mola forte chega lá: o pulo comum bate na face e volta. A face
## dupla tem a própria pedra, mais escura, para o jogador ver de longe que o
## degrau é outro.
##
## A origem fica no canto superior esquerdo. O construtor do mapa define o
## tamanho antes de adicionar a face à cena, e a altura dela é a altura do
## degrau.

const TEXTURE := preload("res://art/ledge.svg")
const TALL_TEXTURE := preload("res://art/tall_ledge.svg")
## Sombra que a face projeta no chão de baixo. É o que faz o desnível ser lido
## como altura, e não como outra cor de chão.
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const SHADOW_HEIGHT := 8.0

## Tamanho em pixels. A altura da face é também a altura do degrau.
@export var size := Vector2(32.0, 32.0)


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	shape.position = size / 2.0
	add_child(shape)


## Altura do degrau, em pixels.
func step_height() -> float:
	return size.y


## Posição global da borda de cima da face, onde começa o chão alto.
func top() -> float:
	return global_position.y


## Posição global da borda de baixo da face, onde começa o chão baixo.
func bottom() -> float:
	return global_position.y + size.y


## Degrau duplo: a face tem duas casas de altura.
func is_tall() -> bool:
	return size.y >= 64.0


func _draw() -> void:
	var texture := TALL_TEXTURE if is_tall() else TEXTURE
	for x: int in int(size.x / 32.0):
		draw_texture_rect(texture, Rect2(Vector2(x * 32.0, 0.0), Vector2(32.0, size.y)), false)
	# Uma face mais alta projeta uma sombra mais longa.
	var shadow := SHADOW_HEIGHT + (size.y - 32.0) / 8.0
	draw_rect(Rect2(Vector2(0.0, size.y), Vector2(size.x, shadow)), SHADOW_COLOR)
