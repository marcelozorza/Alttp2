class_name ChapterRooms
extends RefCounted
## Salas de um capítulo: que tela pertence a que sala, a sala atual, as já
## visitadas, as já limpas e os atores de cada uma.
##
## O mapa é dividido em telas de 20 por 10 casas. Uma sala é uma tela, ou
## várias telas juntas (ROOMS nos dados do capítulo). Uma sala é um Rect2i em
## unidades de tela.
##
## Os atores só agem na sala em que o personagem está. Numa sala limpa, em
## que todos os inimigos foram derrotados, eles não voltam mais (pedido de
## Marcelo em 2026-11-11). Numa sala em que sobrou algum, todos voltam quando
## o personagem sai e entra de novo.

## Tamanho de uma tela, em casas.
const ROOM_TILES := Vector2i(20, 10)

## Sala atual. Começa fora do mapa, para a primeira sala contar como troca.
var current := Rect2i(-1000, -1000, 1, 1)
## Salas em que o personagem já esteve, para o minimapa.
var visited := {}
## Salas em que todos os inimigos foram derrotados.
var cleared := {}
## Atores de cada sala: inimigos, chefes e blocos pesados.
var actors := {}

## Sala maior de cada tela que faz parte de uma.
var _rects := {}


func _init(rooms: Array) -> void:
	for rect: Rect2i in rooms:
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				_rects[Vector2i(x, y)] = rect


## Sala de uma tela: a sala maior que a contém, ou a própria tela.
func room_at(screen: Vector2i) -> Rect2i:
	return _rects.get(screen, Rect2i(screen, Vector2i.ONE))


## Sala de uma casa do mapa.
func of_cell(cell: Vector2i) -> Rect2i:
	return room_at(
		Vector2i(floori(float(cell.x) / ROOM_TILES.x), floori(float(cell.y) / ROOM_TILES.y))
	)


## Sala de um ponto do mundo, em pixels.
func of_point(point: Vector2) -> Rect2i:
	return of_cell(Vector2i((point / float(ChapterMap.TILE)).floor()))


## Área da sala em pixels, com as paredes em volta.
func pixels(room: Rect2i) -> Rect2:
	var tile := float(ChapterMap.TILE)
	return Rect2(Vector2(room.position * ROOM_TILES) * tile, Vector2(room.size * ROOM_TILES) * tile)


## Área da sala sem as paredes em volta, em pixels.
func interior(room: Rect2i) -> Rect2:
	return pixels(room).grow(-float(ChapterMap.TILE))


## Registra um ator na sala da casa dele.
func register(actor: Node, cell: Vector2i) -> void:
	var room := of_cell(cell)
	var list: Array = actors.get(room, [])
	list.append(actor)
	actors[room] = list


## Liga ou desliga os atores de uma sala. Todo ator tem a função set_active.
## Numa sala limpa, os inimigos ficam desligados para sempre.
func activate(room: Rect2i, active: bool) -> void:
	var is_cleared := cleared.has(room)
	for actor: Node in actors.get(room, []):
		actor.call("set_active", active and not (is_cleared and actor is Enemy))


## Inimigos vivos de uma sala.
func enemies_alive(room: Rect2i) -> int:
	var alive := 0
	for actor: Node in actors.get(room, []):
		var enemy := actor as Enemy
		if enemy and not enemy.is_dead():
			alive += 1
	return alive


## Marca como limpa a sala de um inimigo derrotado, se ele era o último dela.
## Devolve se a sala ficou limpa agora.
func mark_cleared_by(defeated: Enemy) -> bool:
	for room: Rect2i in actors:
		if defeated not in actors[room]:
			continue
		if enemies_alive(room) > 0:
			return false
		cleared[room] = true
		return true
	return false
