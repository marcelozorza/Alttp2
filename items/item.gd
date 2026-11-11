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
##
## As melhorias são progressivas, como no randomizer do A Link to the Past: a
## primeira mola encontrada é a mola e a segunda é a mola forte, seja qual for
## a ordem dos baús, e o mesmo vale para a chama. Sem isso, uma seed podia dar
## a mola forte antes da mola, e o jogador não pulava nem com a lógica achando
## que sim (seed travada que Marcelo pegou em 2026-11-07). O jogo e a lógica
## passam todo item por progressive antes de ganhá-lo.
##
## A bomba forte (2026-11-11) é a melhoria da bomba: a explosão abre a parede
## rachada com tábua, que a bomba comum só faz tremer. Ela fica no fim da
## lista porque o número de cada item é o bit dele nos salvamentos.

enum Id { NONE, BOMB, FIRE, SPRING, STRONG_FIRE, STRONG_SPRING, HEART, KEY, BOSS_KEY, STRONG_BOMB }

## Ferramentas, cada uma no seu botão.
const TOOLS := [Id.BOMB, Id.FIRE, Id.SPRING]
## Itens que ficam para sempre e entram na lógica como bits: as ferramentas,
## as melhorias e a chave grande.
const PERMANENT := [
	Id.BOMB, Id.FIRE, Id.SPRING, Id.STRONG_FIRE, Id.STRONG_SPRING, Id.BOSS_KEY, Id.STRONG_BOMB
]
## Cada melhoria e a ferramenta que ela melhora.
const UPGRADES := {Id.STRONG_FIRE: Id.FIRE, Id.STRONG_SPRING: Id.SPRING, Id.STRONG_BOMB: Id.BOMB}


## Bit do item num conjunto de ferramentas guardado como inteiro.
static func bit(id: int) -> int:
	return 1 << id


static func has(tools: int, id: int) -> bool:
	return (tools & bit(id)) != 0


## O que um item vale para quem tem estas ferramentas: a melhoria vira a
## ferramenta enquanto falta a ferramenta, e a ferramenta repetida vira a
## melhoria.
static func progressive(tools: int, id: int) -> int:
	for upgrade: int in UPGRADES:
		var base: int = UPGRADES[upgrade]
		if id == upgrade and not has(tools, base):
			return base
		if id == base and has(tools, base):
			return upgrade
	return id


## As ferramentas depois de ganhar o item, já progressivo.
static func collect(tools: int, id: int) -> int:
	return tools | bit(progressive(tools, id))
