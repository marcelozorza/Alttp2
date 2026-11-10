class_name ChapterMap
extends RefCounted
## Grade de um capítulo lida de linhas de texto.
##
## Cada caractere é uma casa de 32 pixels:
## - "#" parede, " " fora do mapa, "." chão, ":" chão alto, o topo de um degrau,
##   "^" chão mais alto, o topo de um degrau duplo.
## - "@" início do personagem.
## - "A" a "Z" baús. O conteúdo vem dos itens do capítulo, nunca do mapa.
## - SLOTS: bloqueios, os algarismos de 1 a 9 e as letras minúsculas que não
##   são inimigos. O tipo de cada um vem dos dados do capítulo. Casas com o
##   mesmo caractere formam um só bloqueio.
## - "m" minion, "u" ugly, "i" inimigo de gelo, "w" morsa de gelo, "s" atirador
##   de pedras, "x" tatu de pedra, "y" morcego, "z" planta de espinhos, "c"
##   caixa leve, "0" bloco pesado, "=" interruptor no chão e "?" placa de
##   mensagem, que mostra um texto enquanto o personagem está em cima.
## - "*" guardião de gelo, "&" sentinela, "%" guardião antigo e "$" colosso, os
##   chefes.
##
## A conferência de que o capítulo tem caminho até o fim fica fora do jogo, em
## tools/check_chapter.py, que lê os mesmos dados.

enum Block { CRACKED, ICE, LEDGE, LOCKED, BOSS_DOOR, THICK_ICE, TALL_LEDGE, GATE }

## Tamanho de uma casa, em pixels.
const TILE := 32
const LOCATIONS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const SLOTS := "123456789abdefghjklnopqrtv"
const STEPS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const NO_CELL := Vector2i(-1, -1)

var width := 0
var height := 0

var _rows: Array[String] = []
var _blocks := {}


func _init(rows: Array, blocks: Dictionary) -> void:
	for row: String in rows:
		_rows.append(row)
		width = maxi(width, row.length())
	height = _rows.size()
	_blocks = blocks


static func is_location(character: String) -> bool:
	return character.length() == 1 and LOCATIONS.contains(character)


static func is_slot(character: String) -> bool:
	return character.length() == 1 and SLOTS.contains(character)


## Caractere da casa, ou espaço fora da grade.
func tile(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= height or cell.x < 0 or cell.x >= _rows[cell.y].length():
		return " "
	return _rows[cell.y][cell.x]


## Primeira casa com o caractere, ou NO_CELL.
func find(character: String) -> Vector2i:
	for y: int in height:
		var x := _rows[y].find(character)
		if x >= 0:
			return Vector2i(x, y)
	return NO_CELL


## Tipo do bloqueio da casa, um Block, ou -1 se não for bloqueio.
func block_at(cell: Vector2i) -> int:
	return _blocks.get(tile(cell), -1)


## Tipo do bloqueio de uma vaga, pelo caractere.
func block_type(slot: String) -> int:
	return _blocks.get(slot, -1)


## Nível do chão: 0 no chão comum, 1 no chão alto (":"), o topo de um degrau,
## e 2 no chão mais alto ("^"), o topo de um degrau duplo. Um baú, um inimigo
## ou um bloqueio toma o caractere da casa, então fica no nível do chão mais
## alto ao lado dele.
func height_level(cell: Vector2i) -> int:
	var character := tile(cell)
	if character == "^":
		return 2
	if character == ":":
		return 1
	if character == "." or character == "#" or character == " ":
		return 0
	var level := 0
	for step: Vector2i in STEPS:
		var neighbor := tile(cell + step)
		if neighbor == "^":
			return 2
		if neighbor == ":":
			level = 1
	return level
