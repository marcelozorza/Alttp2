class_name Fan
extends StaticBody2D
## Ventilador do laboratório: um pilar que sopra sem parar numa direção fixa
## (lab/wind.gd). Não fere nem morre. Serve para empurrar o personagem numa
## travessia e para carregar uma bomba por cima de um buraco até um alvo de
## explosão. Só sopra com o personagem na sala (set_active). Arte provisória.
##
## A origem fica no centro da base, para a ordenação por profundidade.

const SIZE := Vector2(24.0, 16.0)
const BODY_COLOR := Color(0.55, 0.75, 0.85)

var direction := Vector2.RIGHT

var _active := false


func _ready() -> void:
	collision_layer = Layers.SCENERY
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	shape.position = Vector2(0.0, -SIZE.y / 2.0)
	add_child(shape)


func set_active(active: bool) -> void:
	_active = active
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not _active:
		return
	Wind.push(get_tree(), global_position, direction, delta)
	queue_redraw()


func _draw() -> void:
	GroundShadow.draw(self, Vector2(0.0, -2.0), 28.0)
	draw_rect(Rect2(-14.0, -30.0, 28.0, 30.0), DoorArt.OUTLINE_COLOR)
	draw_rect(Rect2(-12.0, -28.0, 24.0, 26.0), BODY_COLOR)
	var center := Vector2(0.0, -15.0)
	draw_line(center, center + direction * 10.0, DoorArt.OUTLINE_COLOR, 4.0)
	if _active:
		Wind.draw(self, direction)
