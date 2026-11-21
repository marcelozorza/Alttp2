class_name TestTowerData
## Dungeon de teste "torre": uma torre que sobe do sul para o norte em
## zigue-zague, com três andares ligados por duas escadarias. O mapa traz só
## a geometria e as vagas de bloqueios e de baús, na legenda de ChapterMap. O
## tipo de cada bloqueio e o item de cada baú ficam em tabelas separadas do
## mapa.
##
## São 15 salas de uma tela, de 20 por 10 casas, numa grade de 5 por 5, todas
## com o tema de castelo (ROOM_THEMES). O personagem chega com a bomba, a
## chama e a mola (STARTING_TOOLS). A melhoria daqui é a mola forte, no alto
## da primeira escadaria, e sem ela não se cruza o parapeito do segundo
## andar. Cada bloqueio de porta fica uma casa para dentro da sala, num
## nicho, e toda área alta tem parede dos lados: só se sobe pelo degrau.
##
## Salas: primeiro andar, de oeste para leste: entrada (0,4), parapeito
## baixo (1,4), sala da grade (2,4), sala do gelo (3,4) e canto sudeste
## (4,4). Primeira escadaria (4,3). Segundo andar, de leste para oeste: sala
## da grade (4,2), parapeito alto (3,2), sala da chave (2,2), mirante (1,2)
## e canto oeste (0,2). Segunda escadaria (0,1). Terceiro andar, de oeste
## para leste: sala da grade (0,0), antessala (1,0) e o colosso (2,0).
##
## Caminho: no parapeito baixo, a mola sobe o degrau, passa por cima da
## parede do meio e desce do outro lado, com a primeira chave no alto. A
## chave abre a sala da grade, onde o bloco pesado vai para cima do
## interruptor. A chama derrete o gelo da sala seguinte, e a bomba abre a
## parede rachada do canto sudeste, que guarda a segunda chave. Na primeira
## escadaria, dois degraus seguidos levam à mola forte. No segundo andar,
## outro bloco abre a grade, a mola forte cruza o parapeito de degrau duplo,
## a chama derrete o gelo da terceira chave e a bomba abre a parede da
## quarta. Na segunda escadaria, o degrau duplo leva à chave grande. No
## terceiro andar, o último bloco abre a grade, e a chave grande abre a sala
## do colosso.

# O mapa tem 100 casas de largura, uma linha por fileira de casas.
# gdlint: disable=max-line-length
const MAP := [
	"############################################################",
	"#............#.....##......#^^K^^#.....##..................#",
	"#..=....0....#.....##......#^^^^^#.....##..................#",
	"#............#.....##......#ttttt#.....###.................#",
	"#............r.............#ttttt#.......v.........$.......#",
	"#............r...........................v.................#",
	"#............#.....##..................###.................#",
	"#...m........#..u..##...z....u....z....##..................#",
	"#............#.....##..................##..................#",
	"#########..#################################################",
	"#########..#########",
	"#^^^I^^#....#::J:::#",
	"#^^^^^^#....#::::::#",
	"#pppppp#....#qqqqqq#",
	"#pppppp#...........#",
	"#..................#",
	"#..................#",
	"#...y.........x....#",
	"#..................#",
	"#########..#########",
	"#########..#########################################################################################",
	"#.......#ll#.......##.....#^^G^^#......##......#F.#........##^^^^^^^^^^^^^^^^^^##.....#............#",
	"#..................##.....#^^^^^#......##......#..#........##ffffffff##gggggggg##.....#.......=....#",
	"#..................##.....#jjjjj#.....###......#hh#........##ffffffff##gggggggg##.....#............#",
	"#.........................#:::::#.....9..............................##...............e............#",
	"#.........................#nnnnn#.....9..............................##...............e.......0....#",
	"########.......m...##.................###..................##........##........##.....#............#",
	"#....H.o...........##...x.........u....##...z.........z....##..u.....##...m....##..s..#.....m......#",
	"#......o...........##..................##..................##........##........##.....#............#",
	"#########################################################################################..#########",
	"                                                                                #########..#########",
	"                                                                                #^^E^^^#....#^^D^^^#",
	"                                                                                #^^^^^^#....#^^^^^^#",
	"                                                                                #dddddd#....#aaaaaa#",
	"                                                                                #dddddd#....#::::::#",
	"                                                                                #...........#bbbbbb#",
	"                                                                                #..................#",
	"                                                                                #...y..........y...#",
	"                                                                                #..................#",
	"                                                                                #########..#########",
	"#########################################################################################..#########",
	"#..................##::::::::A:::::::::##...........#......##.........#.#^B^^#.##.......#77#.......#",
	"#..m...........m...##::::::::::::::::::##...........#......##.........#.#^^^^#.##..................#",
	"#..................##22222222##33333333###..........#......##.........#.#5555#.##..................#",
	"#............................##..........1..........k.................6.#5555#.....................#",
	"#............................##..........1..........k.................6............................#",
	"#..................##........##........###..........#......##.........#........##...u.......########",
	"#.........@........##...m....##....u...##...=...0...#...m..##..x......#....m...##...........8.C....#",
	"#..................##........##........##...........#......##.........#........##...........8......#",
	"####################################################################################################",
]
# gdlint: enable=max-line-length

