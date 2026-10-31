class_name Relic
extends Area2D
## Relíquia do fim do capítulo. Aparece quando o chefe cai, e tocar nela
## conclui o capítulo.

signal collected

const COLOR := Color(1.0, 0.84, 0.3, 1.0)
const SHINE_COLOR := Color(1.0, 1.0, 0.85, 1.0)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)

var _collected := false


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is Player):
		return
	_collected = true
	collected.emit()


func _draw() -> void:
	var bob := sin(Engine.get_physics_frames() * 0.08) * 2.0
	var center := Vector2(0.0, -12.0 + bob)
	draw_rect(Rect2(Vector2(-4.0, -1.0), Vector2(8.0, 2.0)), SHADOW_COLOR)
	var gem := PackedVector2Array(
		[
			center + Vector2(0.0, -7.0),
			center + Vector2(5.0, 0.0),
			center + Vector2(0.0, 7.0),
			center + Vector2(-5.0, 0.0),
		]
	)
	draw_colored_polygon(gem, COLOR)
	draw_rect(Rect2(center + Vector2(-2.0, -3.0), Vector2(1.0, 3.0)), SHINE_COLOR)
