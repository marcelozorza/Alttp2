class_name ChapterData
extends RefCounted
## Dados de um capítulo, lidos das constantes do arquivo de dados dele: o mapa
## em texto, o tipo de cada bloqueio, a distribuição linear, o alvo e as
## ferramentas que o alvo exige.
##
## Cada capítulo tem só um arquivo de dados, e a cena do capítulo é a mesma
## para todos. Para criar um capítulo novo, basta um arquivo de dados com as
## mesmas constantes e uma linha em SOURCES.

## Arquivo de dados de cada capítulo, na ordem do menu. Precisa ser preload: o
## nome da classe não vale como constante dentro de uma lista.
const SOURCES := [
	preload("res://world/chapter_one/chapter_one_data.gd"),
	preload("res://world/chapter_two/chapter_two_data.gd"),
]

## Número do capítulo, a partir de 1.
var number := 1
var rows: Array = []
var blocks := {}
var linear := {}
var goal := ""
## Ferramentas que o alvo exige, como conjunto de bits de Item.
var goal_tools := 0


static func count() -> int:
	return SOURCES.size()


static func load_number(chapter: int) -> ChapterData:
	var source: Script = SOURCES[clampi(chapter, 1, SOURCES.size()) - 1]
	var constants := source.get_script_constant_map()
	var data := ChapterData.new()
	data.number = clampi(chapter, 1, SOURCES.size())
	data.rows = constants["MAP"]
	data.blocks = constants["BLOCKS"]
	data.linear = constants["LINEAR"]
	data.goal = constants["GOAL"]
	for id: int in constants["GOAL_TOOLS"]:
		data.goal_tools |= Item.bit(id)
	return data
