class_name LabData
## Dados do laboratório, a dungeon fechada em que as mecânicas novas são
## testadas antes de entrar nas dungeons do jogo. Fica fora do mundo e das
## seeds, e abre pelo botão Laboratório do menu.
##
## Este arquivo é gerado por tools/lab/build_lab.py, que descreve uma sala
## por mecânica. Para mudar o laboratório, edite as salas lá e rode o script.
## A legenda dos objetos novos está em progression/map_legend.gd, e o código
## deles em lab/.
##
## São 41 telas de 20 por 10 casas numa grade de 7 por 6. O personagem chega
## só com a espada e acha as ferramentas e as melhorias nas alas.
##
## Salas, pela tela do canto:
## - (0, 0) Cofre
## - (2, 0) Porão
## - (3, 0) Arena do chefe
## - (4, 0) Inimigo como peso
## - (5, 0) Nível de água
## - (6, 0) Clone
## - (0, 1) Fuga do fogo
## - (3, 1) Antessala
## - (4, 1) Tochas em ordem
## - (5, 1) Buraco largo
## - (6, 1) Degrau duplo
## - (0, 2) Inimigos novos
## - (1, 2) Bloco no gelo
## - (2, 2) Blocos em ordem
## - (3, 2) Vento e bomba
## - (4, 2) Sala escura
## - (5, 2) Corrida da placa
## - (6, 2) Portais
## - (0, 3) Gelo liso
## - (1, 3) Estátua espelhada
## - (2, 3) Torretas e blocos
## - (3, 3) Alvo de explosão
## - (4, 3) Tochas
## - (5, 3) Tochas com tempo
## - (6, 3) Esteiras e torretas
## - (0, 4) Arena de levas
## - (1, 4) Cristal
## - (2, 4) Sala de combate
## - (3, 4) Salão central
## - (5, 4) Buracos e vento
## - (6, 4) Piso quebradiço
## - (0, 5) Ímã
## - (1, 5) Eletricidade
## - (2, 5) Bloco e botão
## - (3, 5) Entrada
## - (4, 5) Feixe de luz
## - (5, 5) Corredor sob ataque

