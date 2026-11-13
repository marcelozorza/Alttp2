class_name Relic
extends Area2D
## Relíquia do fim do capítulo. Aparece quando o chefe cai, e tocar nela
## conclui o capítulo.

signal collected

const TEXTURE := preload("res://art/relic.svg")
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)

var _collected := false


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is Player):
		return
	_collected = true
	Sfx.play(&"relic")
	collected.emit()


func _draw() -> void:
	var bob := sin(Clock.tick * 0.08) * 4.0
	var center := Vector2(0.0, -36.0 + bob)
	draw_rect(Rect2(Vector2(-16.0, -3.0), Vector2(32.0, 6.0)), SHADOW_COLOR)
	draw_texture(TEXTURE, (center - TEXTURE.get_size() / 2.0).round())
