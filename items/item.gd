class_name Item
## Itens que um baú pode conter. As ferramentas também são as chaves do mapa.
##
## Para saber se um item é ferramenta, use "id in Item.TOOLS". As funções
## estáticas daqui não podem repetir o nome de um método da classe Script do
## Godot: uma função is_tool, por exemplo, é ignorada, e Item.is_tool(id) chama
## o método do Script, que não recebe argumentos e trava o jogo.

enum Id { NONE, BOMB, FIRE, SPRING, HEART }

## Ferramentas na ordem em que o botão de troca passa por elas.
const TOOLS := [Id.BOMB, Id.FIRE, Id.SPRING]


## Bit do item num conjunto de ferramentas guardado como inteiro.
static func bit(id: int) -> int:
	return 1 << id


static func has(tools: int, id: int) -> bool:
	return (tools & bit(id)) != 0