# gdlint: disable=max-line-length
const MAP := [
	"####################                    ####################################################################################################",
	"#..................#                    #..................##..................##..............#W..##.......U..........##..............#V..#",
	"#........L.........#                    #........X.........##..................##..............#.{.##..................##..............#.{.#",
	"#..................#                    #..................##..................##..............#kk###≈≈≈≈≈≈≈≈≈≈≈≈▭≈≈≈≈≈##..............#kk##",
	"#..................#                    #..................##........&.........##........#...........◢≈≈≈≈≈≈≈≈≈≈≈▭≈≈≈≈◢....................#",
	"#....δ.............#                    #....ⓐ........Ⓑ....##..................##..m....l;l...?......◢≈≈≈≈≈≈≈≈≈≈≈▭≈≈≈≈◢......◎....?........#",
	"#..................#                    #..........?.......##..................##........#.........##≈≈≈≈≈≈≈≈≈≈≈≈▭≈≈≈≈≈##..................#",
	"#..................#                    #..................##..................##..m...............##....◢......!..?...##..¦...............#",
	"#..................#                    #..................##..................##..................##..................##..................#",
	"#########..#########                    #############################..######################################..#############################",
	"#########..##########################################################..######################################..#############################",
	"#........................ll......#...........#...ll.....-..##.......#44#.......##.......#G.#.......##...nnnnn..........##.......#^^^^M^^^^^#",
	"#.............#..........ll......#...........#...ll...#....##...............Ⓐ..##.......#..#.......##.N.nnnnn..........##.......#^^^^^^^^^^#",
	"#.............#..........ll..#...#...............ll...#....#############.......##.......#hh#.......##...nnnnn..........##.......#tttttttttt#",
	"#.....?..................ll..#................#..ll...........887..nnnnn.......##..③..........②....##...nnnnn....?..............#tttttttttt#",
	"#........................ll..#................#..ll...........887..nnnnn..?....##........?.........##...nnnnn..............................#",
	"#.............#..........ll..#...#...........#...ll...#....#############.......##..................##...nnnnn..........##..?...............#",
	"#.............#..........ll......#...........#...ll...#....##............ⓑ.ω...##..①..........④....##...nnnnn..........##..................#",
	"#........................ll......#...............ll........##..................##..................##...nnnnn..........##..................#",
	"#####################################################################..##################..##################..#############################",
	"#####################################################################..##################..##################..#############################",
	"#..............#O.###............o#....##..................##E.#....#22#...⇓...##..................##..............#P..##.....#......#.....#",
	"#....].........#..###...~~~~#~~..o#....##..###.............##..#...............##.####.####.####.|.##..............#.;.##.α...#..β...#..I..#",
	"#..............#ee###...~~~~~~~..o.....##..#F#.............##jj#........#nnnnn###......#..y...#....##.##############kk###.....#......#.....#",
	"#.................e.....~~~~~~~..o#.R..##..#.#..........................#nnnnn###.|.##.#.####.#.##.##..................##..γ..#......#..γ..#",
	"#.........?.......e.....~~~~~~~..o#....##..#.#....................?.....#nnnnn###...#....#....#..#.##.#########################......#######",
	"#.................###.[.~~~~~~~..o#....##...[..............##...........#......##.###.####.##.####.##..................##..................#",
	"#....(.....)..]....##...~~~~~~~..o#....##....[.....?.......##...........#..+...##......|...#...y...##......;..?........##...α.....?....β...#",
	"#.......#ee#.......##.?..........o#....##..................##...........#......##..................##..................##..................#",
	"#########..##########################################################..##################..##################..##################..#########",
	"#########..##########################################################..##################..##################..##################..#########",
	"#########..##########.....#............##........B.........##.......#jj#.......##.......#hh#.......##.......#hh#.......##..................#",
	"#~~#~~~~~~~~~~~~~~~##.{...#...♜........##..................##..................##..|............|..##./............/...##..}............}..#",
	"#~~~~~~~~~~#~~~~~~~##..................##oooooooooooooooooo##..+...........m...##..................##..................##→→→→→→→→→→→→→→→→→→#",
	"#~~~~~~~~~~~~#~~D~~######################..................##..................##........?.............................##..................#",
	"#~~~~~~~~##~~~~~.~~##..................##....}...[....}....##..........?.......##...........................?..........##←←←←←←←←←←←←←←←←←←#",
	"#~~~~~~~~~~~~~~~~~~##.........?....#kk###..................##..................##......i.....i.....##..............#pp###..................#",
	"#~~~~~#~~~~~~~~~#~~##..............#C.###......[...?.......##..............m...##..|............|..##./............#H.###..}.....?......}..#",
	"#...?..............##..............#..###..................##..................##..................##..............#..###..................#",
	"#########..##################..##################..##################..##################..######################################..#########",
	"#########..##################..##################..##################..##################..######################################..#########",
	"#...#...#ee#.......##.....#.....#......##.......#ee#.......##.......#55#................#99#.......##......ll..........##...............Q..#",
	"#...#........_.....##.....#.....#......##...m..........m...##........?...................?.........##......ll......(...##..........?.......#",
	"#.A.#.............###..!..#..!..#..!...###................###.....................................###......ll..........##▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒###",
	"#...e.....?.......e.......g.....f........e.......?........e.......................................l........ll..........################▒▒###",
	"#...e.............e.......g.....f........e................e....?................................?.l....?...ll..........####▒▒▒▒▒▒▒▒▒▒▒▒▒▒###",
	"#...#.............###.....#.....#......###................###.....................................###......ll......(...####▒▒###############",
	"#...#..._....._....##.....#.....#..?...##....]........u....##............................?.........##......ll..........####▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒#",
	"#...#..............##.....#.....#......##.......#33#.......##...........................#11#.......##......ll..........##..................#",
	"#############################..##################..##################..##################..##################..##################..#########",
	"#############################..##################..##################..##################..##################..##################..#########",
	"#........o.........##..................##..................##..................##..............#J..##:::s:::#..#::::s:::::::u:::#..#:::s:::#",
	"#.T......o.........##..............#S.###..............#K.###..................##..............#...##:::::::#..#::::::::::::::::#..#:::::::#",
	"#........o.........##..........▣...#..###..............#..###....?........?....##...◉........╱.#qq###ddddddd#..##vvvvvvvvvvvvvvv#..#rrrrrrr#",
	"#..▣.....o.....∩...................#aa###..............#bb###..................##..................##..........ll......←←←←................#",
	"#........o.............⚡═══.═══.═══⏻...##..................##..................##.......?..........##..........ll..#...←←←←..#...ll........#",
	"#........o....?....##..................##....=....0........##........@.........##..................##...?......ll..#...←←←←..#...ll........#",
	"#........o.........##......▣......?....##..................##..................##.▶..........╲.....##..........ll..#...←←←←..#...ll........#",
	"#........o.........##..................##..................##..................##..................##..................←←←←..#.............#",
	"############################################################################################################################################",
]

