class_name ChapterFourData
## Dados do capítulo 4, a pedreira. O mapa traz só a geometria e as vagas de
## bloqueios e de baús, na legenda de ChapterMap. O tipo de cada bloqueio e o
## item de cada baú ficam em tabelas separadas do mapa.
##
## São 22 telas de 20 por 10 casas numa grade de 6 por 5, em 17 salas: a
## arena, a pedreira e o pátio juntam telas (ROOMS), e nelas a câmera segue o
## personagem. O personagem chega com as três ferramentas e a chama forte
## (STARTING_TOOLS), e o capítulo introduz a segunda melhoria: a mola forte,
## cujo pulo mais alto sobe o degrau duplo. O chão tem três níveis, e o norte
## da pedreira é um platô dois níveis acima da entrada.
##
## Telas: nicho norte (1,0), arena (2,0)-(3,0) e corredor (4,0); mirante (1,1),
## pedreira (2,1)-(3,2) e cofre (4,1); nicho oeste (0,2), forja (1,2), galeria
## dos atiradores (4,2) e nicho leste (5,2); poço (0,3), oficina (1,3), pátio
## (2,3)-(3,3) e depósito (4,3); galeria oeste (1,4), entrada (2,4) e galeria
## leste (3,4).

# O mapa tem 120 casas de largura, uma linha por fileira de casas.
# gdlint: disable=max-line-length
const MAP := [
	"                    ################################################################################",
	"                    #^^^^^^^^^^^^^^^^^^##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^##^^^^^^^^^^^^^^^^^^#",
	"                    #^^^^^^^^^^^^^^^^^^##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^##^^^^^^^^^^m^^^^^^^#",
	"                    #^^^^^^^^^^^^^^^^^^##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^###^^^^u^^^^^^^^m^^^#",
	"                    #^^^^^^^^M^^^^^^^^^##^^^^^^^^^^^^^^^^^$^^^^^^^^^^^^^^^^^^^^^^v^^^^^^^^^^^^^^^^^#",
	"                    #^^^^^^^^^^^^^^^^^^##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^v^^^^^^^^^^^^^^^^^#",
	"                    #^^^m^^^^^^^^^u^^^^##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^###^^^^^^m^^^^^^^^^^#",
	"                    #^^^^^^^^^^^^^^^^^^##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^##^^^^^^^^^^^^u^^s^^#",
	"                    #^^^^^^^^^^^^^^^^^^##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^##^^^^^^^^^^^^^^^^^^#",
	"                    #########^^##########################################################^^#########",
	"                    #########^^##########################################################^^#########",
	"                    #^^^^^^^#ee#^^^^^^^##^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^##^^^^^^^^^^^^^^^^^^#",
	"                    #^^^^^^^^^^^^m^^^^^##^^^s^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^s^^^##^^^s^^^^^^^^^^s^^^#",
	"                    #^^^s^^^^^^^^^^^^^^##^^^^^^^^^^^^^^^^^^^s^^^^^^^^^^^^^^^^^###^^^^^^^^^I^^^^^^^^#",
	"                    #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^5^^^^^^^^^^^^^^^^^^^^#",
	"                    #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^5^^^^^^^^^^^^^^^^^^^^#",
	"                    #^^^^^^^^^^^^^^s^^^##rrrrrr#########################tttttt###^^^^u^^^^^^^^u^^^^#",
	"                    #^^^^^m^^^^^^^^^^^^##rrrrrr#:::::::::::::::::::::::#tttttt.##^^^^^^^^^^^^^^^^^^#",
	"                    #^^^^^^^^^^^^^^^^^^##......#::::s::::::s::::::s::::#.......##^^^^^^^^^^^^^^^^^^#",
	"                    #########^^##########......#:::::::::::::::::::::::#.......#####################",
	"#############################^^##########.......hhhhhhhhhhhhhhhhhhhhhhh........#########################################",
	"#..................####^^^^^^^^^^^^^^^^##......................................###:::s:::##:::s:::###..................#",
	"#.............s....####^^^^^^^^^^^^^^^^##.................m....................###:::::::##:::::::###.............s....#",
	"#..................####qqqqqqqqqqqqqqqq##.....................................####lllllll##nnnnnnn###..................#",
	"#........L...........8#qqqqqqqqqqqqqqqq......u............................u...d...............................K........#",
	"#....................8........................................................d.....m...........m......................#",
	"#..................###........G........##...........m.............m...........###........#######...##.....u............#",
	"#....m.......m.....##....u.........u...##......................................##........9..J..#...##..................#",
	"#..................##..................##......................................##.......m9.....#...##..................#",
	"#############################..##################..#####################################################################",
	"#############################..##################..#################################################",
	"#..................##.......#22#:::C:::##.......#44#:::::::::::::::#.#^^^E^^^#.##::::::#.....7..F..#",
	"#..................##..........#:::::s:##..........#:::s:::::::s:::#.#^^^^^^^#.##::s:::#.....7.....#",
	"#....m.............###.........#fffffff##...m......#:::::::::::::::#.#ppppppp#.##::::::#.....#######",
	"#........H...........b.................##..........#:::::::::::::::#.#ppppppp#...kkkkkk#...........#",
	"#....................b.................##..........#jjjjjjjjjjjjjjj#...............................#",
	"#............m.....###.................##....u.................................##.........u....m...#",
	"#..................##....m........m....##...................m..............m...##...m..............#",
	"#..................##..................##......................................##..................#",
	"#############################..##################..##################..#############################",
	"                    #########..##################..##################..#########",
	"                    #.......#66#.......##.......#11##^^D^^###.......#33##::::::#",
	"                    #..................##...........#^^^^^###...........#:::s::#",
	"                    #....A......u......##...........#ooooo###.....m.....#::::::#",
	"                    #...............................#ooooo#....m........#gggggg#",
	"                    #..........................................................#",
	"                    #...m.........m....##.........@........#######.............#",
	"                    #...............m..##...m...........m..##.B..a.........u...#",
	"                    #..................##..................##....a.............#",
	"                    ############################################################",
]

