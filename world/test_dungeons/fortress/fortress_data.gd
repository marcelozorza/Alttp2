class_name TestFortressData
## Dungeon de teste "fortaleza": um pátio central cercado por alas altas, com
## grade de interruptor e bloco pesado. O mapa traz só a geometria e as vagas
## de bloqueios e de baús, na legenda de ChapterMap. O tipo de cada bloqueio e
## o item de cada baú ficam em tabelas separadas do mapa.
##
## São 15 salas de uma tela, de 20 por 10 casas, numa grade de 5 por 5, todas
## com o tema de castelo (ROOM_THEMES). O personagem chega com a bomba, a
## chama e a mola (STARTING_TOOLS). A melhoria daqui é a mola forte, na torre
## noroeste, que sobe o degrau duplo da torre nordeste, onde fica a chave
## grande. Cada bloqueio de porta fica uma casa para dentro da sala, num
## nicho, e toda área alta tem parede dos lados: só se sobe pelo degrau.
##
## Salas: portão (2,4); arsenal (1,3), casa da guarda (2,3) e capela (3,3);
## adega (0,2), pátio (2,2) e cofre (4,2); base da torre oeste (0,1), ala
## oeste (1,1), antessala (2,1), ala leste (3,1) e base da torre leste (4,1);
## torre noroeste (0,0), sala do trono (2,0) e torre nordeste (4,0).
##
## Caminho: do portão à casa da guarda, onde a bomba abre o arsenal (chave) e
## a chama abre a capela (coração). A chave abre a porta do pátio para a
## antessala. Dali, a oeste, a ala oeste leva à torre noroeste (mola forte) e
## à adega (chave, atrás de parede rachada). A leste, o bloco pesado sobre o
## interruptor abre a grade da ala leste, e a segunda chave abre a base da
## torre leste. A mola forte sobe à chave grande na torre nordeste, e a chave
## grande abre a sala do trono, onde espera a sentinela.

# O mapa tem 100 casas de largura, uma linha por fileira de casas.
# gdlint: disable=max-line-length
const MAP := [
	"####################                    ####################                    ####################",
	"#::::::::F:::::::::#                    #..................#                    #^^^^^^^^I^^^^^^^^^#",
	"#::::::::::::::::::#                    #..................#                    #^^^^^^^^^^^^^^^^^^#",
	"#aaaaaaaaaaaaaaaaaa#                    #.........&........#                    #dddddddddddddddddd#",
	"#..................#                    #..................#                    #dddddddddddddddddd#",
	"#...u.........u....#                    #..................#                    #..................#",
	"#..................#                    #..................#                    #....u.......u.....#",
	"#..................#                    #..................#                    #..................#",
	"#..................#                    #..................#                    #..................#",
	"#########..#########                    #########..#########                    #########..#########",
	"#########..######################################..######################################..#########",
	"#..................##:::::::E::::::::::##.......#66#.......##..................##..................#",
	"#..................##::::::::::::::::::##..................##......H...........##..................#",
	"#..................##888888888888888888##.................###.................###..................#",
	"#.........................................................7...................b....................#",
	"#.........................................................7...................b....................#",
	"#....y.......y.....##..................##.................###.................###....s.......y.....#",
	"#..................##....s.......m.....##...=...0..........##....x.......u.....##..................#",
	"#.......#99#.......##..................##..................##..................##..................#",
	"#########..######################################..######################################..#########",
	"#########..#########                    #########..#########                    #########..#########",
	"#..................#                    #.......#33#.......#                    #..................#",
	"#..................#                    #..####......####..#                    #...m..........m...#",
	"#...m.........m....#                    #..#:C#......#^D#..#                    #......######......#",
	"#..................#                    #..#::#......#^^#..#                    #......#.J..#......#",
	"#..................#                    #..#44#......#55#..#                    #......#....#......#",
	"#........G.........#                    #............#55#..#                    #......#ee###......#",
	"#..................#                    #..................#                    #..................#",
	"#..................#                    #...x..........x...#                    #..................#",
	"####################                    #########..#########                    ####################",
	"                    #############################..#############################",
	"                    #..................##..................##..................#",
	"                    #...A..............##..................##..............B...#",
	"                    #..................###................###..................#",
	"                    #........m...........1................2............s.......#",
	"                    #....................1................2....................#",
	"                    #..................###................###..................#",
	"                    #.....m............##....u........u....##.....u............#",
	"                    #..................##..................##..................#",
	"                    #############################..#############################",
	"                                        #########..#########",
	"                                        #..................#",
	"                                        #..................#",
	"                                        #...m..........m...#",
	"                                        #..................#",
	"                                        #..................#",
	"                                        #..................#",
	"                                        #.........@........#",
	"                                        #..................#",
	"                                        ####################",
]
# gdlint: enable=max-line-length

## Ferramentas com que o personagem chega, dos capítulos anteriores.
const STARTING_TOOLS := [Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING]

## Tipo de cada vaga de bloqueio do mapa.
const BLOCKS := {
	"1": ChapterMap.Block.CRACKED,
	"2": ChapterMap.Block.ICE,
	"3": ChapterMap.Block.LOCKED,
	"4": ChapterMap.Block.LEDGE,
	"5": ChapterMap.Block.TALL_LEDGE,
	"6": ChapterMap.Block.BOSS_DOOR,
	"7": ChapterMap.Block.GATE,
	"8": ChapterMap.Block.LEDGE,
	"9": ChapterMap.Block.CRACKED,
	"a": ChapterMap.Block.LEDGE,
	"b": ChapterMap.Block.LOCKED,
	"d": ChapterMap.Block.TALL_LEDGE,
	"e": ChapterMap.Block.ICE,
}

## Item de cada baú. São 3 chaves para 2 portas trancadas (arsenal, adega e
## ala leste), a mola forte na torre noroeste, a chave grande no alto da
## torre nordeste e 5 corações, um deles no degrau duplo do pátio.
const ITEMS := {
	"A": Item.Id.KEY,
	"B": Item.Id.HEART,
	"C": Item.Id.HEART,
	"D": Item.Id.HEART,
	"E": Item.Id.HEART,
	"F": Item.Id.STRONG_SPRING,
	"G": Item.Id.KEY,
	"H": Item.Id.KEY,
	"I": Item.Id.BOSS_KEY,
	"J": Item.Id.HEART,
}

## Tema de cada sala de uma tela, pela posição da sala: castelo em todas.
const ROOM_THEMES := {
	Vector2i(0, 0): "castle",
	Vector2i(2, 0): "castle",
	Vector2i(4, 0): "castle",
	Vector2i(0, 1): "castle",
	Vector2i(1, 1): "castle",
	Vector2i(2, 1): "castle",
	Vector2i(3, 1): "castle",
	Vector2i(4, 1): "castle",
	Vector2i(0, 2): "castle",
	Vector2i(2, 2): "castle",
	Vector2i(4, 2): "castle",
	Vector2i(1, 3): "castle",
	Vector2i(2, 3): "castle",
	Vector2i(3, 3): "castle",
	Vector2i(2, 4): "castle",
}

## Casa do alvo da dungeon, a sentinela, e as ferramentas que ela exige: a
## bomba abre a armadura, a chama derrete o núcleo e a mola escapa das ondas.
## Só tools/check_chapter.py lê isto.
const GOAL := "&"
const GOAL_TOOLS := [Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING]