## Telas que formam uma sala maior, em unidades de tela.
const ROOMS := [
	Rect2i(3, 4, 2, 1),
	Rect2i(5, 5, 2, 1),
	Rect2i(0, 1, 3, 1),
]

## O personagem chega só com a espada.
const STARTING_TOOLS := []

## Tipo de cada vaga de bloqueio.
const BLOCKS := {
	"1": ChapterMap.Block.LOCKED,
	"2": ChapterMap.Block.LOCKED,
	"3": ChapterMap.Block.LOCKED,
	"4": ChapterMap.Block.BOSS_DOOR,
	"5": ChapterMap.Block.CRACKED,
	"7": ChapterMap.Block.BOARDED,
	"8": ChapterMap.Block.THICK_ICE,
	"9": ChapterMap.Block.ICE,
	"b": ChapterMap.Block.GATE,
	"d": ChapterMap.Block.LEDGE,
	"v": ChapterMap.Block.LEDGE,
	"r": ChapterMap.Block.LEDGE,
	"t": ChapterMap.Block.TALL_LEDGE,
	"e": ChapterMap.Block.SHUTTER,
	"f": ChapterMap.Block.BARRIER,
	"g": ChapterMap.Block.BARRIER_ALT,
	"h": ChapterMap.Block.TORCH_DOOR,
	"j": ChapterMap.Block.BLAST_DOOR,
	"k": ChapterMap.Block.TIMED_GATE,
	"l": ChapterMap.Block.PIT,
	"n": ChapterMap.Block.WIDE_PIT,
	"o": ChapterMap.Block.GAP,
	"p": ChapterMap.Block.WEB,
	"q": ChapterMap.Block.BEAM_DOOR,
	"a": ChapterMap.Block.POWER_DOOR,
}

## Item de cada baú.
const ITEMS := {
	"A": Item.Id.BOMB,
	"B": Item.Id.KEY,
	"C": Item.Id.HEART,
	"D": Item.Id.HEART,
	"E": Item.Id.FIRE,
	"F": Item.Id.KEY,
	"G": Item.Id.SPRING,
	"H": Item.Id.KEY,
	"I": Item.Id.STRONG_SPRING,
	"J": Item.Id.STRONG_FIRE,
	"K": Item.Id.STRONG_BOMB,
	"L": Item.Id.BOSS_KEY,
	"M": Item.Id.HEART,
	"N": Item.Id.HEART,
	"O": Item.Id.STRONG_SWORD,
	"P": Item.Id.HEART,
	"Q": Item.Id.KEY,
	"R": Item.Id.HEART,
	"S": Item.Id.HEART,
	"T": Item.Id.HEART,
	"U": Item.Id.HEART,
	"V": Item.Id.HEART,
	"W": Item.Id.HEART,
	"X": Item.Id.HEART,
}

