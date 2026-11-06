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

const VERSION := 1
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
## Baús já abertos por capítulo: número do capítulo, em texto, para as letras
## dos baús.
static var opened := {}


static func start_new() -> void:
	active = true
	return_entrance = 0
	chapters_done = 0
	tools = 0
	max_health = BASE_HEALTH
	opened = {}


static func is_done(chapter: int) -> bool:
	return (chapters_done & (1 << chapter)) != 0


## O capítulo 1 está sempre aberto. Cada um dos outros abre quando o anterior
## foi vencido.
static func is_open(chapter: int) -> bool:
	return chapter <= 1 or is_done(chapter - 1)


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
	if not data is Dictionary:
		return false
	start_new()
	chapters_done = int(data.get("chapters_done", 0))
	tools = int(data.get("tools", 0))
	max_health = int(data.get("max_health", BASE_HEALTH))
	var saved_opened = data.get("opened", {})
	if saved_opened is Dictionary:
		opened = saved_opened
	return true


static func clear_file() -> void:
	if exists():
		DirAccess.remove_absolute(save_path)
