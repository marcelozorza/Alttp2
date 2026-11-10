class_name GiorginoArt
extends RefCounted
## Desenhos do Giorgino e o ponto dos pés em cada um.
##
## A espada faz parte dos desenhos: na pata quando ele está de pé, presa na
## coleira quando galopa e estendida nos quadros de golpe. Por isso os quadros
## têm tamanhos diferentes e passam do corpo, e cada um guarda onde ficam os
## pés dentro dele, em pixels a partir do canto de cima à esquerda. O
## personagem põe esse ponto sobre a própria origem.
##
## Cada lista segue a ordem de frente, de costas e de lado. O de lado olha para
## a direita, e o jogo espelha para a esquerda.

## Andando, de pé, com o segundo passo logo depois de cada direção.
const WALKING: Array[Texture2D] = [
	preload("res://art/giorgino_stand_down.svg"),
	preload("res://art/giorgino_stand_down_step.svg"),
	preload("res://art/giorgino_stand_up.svg"),
	preload("res://art/giorgino_stand_up_step.svg"),
	preload("res://art/giorgino_stand_side.svg"),
	preload("res://art/giorgino_stand_side_step.svg"),
]
const WALKING_FEET: Array[Vector2] = [
	Vector2(19.5, 40.0),
	Vector2(19.5, 40.0),
	Vector2(14.0, 38.0),
	Vector2(13.5, 38.0),
	Vector2(18.0, 37.0),
	Vector2(17.5, 37.0),
]
## Correndo, nas quatro patas, na mesma ordem.
const RUNNING: Array[Texture2D] = [
	preload("res://art/giorgino_down.svg"),
	preload("res://art/giorgino_down_step.svg"),
	preload("res://art/giorgino_up.svg"),
	preload("res://art/giorgino_up_step.svg"),
	preload("res://art/giorgino_side.svg"),
	preload("res://art/giorgino_side_step.svg"),
]
const RUNNING_FEET: Array[Vector2] = [
	Vector2(15.0, 38.0),
	Vector2(15.0, 33.0),
	Vector2(13.5, 37.0),
	Vector2(14.0, 37.0),
	Vector2(19.0, 31.0),
	Vector2(20.0, 33.0),
]
## Golpe de espada, um quadro por direção. A lâmina cobre a área de dano de
## Sword: até 36 pixels para o lado, 32 para baixo e 48 para cima dos pés.
const THRUST: Array[Texture2D] = [
	preload("res://art/giorgino_thrust_down.svg"),
	preload("res://art/giorgino_thrust_up.svg"),
	preload("res://art/giorgino_thrust_side.svg"),
]
const THRUST_FEET: Array[Vector2] = [
	Vector2(13.5, 40.0),
	Vector2(17.0, 50.0),
	Vector2(18.0, 37.0),
]
## Deitado, sem vida, com a espada caída ao lado.
const FALLEN: Texture2D = preload("res://art/giorgino_fallen.svg")
const FALLEN_FEET := Vector2(25.0, 13.0)
## Os mesmos desenhos sujos da gosma da granada do ugly, mostrados enquanto a
## espada está travada (pedido de Marcelo em 2026-11-08: a gosma tem que ser
## desenho, não efeito por cima). Gerados por tools/giorgino_goo_art.py a
## partir dos desenhos limpos, com o mesmo tamanho e os mesmos pés. Não há
## golpe com gosma, porque a espada travada não golpeia.
const GOO_WALKING: Array[Texture2D] = [
	preload("res://art/giorgino_goo_stand_down.svg"),
	preload("res://art/giorgino_goo_stand_down_step.svg"),
	preload("res://art/giorgino_goo_stand_up.svg"),
	preload("res://art/giorgino_goo_stand_up_step.svg"),
	preload("res://art/giorgino_goo_stand_side.svg"),
	preload("res://art/giorgino_goo_stand_side_step.svg"),
]
const GOO_RUNNING: Array[Texture2D] = [
	preload("res://art/giorgino_goo_down.svg"),
	preload("res://art/giorgino_goo_down_step.svg"),
	preload("res://art/giorgino_goo_up.svg"),
	preload("res://art/giorgino_goo_up_step.svg"),
	preload("res://art/giorgino_goo_side.svg"),
	preload("res://art/giorgino_goo_side_step.svg"),
]
const GOO_FALLEN: Texture2D = preload("res://art/giorgino_goo_fallen.svg")


## Índice da direção nas listas: 0 de frente, 1 de costas e 2 de lado.
static func direction_index(facing: Vector2) -> int:
	if facing.y > 0.0:
		return 0
	if facing.y < 0.0:
		return 1
	return 2
