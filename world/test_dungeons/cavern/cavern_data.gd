class_name TestCavernData
## Dungeon de teste "Caverna", do tamanho da geleira: 15 salas de uma tela, de
## 20 por 10 casas, numa grade de 5 por 5. Aberta só pelo menu de título, fora
## do mundo, das seeds e da progressão. O mapa traz só a geometria e as vagas
## de bloqueios e de baús, na legenda de ChapterMap.
##
## A caverna é uma espiral: da entrada, no sul, o caminho dá a volta por fora
## no sentido horário e se enrola até o colosso, no centro. A espiral ocupa as
## colunas 0 a 3 e as linhas 1 a 4 da grade, e o resto fica vazio. O personagem
## chega com a bomba, a chama e a mola (STARTING_TOOLS) e acha a mola forte na
## forja. Há sete paredes rachadas para a bomba, em portas e em nichos de baú.
## O chão sobe um nível no degrau da coluna oeste, desce de volta na forja e
## sobe dois de uma vez na escadaria, que só a mola forte vence. Dois atalhos
## voltam ao começo: as grades da antessala e da câmara, que abrem por dentro,
## com o bloco pesado sobre o interruptor, e ligam o fim da espiral à entrada
## e à subida oeste. Cada bloqueio de porta fica uma casa para dentro da sala.
##
## Salas, na ordem da espiral: entrada (2,4), galeria das rachaduras (1,4),
## gruta oeste (0,4), subida oeste (0,3), degrau (0,2), canto noroeste (0,1),
## galeria norte (1,1), sala do bloco (2,1), canto nordeste (3,1), forja
## (3,2), poço leste (3,3), antessala (2,3), câmara da chave grande (1,3),
## escadaria (1,2) e o colosso (2,2).

# O mapa tem 100 casas de largura, uma linha por fileira de casas.
# gdlint: disable=max-line-length
const MAP := [
	"                                                                                                    ",
	"                                                                                                    ",
	"                                                                                                    ",
	"                                                                                                    ",
	"                                                                                                    ",
	"                                                                                                    ",
	"                                                                                                    ",
	"                                                                                                    ",
	"                                                                                                    ",
	"                                                                                                    ",
	"################################################################################                    ",
	"#::::::::::::::::::##::::::::::::::::::##::::::::::::#C#:::##::::::::::::::::::#                    ",
	"#::::::::::::y:::::##:::::s::::::::::::##:::::m::::::#:#:::##::::s::::::::s::::#                    ",
	"#::::u::::::::::::###:::::::::::::::::###::::::::::::#9#::###::::::::::::::::::#                    ",
	"#:::::::::::::::::7::::::::::##:::::::8:::::::::::::::::::k::::::::::::::::::::#                    ",
	"#:::::::::::::::::7::::::::::##:::::::8:::::::::::::::::::k::::::::::::::::::::#                    ",
	"#:::##::::::m:::::###:::::::::::::::::###::::::::::::::u::###::::z::::::::m::::#                    ",
	"#:::##:::::::::::::##:::::::::::x::::::##::::=:::0:::::::::##::::::::::::::::::#                    ",
	"#::::::::::::::::::##::::::::::::::::::##::::::::::::::::::##:::::::#bb#:::::::#                    ",
	"#########::##########################################################::#########                    ",
	"#########::##########################################################::#########                    ",
	"#:::::::#66#:::::::##^^^^^^^^^^^^^^^^^^##^^^^^^^^^^^^^^^^^^##::::::::::::::::::#                    ",
	"#::::::::::::::B:::##^^^^s^^^^^^^s^^^^^##^^^^^^^^^^^^^^^^^^##::::y::::::::m::::#                    ",
	"#:::s::::::::::::::##^^^^^^^^^^^^^^^^^###^^^^^^^^^^^^^^^^^^##::::::::::::::::::#                    ",
	"#::::::::::::::::::##^^^^^^^^m^^^^^^^^n^^^^^^^^^^^$^^^^^^^^##dddddddddddddddddd#                    ",
	"#aaaaaaaaaaaaaaaaaa##^^^^^^^^^^^^^^^^^n^^^^^^^^^^^^^^^^^^^^##..................#                    ",
	"#..................##ooooooooooooooooo###^^^^^^^^^^^^^^^^^^##...F..............#                    ",
	"#.....m.......u....##ooooooooooooooooo###^^^^^^^^^^^^^^^^^^##.............x....#                    ",
	"#..................##..................##^^^^^^^^^^^^^^^^^^##..................#                    ",
	"#########..##################..######################################..#########                    ",
	"#########..##################..######################################..#########                    ",
	"#..#I#..#44#.......##.......#jj##^G^^#.##..................##............#^D^^^#                    ",
	"#..#.#........x....##..=..0.....#^^^^#.##...=...0......E...##....u.......#^^^^^#                    ",
	"#..#5#.............###..........#qqqq#.###.................###...........#fffff#                    ",
	"#....................l..........#qqqq#...g...................e...........#fffff#                    ",
	"#....................l...................g...................e.................#                    ",
	"#..................###....########.....###...m........x....###.................#                    ",
	"#....m........#....##..m..#.J....#..u..##..................##.....z.....m......#                    ",
	"#..................##.....#......#.....##.......#hh#.......##..................#                    ",
	"#########..##################..##################..#############################                    ",
	"#########..##################..##################..#########                                        ",
	"#.......#33#.......##.......#22#.......##............#^H^^^#                                        ",
	"#...A..............##....m.........#...##............#^^^^^#                                        ",
	"#............y.....###.................##............#ppppp#                                        ",
	"#....................1...............................#ppppp#                                        ",
	"#....................1.....................................#                                        ",
	"#.....m............###.................##.........@........#                                        ",
	"#..##.........##...##...#........u.....##..................#                                        ",
	"#..................##..................##..................#                                        ",
	"############################################################                                        ",
]
# gdlint: enable=max-line-length

