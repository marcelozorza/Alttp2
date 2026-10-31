class_name Item
## Itens que um baú pode conter. As ferramentas também são as chaves do mapa.

enum Id { NONE, BOMB, FIRE, SPRING, HEART }

## Ferramentas na ordem em que o botão de troca passa por elas.
const TOOLS := [Id.BOMB, Id.FIRE, Id.SPRING]


## Bit do item num conjunto de ferramentas guardado como inteiro.
static func bit(id: int) -> int:
	return 1 << id


static func is_tool(id: int) -> bool:
	return id in TOOLS


static func has(tools: int, id: int) -> bool:
	return (tools & bit(id)) != 0
