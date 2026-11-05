class_name ChapterMap
extends RefCounted
## Grade de um capítulo lida de linhas de texto, com a lógica de alcance que
## garante que toda seed tenha caminho.
##
## Cada caractere é uma casa de 16 pixels:
## - "#" parede, " " fora do mapa, "." chão, ":" chão alto, o topo de um degrau.
## - "@" início do personagem.
## - "A" a "Z" baús. O conteúdo vem da distribuição, nunca do mapa.
## - SLOTS: bloqueios, os algarismos de 1 a 9 e as letras minúsculas que não
##   são inimigos. O tipo de cada um vem dos dados do capítulo. Casas com o
##   mesmo caractere formam um só bloqueio.
## - "m" minion, "u" ugly, "i" inimigo de gelo, "c" caixa leve.
## - "*" guardião de gelo e "&" sentinela, os chefes.
##
## As regras de alcance são as mesmas do jogo: parede rachada passa com a
## bomba, gelo passa com a chama, porta trancada passa depois de aberta com
## uma chave pequena, porta do chefe passa com a chave grande, e a face de
## degrau passa de baixo para cima só com a mola e de cima para baixo sempre.
## Um baú conta como alcançado se alguma casa vizinha for alcançada.
##
## Como no NES, que guardava o mapa em blocos e não em pixels, a lógica não
## anda casa por casa. Ao ler o mapa, as casas livres ligadas entre si viram
## uma região, e cada bloqueio vira uma região própria. A lógica anda pelo
## grafo dessas regiões, que tem poucas dezenas de nós, e por isso testa
## milhares de ordens de abrir portas num instante.

enum Block { CRACKED, ICE, LEDGE, LOCKED, BOSS_DOOR }

## Tamanho de uma casa, em pixels.
const TILE := 16
const LOCATIONS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const SLOTS := "123456789abdefghjklnopqrstvwxyz"
const STEPS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
const NO_CELL := Vector2i(-1, -1)
const NO_NODE := -1
## Item que abre cada tipo de bloqueio para sempre. A porta trancada fica de
## fora, porque cada uma gasta uma chave pequena.
const OPENED_BY := {
	Block.CRACKED: Item.Id.BOMB,
	Block.ICE: Item.Id.FIRE,
	Block.BOSS_DOOR: Item.Id.BOSS_KEY,
}

var width := 0
var height := 0

var _rows: Array[String] = []
var _blocks := {}
## Região de cada casa livre.
var _node_of := {}
## Vaga de bloqueio de cada região, ou "" para chão livre.
var _node_slot: Array[String] = []
## Passagens entre regiões: [de, para, exige a mola].
var _edges: Array[Array] = []
## Passagens que saem de cada região, pelo número da região.
var _edges_from: Array[Array] = []
## Regiões vizinhas de cada baú.
var _location_nodes := {}


func _init(rows: Array, blocks: Dictionary) -> void:
	for row: String in rows:
		_rows.append(row)
		width = maxi(width, row.length())
	height = _rows.size()
	_blocks = blocks
	_build_graph()


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


## Simula a partida e diz se a distribuição é vencível em qualquer ordem de
## abrir as portas trancadas.
##
## Cada estado é o conjunto de portas já abertas. Num estado, o jogador abre
## todos os baús que alcança, porque abrir um baú nunca atrapalha. Depois ele
## pode gastar uma chave em qualquer porta trancada que alcança. A distribuição
## só vale se todo estado sem saída já tiver o alvo alcançado com as
## ferramentas exigidas, um conjunto de bits de Item. Assim nenhum jogador
## fica preso por ter gastado a chave na porta errada.
func is_beatable(distribution: Dictionary, goal: String, goal_tools: int) -> bool:
	var goal_node: int = _node_of.get(find(goal), NO_NODE)
	return _check_state({}, distribution, goal_node, goal_tools, {})


func _check_state(
	opened: Dictionary, distribution: Dictionary, goal_node: int, goal_tools: int, seen: Dictionary
) -> bool:
	var key := _state_key(opened)
	if seen.has(key):
		return true
	seen[key] = true
	var settled := _settle(distribution, opened)
	var reached: Dictionary = settled["reached"]
	var tools: int = settled["tools"]
	var spare: int = settled["keys"] - opened.size()
	var doors: Array[String] = []
	if spare > 0:
		doors = _doors_in_reach(reached, tools, opened)
	if doors.is_empty():
		return reached.has(goal_node) and (tools & goal_tools) == goal_tools
	for door: String in doors:
		var next := opened.duplicate()
		next[door] = true
		if not _check_state(next, distribution, goal_node, goal_tools, seen):
			return false
	return true


