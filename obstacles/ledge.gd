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

const FACE_COLOR := Color(0.38, 0.31, 0.24, 1.0)
const STRIPE_COLOR := Color(0.31, 0.25, 0.19, 1.0)
const LIP_COLOR := Color(0.62, 0.62, 0.54, 1.0)
const SHADOW_COLOR := Color(0.2, 0.17, 0.13, 1.0)

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
	draw_rect(Rect2(Vector2.ZERO, size), FACE_COLOR)
	for x: int in range(2, int(size.x), 5):
		draw_rect(Rect2(Vector2(x, 3.0), Vector2(1.0, size.y - 4.0)), STRIPE_COLOR)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 2.0)), LIP_COLOR)
	draw_rect(Rect2(Vector2(0.0, size.y - 1.0), Vector2(size.x, 1.0)), SHADOW_COLOR)
