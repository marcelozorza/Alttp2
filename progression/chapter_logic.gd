class_name ChapterLogic
extends RefCounted
## Lógica de alcance de um capítulo, a mesma de tools/check_chapter.py, dentro
## do jogo, para o gerador de seeds (progression/randomizer.gd). Qualquer
## mudança nas regras precisa ser feita nos dois, e o teste de fumaça imprime
## as esferas dos capítulos lineares para comparar com as do conferidor.
##
## Como no NES, que guardava o mapa em blocos e não em pixels, a lógica não
## anda casa por casa. As casas livres ligadas entre si viram uma região, e
## cada bloqueio vira uma região própria. A lógica anda pelo grafo dessas
## regiões. As regras são as do jogo: parede rachada passa com a bomba, gelo
## com a chama ou a chama forte, gelo grosso só com a chama forte, porta
## trancada depois de aberta com uma chave pequena, porta do chefe com a chave
## grande, a face de degrau sobe só com a mola e desce sempre, a do degrau
## duplo sobe só com a mola forte, e a grade abre quando a região do
## interruptor dela é alcançada. Um baú conta como alcançado se alguma casa
## vizinha for alcançada.
##
## Numa visita à dungeon, cada chave pequena pode ser gasta em qualquer porta
## alcançada, e a ordem importa. A lógica percorre todas as ordens: um estado
## é o conjunto de portas abertas, e os estados sem saída, em que não sobra
## porta alcançada para gastar chave, são os fins possíveis da visita. Um baú
## é garantido com um conjunto de ferramentas quando é alcançado em todos
## esses fins, qualquer que seja a ordem. Sair da dungeon e entrar de novo
## fecha as portas e devolve as chaves, então o pior que uma ordem ruim faz é
## obrigar a sair e voltar.

const NO_NODE := -1
const ROOM_TILES := Vector2i(20, 10)

var map: ChapterMap
## Ferramentas que o chefe exige, como bits de Item.
var goal_tools := 0

var _rooms: Array = []
## Região de cada casa livre.
var _node_of := {}
## Vaga de bloqueio de cada região, ou "" para chão livre.
var _node_slot: Array[String] = []
## Passagens entre regiões: [de, para, ferramentas exigidas como bits].
var _edges: Array[Array] = []
var _edges_from: Array[Array] = []
## Passagens que chegam a cada grade, pela vaga dela.
var _edges_into_gate := {}
## Letras dos baús, em ordem, e as regiões vizinhas de cada um.
var _locations: Array[String] = []
var _location_nodes := {}
var _gates: Array[String] = []
## Região do interruptor de cada grade.
var _gate_source := {}
var _locked: Array[String] = []
var _start_node := NO_NODE
var _goal_node := NO_NODE


func _init(data: ChapterData) -> void:
	map = ChapterMap.new(data.rows, data.blocks)
	_rooms = data.rooms
	for id: int in data.goal_tools:
		goal_tools |= Item.bit(id)
	var slots: Array = data.blocks.keys()
	slots.sort()
	for slot: String in slots:
		if data.blocks[slot] == ChapterMap.Block.LOCKED:
			_locked.append(slot)
		elif data.blocks[slot] == ChapterMap.Block.GATE:
			_gates.append(slot)
	_build_graph()
	_start_node = _node_of.get(map.find("@"), NO_NODE)
	_goal_node = _node_of.get(map.find(data.goal), NO_NODE)


## Baús alcançados em todos os fins possíveis de uma visita com as
## ferramentas dadas, em ordem alfabética.
func guaranteed(items: Dictionary, tools: int) -> Array[String]:
	var ends := dead_ends(items, tools)
	var result: Array[String] = []
	for location: String in _locations:
		var everywhere := true
		for end: Dictionary in ends:
			if not end["collected"].has(location):
				everywhere = false
				break
		if everywhere:
			result.append(location)
	return result


## Vencível com as ferramentas dadas em qualquer ordem de abrir portas: todo
## fim de visita alcança o chefe com o que ele exige.
func is_beatable(items: Dictionary, tools: int) -> bool:
	for end: Dictionary in dead_ends(items, tools):
		if not end["reached"].has(_goal_node) or (end["tools"] & goal_tools) != goal_tools:
			return false
	return true


## Ordem em que os baús se tornam alcançáveis com todas as portas abertas, em
## esferas, para comparar com tools/check_chapter.py.
func spheres(items: Dictionary, tools: int) -> Array:
	var opened := {}
	for slot: String in _locked:
		opened[slot] = true
	return settle(items, tools, opened)["order"]


