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
## itens. A dungeon fica como o jogador a deixou ao sair (dungeons): portas,
## bloqueios, baús, chaves na mão, salas limpas e mapa. O arquivo guarda o número
## da seed, e a distribuição é gerada de novo ao carregar.
##
## O cronômetro do jogo inteiro (run_ticks) conta desde o Novo jogo, no mundo
## e nos capítulos, para com a pausa e é gravado junto com o resto.

## Versão do arquivo. A 1 numerava os capítulos de 1 a 4, antes de o
## capítulo 1 virar o tutorial (2026-11-06), então um arquivo antigo é
## descartado.
const VERSION := 2
const BASE_HEALTH := 6
## Sem entrada de volta: o personagem aparece no início do mundo num jogo
## novo, ou na pedra de salvamento num jogo já começado.
const NO_ENTRANCE := -1

## Ligado durante o jogo contínuo. O treino joga um capítulo avulso.
static var active := false
## Capítulo de onde o personagem volta ao mundo, para aparecer na entrada
## dele, ou NO_ENTRANCE.
static var return_entrance := NO_ENTRANCE
## Ligado enquanto o personagem está na dungeon de teste a partir do mundo:
## ela é um treino, com as ferramentas e a vida dela mesma, e nada do que
## acontece lá dentro passa para o jogo. Só fica gravado que foi vencida.
static var practice := false
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
## Como cada dungeon ficou quando o personagem saiu dela, no modo
## randomizado, por número do capítulo em texto: baús abertos, bloqueios
## removidos, blocos travados, salas limpas, salas visitadas e chaves na mão
## (ver Chapter._dungeon_state). Marcelo saiu de uma dungeon para buscar a
## bomba em outra e, na volta, achou portas, inimigos e mapa zerados: "tudo
## fica como deixei" (2026-11-13).
static var dungeons := {}


static func start_new() -> void:
	active = true
	practice = false
	return_entrance = NO_ENTRANCE
	chapters_done = 0
	tools = 0
	max_health = BASE_HEALTH
	run_ticks = 0
	opened = {}
	dungeons = {}
	seed = 0
	seed_items = {}


## Jogo novo no modo randomizado, com a distribuição da seed.
static func start_seed(seed_value: int) -> void:
	start_new()
	seed = seed_value
	seed_items = Randomizer.generate(seed_value)


## No modo randomizado, a morte perde tudo: a mesma seed recomeça do zero, e o
## arquivo é gravado assim na hora, para que sair do jogo na tela de derrota
## não salve a partida (decisão de Marcelo em 2026-11-07, jogando).
static func restart_seed() -> void:
	start_seed(seed)
	save()


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


## Estado guardado de uma dungeon, ou vazio se o personagem ainda não saiu
## dela nesta partida.
static func dungeon_state(chapter: int) -> Dictionary:
	var state = dungeons.get(str(chapter), {})
	return state if state is Dictionary else {}


## Guarda o estado de uma dungeon na saída e grava.
static func record_dungeon(chapter: int, state: Dictionary) -> void:
	dungeons[str(chapter)] = state
	save()


static func was_opened(chapter: int, location: String) -> bool:
	var letters: String = opened.get(str(chapter), "")
	return letters.contains(location)


## Se o jogo já começou: algum capítulo vencido, algum baú gravado ou algum
## tempo de relógio. Ao continuar, o personagem aparece na pedra de salvamento.
static func has_started() -> bool:
	return chapters_done != 0 or run_ticks > 0 or not opened.is_empty()


## Registra a dungeon de teste vencida. Ferramentas, vida e baús não mudam.
static func record_practice() -> void:
	chapters_done |= 1 << ChapterData.TUTORIAL
	return_entrance = ChapterData.TUTORIAL
	save()


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
## fica: ferramenta, melhoria ou coração. As chaves ficam com o estado da
## dungeon, gravado na saída (record_dungeon).
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
		"dungeons": dungeons,
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
	var saved_dungeons = data.get("dungeons", {})
	if saved_dungeons is Dictionary:
		dungeons = saved_dungeons
	seed = int(data.get("seed", 0))
	if seed != 0:
		seed_items = Randomizer.generate(seed)
	return true


static func clear_file() -> void:
	if exists():
		DirAccess.remove_absolute(save_path)
