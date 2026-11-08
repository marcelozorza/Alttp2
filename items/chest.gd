class_name Chest
extends StaticBody2D
## Baú que guarda um item. Abre com um golpe de espada, e o item vai direto
## para o personagem. O conteúdo vem da tabela de itens do capítulo, nunca do
## mapa.
##
## A origem fica no centro da base, para a ordenação por profundidade.

signal opened(chest: Chest)

const CLOSED_TEXTURE := preload("res://art/chest.svg")
const OPEN_TEXTURE := preload("res://art/chest_open.svg")
## Canto do desenho em relação à origem, no centro da base.
const TEXTURE_OFFSET := Vector2(-16.0, -30.0)
const SIZE := Vector2(28.0, 20.0)
## Ticks em que o item fica flutuando sobre o baú aberto.
const SHOW_ITEM_TICKS := 60

## Nome do local na lógica do capítulo.
@export var location_id := ""
## Item guardado.
@export var item := Item.Id.NONE

var is_open := false

var _open_tick := -1000


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)


## Começa aberto e vazio, num capítulo já vencido em que o item deste baú
## ficou com o personagem.
func open_silently() -> void:
	is_open = true
	queue_redraw()


## Só a espada abre o baú. Fogo e explosões não abrem, para que nenhum baú
## seja aberto do outro lado de uma parede ou de um bloqueio.
func take_hit(_amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if is_open or kind != Hit.Kind.SWORD:
		return
	is_open = true
	_open_tick = Clock.tick
	Sfx.play(&"chest_open")
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		# O baú passa a mostrar o que de fato deu: a mola forte achada antes da
		# mola é a mola.
		item = Item.progressive(player.tool_bits(), item)
		player.give_item(item)
	opened.emit(self)
	queue_redraw()


## Redesenha enquanto o item aparece e mais uma vez depois, para apagá-lo.
func _physics_process(_delta: float) -> void:
	if is_open and Clock.tick - _open_tick <= SHOW_ITEM_TICKS + 1:
		queue_redraw()


func _draw() -> void:
	if not is_open:
		draw_texture(CLOSED_TEXTURE, TEXTURE_OFFSET)
		return
	draw_texture(OPEN_TEXTURE, TEXTURE_OFFSET)
	var elapsed := Clock.tick - _open_tick
	if elapsed <= SHOW_ITEM_TICKS:
		var rise := minf(elapsed, 20.0)
		ToolIcons.draw(self, item, Vector2(0.0, -SIZE.y - 20.0 - rise), Color.WHITE, 2)