## Abre tudo o que alcança com as portas dadas, ganha os itens e repete até
## não haver novidade.
func _settle(distribution: Dictionary, opened: Dictionary) -> Dictionary:
	var start: int = _node_of[find("@")]
	var tools := 0
	var keys := 0
	var collected := {}
	var reached := {}
	var progressed := true
	while progressed:
		progressed = false
		reached = _reachable(start, tools, opened)
		for location: String in _location_nodes:
			if collected.has(location) or not _touches(reached, _location_nodes[location]):
				continue
			collected[location] = true
			progressed = true
			var item: int = distribution.get(location, Item.Id.NONE)
			if item == Item.Id.KEY:
				keys += 1
			elif item in Item.PERMANENT:
				tools |= Item.bit(item)
	return {"reached": reached, "tools": tools, "keys": keys}


## Regiões alcançáveis a partir de start, num dicionário usado como conjunto.
func _reachable(start: int, tools: int, opened: Dictionary) -> Dictionary:
	var reached := {start: true}
	var frontier: Array[int] = [start]
	while not frontier.is_empty():
		var node: int = frontier.pop_back()
		for edge: Array in _edges_from[node]:
			if reached.has(edge[1]):
				continue
			if _can_pass(edge, tools, opened):
				reached[edge[1]] = true
				frontier.append(edge[1])
	return reached


## Portas trancadas, ainda fechadas, vizinhas de uma região alcançada.
func _doors_in_reach(reached: Dictionary, tools: int, opened: Dictionary) -> Array[String]:
	var doors: Array[String] = []
	for edge: Array in _edges:
		var slot := _node_slot[edge[1]]
		if not reached.has(edge[0]) or doors.has(slot) or opened.has(slot):
			continue
		if block_type(slot) != Block.LOCKED:
			continue
		if edge[2] and not Item.has(tools, Item.Id.SPRING):
			continue
		doors.append(slot)
	return doors


func _can_pass(edge: Array, tools: int, opened: Dictionary) -> bool:
	if edge[2] and not Item.has(tools, Item.Id.SPRING):
		return false
	var slot := _node_slot[edge[1]]
	if slot == "":
		return true
	var kind := block_type(slot)
	if kind == Block.LOCKED:
		return opened.has(slot)
	return kind in OPENED_BY and Item.has(tools, OPENED_BY[kind])


func _touches(reached: Dictionary, nodes: Array) -> bool:
	for node: int in nodes:
		if reached.has(node):
			return true
	return false


func _state_key(opened: Dictionary) -> String:
	var slots: Array = opened.keys()
	slots.sort()
	return "".join(PackedStringArray(slots))


## Casa onde dá para ficar: chão ou bloqueio que não seja face de degrau.
func _is_space(cell: Vector2i) -> bool:
	var character := tile(cell)
	if character == "#" or character == " " or is_location(character):
		return false
	return block_at(cell) != Block.LEDGE


## Vaga da casa, ou "" para chão livre.
func _slot_of(cell: Vector2i) -> String:
	var character := tile(cell)
	return character if is_slot(character) else ""


## Junta as casas livres em regiões e liga as regiões pelas passagens.
func _build_graph() -> void:
	for y: int in height:
		for x: int in _rows[y].length():
			var cell := Vector2i(x, y)
			if not _is_space(cell) or _node_of.has(cell):
				continue
			_flood(cell, _node_slot.size())
			_node_slot.append(_slot_of(cell))
	var known := {}
	for cell: Vector2i in _node_of:
		for step: Vector2i in STEPS:
			var target := _step_target(cell, step)
			if target.is_empty():
				continue
			var to: int = _node_of[target[0]]
			var from: int = _node_of[cell]
			var key := "%d>%d>%s" % [from, to, target[1]]
			if from != to and not known.has(key):
				known[key] = true
				_edges.append([from, to, target[1]])
	for _node: int in _node_slot.size():
		_edges_from.append([])
	for edge: Array in _edges:
		_edges_from[edge[0]].append(edge)
	for y: int in height:
		for x: int in _rows[y].length():
			var cell := Vector2i(x, y)
			if not is_location(tile(cell)):
				continue
			var nodes: Array[int] = []
			for step: Vector2i in STEPS:
				if _node_of.has(cell + step):
					nodes.append(_node_of[cell + step])
			_location_nodes[tile(cell)] = nodes


## Marca a região que começa em first: casas livres vizinhas com a mesma vaga.
func _flood(first: Vector2i, node: int) -> void:
	var slot := _slot_of(first)
	_node_of[first] = node
	var frontier: Array[Vector2i] = [first]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step: Vector2i in STEPS:
			var next := cell + step
			if _node_of.has(next) or not _is_space(next) or _slot_of(next) != slot:
				continue
			_node_of[next] = node
			frontier.append(next)


## Casa de chegada de um passo e se ele exige a mola, ou vazio se o passo não
## leva a lugar nenhum. A face de degrau se atravessa de uma vez até a casa do
## outro lado: para cima só com a mola, para baixo sempre.
func _step_target(cell: Vector2i, step: Vector2i) -> Array:
	var next := cell + step
	if block_at(next) != Block.LEDGE:
		return [next, false] if _is_space(next) else []
	if step != Vector2i.UP and step != Vector2i.DOWN:
		return []
	var beyond := next + step
	if not _is_space(beyond):
		return []
	return [beyond, step == Vector2i.UP]