## Fins possíveis de uma visita: os estados sem porta alcançada para gastar
## chave, cada um com o que foi alcançado e ganho até ali.
func dead_ends(items: Dictionary, tools: int) -> Array[Dictionary]:
	var ends: Array[Dictionary] = []
	var seen := {}
	var stack: Array[Dictionary] = [{}]
	while not stack.is_empty():
		var opened: Dictionary = stack.pop_back()
		var key := _state_key(opened)
		if seen.has(key):
			continue
		seen[key] = true
		var settled := settle(items, tools, opened)
		var doors: Array[String] = []
		if settled["keys"] - opened.size() > 0:
			doors = _doors_in_reach(settled["reached"], settled["tools"], opened)
		if doors.is_empty():
			ends.append(settled)
		for door: String in doors:
			var next := opened.duplicate()
			next[door] = true
			stack.append(next)
	return ends


## Abre tudo o que alcança com as portas dadas, ganha os itens e repete até
## não haver novidade. Devolve as regiões alcançadas, as ferramentas, as
## chaves, os baús abertos e a ordem deles em esferas.
func settle(items: Dictionary, starting_tools: int, opened: Dictionary) -> Dictionary:
	var tools := starting_tools
	var keys := 0
	var collected := {}
	var order := []
	var reached := {}
	var progressed := true
	while progressed:
		reached = reachable_nodes(_start_node, tools, opened)
		var fresh: Array[String] = []
		for location: String in _locations:
			if not collected.has(location) and _touches(reached, _location_nodes[location]):
				fresh.append(location)
		progressed = not fresh.is_empty()
		if progressed:
			order.append(fresh)
		for location: String in fresh:
			collected[location] = true
			var item: int = items.get(location, Item.Id.NONE)
			if item == Item.Id.KEY:
				keys += 1
			elif item in Item.PERMANENT:
				tools = Item.collect(tools, item)
	return {
		"reached": reached, "tools": tools, "keys": keys, "collected": collected, "order": order
	}


## Regiões alcançáveis a partir de start, num dicionário usado como conjunto.
## Uma grade abre quando a região do interruptor é alcançada, e as passagens
## até ela, vistas antes disso, ganham nova chance.
func reachable_nodes(start: int, tools: int, opened: Dictionary) -> Dictionary:
	var reached := {start: true}
	var frontier: Array[int] = [start]
	while not frontier.is_empty():
		while not frontier.is_empty():
			var node: int = frontier.pop_back()
			for edge: Array in _edges_from[node]:
				if not reached.has(edge[1]) and _can_pass(edge, tools, opened, reached):
					reached[edge[1]] = true
					frontier.append(edge[1])
		for slot: String in _gates:
			if not reached.has(_gate_source.get(slot, NO_NODE)):
				continue
			for edge: Array in _edges_into_gate.get(slot, []):
				if reached.has(edge[0]) and not reached.has(edge[1]):
					if _can_pass(edge, tools, opened, reached):
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
		if map.block_type(slot) != ChapterMap.Block.LOCKED:
			continue
		if edge[2] != 0 and (tools & edge[2]) != edge[2]:
			continue
		doors.append(slot)
	return doors


func _can_pass(edge: Array, tools: int, opened: Dictionary, reached: Dictionary) -> bool:
	if edge[2] != 0 and (tools & edge[2]) != edge[2]:
		return false
	return _can_enter_slot(_node_slot[edge[1]], tools, opened, reached)


func _can_enter_slot(slot: String, tools: int, opened: Dictionary, reached: Dictionary) -> bool:
	if slot == "":
		return true
	var passes := false
	match map.block_type(slot):
		ChapterMap.Block.GATE:
			passes = reached.has(_gate_source.get(slot, NO_NODE))
		ChapterMap.Block.CRACKED:
			passes = Item.has(tools, Item.Id.BOMB)
		ChapterMap.Block.BOARDED:
			passes = Item.has(tools, Item.Id.STRONG_BOMB)
		ChapterMap.Block.ICE:
			passes = Item.has(tools, Item.Id.FIRE) or Item.has(tools, Item.Id.STRONG_FIRE)
		ChapterMap.Block.THICK_ICE:
			passes = Item.has(tools, Item.Id.STRONG_FIRE)
		ChapterMap.Block.LOCKED:
			passes = opened.has(slot)
		ChapterMap.Block.BOSS_DOOR:
			passes = Item.has(tools, Item.Id.BOSS_KEY)
	return passes


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
	var character := map.tile(cell)
	if character == "#" or character == " " or ChapterMap.is_location(character):
		return false
	return not _is_ledge(cell)


func _is_ledge(cell: Vector2i) -> bool:
	var kind := map.block_at(cell)
	return kind == ChapterMap.Block.LEDGE or kind == ChapterMap.Block.TALL_LEDGE


