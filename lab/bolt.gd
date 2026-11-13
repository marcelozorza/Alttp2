class_name Bolt
extends Node2D
## Disparo da torreta do laboratório: voa reto até bater em algo. Fere o
## personagem no chão e some em qualquer coisa sólida, o que faz de um bloco
## empurrado um escudo. O personagem no ar passa por cima. Arte provisória.

const COLOR := Color(1.0, 0.35, 0.3)
const CORE_COLOR := Color(1.0, 0.9, 0.7)

var direction := Vector2.RIGHT
var speed := 200.0
var damage := 1
var shooter: CollisionObject2D

var _shape := RectangleShape2D.new()
var _traveled := 0.0


func _ready() -> void:
	_shape.size = Vector2(10.0, 10.0)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_traveled += speed * delta
	if _hit_something() or _traveled > 1400.0:
		queue_free()


func _hit_something() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = Layers.SCENERY
	if is_instance_valid(shooter):
		var excluded: Array[RID] = [shooter.get_rid()]
		query.exclude = excluded
	var results := get_world_2d().direct_space_state.intersect_shape(query, 4)
	for result: Dictionary in results:
		var player := result["collider"] as Player
		if player:
			player.take_hit(damage, direction)
	return not results.is_empty()


func _draw() -> void:
	draw_circle(Vector2(0.0, -8.0), 6.0, COLOR)
	draw_circle(Vector2(0.0, -8.0), 3.0, CORE_COLOR)
	draw_rect(Rect2(-5.0, -2.0, 10.0, 4.0), Color(0.0, 0.0, 0.0, 0.35))
