class_name Progress
## Progresso do jogo contínuo: os capítulos vencidos, as ferramentas e as
## melhorias, a vida máxima e os baús de coração e de ferramenta já abertos
## em cada capítulo. Fica num arquivo JSON na pasta do usuário.
##
## Um capítulo só conta quando o personagem toca a relíquia. Nessa hora o
## progresso é gravado, e a pedra de salvamento do mundo grava de novo e
## enche a vida. Sair de um capítulo no meio perde o que foi feito nele.
##
## Num capítulo já vencido, os baús de coração e de ferramenta começam
## abertos, para a vida máxima não crescer duas vezes. Os baús de chave
## começam fechados, porque as portas também, e a chave grande não vem de um
## capítulo para outro.
##
## Com "active" desligado, o capítulo é jogado avulso, a partir do treino, e
## nada é gravado.
##
## No modo randomizado (seed diferente de zero), o item de cada baú vem da
## distribuição da seed (progression/randomizer.gd), as três entradas do mundo
## abrem de início e cada baú de ferramenta, melhoria ou coração é gravado na
## hora em que abre, porque o jogador entra e sai das dungeons conforme acha
## itens. As chaves continuam valendo só na visita. O arquivo guarda o número
## da seed, e a distribuição é gerada de novo ao carregar.
##
## O cronômetro do jogo inteiro (run_ticks) conta desde o Novo jogo, no mundo
## e nos capítulos, para com a pausa e é gravado junto com o resto.

## Versão do arquivo. A 1 numerava os capítulos de 1 a 4, antes de o
## capítulo 1 virar o tutorial (2026-11-06), então um arquivo antigo é
## descartado.
const VERSION := 2
const BASE_HEALTH := 6

## Ligado durante o jogo contínuo. O treino joga um capítulo avulso.
static var active := false
## Capítulo de onde o personagem volta ao mundo, para aparecer na entrada
## dele. Zero põe o personagem na pedra de salvamento.
static var return_entrance := 0
## Arquivo de salvamento. O teste de fumaça usa outro, para não mexer no do
## jogador.
static var save_path := "user://save.json"

## Bit n ligado quando o capítulo n foi vencido.
static var chapters_done := 0
## Ferramentas e melhorias, nos bits de Item, sem a chave grande.
static var tools := 0
static var max_health := BASE_HEALTH
## Ticks de jogo desde o Novo jogo, para o cronômetro do jogo inteiro (pedido
## de Marcelo em 2026-11-07).
static var run_ticks := 0
## Número da seed do modo randomizado. Zero é o modo original.
static var seed := 0
## Distribuição da seed: item de cada baú, por número de capítulo e letra.
static var seed_items := {}
## Baús já abertos por capítulo: número do capítulo, em texto, para as letras
## dos baús.
static var opened := {}


static func start_new() -> void:
	active = true
	return_entrance = 0
	chapters_done = 0
	tools = 0
	max_health = BASE_HEALTH
	run_ticks = 0
	opened = {}
	seed = 0
	seed_items = {}


## Jogo novo no modo randomizado, com a distribuição da seed.
static func start_seed(seed_value: int) -> void:
	start_new()
	seed = seed_value
	seed_items = Randomizer.generate(seed_value)


static func is_done(chapter: int) -> bool:
	return (chapters_done & (1 << chapter)) != 0


## Todos os capítulos do mundo vencidos: a vitória.
static func all_done() -> bool:
	for chapter: int in range(1, ChapterData.count() + 1):
		if not is_done(chapter):
			return false
	return true


## O capítulo 1 está sempre aberto. Cada um dos outros abre quando o anterior
## foi vencido. No modo randomizado, todos abrem de início.
static func is_open(chapter: int) -> bool:
	return chapter <= 1 or is_done(chapter - 1) or seed != 0


## Item de um baú: o da seed no modo randomizado, senão o da tabela linear.
static func item_at(chapter: int, location: String, linear_item: int) -> int:
	if active and seed != 0 and seed_items.has(chapter):
		return seed_items[chapter].get(location, linear_item)
	return linear_item


static func was_opened(chapter: int, location: String) -> bool:
	var letters: String = opened.get(str(chapter), "")
	return letters.contains(location)


## Registra o capítulo vencido, com o que o personagem tem ao fim dele, e
## grava.
static func record_chapter(chapter: int, player: Player, chests: Array[Chest]) -> void:
	chapters_done |= 1 << chapter
	tools = player.tool_bits() & ~Item.bit(Item.Id.BOSS_KEY)
	max_health = player.max_health
	var letters: String = opened.get(str(chapter), "")
	for chest: Chest in chests:
		if chest.is_open and _persists(chest.item) and not letters.contains(chest.location_id):
			letters += chest.location_id
	opened[str(chapter)] = letters
	return_entrance = chapter
	save()


## No modo randomizado, grava um baú na hora em que abre, se o item dele
## fica: ferramenta, melhoria ou coração. A chave grande não fica, como as
## chaves pequenas, porque as portas fecham de novo ao sair da dungeon.
static func record_chest(chapter: int, chest: Chest, player: Player) -> void:
	if not _persists(chest.item):
		return
	tools = player.tool_bits() & ~Item.bit(Item.Id.BOSS_KEY)
	max_health = player.max_health
	var letters: String = opened.get(str(chapter), "")
	if not letters.contains(chest.location_id):
		letters += chest.location_id
	opened[str(chapter)] = letters
	save()


## Itens que não voltam ao baú num capítulo já vencido.
static func _persists(item: int) -> bool:
	return item == Item.Id.HEART or (item in Item.PERMANENT and item != Item.Id.BOSS_KEY)


static func exists() -> bool:
	return FileAccess.file_exists(save_path)


static func save() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("Não deu para gravar o progresso em %s." % save_path)
		return
	var data := {
		"version": VERSION,
		"chapters_done": chapters_done,
		"tools": tools,
		"max_health": max_health,
		"run_ticks": run_ticks,
		"seed": seed,
		"opened": opened,
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## Lê o arquivo e liga o jogo contínuo. Diz se conseguiu.
static func load_file() -> bool:
	if not exists():
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return false
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if not data is Dictionary or int(data.get("version", 0)) != VERSION:
		clear_file()
		return false
	start_new()
	chapters_done = int(data.get("chapters_done", 0))
	tools = int(data.get("tools", 0))
	max_health = int(data.get("max_health", BASE_HEALTH))
	run_ticks = int(data.get("run_ticks", 0))
	var saved_opened = data.get("opened", {})
	if saved_opened is Dictionary:
		opened = saved_opened
	seed = int(data.get("seed", 0))
	if seed != 0:
		seed_items = Randomizer.generate(seed)
	return true


static func clear_file() -> void:
	if exists():
		DirAccess.remove_absolute(save_path)
