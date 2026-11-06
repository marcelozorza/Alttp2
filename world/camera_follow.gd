class_name CameraFollow
## Câmera de empurrão, com zona morta. O personagem anda livre pelo meio da
## tela sem a câmera se mexer. Quando ele chega a EDGE_TILES casas da borda da
## tela, a câmera anda junto com ele, mantendo essa distância. O centro da
## câmera fica preso aos limites dados, como antes, para nunca mostrar fora
## da sala ou do mapa. Pedido de Marcelo em 2026-11-06: com a câmera sempre
## centrada, parecia que o personagem ficava parado e o mundo é que andava.

const HALF_SCREEN := Vector2(160.0, 90.0)
## Casas entre o personagem e a borda da tela a partir das quais a câmera anda.
const EDGE_TILES := 3


## Câmera centrada no alvo, presa aos limites. Serve para o primeiro quadro
## de uma sala ou do mapa.
static func centered(target: Vector2, low: Vector2, high: Vector2) -> Vector2:
	return target.clamp(low, high)


## Câmera empurrada pelo alvo: só sai de onde está quando o alvo passa da zona
## morta. top_inset é a altura da barra do HUD, que cobre o alto da tela.
static func pushed(
	camera: Vector2, target: Vector2, low: Vector2, high: Vector2, top_inset: float
) -> Vector2:
	var edge := float(EDGE_TILES * ChapterMap.TILE)
	var zone_min := Vector2(-HALF_SCREEN.x + edge, -HALF_SCREEN.y + top_inset + edge)
	var zone_max := HALF_SCREEN - Vector2.ONE * edge
	var offset := target - camera
	var moved := camera
	if offset.x < zone_min.x:
		moved.x = target.x - zone_min.x
	elif offset.x > zone_max.x:
		moved.x = target.x - zone_max.x
	if offset.y < zone_min.y:
		moved.y = target.y - zone_min.y
	elif offset.y > zone_max.y:
		moved.y = target.y - zone_max.y
	return moved.clamp(low, high)
