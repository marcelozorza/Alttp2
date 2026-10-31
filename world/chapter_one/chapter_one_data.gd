class_name ChapterOneData
## Dados do capítulo 1. O mapa traz só a geometria e as vagas de bloqueios e de
## baús, na legenda de ChapterMap. O tipo de cada bloqueio e o item de cada baú
## ficam separados, para que a seed redistribua os itens sem mexer no mapa.
##
## São 8 salas de uma tela, de 20 por 10 casas, numa grade de 3 por 4. As
## portas ficam no meio das paredes e têm duas casas de largura.

const MAP := [
	"                    ####################",
	"                    #..................#",
	"                    #..................#",
	"                    #.........*........#",
	"                    #..................#",
	"                    #..................#",
	"                    #..................#",
	"                    #..................#",
	"                    #..................#",
	"                    #########..#########",
	"                    #########88#########",
	"                    #..................#",
	"                    #.........l........#",
	"                    #..................#",
	"                    #########99#########",
	"                    #..................#",
	"                    #....h........i....#",
	"                    #..................#",
	"                    #..................#",
	"                    #########..#########",
	"#############################..#############################",
	"#..................##::::::::::::::::::##..........#::::F::#",
	"#...D..............##::::::::::::::::::##..........#:::::::#",
	"#..................##555555555555555555##..........#7777777#",
	"#.....l................................4...................#",
	"#..............l.......................4...................#",
	"#..................##....l.............##...E....i.........#",
	"#..................##..................##.............l....#",
	"#..................##..................##..................#",
	"#########..##################..##################..#########",
	"#########33##################..##################66#########",
	"#..................##..................##..................#",
	"#.....l............##..................##...A..............#",
	"#..................##....l.......c.....##.........h........#",
	"#...................1......................................#",
	"#...................1..................................#####",
	"#...C..............##..................##..............2...#",
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
	"6": ChapterMap.Block.LEDGE,
	"7": ChapterMap.Block.LEDGE,
	"8": ChapterMap.Block.CRACKED,
	"9": ChapterMap.Block.ICE,
}

## Distribuição linear, a ordem pensada para ensinar: bomba, chama e mola. Cada
## bloqueio aparece antes da ferramenta que o resolve. É só mais uma seed.
const LINEAR := {
	"A": Item.Id.BOMB,
	"B": Item.Id.HEART,
	"C": Item.Id.FIRE,
	"D": Item.Id.HEART,
	"E": Item.Id.SPRING,
	"F": Item.Id.HEART,
}

## Casa do alvo do capítulo: o chefe.
const GOAL := "*"
## Ferramentas exigidas para vencer o chefe: a chama quebra a casca e a mola
## escapa das ondas.
const GOAL_TOOLS := [Item.Id.FIRE, Item.Id.SPRING]
