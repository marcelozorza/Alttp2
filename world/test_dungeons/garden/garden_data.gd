class_name TestGardenData
## Dungeon de teste "jardim": um jardim em labirinto, não linear, com sebes
## no meio das salas e muitos inimigos. O mapa traz só a geometria e as vagas
## de bloqueios e de baús, na legenda de ChapterMap. O tipo de cada bloqueio e
## o item de cada baú ficam em tabelas separadas do mapa.
##
## São 15 salas de uma tela, de 20 por 10 casas, numa grade de 5 por 5, todas
## com o tema de musgo (ROOM_THEMES). O personagem chega com a bomba, a chama
## e a mola (STARTING_TOOLS). A melhoria daqui é a chama forte, na estufa,
## que derrete o gelo grosso da gruta, onde fica a chave grande. Cada
## bloqueio de porta fica uma casa para dentro da sala, num nicho.
##
## Salas: entrada (0,4) e canteiros (1,4); aleia oeste (0,3), praça (1,3) e
## aleia leste (2,3); labirinto oeste (0,2), encruzilhada (1,2), roseiral
## (2,2) e viveiro (3,2); terraço (1,1), estufa (2,1), pomar (3,1) e
## antessala (4,1); gruta (3,0) e o guardião antigo (4,0).
##
## Caminho: da entrada, pelos canteiros, à praça, de onde saem três caminhos
## que podem ser feitos em qualquer ordem, cada um com uma chave. A oeste, a
## aleia leva ao labirinto oeste (chave). A leste, a aleia e uma porta de
## gelo levam ao roseiral (chave). Ao norte, a encruzilhada leva ao terraço,
## onde a mola sobe o degrau até a chave. Paredes rachadas escondem atalhos:
## da entrada direto à aleia oeste, e da encruzilhada para o labirinto oeste
## e para o roseiral. A estufa, entre o terraço e o roseiral, guarda a chama
## forte atrás de gelo. As três chaves abrem em série o viveiro, o pomar e a
## antessala. Do pomar se sobe à gruta, onde a chama forte derrete o gelo
## grosso da chave grande, e a chave grande abre a sala do guardião antigo.

# O mapa tem 100 casas de largura, uma linha por fileira de casas.
# gdlint: disable=max-line-length
const MAP := [
	"                                                            ########################################",
	"                                                            #........I.........##..................#",
	"                                                            #..................##..................#",
	"                                                            #aaaaaaaaaaaaaaaaaa##........%.........#",
	"                                                            #aaaaaaaaaaaaaaaaaa##..................#",
	"                                                            #..................##..................#",
	"                                                            #...w....i....w....##..................#",
	"                                                            #..................##..................#",
	"                                                            #..................##.......#bb#.......#",
	"                                                            #########..##################..#########",
	"                    #################################################..##################..#########",
	"                    #::::::::E:::::::::##..................##..................##..................#",
	"                    #::::::::::::::::::##......######...G..##..m...............##..............s...#",
	"                    #666666666666666666##..w...#.F..#.y....##....#.....m.#.....###..###......###...#",
	"                    #..........................#....#......##....#.......#.......9.................#",
	"                    #...............z..........#77###......##....#...u...#.......9....x............#",
	"                    #...s.........u....##..............m...##....#.......#.....###...........u.....#",
	"                    #.......m..........##...z..............##..z...........w...##..J............z..#",
	"                    #..................##..................##.......#88#.......##..................#",
	"                    #########..##################..##################..#############################",
	"#############################..##################..##################..#########",
	"#.......#..........##..................##..................##..................#",
	"#.C.....#..........##....m.........y...##.....#........z...##...............m..#",
	"#...#.m.#...#####..###.####......####..###..z.#............###...###.....u.....#",
	"#...#...#...#........2.......x...........4....#..............5.............y...#",
	"#...#...#...#.u......2...................4..y........#.......5.......s.........#",
	"#.m.#...#...#......###.####......####..###........u..#.....###....x.....###....#",
	"#...#.z........y...##....z........m....##..D.........#.m...##...z..........H...#",
	"#...#..............##..................##.......#33#.......##..................#",
	"#########..##################..##################..#############################",
	"#########..##################..##################..#########",
	"#....#.............##..................##..................#",
	"#.B..#......y......##...##........##...##......x...........#",
	"#....#.............##.....m............##..#####......u....#",
	"#....#........#.....................z......................#",
	"#....#..z.....#........z...................................#",
	"#..u..........#.m..##............m.....##....s......#####..#",
	"#..................##...##........##...##..m............z..#",
	"#.......#11#.......##..................##..................#",
	"#########..##################..#############################",
	"#########..##################..#########",
	"#..................##..................#",
	"#...###.....####...##...............m..#",
	"#.....z............##..####......####..#",
	"#.............m..........z.............#",
	"#............................u.....z...#",
	"#...@..............##..####......####..#",
	"#...........###....##.A................#",
	"#..................##..................#",
	"########################################",
]
# gdlint: enable=max-line-length

## Ferramentas com que o personagem chega, dos capítulos anteriores.
const STARTING_TOOLS := [Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING]

## Tipo de cada vaga de bloqueio do mapa.
const BLOCKS := {
	"1": ChapterMap.Block.CRACKED,
	"2": ChapterMap.Block.CRACKED,
	"3": ChapterMap.Block.ICE,
	"4": ChapterMap.Block.CRACKED,
	"5": ChapterMap.Block.LOCKED,
	"6": ChapterMap.Block.LEDGE,
	"7": ChapterMap.Block.ICE,
	"8": ChapterMap.Block.LOCKED,
	"9": ChapterMap.Block.LOCKED,
	"a": ChapterMap.Block.THICK_ICE,
	"b": ChapterMap.Block.BOSS_DOOR,
}

## Item de cada baú. São 3 chaves para 3 portas trancadas, uma em cada
## caminho da praça (labirinto oeste, roseiral e terraço), a chama forte na
## estufa, a chave grande na gruta, atrás de gelo grosso, e 5 corações.
const ITEMS := {
	"A": Item.Id.HEART,
	"B": Item.Id.HEART,
	"C": Item.Id.KEY,
	"D": Item.Id.KEY,
	"E": Item.Id.KEY,
	"F": Item.Id.STRONG_FIRE,
	"G": Item.Id.HEART,
	"H": Item.Id.HEART,
	"I": Item.Id.BOSS_KEY,
	"J": Item.Id.HEART,
}

## Tema de cada sala de uma tela, pela posição da sala: musgo em todas.
const ROOM_THEMES := {
	Vector2i(3, 0): "moss",
	Vector2i(4, 0): "moss",
	Vector2i(1, 1): "moss",
	Vector2i(2, 1): "moss",
	Vector2i(3, 1): "moss",
	Vector2i(4, 1): "moss",
	Vector2i(0, 2): "moss",
	Vector2i(1, 2): "moss",
	Vector2i(2, 2): "moss",
	Vector2i(3, 2): "moss",
	Vector2i(0, 3): "moss",
	Vector2i(1, 3): "moss",
	Vector2i(2, 3): "moss",
	Vector2i(0, 4): "moss",
	Vector2i(1, 4): "moss",
}

## Casa do alvo da dungeon, o guardião antigo, e as ferramentas que ele
## exige: a chama forte quebra a casca grossa e a mola escapa das ondas. Só
## tools/check_chapter.py lê isto.
const GOAL := "%"
const GOAL_TOOLS := [Item.Id.STRONG_FIRE, Item.Id.SPRING]
