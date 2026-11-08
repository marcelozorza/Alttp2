class_name Randomizer
## Gera a distribuição de itens de uma seed sobre as dungeons do mundo, o
## modo randomizado, o jogo de verdade (orientação de Marcelo em 2026-11-07).
##
## A seed é um número de 1 a 999999 que o jogador digita ou sorteia, e o mesmo
## número dá o mesmo jogo em qualquer cópia do jogo: o sorteio só depende
## dele, nunca da máquina, da hora ou da ordem em que as coisas carregam. O
## tutorial fica fora da seed. As chaves pequenas e a chave grande ficam nos
## baús delas, como no modo padrão do randomizer de ALttP. As ferramentas e
## as melhorias, os itens de progressão, se espalham pelos outros baús das
## três dungeons, e os corações preenchem o que sobra.
##
## O preenchimento é o "assumed fill" dos randomizers: cada item de progressão
## entra, numa ordem sorteada, num baú garantido com os itens que ainda estão
## por colocar, mais os já colocados que a lógica alcança. Um baú é garantido
## quando é alcançado em qualquer ordem de gastar as chaves dentro da dungeon
## (ver progression/chapter_logic.gd). O sorteio escolhe primeiro a dungeon,
## entre as que têm baú garantido, e depois o baú, para os itens se
## espalharem pelas três em vez de se juntarem na dungeon com mais baús. No
## fim, a seed é conferida de ponta a ponta: começando sem nada, com as
## entradas todas abertas, o jogador alcança todas as ferramentas e vence os
## três chefes em qualquer ordem de portas. Uma seed que não passa é sorteada
## de novo, com o mesmo gerador, então o resultado continua o mesmo para o
## mesmo número.

const MIN_SEED := 1
const MAX_SEED := 999999
## Tentativas de preencher antes de desistir e usar a distribuição linear.
const MAX_ATTEMPTS := 100
## Itens que a seed embaralha entre as dungeons.
const PROGRESSION := [
	Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING, Item.Id.STRONG_FIRE, Item.Id.STRONG_SPRING
]


## Seed sugerida ao abrir a tela, sem compromisso com nada.
static func random_seed() -> int:
	return randi_range(MIN_SEED, MAX_SEED)


## Distribuição da seed: o item de cada baú, por número de capítulo e letra.
static func generate(seed_value: int) -> Dictionary:
	var logics := {}
	var fixed := {}
	var linear := {}
	var slots: Array = []
	var fillers: Array = []
	for chapter: int in range(1, ChapterData.count() + 1):
		var data := ChapterData.load_number(chapter)
		logics[chapter] = ChapterLogic.new(data)
		linear[chapter] = data.items
		fixed[chapter] = {}
		var letters: Array = data.items.keys()
		letters.sort()
		for letter: String in letters:
			var item: int = data.items[letter]
			if item == Item.Id.KEY or item == Item.Id.BOSS_KEY:
				fixed[chapter][letter] = item
			else:
				slots.append([chapter, letter])
				if item not in PROGRESSION:
					fillers.append(item)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for _attempt: int in MAX_ATTEMPTS:
		var table := _fill(logics, fixed, slots, fillers, rng)
		if not table.is_empty() and verify(logics, table):
			return table
	push_error("Nenhuma distribuição vencível para a seed %d." % seed_value)
	return linear


## Simula o jogo inteiro: começando sem nada, o jogador abre o que é garantido
## em cada dungeon, ganha as ferramentas e repete. A seed vale se no fim tem
## todos os itens de progressão e vence todos os chefes.
static func verify(logics: Dictionary, table: Dictionary) -> bool:
	var tools := 0
	var collected := {}
	var gained := true
	while gained:
		gained = false
		for chapter: int in logics:
			var logic: ChapterLogic = logics[chapter]
			for letter: String in logic.guaranteed(table[chapter], tools):
				var key := "%d%s" % [chapter, letter]
				if collected.has(key):
					continue
				collected[key] = true
				var item: int = table[chapter].get(letter, Item.Id.NONE)
				if item in PROGRESSION:
					tools = Item.collect(tools, item)
					gained = true
	for item: int in PROGRESSION:
		if not Item.has(tools, item):
			return false
	for chapter: int in logics:
		var logic: ChapterLogic = logics[chapter]
		if not logic.is_beatable(table[chapter], tools):
			return false
	return true


## Texto da distribuição, para o teste e para depurar: "1:A=KEY,B=HEART 2:...".
static func describe(table: Dictionary) -> String:
	var parts: Array[String] = []
	var chapters: Array = table.keys()
	chapters.sort()
	for chapter: int in chapters:
		var letters: Array = table[chapter].keys()
		letters.sort()
		var entries: Array[String] = []
		for letter: String in letters:
			entries.append("%s=%s" % [letter, Item.Id.keys()[table[chapter][letter]]])
		parts.append("%d:%s" % [chapter, ",".join(entries)])
	return " ".join(parts)


## Uma tentativa de preenchimento. Vazio quando algum item ficou sem baú.
static func _fill(
	logics: Dictionary, fixed: Dictionary, slots: Array, fillers: Array, rng: RandomNumberGenerator
) -> Dictionary:
	var table := {}
	for chapter: int in fixed:
		table[chapter] = fixed[chapter].duplicate()
	var pool: Array = PROGRESSION.duplicate()
	_shuffle(pool, rng)
	while not pool.is_empty():
		var item: int = pool.pop_back()
		# O que o jogador teria com o resto do saco: com uma só mola no saco,
		# ele tem a mola e não a mola forte, porque os itens são progressivos.
		var assumed := 0
		for other: int in pool:
			assumed = Item.collect(assumed, other)
		var options := _available(logics, table, assumed)
		if options.is_empty():
			return {}
		var chapters: Array = options.keys()
		var chapter: int = chapters[rng.randi_range(0, chapters.size() - 1)]
		var letters: Array = options[chapter]
		table[chapter][letters[rng.randi_range(0, letters.size() - 1)]] = item
	var rest: Array = fillers.duplicate()
	_shuffle(rest, rng)
	for slot: Array in slots:
		if not table[slot[0]].has(slot[1]):
			table[slot[0]][slot[1]] = rest.pop_back() if not rest.is_empty() else Item.Id.HEART
	return table


## Baús vazios garantidos com as ferramentas dadas: as letras de cada
## capítulo que tem algum, em ordem fixa.
static func _available(logics: Dictionary, table: Dictionary, tools: int) -> Dictionary:
	var options := {}
	var chapters: Array = logics.keys()
	chapters.sort()
	for chapter: int in chapters:
		var logic: ChapterLogic = logics[chapter]
		var letters: Array[String] = []
		for letter: String in logic.guaranteed(table[chapter], tools):
			if not table[chapter].has(letter):
				letters.append(letter)
		if not letters.is_empty():
			options[chapter] = letters
	return options


## Embaralha no lugar, só com o gerador da seed.
static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for i: int in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = values[i]
		values[i] = values[j]
		values[j] = swap