## Ferramentas com que o personagem chega, dos capítulos anteriores.
const STARTING_TOOLS := [Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING]

## Tipo de cada vaga de bloqueio do mapa.
const BLOCKS := {
	"1": ChapterMap.Block.LOCKED,
	"2": ChapterMap.Block.LEDGE,
	"3": ChapterMap.Block.LEDGE,
	"5": ChapterMap.Block.TALL_LEDGE,
	"6": ChapterMap.Block.ICE,
	"7": ChapterMap.Block.LOCKED,
	"8": ChapterMap.Block.CRACKED,
	"9": ChapterMap.Block.LOCKED,
	"a": ChapterMap.Block.LEDGE,
	"b": ChapterMap.Block.LEDGE,
	"d": ChapterMap.Block.TALL_LEDGE,
	"e": ChapterMap.Block.GATE,
	"f": ChapterMap.Block.TALL_LEDGE,
	"g": ChapterMap.Block.TALL_LEDGE,
	"h": ChapterMap.Block.ICE,
	"j": ChapterMap.Block.LEDGE,
	"k": ChapterMap.Block.GATE,
	"l": ChapterMap.Block.LOCKED,
	"n": ChapterMap.Block.LEDGE,
	"o": ChapterMap.Block.CRACKED,
	"p": ChapterMap.Block.TALL_LEDGE,
	"q": ChapterMap.Block.LEDGE,
	"r": ChapterMap.Block.GATE,
	"t": ChapterMap.Block.TALL_LEDGE,
	"v": ChapterMap.Block.BOSS_DOOR,
}

## Item de cada baú. São 4 chaves para 4 portas trancadas em sequência, a
## mola forte no alto da primeira escadaria, a chave grande no alto da
## segunda e 5 corações, três deles em cima de degraus duplos.
const ITEMS := {
	"A": Item.Id.KEY,
	"B": Item.Id.HEART,
	"C": Item.Id.KEY,
	"D": Item.Id.STRONG_SPRING,
	"E": Item.Id.HEART,
	"F": Item.Id.KEY,
	"G": Item.Id.HEART,
	"H": Item.Id.KEY,
	"I": Item.Id.BOSS_KEY,
	"J": Item.Id.HEART,
	"K": Item.Id.HEART,
}

## Tema de cada sala de uma tela, pela posição da sala: castelo em todas.
const ROOM_THEMES := {
	Vector2i(0, 0): "castle",
	Vector2i(1, 0): "castle",
	Vector2i(2, 0): "castle",
	Vector2i(0, 1): "castle",
	Vector2i(0, 2): "castle",
	Vector2i(1, 2): "castle",
	Vector2i(2, 2): "castle",
	Vector2i(3, 2): "castle",
	Vector2i(4, 2): "castle",
	Vector2i(4, 3): "castle",
	Vector2i(0, 4): "castle",
	Vector2i(1, 4): "castle",
	Vector2i(2, 4): "castle",
	Vector2i(3, 4): "castle",
	Vector2i(4, 4): "castle",
}

## Casa do alvo da dungeon, o colosso, e as ferramentas que ele exige, como
## no capítulo 3. Só tools/check_chapter.py lê isto.
const GOAL := "$"
const GOAL_TOOLS := [Item.Id.STRONG_SPRING, Item.Id.BOMB]
