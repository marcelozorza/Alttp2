extends Node
## Lote de sementes: gera muitas sementes do modo randomizado e resume o que
## saiu, para achar semente sem saída, itens que caem sempre no mesmo lugar e
## jogos repetidos. Não muda nada no projeto.
##
##     godot --headless --path . res://tools/seed_batch.tscn -- 2000
##
## O número é a quantidade de sementes, a partir da 1. Sem ele, são 1000.
##
## Para cada semente, confere de novo se o jogo é vencível e conta: em que
## dungeon cada item de progressão caiu, em quantas rodadas de "achar item e
## voltar" o jogo se resolve, quantos itens de progressão dá para pegar sem
## nenhuma ferramenta, e quantas distribuições diferentes apareceram.

const DEFAULT_COUNT := 1000


func _ready() -> void:
	var count := DEFAULT_COUNT
	for argument: String in OS.get_cmdline_user_args():
		if argument.is_valid_int():
			count = int(argument)
	var logics := {}
	var linear := {}
	var free_slots := 0
	for chapter: int in range(1, ChapterData.count() + 1):
		var data := ChapterData.load_number(chapter)
		logics[chapter] = ChapterLogic.new(data)
		linear[chapter] = data.items
		for letter: String in data.items:
			if data.items[letter] != Item.Id.KEY and data.items[letter] != Item.Id.BOSS_KEY:
				free_slots += 1
	var failed: Array[int] = []
	var fallback: Array[int] = []
	var tables := {}
	var placements := {}
	var by_dungeon := {}
	var by_chest := {}
	var any_item := {}
	var rounds_count := {}
	var first_count := {}
	for item: int in Randomizer.PROGRESSION:
		by_dungeon[item] = {}
		by_chest[item] = {}
	var started := Time.get_ticks_msec()
	for seed_value: int in range(1, count + 1):
		var table := Randomizer.generate(seed_value)
		if not Randomizer.verify(logics, table):
			failed.append(seed_value)
		if table == linear:
			fallback.append(seed_value)
		tables[Randomizer.describe(table)] = true
		var placement: Array[String] = []
		for chapter: int in table:
			for letter: String in table[chapter]:
				var item: int = table[chapter][letter]
				if item not in Randomizer.PROGRESSION:
					continue
				var chest := "%d%s" % [chapter, letter]
				# As duas molas, ou as duas chamas, valem o mesmo: a primeira
				# achada é a fraca.
				placement.append("%s=%d" % [chest, Item.progressive(0, item)])
				by_dungeon[item][chapter] = by_dungeon[item].get(chapter, 0) + 1
				by_chest[item][chest] = by_chest[item].get(chest, 0) + 1
				any_item[chest] = any_item.get(chest, 0) + 1
		placement.sort()
		placements[",".join(placement)] = true
		var walk := _walk(logics, table)
		rounds_count[walk[0]] = rounds_count.get(walk[0], 0) + 1
		first_count[walk[1]] = first_count.get(walk[1], 0) + 1
	var elapsed := Time.get_ticks_msec() - started
	print("LOTE: %d sementes, %d ms por semente" % [count, elapsed / maxi(1, count)])
	print("LOTE: baús que recebem item sorteado %d" % free_slots)
	print("LOTE: sem saída %s" % [failed])
	print("LOTE: caíram na distribuição do jogo original %s" % [fallback])
	print("LOTE: distribuições diferentes %d de %d" % [tables.size(), count])
	print("LOTE: posições diferentes dos itens de progressão %d" % placements.size())
	for item: int in Randomizer.PROGRESSION:
		var parts: Array[String] = []
		for chapter: int in logics:
			var share: int = by_dungeon[item].get(chapter, 0)
			parts.append("dungeon %d %d%%" % [chapter, roundi(100.0 * share / count)])
		var chests: Array = by_chest[item].keys()
		chests.sort_custom(
			func(a: String, b: String) -> bool: return by_chest[item][a] > by_chest[item][b]
		)
		var top: Array[String] = []
		for chest: String in chests.slice(0, 4):
			top.append("%s %d%%" % [chest, roundi(100.0 * by_chest[item][chest] / count)])
		print(
			(
				"LOTE: %s -> %s. Em %d baús, mais comuns: %s"
				% [Item.Id.keys()[item], ", ".join(parts), chests.size(), ", ".join(top)]
			)
		)
	var busiest: Array = any_item.keys()
	busiest.sort_custom(func(a: String, b: String) -> bool: return any_item[a] > any_item[b])
	var busy: Array[String] = []
	for chest: String in busiest.slice(0, 6):
		busy.append("%s %d%%" % [chest, roundi(100.0 * any_item[chest] / count)])
	print("LOTE: baús que mais têm item de progressão: %s" % ", ".join(busy))
	print("LOTE: rodadas até ter tudo (rodadas: sementes) %s" % [_sorted(rounds_count)])
	print(
		(
			"LOTE: itens de progressão alcançados sem nada (itens: sementes) %s"
			% [_sorted(first_count)]
		)
	)
	get_tree().quit()


## Joga a semente como a lógica: em cada rodada, pega tudo o que é garantido
## com as ferramentas do começo da rodada. Devolve o número de rodadas que
## deram item de progressão e quantos deles vieram na primeira.
func _walk(logics: Dictionary, table: Dictionary) -> Array[int]:
	var tools := 0
	var collected := {}
	var rounds := 0
	var first := 0
	while true:
		var gained: Array[int] = []
		for chapter: int in logics:
			var logic: ChapterLogic = logics[chapter]
			for letter: String in logic.guaranteed(table[chapter], tools):
				var key := "%d%s" % [chapter, letter]
				if collected.has(key):
					continue
				collected[key] = true
				var item: int = table[chapter].get(letter, Item.Id.NONE)
				if item in Randomizer.PROGRESSION:
					gained.append(item)
		if gained.is_empty():
			break
		rounds += 1
		if rounds == 1:
			first = gained.size()
		for item: int in gained:
			tools = Item.collect(tools, item)
	return [rounds, first]


func _sorted(counts: Dictionary) -> String:
	var keys: Array = counts.keys()
	keys.sort()
	var parts: Array[String] = []
	for key: int in keys:
		parts.append("%d: %d" % [key, counts[key]])
	return ", ".join(parts)
