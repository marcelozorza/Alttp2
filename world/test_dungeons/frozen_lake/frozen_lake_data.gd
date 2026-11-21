class_name TestFrozenLakeData
## Dungeon de teste: o lago gelado. Não faz parte da versão linear do jogo.
## O mapa traz só a geometria e as vagas de bloqueios e de baús, na legenda de
## ChapterMap. O tipo de cada bloqueio e o item de cada baú ficam em tabelas
## separadas do mapa.
##
## São 15 salas de uma tela, de 20 por 10 casas, numa grade de 5 por 5, todas
## com o tema de gelo (ROOM_THEMES). O personagem chega com a bomba, a chama e
## a mola (STARTING_TOOLS). As salas formam um anel em volta de um lago
## central, com quatro salas de canto para fora do anel. A chama forte vem
## cedo: fica na ilha do meio do lago, cercada de gelo comum, logo ao norte da
## entrada. Com ela o gelo grosso do resto da dungeon derrete. Cada bloqueio
## de porta fica uma casa para dentro da sala, num nicho, e toda área alta tem
## parede dos lados: só se sobe pelo degrau.
##
## Salas: guardião antigo (2,0); mirante oeste (0,1), margem noroeste (1,1),
## antessala (2,1), margem nordeste (3,1) e cofre (4,1); margem oeste (1,2),
## lago (2,2) e margem leste (3,2); gruta oeste (0,3), margem sudoeste (1,3),
## margem sul (2,3), margem sudeste (3,3) e câmara da grade (4,3); e a
## entrada (2,4).
##
## Caminho: da entrada à margem sul, onde a chama derrete o gelo da porta do
## lago. No lago, a chama abre a ilha da chama forte, e a chama forte abre o
## nicho do coração, a leste, e a passagem para a margem oeste. Na margem
## sudoeste, a mola sobe à primeira chave, a bomba abre a gruta oeste
## (coração) e o gelo grosso do norte também leva à margem oeste (segunda
## chave, no degrau). O lado leste do anel só abre com chave: pela porta da
## margem sul ou pela porta da margem noroeste, em qualquer ordem. A leste
## ficam a câmara da grade (bloco pesado sobre o interruptor, terceira
## chave), a margem leste (coração no degrau) e o cofre, com a chave grande
## atrás de gelo grosso. A chave grande abre a porta da antessala para o
## guardião antigo.

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
	"#################################################..#################################################",
	"#::C:::#...........##..................##.......#kk#.......##..................##......#.I..#......#",
	"#::::::#....y......##....w.............##....z........z....##....w.......u.....##......#....#..i...#",
	"#gggggg#...........###................###..................##................####......#nnnn#......#",
	"#....................f................2......................................hh........#nnnn#......#",
	"#....................f................2......................................hh....................#",
	"#..................###................###..................##................####..................#",
	"#........i.........##.....i......u.....##.....w......i.....##....i.............##...w..........w...#",
	"#..................##..................##..................##..................##..................#",
	"#############################..######################################..#############################",
	"                    #########..######################################..#########",
	"                    #::B:::#...........##..i...........##..##...........#::J:::#",
	"                    #::::::#......w....##..............##H.##...x.......#::::::#",
	"                    #bbbbbb#...........####..44444444..##..##...........#jjjjjj#",
	"                    #....................dd..5..F...6..ee..##..................#",
	"                    #....................dd..5......6..ee..##..................#",
	"                    #..................####..77777777..##..##..................#",
	"                    #....i........i....##..............##..##....i........m....#",
	"                    #..................##............i.##..##..................#",
	"                    #########..##################..##################..#########",
	"#############################..##################..##################..#############################",
	"#..................##.......#99##::A:::##.......#33#.......##..................##........#.........#",
	"#..D...............##.......#99##::::::##...i..............##....u........i....##.......#K#....y...#",
	"#..................###..........#aaaaaa##.................###..................##.......#.#........#",
	"#.......y............8....................................1.............................#l#........#",
	"#....................8....................................1........................................#",
	"#....i.............###........i........##.................###..................##...=....0.........#",
	"#...........m......##...w..............##.............m....##.....w.......i....##..................#",
	"#..................##..................##..................##..................##.............m....#",
	"#################################################..#################################################",
	"                                        #########..#########",
	"                                        #..................#",
	"                                        #..................#",
	"                                        #...i..........i...#",
	"                                        #..................#",
	"                                        #..................#",
	"                                        #........@.........#",
	"                                        #..................#",
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
	"3": ChapterMap.Block.ICE,
	"4": ChapterMap.Block.ICE,
	"5": ChapterMap.Block.ICE,
	"6": ChapterMap.Block.ICE,
	"7": ChapterMap.Block.ICE,
	"8": ChapterMap.Block.CRACKED,
	"9": ChapterMap.Block.THICK_ICE,
	"a": ChapterMap.Block.LEDGE,
	"b": ChapterMap.Block.LEDGE,
	"d": ChapterMap.Block.THICK_ICE,
	"e": ChapterMap.Block.THICK_ICE,
	"f": ChapterMap.Block.ICE,
	"g": ChapterMap.Block.LEDGE,
	"h": ChapterMap.Block.THICK_ICE,
	"j": ChapterMap.Block.LEDGE,
	"k": ChapterMap.Block.BOSS_DOOR,
	"l": ChapterMap.Block.GATE,
	"n": ChapterMap.Block.THICK_ICE,
}

## Item de cada baú. São 3 chaves para 2 portas trancadas, a chama forte na
## ilha do lago, a chave grande no cofre, atrás de gelo grosso, e 4 corações.
const ITEMS := {
	"A": Item.Id.KEY,
	"B": Item.Id.KEY,
	"C": Item.Id.HEART,
	"D": Item.Id.HEART,
	"F": Item.Id.STRONG_FIRE,
	"H": Item.Id.HEART,
	"I": Item.Id.BOSS_KEY,
	"J": Item.Id.HEART,
	"K": Item.Id.KEY,
}

## Tema visual de cada sala, pela posição na grade.
const ROOM_THEMES := {
	Vector2i(2, 0): "ice",
	Vector2i(0, 1): "ice",
	Vector2i(1, 1): "ice",
	Vector2i(2, 1): "ice",
	Vector2i(3, 1): "ice",
	Vector2i(4, 1): "ice",
	Vector2i(1, 2): "ice",
	Vector2i(2, 2): "ice",
	Vector2i(3, 2): "ice",
	Vector2i(0, 3): "ice",
	Vector2i(1, 3): "ice",
	Vector2i(2, 3): "ice",
	Vector2i(3, 3): "ice",
	Vector2i(4, 3): "ice",
	Vector2i(2, 4): "ice",
}

## Casa do alvo, o guardião antigo, e as ferramentas que ele exige: a chama
## forte quebra a casca grossa e a mola escapa das ondas. Só
## tools/check_chapter.py lê isto.
const GOAL := "%"
const GOAL_TOOLS := [Item.Id.STRONG_FIRE, Item.Id.SPRING]
