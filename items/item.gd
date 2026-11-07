class_name Item
## Itens que um baú pode conter. As ferramentas também são as chaves do mapa.
##
## Para saber se um item é ferramenta, use "id in Item.TOOLS". As funções
## estáticas daqui não podem repetir o nome de um método da classe Script do
## Godot: uma função is_tool, por exemplo, é ignorada, e Item.is_tool(id) chama
## o método do Script, que não recebe argumentos e trava o jogo.
##
## A chave pequena abre uma porta trancada e some ao abrir, então conta como
## quantidade. A chave grande abre a porta do chefe e nunca se gasta, então
## entra no conjunto de bits junto com as ferramentas.
##
## A chama forte e a mola forte são melhorias: não ganham botão, mas mudam a
## ferramenta. A chama forte derrete o gelo grosso e queima mais, e a mola
## forte dá um pulo mais alto, que sobe o degrau duplo. A partir do capítulo 2,
## cada capítulo novo melhora uma ferramenta em vez de criar outra.

enum Id { NONE, BOMB, FIRE, SPRING, STRONG_FIRE, STRONG_SPRING, HEART, KEY, BOSS_KEY }

## Ferramentas, cada uma no seu botão.
const TOOLS := [Id.BOMB, Id.FIRE, Id.SPRING]
## Itens que ficam para sempre e entram na lógica como bits: as ferramentas,
## as melhorias e a chave grande.
const PERMANENT := [Id.BOMB, Id.FIRE, Id.SPRING, Id.STRONG_FIRE, Id.STRONG_SPRING, Id.BOSS_KEY]


## Bit do item num conjunto de ferramentas guardado como inteiro.
static func bit(id: int) -> int:
	return 1 << id


static func has(tools: int, id: int) -> bool:
	return (tools & bit(id)) != 0
