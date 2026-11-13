class_name BlockMaker
extends StaticBody2D
## Fonte de blocos do laboratório: um pedestal que cria um bloco solto
## (lab/free_block.gd) na casa logo ao sul dele a cada golpe de espada. Só
## existe um bloco dela por vez: enquanto o bloco está inteiro, o golpe o
## traz de volta para a casa da fonte, e só depois que ele afunda num buraco
## a fonte cria outro. Serve às salas que gastam mais de um bloco. Com a
## casa da fonte ocupada, o golpe é negado. Arte provisória.
##
## A origem fica no centro da base, para a ordenação por profundidade.

const SIZE := Vector2(24.0, 14.0)
const BLOCK_SCENE := preload("res://lab/free_block.tscn")
## Ticks em que um golpe novo é ignorado depois de um que valeu.
const DEBOUNCE_TICKS := 20
const BASE_COLOR := Color(0.4, 0.45, 0.6)
const RUNE_COLOR := Color(0.75, 0.85, 1.0)

## Bloco atual da fonte.
var _block: FreeBlock
var _made_tick := -1000
var _probe := RectangleShape2D.new()


func _ready() -> void:
	collision_layer = Layers.SCENERY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)
	_probe.size = Vector2(ChapterMap.TILE - 8.0, ChapterMap.TILE - 8.0)


## Diz se a fonte tem um bloco inteiro no mundo.
func has_block() -> bool:
	return _block != null and not _block.locked


func take_hit(_amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if kind != Hit.Kind.SWORD or Clock.tick - _made_tick < DEBOUNCE_TICKS:
		return
	if (has_block() and _block.is_tumbling()) or not _spawn_cell_free():
		Sfx.play(&"deny")
		return
	_made_tick = Clock.tick
	if has_block():
		_block.reset()
	else:
		_create()
	Sfx.play(&"item_key")
	queue_redraw()


## Casa em que o bloco nasce: a do sul da fonte.
func _spawn_cell() -> Vector2i:
	return Pit.cell_of(global_position + Vector2(0.0, -SIZE.y / 2.0)) + Vector2i.DOWN


func _spawn_cell_free() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _probe
	query.transform = Transform2D(
		0.0, (Vector2(_spawn_cell()) + Vector2(0.5, 0.5)) * ChapterMap.TILE
	)
	query.collision_mask = Layers.SCENERY
	var excluded: Array[RID] = [get_rid()]
	if has_block():
		excluded.append(_block.get_rid())
	query.exclude = excluded
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _create() -> void:
	var cell := _spawn_cell()
	_block = BLOCK_SCENE.instantiate() as FreeBlock
	_block.position = (
		(Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE + FloorSwitch.BLOCK_OFFSET
	)
	get_parent().add_child(_block)
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	if chapter:
		chapter.rooms.register(_block, cell)


func _draw() -> void:
	GroundShadow.draw(self, Vector2(0.0, -2.0), 28.0)
	draw_rect(Rect2(-14.0, -22.0, 28.0, 22.0), DoorArt.OUTLINE_COLOR)
	draw_rect(Rect2(-12.0, -20.0, 24.0, 18.0), BASE_COLOR)
	var glow := RUNE_COLOR if not has_block() else RUNE_COLOR.darkened(0.45)
	draw_rect(Rect2(-5.0, -16.0, 10.0, 10.0), glow)
	draw_rect(Rect2(-5.0, -16.0, 10.0, 10.0), DoorArt.OUTLINE_COLOR, false, 1.0)