## Texto de cada placa, pela casa dela.
const MESSAGES := {
	Vector2i(94, 5): "A placa fica numa ilha. Atraia um inimigo por cima dela, sem matá-lo.",
	Vector2i(130, 5): "A marca grava 5 segundos dos seus passos. O clone repete e pesa na placa.",
	Vector2i(51, 6): "Porão: o buraco da antessala cai aqui. O outro buraco leva de volta.",
	Vector2i(115, 7):
	"O cristal troca o nível da água. Cheia, a balsa é ponte. Vazia, o leito é chão.",
	Vector2i(6, 14): "Fim da fuga. O cofre fica ao norte.",
	Vector2i(113, 14): "Buraco largo: só a mola forte, com corrida, chega ao outro lado.",
	Vector2i(74, 15):
	"Oeste: buraco largo, tábuas e gelo grosso. Depois, a fuga. O portal do cofre chega aqui.",
	Vector2i(89, 15): "Acenda na ordem das pedrinhas ao pé de cada tocha. Errou, apagam todas.",
	Vector2i(123, 16): "Degrau duplo: só a mola forte sobe.",
	Vector2i(10, 25):
	"Escudeiro: só leva golpe de lado ou por trás. Soprador: empurra com vento. Rastro: deixa fogo.",
	Vector2i(66, 25):
	"O vento carrega a bomba por cima do buraco. Solte-a na frente do ventilador.",
	Vector2i(51, 27): "Empurre o bloco para o lado certo. Se travar o corredor, a bomba desfaz.",
	Vector2i(110, 27): "A placa abre a grade verde por 4 segundos. Corra.",
	Vector2i(130, 27): "Portais: pisar num leva ao outro da mesma cor.",
	Vector2i(22, 28): "No gelo o bloco desliza até bater. Leve-o ao buraco em frente à passagem.",
	Vector2i(89, 34): "Acenda as quatro tochas com a chama para abrir a porta amarela.",
	Vector2i(71, 35): "Alvo roxo: só a explosão da bomba o aciona. Ele abre a porta roxa.",
	Vector2i(108, 35):
	"Estas tochas apagam sozinhas: acenda as três antes. A teia só sai com fogo.",
	Vector2i(30, 36): "A estátua copia seus passos ao contrário. Leve-a até a placa verde.",
	Vector2i(51, 37):
	"Torretas atiram em cruz. O bloco azul para o tiro e tampa o buraco. A bomba o devolve.",
	Vector2i(129, 37): "Esteiras: carregam quem está no chão. Pular passa por cima.",
	Vector2i(4, 38):
	"Gelo liso: você desliza reto até bater em algo. Escolha a direção a cada parada.",
	Vector2i(69, 42): "Norte, parede rachada: ala da bomba.",
	Vector2i(89, 42): "Norte, gelo: ala do fogo.",
	Vector2i(131, 42):
	"Piso quebradiço: racha ao pisar e cai ao sair. Não pise duas vezes na mesma casa.",
	Vector2i(10, 44): "Arena: três levas de inimigos. As portas abrem depois da última.",
	Vector2i(49, 44): "Sala de combate: as portas vermelhas só abrem com todos os inimigos mortos.",
	Vector2i(63, 45): "Oeste, aberta: ala da espada. Comece por ela.",
	Vector2i(96, 45): "Leste, buraco: ala da mola.",
	Vector2i(103, 45): "Buraco: pule com a mola. Cair custa vida e devolve à entrada da sala.",
	Vector2i(35, 47): "Cristal: cada golpe troca as barreiras. A azul abre quando a laranja fecha.",
	Vector2i(89, 47): "Sul, trancada: sala do feixe de luz. As chaves estão nas alas.",
	Vector2i(65, 53): "Laboratório: cada sala testa uma mecânica nova. A placa da sala diz qual é.",
	Vector2i(74, 53): "Os desenhos daqui são provisórios. Vale o que acontece, não a aparência.",
	Vector2i(88, 55): "Feixe de luz: um golpe de espada vira o espelho. Leve a luz até o olho.",
	Vector2i(14, 56): "Ímã: um golpe de espada o liga, e ele puxa o bloco de metal da mesma linha.",
	Vector2i(104, 56):
	"Corredor sob ataque: atravesse até a outra porta. A esteira puxa para trás.",
	Vector2i(34, 57): "Eletricidade: empurre os blocos de metal para fechar as falhas do fio.",
}

## Levas de inimigos de cada arena, pela tela: um inimigo por letra.
const WAVES := {
	Vector2i(0, 4): ["mmm", "m]u", ")(m"],
}

## Telas das salas escuras.
const DARK_ROOMS := [
	Vector2i(4, 2),
]

## Alvo da lógica, para tools/check_chapter.py: a sentinela e o que ela exige.
const GOAL := "&"
const GOAL_TOOLS := [Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING]
