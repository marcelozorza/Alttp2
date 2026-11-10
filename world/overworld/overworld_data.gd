class_name OverworldData
## Mapa do mundo de chegada, que liga as dungeons. Redesenhado em 2026-11-10 a
## pedido de Marcelo: o personagem começa numa clareira ao sul, e a primeira
## porta que ele vê, logo ao norte, é a da dungeon de teste. No caminho até
## ela, as regras iniciais estão gravadas em lajes no chão, para serem lidas
## andando, sem parar o jogo. Passando a dungeon de teste, a clareira grande
## tem a pedra de salvamento, um lago e as três dungeons na linha de árvores
## ao norte, cada uma com a fachada e o chão do tema dela.
##
## Legenda: "#" mata, "~" água, "." grama, "," caminho de terra, "=" calçada
## do castelo, "*" neve, ";" lajes das ruínas, "@" início, "S" pedra de
## salvamento e os algarismos as entradas, duas casas cada, com o número do
## capítulo. O zero é a dungeon de teste.

# O mapa tem 40 casas de largura, duas telas, e 26 de altura.
const MAP := [
	"########################################",
	"########################################",
	"######11##########22##########33########",
	"#####=,,=....###**,,**###....;,,;..#####",
	"####.=,,=.....##**,,**##....;;,,;;..####",
	"###..==,,=.....**,,,**......;,,;;....###",
	"###....,,........,,.........,,.......###",
	"##.....,,,,,,,,,,,,,,,,,,,,,,,........##",
	"##.......~~~.....,,.....##............##",
	"##......~~~~~....,,....####.....#.....##",
	"###.....~~~~.....,,.....##.....###...###",
	"###......~~......,S.............#....###",
	"####.............,,.................####",
	"#####...........,,,,...............#####",
	"########......,,,,,,,,.......###########",
	"###########..,,,,..,,,,..###############",
	"###########..,,,####,,,..###############",
	"###########..,,##00##,,..###############",
	"############..,,,,,,,,..################",
	"#############....,,....#################",
	"#############....,,....#################",
	"#############....,,....#################",
	"#############....,,....#################",
	"#############....,,....#################",
	"##############...@....##################",
	"########################################",
]

## Textos gravados em lajes no chão: o centro da laje, em casas, e o texto.
## Só as regras que valem desde o primeiro passo. Os itens o jogador descobre
## sozinho, e os nomes dos botões seguem o controle do Super Nintendo.
const FLOOR_TEXTS := [
	[Vector2(18.0, 22.75), "Botão B: espada."],
	[Vector2(18.0, 21.65), "Toque 2 vezes na direção para correr."],
	[Vector2(18.0, 20.55), "Correndo, nenhum golpe te acerta."],
	[Vector2(18.0, 19.45), "O fôlego acaba. Descanse e corra de novo."],
	[Vector2(18.0, 18.45), "Aprenda aqui dentro."],
	[Vector2(21.6, 11.5), "A pedra guarda o jogo e cura."],
	[Vector2(18.0, 7.5), "Três dungeons. Em cada uma, um chefe."],
]
