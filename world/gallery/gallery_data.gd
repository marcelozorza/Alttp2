class_name GalleryData
## Galeria: a área de testes com todos os elementos do jogo, aberta pelo menu
## de título (pedido de Marcelo em 2026-11-08, para ver as sprites e os
## cenários sem jogar as dungeons). Quatro salas de uma tela, uma por tema de
## dungeon (ROOM_THEMES): pedra, castelo, gelo e ruínas. Todos os inimigos e
## os quatro chefes agem como no jogo, mas o Giorgino não perde vida
## (NO_DAMAGE). Ele chega com todas as ferramentas, e cada baú tem um item
## diferente, inclusive a chave da porta trancada e a chave grande da porta do
## chefe. Fora das listas de capítulos e da lógica das seeds.

const MAP := [
	"########################################",
	"#..................##..................#",
	"#.@...::::::.....B.##...i..55...66.w...#",
	"#.....::::::...m...##..................#",
	"#.....222222....*..33..................#",
	"#..?...............33.........&........#",
	"#.............11...##..................#",
	"#.A..u..........c..##.C..............D.#",
	"#..................##..................#",
	"#########..##################77#########",
	"#########..##################77#########",
	"#.....^^^^.........##..................#",
	"#..s..^^^^......x..##..y............z..#",
	"#.....8888.........##..................#",
	"#.....8888.........44..................#",
	"#.........%........44.........$........#",
	"#............=0....##..................#",
	"#.E..............F.##.G..............H.#",
	"#..................##..................#",
	"########################################",
]

const BLOCKS := {
	"1": ChapterMap.Block.CRACKED,
	"2": ChapterMap.Block.LEDGE,
	"3": ChapterMap.Block.LOCKED,
	"4": ChapterMap.Block.BOSS_DOOR,
	"5": ChapterMap.Block.ICE,
	"6": ChapterMap.Block.THICK_ICE,
	"7": ChapterMap.Block.GATE,
	"8": ChapterMap.Block.TALL_LEDGE,
}

const ITEMS := {
	"A": Item.Id.BOMB,
	"B": Item.Id.KEY,
	"C": Item.Id.FIRE,
	"D": Item.Id.BOSS_KEY,
	"E": Item.Id.SPRING,
	"F": Item.Id.HEART,
	"G": Item.Id.STRONG_FIRE,
	"H": Item.Id.STRONG_SPRING,
}

const STARTING_TOOLS := [
	Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING, Item.Id.STRONG_FIRE, Item.Id.STRONG_SPRING
]

## Tema de cada sala de uma tela, pela posição da sala.
const ROOM_THEMES := {
	Vector2i(0, 0): "stone",
	Vector2i(1, 0): "castle",
	Vector2i(0, 1): "ice",
	Vector2i(1, 1): "moss",
}

## Texto da placa de mensagem ("?" no mapa), pela casa dela.
const MESSAGES := {
	Vector2i(3, 5): "Placa de mensagem. O texto aparece enquanto o Giorgino está em cima dela.",
}

## O Giorgino não perde vida aqui.
const NO_DAMAGE := true