## Vaga da casa, ou "" para chão livre.
func _slot_of(cell: Vector2i) -> String:
	var character := map.tile(cell)
	return character if ChapterMap.is_slot(character) else ""


## Sala de uma casa, em unidades de tela: a sala maior que contém a tela, ou
## a própria tela.
func _room_of_cell(cell: Vector2i) -> Rect2i:
	var screen := Vector2i(cell.x / ROOM_TILES.x, cell.y / ROOM_TILES.y)
	for rect: Rect2i in _rooms:
		if rect.has_point(screen):
			return rect
	return Rect2i(screen, Vector2i.ONE)


## Casa de chegada de um passo e as ferramentas que ele exige, ou vazio se o
## passo não leva a lugar nenhum. A face de degrau se atravessa de uma vez até
## a casa do outro lado: para cima só com a mola, ou com a mola forte no degrau
## duplo, e para baixo sempre.
func _step_target(cell: Vector2i, step: Vector2i) -> Array:
	var next := cell + step
	if not _is_ledge(next):
		return [next, 0] if _is_space(next) else []
	if step != Vector2i.UP and step != Vector2i.DOWN:
		return []
	var slot := map.tile(next)
	var beyond := next
	while map.tile(beyond) == slot:
		beyond += step
	if not _is_space(beyond):
		return []
	var need := 0
	if step == Vector2i.UP:
		var tall := map.block_at(next) == ChapterMap.Block.TALL_LEDGE
		need = Item.bit(Item.Id.STRONG_SPRING if tall else Item.Id.SPRING)
	return [beyond, need]


## Junta as casas livres em regiões e liga as regiões pelas passagens.
func _build_graph() -> void:
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			if not _is_space(cell) or _node_of.has(cell):
				continue
			_flood(cell, _node_slot.size())
			_node_slot.append(_slot_of(cell))
	_find_gate_sources()
	var known := {}
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			if not _node_of.has(cell):
				continue
			for step: Vector2i in ChapterMap.STEPS:
				var target := _step_target(cell, step)
				if target.is_empty():
					continue
				var from: int = _node_of[cell]
				var to: int = _node_of[target[0]]
				var key := "%d>%d>%d" % [from, to, target[1]]
				if from != to and not known.has(key):
					known[key] = true
					_edges.append([from, to, target[1]])
	for _node: int in _node_slot.size():
		_edges_from.append([])
	for edge: Array in _edges:
		_edges_from[edge[0]].append(edge)
		var slot := _node_slot[edge[1]]
		if slot in _gates:
			if not _edges_into_gate.has(slot):
				_edges_into_gate[slot] = []
			_edges_into_gate[slot].append(edge)
	for y: int in map.height:
		for x: int in map.width:
			var cell := Vector2i(x, y)
			var character := map.tile(cell)
			if not ChapterMap.is_location(character):
				continue
			var nodes: Array[int] = []
			for step: Vector2i in ChapterMap.STEPS:
				if _node_of.has(cell + step):
					nodes.append(_node_of[cell + step])
			_location_nodes[character] = nodes
	_locations.assign(_location_nodes.keys())
	_locations.sort()


## Marca a região que começa em first: casas livres vizinhas com a mesma vaga.
func _flood(first: Vector2i, node: int) -> void:
	var slot := _slot_of(first)
	_node_of[first] = node
	var frontier: Array[Vector2i] = [first]
	while not frontier.is_empty():
		var cell: Vector2i = frontier.pop_back()
		for step: Vector2i in ChapterMap.STEPS:
			var next := cell + step
			if _node_of.has(next) or not _is_space(next) or _slot_of(next) != slot:
				continue
			_node_of[next] = node
			frontier.append(next)


## Região do interruptor de cada grade: um interruptor na mesma sala, numa
## região vizinha da grade. Sem ele, a grade nunca abre.
func _find_gate_sources() -> void:
	for slot: String in _gates:
		var cells: Array[Vector2i] = []
		for y: int in map.height:
			for x: int in map.width:
				if map.tile(Vector2i(x, y)) == slot:
					cells.append(Vector2i(x, y))
		if cells.is_empty():
			continue
		var room := _room_of_cell(cells[0])
		var neighbors := {}
		for cell: Vector2i in cells:
			for step: Vector2i in ChapterMap.STEPS:
				var next := cell + step
				if _node_of.has(next) and map.tile(next) != slot:
					neighbors[_node_of[next]] = true
		for y: int in map.height:
			for x: int in map.width:
				var switch := Vector2i(x, y)
				if map.tile(switch) != "=" or _room_of_cell(switch) != room:
					continue
				var node: int = _node_of.get(switch, NO_NODE)
				if neighbors.has(node):
					_gate_source[slot] = node
					break
			if _gate_source.has(slot):
				break