## Ferramentas com que o personagem chega, dos capítulos anteriores.
const STARTING_TOOLS := [Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING]

## Tipo de cada vaga de bloqueio do mapa.
const BLOCKS := {
	"1": ChapterMap.Block.CRACKED,
	"2": ChapterMap.Block.CRACKED,
	"3": ChapterMap.Block.LOCKED,
	"4": ChapterMap.Block.ICE,
	"5": ChapterMap.Block.CRACKED,
	"6": ChapterMap.Block.CRACKED,
	"7": ChapterMap.Block.LOCKED,
	"8": ChapterMap.Block.CRACKED,
	"9": ChapterMap.Block.CRACKED,
	"a": ChapterMap.Block.LEDGE,
	"b": ChapterMap.Block.LOCKED,
	"d": ChapterMap.Block.LEDGE,
	"e": ChapterMap.Block.LOCKED,
	"f": ChapterMap.Block.TALL_LEDGE,
	"g": ChapterMap.Block.CRACKED,
	"h": ChapterMap.Block.GATE,
	"j": ChapterMap.Block.LOCKED,
	"k": ChapterMap.Block.GATE,
	"l": ChapterMap.Block.GATE,
	"n": ChapterMap.Block.BOSS_DOOR,
	"o": ChapterMap.Block.TALL_LEDGE,
	"p": ChapterMap.Block.TALL_LEDGE,
	"q": ChapterMap.Block.TALL_LEDGE,
}

## Item de cada baú. São 5 chaves para 5 portas trancadas, uma atrás da outra
## na espiral: A na gruta oeste, B no alto do degrau, C num nicho rachado da
## sala do bloco, D na plataforma alta do poço leste, que pede a mola forte, e
## E na antessala. A mola forte F fica na forja e a chave grande G, na
## plataforma alta da câmara. Os corações: H na plataforma alta da entrada, I
## num nicho rachado da subida oeste e J no bolso secreto da câmara, que só se
## alcança pela parede rachada ao norte da galeria das rachaduras.
const ITEMS := {
	"A": Item.Id.KEY,
	"B": Item.Id.KEY,
	"C": Item.Id.KEY,
	"D": Item.Id.KEY,
	"E": Item.Id.KEY,
	"F": Item.Id.STRONG_SPRING,
	"G": Item.Id.BOSS_KEY,
	"H": Item.Id.HEART,
	"I": Item.Id.HEART,
	"J": Item.Id.HEART,
}

## Tema de cada sala de uma tela, pela posição da sala: a caverna inteira é
## de pedra.
const ROOM_THEMES := {
	Vector2i(2, 4): "stone",
	Vector2i(1, 4): "stone",
	Vector2i(0, 4): "stone",
	Vector2i(0, 3): "stone",
	Vector2i(0, 2): "stone",
	Vector2i(0, 1): "stone",
	Vector2i(1, 1): "stone",
	Vector2i(2, 1): "stone",
	Vector2i(3, 1): "stone",
	Vector2i(3, 2): "stone",
	Vector2i(3, 3): "stone",
	Vector2i(2, 3): "stone",
	Vector2i(1, 3): "stone",
	Vector2i(1, 2): "stone",
	Vector2i(2, 2): "stone",
}

## Casa do alvo, o colosso, e as ferramentas que ele exige, como no capítulo
## 3. Só tools/check_chapter.py lê isto.
const GOAL := "$"
const GOAL_TOOLS := [Item.Id.STRONG_SPRING, Item.Id.BOMB]
