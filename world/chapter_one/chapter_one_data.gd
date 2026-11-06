class_name ChapterOneData
## Dados do capítulo 1. O mapa traz só a geometria e as vagas de bloqueios e de
## baús, na legenda de ChapterMap. O tipo de cada bloqueio e o item de cada baú
## ficam em tabelas separadas do mapa.
##
## São 8 salas de uma tela, de 20 por 10 casas, numa grade de 3 por 4. As
## portas ficam no meio das paredes e têm duas casas de largura. Um bloqueio
## de porta fica uma casa para dentro da sala, num nicho entre duas paredes,
## para aparecer inteiro na tela e não na beira dela.

const MAP := [
	"                    ####################",
	"                    #::::::::::::::::::#",
	"                    #::::::::::::::::::#",
	"                    #:::::::::*::::::::#",
	"                    #::::::::::::::::::#",
	"                    #::::::::::::::::::#",
	"                    #::::::::::::::::::#",
	"                    #::::::::::::::::::#",
	"                    #::::::::::::::::::#",
	"                    #########::#########",
	"                    #########::#########",
	"                    #:::::::#88#:::::::#",
	"                    #:::::::::m::::::::#",
	"                    #::::::::::::::::::#",
	"                    #########99#########",
	"                    #::::::::::::::::::#",
	"                    #::::u::::::::i::::#",
	"                    #::::::::::::::::::#",
	"                    #::::::::::::::::::#",
	"                    #########::#########",
	"#############################::#############################",
	"#..................##::::::::::::::::::##..........#::::F::#",
	"#...D..............##::::::::::::::::::##..........#:::::::#",
	"#..................##55555555555555555###..........#7777777#",
	"#.....m...............................4....................#",
	"#..............m......................4....................#",
	"#..................##....m............###...E....i.........#",
	"#..................##..................##.............m....#",
	"#..................##..................##..................#",
	"#########..##################..##################..#########",
	"#########..##################..##################..#########",
	"#.......#33#.......##..................##.......#66#.......#",
	"#.....m............##..................##...A..............#",
	"#..................###...m.......c.....##.........u........#",
	"#....................1.....................................#",
	"#....................1.................................#####",
	"#...C..............###.................##..............2...#",
	"#............i.....##.........@........##..............2.B.#",
	"#..................##..................##..............#...#",
	"############################################################",
]

## Tipo de cada vaga de bloqueio do mapa.
const BLOCKS := {
	"1": ChapterMap.Block.CRACKED,
	"2": ChapterMap.Block.CRACKED,
	"3": ChapterMap.Block.ICE,
	"4": ChapterMap.Block.ICE,
	"5": ChapterMap.Block.LEDGE,
	"6": ChapterMap.Block.ICE,
	"7": ChapterMap.Block.LEDGE,
	"8": ChapterMap.Block.CRACKED,
	"9": ChapterMap.Block.ICE,
}

## Item de cada baú, na ordem pensada para ensinar: bomba, chama e mola. Cada
## bloqueio aparece antes da ferramenta que o resolve.
const ITEMS := {
	"A": Item.Id.BOMB,
	"B": Item.Id.HEART,
	"C": Item.Id.FIRE,
	"D": Item.Id.HEART,
	"E": Item.Id.SPRING,
	"F": Item.Id.HEART,
}

## Casa do alvo do capítulo, o chefe, e as ferramentas que ele exige: a chama
## quebra a casca e a mola escapa das ondas. Só tools/check_chapter.py lê isto.
const GOAL := "*"
const GOAL_TOOLS := [Item.Id.FIRE, Item.Id.SPRING]
