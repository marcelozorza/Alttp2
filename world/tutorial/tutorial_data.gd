class_name TutorialData
## Dados do tutorial, o antigo capítulo 1, jogado fora do mundo a partir do
## menu de título (decisão de Marcelo em 2026-11-06). O mapa traz só a
## geometria e as vagas de bloqueios e de
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
	"                    #:::::::?:m::::::::#",
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
	"#..................##.........?..y.....##.....?.......m....#",
	"#..................##..................##..................#",
	"#########..##################..##################..#########",
	"#########..##################..##################..#########",
	"#.......#33#.......##########aa##########.......#66#.......#",
	"#.....m............##..=...............##...A..............#",
	"#..................###...m.............##.........u........#",
	"#................?...1........................?............#",
	"#....................1........?........................#####",
	"#...C..............###.0...............##..............2...#",
	"#............i.....##....?....@........##..............2.B.#",
	"#..................##..................##..............#...#",
	"############################################################",
]

## Tipo de cada vaga de bloqueio do mapa.
const BLOCKS := {
	"a": ChapterMap.Block.GATE,
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

## Texto de cada placa de mensagem ("?" no mapa), pela casa dela. As placas
## explicam o jogo passo a passo, sem parar o jogador (pedido de Marcelo em
## 2026-11-10): os bloqueios e os itens, o bloco e o botão, o mapa, o ossinho,
## a diferença entre o jogo original e o Randomizado, e o chefe.
const MESSAGES := {
	Vector2i(30, 35):
	"Toda dungeon tem gelo, porta trancada, parede rachada e lugar alto. Cada um pede um item.",
	Vector2i(25, 37):
	"Empurre o bloco até o botão do chão. Com o bloco em cima, a grade fica aberta.",
	Vector2i(46, 34):
	"Cada item que você achar ganha um botão. Viu um bloqueio antes? Volte lá com o item.",
	Vector2i(30, 27):
	"START abre o mapa, com os baús, as portas e os bloqueios das salas em que você já entrou.",
	Vector2i(17, 34): "Inimigos às vezes deixam um ossinho. O ossinho cura.",
	Vector2i(46, 27):
	"Aqui, cada item fica sempre no mesmo baú. No Randomizado, uma semente embaralha os itens.",
	Vector2i(28, 12): "O chefe pede os itens desta dungeon. Use tudo o que você achou.",
}
