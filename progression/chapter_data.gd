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


static func count() -> int:
	return SOURCES.size()


## Carrega o capítulo pelo número, ou o tutorial com TUTORIAL.
static func load_number(chapter: int) -> ChapterData:
	var data := ChapterData.new()
	var source: Script = TUTORIAL_SOURCE
	if chapter != TUTORIAL:
		data.number = clampi(chapter, 1, SOURCES.size())
		source = SOURCES[data.number - 1]
	else:
		data.number = TUTORIAL
	var constants := source.get_script_constant_map()
	data.rows = constants["MAP"]
	data.blocks = constants["BLOCKS"]
	data.items = constants["ITEMS"]
	data.starting_tools = constants.get("STARTING_TOOLS", [])
	data.rooms = constants.get("ROOMS", [])
	data.goal = constants.get("GOAL", "")
	data.goal_tools = constants.get("GOAL_TOOLS", [])
	return data
