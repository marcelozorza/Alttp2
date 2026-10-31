class_name Randomizer
## Gera distribuições de itens com caminho garantido.
##
## Embaralha os itens da distribuição linear entre os mesmos baús e só aceita
## o que a lógica do mapa considera vencível. A mesma seed gera sempre a mesma
## distribuição, em qualquer máquina.

## Tentativas antes de desistir e usar a distribuição linear.
const MAX_ATTEMPTS := 1000


static func shuffled(
	map: ChapterMap, linear: Dictionary, seed_value: int, goal: String, goal_tools: int
) -> Dictionary:
	var locations: Array = linear.keys()
	locations.sort()
	var items: Array = []
	for location: String in locations:
		items.append(linear[location])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for _attempt: int in MAX_ATTEMPTS:
		for i: int in range(items.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var swap: Variant = items[i]
			items[i] = items[j]
			items[j] = swap
		var distribution := {}
		for i: int in locations.size():
			distribution[locations[i]] = items[i]
		if map.is_beatable(distribution, goal, goal_tools):
			return distribution
	push_error("Nenhuma distribuição vencível para a seed %d." % seed_value)
	return linear.duplicate()
