class_name Ledge
extends StaticBody2D
## Face de um degrau alto, vista de frente. O chão de cima fica ao norte.
##
## Andando, ninguém atravessa a face. O personagem sobe com o pulo da mola, se
## estiver alto o bastante ao encostar nela vindo do sul, e desce num salto ao
## andar contra ela vindo do norte. A travessia fica a cargo do personagem
## (ver player.gd). A face só informa onde ficam as bordas e a altura.
##
## A origem fica no canto superior esquerdo. O construtor do mapa define o
## tamanho antes de adicionar a face à cena.

const TEXTURE := preload("res://art/ledge.svg")

## Tamanho em pixels. A altura da face é também a altura do degrau.
@export var size := Vector2(16.0, 16.0)


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


func _draw() -> void:
	for x: int in int(size.x / 16.0):
		draw_texture_rect(TEXTURE, Rect2(Vector2(x * 16.0, 0.0), Vector2(16.0, size.y)), false)
