class_name FreeBlock
extends HeavyBlock
## Bloco solto do laboratório: o bloco pesado sem trilho. Tomba de casa em
## casa para qualquer lado em que a casa seguinte esteja livre, o que permite
## quebra-cabeças de ordem, usar o bloco como escudo e tampar um buraco de
## ponte: empurrado para dentro de um buraco, ele afunda e a casa vira chão.
##
## Ele só anda no miolo da sala, a duas casas das paredes de fora, para nunca
## tampar uma porta. Como o bloco pesado, volta ao lugar inicial quando o
## personagem entra de novo na sala. Uma explosão também o devolve ao lugar,
## para desfazer um empurrão errado sem sair da sala. Em cima do gelo liso
## (lab/ice_field.gd), ele desliza reto até bater em algo, e outro bloco
## serve de freio.

## Casas de borda da sala em que o bloco não entra.
const ROOM_MARGIN := 2

var _probe := RectangleShape2D.new()


func _ready() -> void:
	super()
	_probe.size = Vector2(tile - 8.0, tile - 8.0)
	modulate = Color(0.75, 0.85, 1.0)


func take_hit(_amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if Hit.is_blast(kind) and not locked and not is_tumbling():
		reset()


## A casa seguinte serve se fica no miolo da sala e não tem nada sólido.
func _can_move_to(cell: Vector2i) -> bool:
	var room := ChapterRooms.ROOM_TILES
	var inside := Vector2i(posmod(cell.x, room.x), posmod(cell.y, room.y))
	if inside.x < ROOM_MARGIN or inside.x >= room.x - ROOM_MARGIN:
		return false
	if inside.y < ROOM_MARGIN or inside.y >= room.y - ROOM_MARGIN:
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _probe
	query.transform = Transform2D(0.0, (Vector2(cell) + Vector2(0.5, 0.5)) * tile)
	query.collision_mask = Layers.SCENERY
	var excluded: Array[RID] = [get_rid()]
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		excluded.append(player.get_rid())
	query.exclude = excluded
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


## Parado numa casa de buraco aberto, o bloco afunda e tampa a casa.
func _on_landed() -> void:
	var cell := _cell()
	for pit: Pit in get_tree().get_nodes_in_group("pits"):
		if pit.is_open_at(cell):
			pit.fill(cell)
			locked = true
			visible = false
			$Base.set_deferred("disabled", true)
			Sfx.play(&"ledge_drop")
			return
	# No gelo liso, o bloco segue deslizando até bater em algo.
	var ice := get_tree().get_first_node_in_group("ice_field") as IceField
	var next := cell + Vector2i(_tumble_direction)
	if ice and ice.cells.has(cell) and _can_move_to(next):
		_start_tumble(_tumble_direction)
