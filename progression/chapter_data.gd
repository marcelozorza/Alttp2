class_name ChapterData
extends RefCounted
## Dados de um capítulo, lidos das constantes do arquivo de dados dele: o mapa
## em texto, o tipo de cada bloqueio, o item de cada baú e, se houver, as
## ferramentas com que o personagem chega (STARTING_TOOLS), que nos capítulos
## seguintes ao 2 são as três ferramentas já ganhas.
##
## Cada capítulo tem só um arquivo de dados, e a cena do capítulo é a mesma
## para todos. Para criar um capítulo novo, basta um arquivo de dados com as
## mesmas constantes e uma linha em SOURCES. O arquivo também declara GOAL e
## GOAL_TOOLS, que só tools/check_chapter.py lê, para garantir fora do Godot
## que o capítulo tem caminho até o chefe.

## Arquivo de dados de cada capítulo, na ordem do menu. Precisa ser preload: o
## nome da classe não vale como constante dentro de uma lista.
const SOURCES := [
	preload("res://world/chapter_one/chapter_one_data.gd"),
	preload("res://world/chapter_two/chapter_two_data.gd"),
	preload("res://world/chapter_three/chapter_three_data.gd"),
]

## Número do capítulo, a partir de 1.
var number := 1
var rows: Array = []
var blocks := {}
## Item de cada baú, pela letra do baú no mapa.
var items := {}
## Ferramentas com que o personagem chega, como Item.Id.
var starting_tools: Array = []


static func count() -> int:
	return SOURCES.size()


static func load_number(chapter: int) -> ChapterData:
	var source: Script = SOURCES[clampi(chapter, 1, SOURCES.size()) - 1]
	var constants := source.get_script_constant_map()
	var data := ChapterData.new()
	data.number = clampi(chapter, 1, SOURCES.size())
	data.rows = constants["MAP"]
	data.blocks = constants["BLOCKS"]
	data.items = constants["ITEMS"]
	data.starting_tools = constants.get("STARTING_TOOLS", [])
	return data
