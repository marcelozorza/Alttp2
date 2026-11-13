class_name Progress
## Progresso do jogo contínuo: os capítulos vencidos, as ferramentas e as
## melhorias, a vida máxima e os baús de coração e de ferramenta já abertos
## em cada capítulo. Vale só durante a sessão: o jogo não tem salvamento em
## arquivo (decisão de Marcelo em 2026-11-13), vai-se até o fim toda vez.
##
## Um capítulo só conta quando o personagem toca a relíquia. Nessa hora o
## progresso é registrado. A pedra do mundo enche a vida e marca o ponto de
## volta da sessão (checkpoint). Sair de um capítulo no meio perde o que foi
## feito nele.
##
## Num capítulo já vencido, os baús de coração e de ferramenta começam
## abertos, para a vida máxima não crescer duas vezes. Os baús de chave
## começam fechados, porque as portas também, e a chave grande não vem de um
## capítulo para outro.
##
## Com "active" desligado, o capítulo é jogado avulso, a partir do treino, e
## nada é registrado.
##
## No modo randomizado (seed diferente de zero), o item de cada baú vem da
## distribuição da seed (progression/randomizer.gd), as três entradas do mundo
## abrem de início e cada baú de ferramenta, melhoria ou coração é registrado na
## hora em que abre, porque o jogador entra e sai das dungeons conforme acha
## itens. A dungeon fica como o jogador a deixou ao sair (dungeons): portas,
## bloqueios, baús, chaves na mão, salas limpas e mapa.
##
## O cronômetro do jogo inteiro (run_ticks) conta desde o Novo jogo, no mundo
## e nos capítulos, e para com a pausa.

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
## Estado guardado na última pedra de salvamento tocada nesta sessão. Só na
## memória: a derrota no modo randomizado volta a ele (restore_checkpoint).
static var checkpoint := {}


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
	checkpoint = {}


## Jogo novo no modo randomizado, com a distribuição da seed.
static func start_seed(seed_value: int) -> void:
	start_new()
	seed = seed_value
	seed_items = Randomizer.generate(seed_value)


## No modo randomizado, a morte sem ponto de volta perde tudo: a mesma seed
## recomeça do zero (decisão de Marcelo em 2026-11-07, jogando).
static func restart_seed() -> void:
	start_seed(seed)


## Guarda o estado atual como ponto de volta. Chamado pela pedra de salvamento.
static func mark_checkpoint() -> void:
	checkpoint = {
		"chapters_done": chapters_done,
		"tools": tools,
		"max_health": max_health,
		"opened": opened.duplicate(true),
		"dungeons": dungeons.duplicate(true),
	}


## Derrota no modo randomizado: volta ao estado da última pedra tocada nesta
## sessão, ou ao começo da semente se nenhuma foi tocada. O relógio da partida
## não volta. Decisão de Marcelo em 2026-11-13, no lugar de perder tudo.
static func restore_checkpoint() -> void:
	if checkpoint.is_empty():
		restart_seed()
		return
	chapters_done = checkpoint["chapters_done"]
	tools = checkpoint["tools"]
	max_health = checkpoint["max_health"]
	opened = checkpoint["opened"].duplicate(true)
	dungeons = checkpoint["dungeons"].duplicate(true)
	return_entrance = NO_ENTRANCE


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


## Guarda o estado de uma dungeon na saída.
static func record_dungeon(chapter: int, state: Dictionary) -> void:
	dungeons[str(chapter)] = state


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


## Registra o capítulo vencido, com o que o personagem tem ao fim dele.
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


## Itens que não voltam ao baú num capítulo já vencido.
static func _persists(item: int) -> bool:
	return item == Item.Id.HEART or (item in Item.PERMANENT and item != Item.Id.BOSS_KEY)
