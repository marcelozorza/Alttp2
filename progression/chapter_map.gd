class_name ChapterMap
extends RefCounted
## Grade de um capítulo lida de linhas de texto, com a lógica de alcance que
## garante que toda seed tenha caminho.
##
## Cada caractere é uma casa de 16 pixels:
## - "#" parede, " " fora do mapa, "." chão, ":" chão alto, o topo de um degrau.
## - "@" início do personagem.
## - "A" a "Z" baús. O conteúdo vem da distribuição, nunca do mapa.
## - "1" a "9" bloqueios. O tipo de cada um vem dos dados do capítulo. Casas
##   com o mesmo número formam um só bloqueio.
## - "m" minion, "u" ugly, "i" inimigo de gelo, "*" chefe, "c" caixa leve.
##
## As regras de alcance são as mesmas do jogo: parede rachada passa com a
## bomba, gelo passa com a chama, e a face de degrau passa de baixo para cima
## só com a mola e de cima para baixo sempre. Um baú conta como alcançado se
## alguma casa vizinha for alcançada.

enum Block { CRACKED, ICE, LEDGE }

## Tamanho de uma casa, em pixels.
const TILE := 16
const LOCATIONS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const SLOTS := "123456789"
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


## Tipo do bloqueio de uma vaga, pelo número.
func block_type(slot: String) -> int:
	return _blocks.get(slot, -1)


## Chão alto: o topo de um degrau, ou um baú ao lado de chão alto.
func is_high(cell: Vector2i) -> bool:
	if tile(cell) == ":":
		return true
	if not is_location(tile(cell)):
		return false
	for step: Vector2i in STEPS:
		if tile(cell + step) == ":":
			return true
	return false


## Diz se dá para ficar na casa com as ferramentas dadas.
func is_walkable(cell: Vector2i, tools: int) -> bool:
	var character := tile(cell)
	if character == "#" or character == " " or is_location(character):
		return false
	match block_at(cell):
		Block.CRACKED:
			return Item.has(tools, Item.Id.BOMB)
		Block.ICE:
			return Item.has(tools, Item.Id.FIRE)
		Block.LEDGE:
			return false
	return true


## Casas alcançáveis a partir de start com as ferramentas dadas, num dicionário
## usado como conjunto.
func reachable(start: Vector2i, tools: int) -> Dictionary:
	var reached := {start: true}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step: Vector2i in STEPS:
			var next := _step(cell, step, tools)
			if next != NO_CELL and not reached.has(next):
				reached[next] = true
				frontier.append(next)
	return reached


## Baús com alguma casa vizinha alcançada.
func reached_locations(reached: Dictionary) -> Array[String]:
	var found: Array[String] = []
	for y: int in height:
		for x: int in _rows[y].length():
			var character := _rows[y][x]
			if not is_location(character):
				continue
			for step: Vector2i in STEPS:
				if reached.has(Vector2i(x, y) + step):
					found.append(character)
					break
	return found


## Simula a partida: abre tudo o que alcança, ganha as ferramentas e repete até
## não haver novidade. A distribuição é vencível se, no fim, a casa do alvo for
## alcançada com as ferramentas exigidas, um conjunto de bits de Item.
func is_beatable(distribution: Dictionary, goal: String, goal_tools: int) -> bool:
	var start := find("@")
	var tools := 0
	var collected := {}
	var reached := {}
	var progressed := true
	while progressed:
		progressed = false
		reached = reachable(start, tools)
		for location: String in reached_locations(reached):
			if collected.has(location):
				continue
			collected[location] = true
			progressed = true
			var item: int = distribution.get(location, Item.Id.NONE)
			if Item.is_tool(item):
				tools |= Item.bit(item)
	return reached.has(find(goal)) and (tools & goal_tools) == goal_tools


func _step(cell: Vector2i, step: Vector2i, tools: int) -> Vector2i:
	var next := cell + step
	if block_at(next) != Block.LEDGE:
		return next if is_walkable(next, tools) else NO_CELL
	# Face de degrau: atravessa de uma vez até a casa do outro lado.
	var climbing := step == Vector2i.UP and Item.has(tools, Item.Id.SPRING)
	if not climbing and step != Vector2i.DOWN:
		return NO_CELL
	var beyond := next + step
	return beyond if is_walkable(beyond, tools) else NO_CELL
