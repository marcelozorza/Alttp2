class_name MirrorStatue
extends CharacterBody2D
## Estátua espelhada do laboratório: copia cada passo do personagem com a
## horizontal invertida. Ele vai para a esquerda, ela vai para a direita, e
## para cima e para baixo os dois vão juntos. Não fere nem morre. O desafio
## é guiá-la até uma placa de pressão, usando as paredes para desalinhar os
## dois. Ela pesa sobre as placas (grupo plate_weights). Arte provisória.
##
## Liga e desliga com a sala e volta ao lugar a cada entrada (set_active).
## A origem fica no centro da base, para a ordenação por profundidade.

const SIZE := Vector2(22.0, 14.0)
## Passo máximo copiado por tick, em pixels. Acima disso o personagem foi
## levado por um portal ou por uma queda, e ela não copia.
const MAX_STEP := 8.0
const BODY_COLOR := Color(0.7, 0.7, 0.78)
const EYE_COLOR := Color(0.3, 0.9, 0.9)

var _active := false
var _last_player := Vector2.ZERO

@onready var _home := global_position


func _ready() -> void:
	add_to_group("plate_weights")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = Layers.SCENERY
	collision_mask = Layers.SCENERY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)


func set_active(active: bool) -> void:
	_active = active
	global_position = _home
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		_last_player = player.global_position


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	var step := player.global_position - _last_player
	_last_player = player.global_position
	if step == Vector2.ZERO or step.length() > MAX_STEP:
		return
	move_and_collide(Vector2(-step.x, step.y))


func _draw() -> void:
	GroundShadow.draw(self, Vector2(0.0, -2.0), 26.0)
	draw_rect(Rect2(-13.0, -36.0, 26.0, 36.0), DoorArt.OUTLINE_COLOR)
	draw_rect(Rect2(-11.0, -34.0, 22.0, 32.0), BODY_COLOR)
	draw_rect(Rect2(-7.0, -28.0, 5.0, 5.0), EYE_COLOR)
	draw_rect(Rect2(2.0, -28.0, 5.0, 5.0), EYE_COLOR)