## Telas que formam uma sala maior, em unidades de tela.
const ROOMS := [
	Rect2i(2, 0, 2, 1),
	Rect2i(2, 1, 2, 2),
	Rect2i(2, 3, 2, 1),
]

## Ferramentas com que o personagem chega.
const STARTING_TOOLS := [Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING, Item.Id.STRONG_FIRE]

## Tipo de cada vaga de bloqueio.
const BLOCKS := {
	"1": ChapterMap.Block.LOCKED,
	"2": ChapterMap.Block.LOCKED,
	"3": ChapterMap.Block.LOCKED,
	"4": ChapterMap.Block.LOCKED,
	"5": ChapterMap.Block.LOCKED,
	"6": ChapterMap.Block.CRACKED,
	"7": ChapterMap.Block.CRACKED,
	"8": ChapterMap.Block.CRACKED,
	"9": ChapterMap.Block.CRACKED,
	"a": ChapterMap.Block.ICE,
	"b": ChapterMap.Block.ICE,
	"d": ChapterMap.Block.ICE,
	"e": ChapterMap.Block.ICE,
	"f": ChapterMap.Block.LEDGE,
	"g": ChapterMap.Block.LEDGE,
	"h": ChapterMap.Block.LEDGE,
	"j": ChapterMap.Block.LEDGE,
	"k": ChapterMap.Block.LEDGE,
	"l": ChapterMap.Block.LEDGE,
	"n": ChapterMap.Block.LEDGE,
	"o": ChapterMap.Block.TALL_LEDGE,
	"p": ChapterMap.Block.TALL_LEDGE,
	"q": ChapterMap.Block.TALL_LEDGE,
	"r": ChapterMap.Block.TALL_LEDGE,
	"t": ChapterMap.Block.TALL_LEDGE,
	"v": ChapterMap.Block.BOSS_DOOR,
}

## Item de cada baú. A ordem linear: as chaves A e B para as portas 1 e 3 do
## pátio, a chave F do depósito, a mola forte G na forja atrás da porta 2, e
## dali a chave E do pátio, a chave J da galeria e a chave grande I no cofre.
const ITEMS := {
	"A": Item.Id.KEY,
	"B": Item.Id.KEY,
	"C": Item.Id.HEART,
	"D": Item.Id.HEART,
	"E": Item.Id.KEY,
	"F": Item.Id.KEY,
	"G": Item.Id.STRONG_SPRING,
	"H": Item.Id.KEY,
	"I": Item.Id.BOSS_KEY,
	"J": Item.Id.KEY,
	"K": Item.Id.HEART,
	"L": Item.Id.HEART,
	"M": Item.Id.HEART,
}

## Alvo da lógica, para tools/check_chapter.py: o colosso e o que ele exige.
const GOAL := "$"
const GOAL_TOOLS := [Item.Id.STRONG_SPRING, Item.Id.BOMB]
