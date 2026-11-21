class_name ChapterData
extends RefCounted
## Dados de um capítulo, lidos das constantes do arquivo de dados dele: o mapa
## em texto, o tipo de cada bloqueio, o item de cada baú e, se houver, as
## ferramentas com que o personagem chega (STARTING_TOOLS), que nos capítulos
## seguintes ao 1 são as três ferramentas já ganhas, e as salas maiores que
## uma tela (ROOMS), retângulos em salas de 20 por 10 casas.
##
## O tutorial é o antigo capítulo 1, jogado fora do mundo, e tem o número 0.
##
## Cada capítulo tem só um arquivo de dados, e a cena do capítulo é a mesma
## para todos. Para criar um capítulo novo, basta um arquivo de dados com as
## mesmas constantes e uma linha em SOURCES. O arquivo também declara GOAL e
## GOAL_TOOLS, a casa do chefe e o que ele exige, que tools/check_chapter.py
## lê para garantir fora do Godot que o capítulo tem caminho até o chefe, e
## que o gerador de seeds lê pela mesma lógica (progression/chapter_logic.gd).

## Arquivo de dados de cada capítulo, na ordem do mundo. Precisa ser preload: o
## nome da classe não vale como constante dentro de uma lista.
const SOURCES := [
	preload("res://world/chapter_one/chapter_one_data.gd"),
	preload("res://world/chapter_two/chapter_two_data.gd"),
	preload("res://world/chapter_three/chapter_three_data.gd"),
]
const TUTORIAL_SOURCE := preload("res://world/tutorial/tutorial_data.gd")
const TUTORIAL := 0
## A galeria, a área de testes com todos os elementos do jogo, fora do mundo e
## das seeds (world/gallery/gallery_data.gd).
const GALLERY_SOURCE := preload("res://world/gallery/gallery_data.gd")
const GALLERY := -1
## Dungeons de teste, do tamanho da geleira, abertas só pelo menu de título
## para Marcelo experimentar (pedido de 2026-11-21). Fora do mundo, das seeds
## e da progressão. Números negativos a partir de -2, nome no menu ao lado.
const TEST_SOURCES := {
	-2: preload("res://world/test_dungeons/fortress/fortress_data.gd"),
	-3: preload("res://world/test_dungeons/cavern/cavern_data.gd"),
	-4: preload("res://world/test_dungeons/temple/temple_data.gd"),
	-5: preload("res://world/test_dungeons/frozen_lake/frozen_lake_data.gd"),
	-6: preload("res://world/test_dungeons/tower/tower_data.gd"),
	-7: preload("res://world/test_dungeons/garden/garden_data.gd"),
}
const TEST_NAMES := {
	-2: "Fortaleza",
	-3: "Caverna",
	-4: "Templo",
	-5: "Lago gelado",
	-6: "Torre",
	-7: "Jardim",
}
## Número do capítulo, a partir de 1. Zero é o tutorial.
var number := 1
var rows: Array = []
var blocks := {}
## Item de cada baú, pela letra do baú no mapa.
var items := {}
## Ferramentas com que o personagem chega, como Item.Id.
var starting_tools: Array = []
## Salas maiores que uma tela, como Rect2i em unidades de sala. As outras
## salas têm uma tela.
var rooms: Array = []
## Casa do chefe e as ferramentas que ele exige, como Item.Id.
var goal := ""
var goal_tools: Array = []
## Tema de cada sala de uma tela (Vector2i para nome de tema), quando o
## capítulo mistura temas, como a galeria. Vazio, o tema vem do número.
var room_themes := {}
## Texto de cada placa de mensagem ("?" no mapa), pela casa dela.
var messages := {}
## O personagem não perde vida, como na galeria.
var no_damage := false
## Levas de inimigos de uma arena, pela tela dela: cada leva é um texto com
## um caractere de inimigo por marcador de nascimento.
var waves := {}


## Verdadeiro para as dungeons de teste do menu (TEST_SOURCES).
static func is_test(chapter: int) -> bool:
	return TEST_SOURCES.has(chapter)


static func count() -> int:
	return SOURCES.size()


## Carrega o capítulo pelo número, ou o tutorial com TUTORIAL.
static func load_number(chapter: int) -> ChapterData:
	if chapter == GALLERY:
		return from_source(GALLERY_SOURCE, GALLERY)
	if chapter == TUTORIAL:
		return from_source(TUTORIAL_SOURCE, TUTORIAL)
	if TEST_SOURCES.has(chapter):
		return from_source(TEST_SOURCES[chapter], chapter)
	var number := clampi(chapter, 1, SOURCES.size())
	return from_source(SOURCES[number - 1], number)


## Lê as constantes de um arquivo de dados. Os testes usam esta função para
## abrir um capítulo que não está no jogo (tools/bench/bench_data.gd).
static func from_source(source: Script, chapter: int) -> ChapterData:
	var data := ChapterData.new()
	data.number = chapter
	var constants := source.get_script_constant_map()
	data.rows = constants["MAP"]
	data.blocks = constants["BLOCKS"]
	data.items = constants["ITEMS"]
	data.starting_tools = constants.get("STARTING_TOOLS", [])
	data.rooms = constants.get("ROOMS", [])
	data.goal = constants.get("GOAL", "")
	data.goal_tools = constants.get("GOAL_TOOLS", [])
	data.room_themes = constants.get("ROOM_THEMES", {})
	data.messages = constants.get("MESSAGES", {})
	data.no_damage = constants.get("NO_DAMAGE", false)
	data.waves = constants.get("WAVES", {})
	return data
