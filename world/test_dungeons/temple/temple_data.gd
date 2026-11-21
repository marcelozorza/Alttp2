class_name TestTempleData
## Dungeon de teste: o templo em ruínas, tomado pelo mato. O mapa traz só a
## geometria e as vagas de bloqueios e de baús, na legenda de ChapterMap. O
## tipo de cada bloqueio e o item de cada baú ficam em tabelas separadas do
## mapa.
##
## São 15 salas de uma tela, de 20 por 10 casas, numa grade de 5 por 5, em
## losango: 1, 3, 5, 5 e 1 salas por linha. O personagem chega com a bomba, a
## chama e a mola (STARTING_TOOLS). O templo tem duas alas simétricas, e o
## centro só abre com as duas resolvidas: a ala leste guarda a chama forte,
## que derrete o gelo grosso da nave, e a ala oeste guarda a mola forte, que
## sobe o degrau duplo do baú da chave grande. Cada ala dá a volta por fora e
## termina num santuário sem outra saída. Como nos capítulos, cada bloqueio de
## porta fica uma casa para dentro da sala, num nicho.
##
## Salas: entrada (2,4); pátio oeste (1,3), com uma chave no alto de um
## degrau, saguão (2,3) e pátio leste (3,3), com uma chave atrás do gelo;
## sala do bloco oeste (0,3) e sala das morsas (4,3); galeria do gelo (0,2),
## galeria rachada (1,2), nave (2,2), galeria leste (3,2) e sala do bloco
## leste (4,2); santuário oeste (1,1), com a mola forte, antessala (2,1), com
## a chave grande no degrau duplo, e santuário leste (3,1), com a chama
## forte; e o colosso (2,0).
##
## Ala oeste: porta trancada, grade com bloco e interruptor, parede de gelo e
## parede rachada. Ala leste: parede rachada, porta trancada, grade com bloco
## e interruptor e gelo. São 4 chaves para 3 portas trancadas, uma em cada
## pátio e uma em cada santuário, para qualquer ordem de abrir servir.

# O mapa tem 100 casas de largura, uma linha por fileira de casas.
# gdlint: disable=max-line-length
const MAP := [
	"                                        ####################",
	"                                        #..................#",
	"                                        #..z............z..#",
	"                                        #..................#",
	"                                        #.........$........#",
	"                                        #..................#",
	"                                        #..................#",
	"                                        #..z............z..#",
	"                                        #..................#",
	"                                        #########..#########",
	"                    #############################..#############################",
	"                    #.......#..L.#.....##:::P:::#aa#^^^I^^^##....#::::F:::#....#",
	"                    #..B....#....#.....##:::::::#..#^^^^^^^##....#::::::::#....#",
	"                    #.......#7777#.....##vvvvvvv#..#ttttttt##....#eeeeeeee#....#",
	"                    #..................##..........#ttttttt##..................#",
	"                    #.....u.......u....##..................##..K......w........#",
	"                    #..................##....w........w....##..................#",
	"                    #..z............z..##..................##..z............z..#",
	"                    #..................##..................##..................#",
	"                    #########..##################..##################..#########",
	"#############################..##################..##################..#############################",
	"#..H.........55....##.......#66#.......##..................##.......#dd#.......##..................#",
	"#............55....##..................##....x........x....##..................##.............=....#",
	"#.....y......55....##....s.......x.....##..................##...m........s.....###.................#",
	"#............55........................##gggggggggggggggggg##....................n.................#",
	"#............55........................##gggggggggggggggggg##....................n.................#",
	"#............55..z.##..................##..................##..................###............0....#",
	"#...z........55....##.......m......J...##.........u........##......z...........##.....x............#",
	"#............55....##..................##..................##..................##..................#",
	"#########..######################################..######################################..#########",
	"#########..######################################..######################################..#########",
	"#.......#kk#.......##.........#::::A:::##.......#33#.......##........#...C....###.......#22#.......#",
	"#..................##.........#::::::::##..................##........#........###..................#",
	"#...........w......###....m...#44444444##...m..........m...##....y...#88888888###.....w.....w......#",
	"#...=...0............1........................................................9....................#",
	"#....................1........................................................9....................#",
	"#....w.............###.......x.........##..................##.......i.........###..................#",
	"#..................##..................##.........u........##..................##.........G........#",
	"#..................##..................##..................##..................##..................#",
	"#################################################..#################################################",
	"                                        #########..#########",
	"                                        #..................#",
	"                                        #..z............z..#",
	"                                        #..................#",
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
	"1": ChapterMap.Block.LOCKED,
	"2": ChapterMap.Block.LOCKED,
	"3": ChapterMap.Block.LOCKED,
	"4": ChapterMap.Block.LEDGE,
	"5": ChapterMap.Block.ICE,
	"6": ChapterMap.Block.CRACKED,
	"7": ChapterMap.Block.ICE,
	"8": ChapterMap.Block.ICE,
	"9": ChapterMap.Block.CRACKED,
	"a": ChapterMap.Block.BOSS_DOOR,
	"d": ChapterMap.Block.ICE,
	"e": ChapterMap.Block.LEDGE,
	"g": ChapterMap.Block.THICK_ICE,
	"k": ChapterMap.Block.GATE,
	"n": ChapterMap.Block.GATE,
	"t": ChapterMap.Block.TALL_LEDGE,
	"v": ChapterMap.Block.LEDGE,
}

## Item de cada baú. São 4 chaves para 3 portas trancadas, a mola forte no
## santuário oeste, a chama forte no santuário leste, a chave grande na
## antessala, no alto do degrau duplo, e 4 corações.
const ITEMS := {
	"A": Item.Id.KEY,
	"B": Item.Id.KEY,
	"C": Item.Id.KEY,
	"F": Item.Id.STRONG_FIRE,
	"G": Item.Id.HEART,
	"H": Item.Id.HEART,
	"I": Item.Id.BOSS_KEY,
	"J": Item.Id.HEART,
	"K": Item.Id.KEY,
	"L": Item.Id.STRONG_SPRING,
	"P": Item.Id.HEART,
}

## Tema de cada sala de uma tela, pela posição da sala.
const ROOM_THEMES := {
	Vector2i(2, 0): "moss",
	Vector2i(1, 1): "moss",
	Vector2i(2, 1): "moss",
	Vector2i(3, 1): "moss",
	Vector2i(0, 2): "moss",
	Vector2i(1, 2): "moss",
	Vector2i(2, 2): "moss",
	Vector2i(3, 2): "moss",
	Vector2i(4, 2): "moss",
	Vector2i(0, 3): "moss",
	Vector2i(1, 3): "moss",
	Vector2i(2, 3): "moss",
	Vector2i(3, 3): "moss",
	Vector2i(4, 3): "moss",
	Vector2i(2, 4): "moss",
}

## Casa do alvo, o colosso, e as ferramentas que ele exige, como no capítulo
## 3. Só tools/check_chapter.py lê isto.
const GOAL := "$"
const GOAL_TOOLS := [Item.Id.STRONG_SPRING, Item.Id.BOMB]
