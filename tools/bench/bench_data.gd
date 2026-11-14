class_name BenchData
## Bancada de teste dos mecanismos de sala (mechanics/). Não faz parte do
## jogo: fica em tools/, fora do exe, e só o teste tools/mechanics_test.gd a
## abre. São seis salas de uma tela em fila, uma ou duas mecânicas por sala:
##
## 0. Cristal, barreira azul na porta e barreira laranja no nicho do baú.
## 1. Placa de pressão com tempo e a grade verde, com um desvio no caminho.
## 2. Três tochas com tempo e a porta amarela.
## 3. Arena de duas levas, a segunda com o rastro de fogo.
## 4. Chão de gelo, e o ventilador que carrega a bomba até um cristal.
## 5. O chefe, alvo da lógica.
##
## Confira com: python3 tools/check_chapter.py tools/bench/bench_data.gd

# gdlint: disable=max-line-length
const MAP := [
	"########################################################################################################################",
	"#............#A.g..##..............#...##..................##..................##...........#⇓#....##..................#",
	"#............#..g..##..............#.;.##./............/...##............_.....##.~~~~~~~.....#....##..................#",
	"#.....!......####.###..............#...##.................####................###.~~~~~~~...#.#...###..................#",
	"#.................f................k......................h..e................e...~~~~~~~...#.#...f...........*........#",
	"#..@..............f................k......................h..e................e...~~~~~~~...#.#...f....................#",
	"#.................###.##############...##.................####................###.~~~~~~~...#.#...###..................#",
	"#..................##..............#...##./................##......._.....__...##...........#!#....##..................#",
	"#..................##.........;....#...##..................##..................##..................##..................#",
	"########################################################################################################################",
]
# gdlint: enable=max-line-length

## Tipo de cada vaga de bloqueio do mapa.
const BLOCKS := {
	"e": ChapterMap.Block.SHUTTER,
	"f": ChapterMap.Block.BARRIER,
	"g": ChapterMap.Block.BARRIER_ALT,
	"h": ChapterMap.Block.TORCH_DOOR,
	"k": ChapterMap.Block.TIMED_GATE,
}

## Item de cada baú.
const ITEMS := {
	"A": Item.Id.HEART,
}

const STARTING_TOOLS := [Item.Id.BOMB, Item.Id.FIRE]

## Levas de inimigos da arena, pela tela: um inimigo por letra.
const WAVES := {
	Vector2i(3, 0): ["mm", ")m"],
}

## Alvo da lógica, para tools/check_chapter.py.
const GOAL := "*"
const GOAL_TOOLS := []
