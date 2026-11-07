class_name ChapterTwoData
## Dados do capítulo 2, a geleira (o antigo capítulo 3, renumerado em
## 2026-11-06). O mapa traz só a geometria e as vagas de
## bloqueios e de baús, na legenda de ChapterMap. O tipo de cada bloqueio e o
## item de cada baú ficam em tabelas separadas do mapa.
##
## São 15 salas de uma tela, de 20 por 10 casas, numa grade de 5 por 5. O
## personagem chega com a bomba, a chama e a mola dos capítulos anteriores
## (STARTING_TOOLS), e o capítulo introduz a primeira melhoria: a chama forte,
## que derrete o gelo grosso. O gelo grosso aparece desde a entrada, atrás de
## um coração à vista, e a chama comum só o faz tremer. A dungeon inteira abre
## quando a chama forte chega. Como nos outros capítulos, cada bloqueio de
## porta fica uma casa para dentro da sala, num nicho.
##
## Salas: entrada (2,4), galeria oeste (1,4) e galeria leste (3,4); cripta
## oeste (1,3), salão (2,3) e galeria leste alta (3,3); nicho oeste (0,2), ala
## oeste (1,2), encruzilhada (2,2), ala leste (3,2) e nicho leste (4,2); forja
## (1,1), antessala (2,1) e cofre (3,1); e o guardião antigo (2,0).

# O mapa tem 100 casas de largura, uma linha por fileira de casas.
# gdlint: disable=max-line-length
const MAP := [
	"                                        ####################",
	"                                        #..................#",
	"                                        #..................#",
	"                                        #.........%........#",
	"                                        #..................#",
	"                                        #..................#",
	"                                        #..................#",
	"                                        #..................#",
	"                                        #..................#",
	"                                        #########..#########",
	"                    #############################..#############################",
	"                    #.............#..G.##..................##..................#",
	"                    #..m..........#....##...w.....u....w...##..................#",
	"                    #..........u..#gggg##..................##...w.........w....#",
	"                    #.....F.......#gggg##..................##........I.........#",
	"                    #..................##########hh##########..................#",
	"                    #...u..............##.......#hh#.......##..................#",
	"                    #........m.........##...i..........i...##..................#",
	"                    #..................##..................##..................#",
	"                    #########..##################..##################..#########",
	"#############################..##################..##################..#############################",
	"#..................##.......#dd#.......##.......#aa#.......##.......#ff#.......##.........#........#",
	"#..................##..................##......z....z......##.......#ff#.......##........#J#.......#",
	"#..................###............i....##..m.............####.................###........#.#.......#",
	"#........H...........b...................................99...................e..........#k#.......#",
	"#....................b...................................99...................e....................#",
	"#............m.....###.................##.....u..........####....w............###...=...0....w.....#",
	"#........y.........##.....i............##.............m....##.............i....##..................#",
	"#..................##..................##..................##..................##..................#",
	"#################################################..##################..#############################",
	"                    #############################..##################..#########",
	"                    #:::D::::#.........##..................##.......#66#:::K:::#",
	"                    #::::::::#.........##...E..............##.......#66#:::::::#",
	"                    #77777777#.......####.............u....##.....m....#8888888#",
	"                    #................44........................................#",
	"                    #............i...44........................................#",
	"                    #....i...........####....w.............##...i.........i....#",
	"                    #..................##.....x.....m......##..................#",
	"                    #..................##..................##..................#",
	"                    #########..##################..##################..#########",
	"                    #########..##################..##################..#########",
	"                    #.......#33#.......##.......#11#.C..#..##.......#55#.......#",
	"                    #..................##..........#....#..##..................#",
	"                    #.....m............##....m.....#jjjj#..##..................#",
	"                    #............m.................#jjjj#........u.............#",
	"                    #.....................................................######",
	"                    #...A..............##.........@........##.........i...2..B.#",
	"                    #.........m........##..................##.............2....#",
	"                    #..................##..................##.............######",
	"                    ############################################################",
]
# gdlint: enable=max-line-length

## Ferramentas com que o personagem chega, dos capítulos anteriores.
const STARTING_TOOLS := [Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING]

## Tipo de cada vaga de bloqueio do mapa.
const BLOCKS := {
	"1": ChapterMap.Block.LOCKED,
	"2": ChapterMap.Block.ICE,
	"3": ChapterMap.Block.CRACKED,
	"4": ChapterMap.Block.THICK_ICE,
	"5": ChapterMap.Block.LOCKED,
	"6": ChapterMap.Block.THICK_ICE,
	"7": ChapterMap.Block.LEDGE,
	"8": ChapterMap.Block.LEDGE,
	"9": ChapterMap.Block.THICK_ICE,
	"a": ChapterMap.Block.BOSS_DOOR,
	"b": ChapterMap.Block.CRACKED,
	"d": ChapterMap.Block.LOCKED,
	"e": ChapterMap.Block.LOCKED,
	"f": ChapterMap.Block.THICK_ICE,
	"g": ChapterMap.Block.THICK_ICE,
	"h": ChapterMap.Block.THICK_ICE,
	"j": ChapterMap.Block.THICK_ICE,
	"k": ChapterMap.Block.GATE,
}

## Item de cada baú. São 5 chaves para 4 portas trancadas, a chama forte na
## forja, com uma chave atrás de gelo grosso logo ao lado, a chave grande no
## cofre, atrás de gelo grosso e de morsas, e 4 corações.
const ITEMS := {
	"A": Item.Id.KEY,
	"B": Item.Id.KEY,
	"C": Item.Id.HEART,
	"D": Item.Id.HEART,
	"E": Item.Id.KEY,
	"F": Item.Id.STRONG_FIRE,
	"G": Item.Id.KEY,
	"H": Item.Id.HEART,
	"I": Item.Id.BOSS_KEY,
	"J": Item.Id.HEART,
	"K": Item.Id.KEY,
}

## Casa do alvo do capítulo, o guardião antigo, e as ferramentas que ele
## exige: a chama forte quebra a casca grossa e a mola escapa das ondas. Só
## tools/check_chapter.py lê isto.
const GOAL := "%"
const GOAL_TOOLS := [Item.Id.STRONG_FIRE, Item.Id.SPRING]
