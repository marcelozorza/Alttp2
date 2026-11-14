class_name DungeonState
## Estado de uma dungeon em valores simples (texto, números e listas): letras
## dos baús abertos, vagas dos bloqueios removidos, posição dos blocos
## travados, salas limpas e visitadas, chaves pequenas e a chave grande.
##
## No modo randomizado, a dungeon fica como o jogador a deixou ao sair e
## voltar (Progress.dungeons): Marcelo saiu de uma dungeon para buscar a bomba
## em outra e, na volta, achou portas, inimigos e mapa zerados (2026-11-13).


## Como a dungeon está agora.
static func capture(chapter: Chapter) -> Dictionary:
	var chests := ""
	for chest: Chest in chapter.chests():
		if chest.is_open:
			chests += chest.location_id
	var slots := ""
	for slot: String in chapter.obstacle_slots():
		if not chapter.obstacle_at(slot) is SwitchDoor and chapter.block_cleared(slot):
			slots += slot
	var player := chapter.player()
	return {
		"chests": chests,
		"slots": slots,
		"blocks": chapter.gates.locked_blocks(),
		"cleared": _rooms_to_lists(chapter.rooms.cleared),
		"visited": _rooms_to_lists(chapter.rooms.visited),
		"keys": player.keys,
		"boss_key": player.has_tool(Item.Id.BOSS_KEY),
	}


## Põe a dungeon como estava no estado guardado. Vazio, não muda nada.
static func apply(chapter: Chapter, state: Dictionary) -> void:
	if state.is_empty():
		return
	var chests: String = str(state.get("chests", ""))
	for chest: Chest in chapter.chests():
		if chests.contains(chest.location_id):
			chest.open_silently()
	for slot: String in str(state.get("slots", "")):
		var obstacle := chapter.obstacle_at(slot)
		if obstacle is LockedDoor:
			(obstacle as LockedDoor).open_silently()
		elif obstacle is Obstacle and not obstacle is SwitchDoor:
			(obstacle as Obstacle).clear_silently()
	chapter.gates.lock_blocks(state.get("blocks", []))
	_lists_to_rooms(state.get("cleared", []), chapter.rooms.cleared)
	_lists_to_rooms(state.get("visited", []), chapter.rooms.visited)
	var player := chapter.player()
	player.keys = int(state.get("keys", 0))
	if state.get("boss_key", false):
		player.restore(player.tool_bits() | Item.bit(Item.Id.BOSS_KEY), player.max_health)


static func _rooms_to_lists(rooms: Dictionary) -> Array:
	var lists: Array = []
	for room: Rect2i in rooms:
		lists.append([room.position.x, room.position.y, room.size.x, room.size.y])
	return lists


static func _lists_to_rooms(lists: Variant, rooms: Dictionary) -> void:
	if not lists is Array:
		return
	for entry in lists:
		if entry is Array and entry.size() >= 4:
			var corner := Vector2i(int(entry[0]), int(entry[1]))
			rooms[Rect2i(corner, Vector2i(int(entry[2]), int(entry[3])))] = true
