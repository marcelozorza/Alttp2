class_name Fireball
extends Node2D
## Bola de fogo da chama. Voa reto na direção da frente até bater em algo ou
## percorrer o alcance. Derrete gelo, acende bombas e queima inimigos.
##
## A posição é a do chão. O desenho fica um pouco acima, com a sombra embaixo.

const TEXTURE := preload("res://art/fireball.svg")
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
## Altura do desenho acima do chão, em pixels.
const DRAW_HEIGHT := 6.0

## Velocidade, em pixels por segundo.
@export_range(10.0, 400.0, 1.0) var speed := 170.0
## Distância máxima, em pixels.
@export_range(8.0, 320.0, 1.0) var max_distance := 120.0
## Dano por acerto.
@export_range(1, 10, 1) var damage := 1

var direction := Vector2.RIGHT
var shooter: CollisionObject2D

var _traveled := 0.0
var _shape := RectangleShape2D.new()


func _ready() -> void:
	add_to_group("fireballs")
	_shape.size = Vector2(6.0, 6.0)


func _physics_process(delta: float) -> void:
	if _hit_something() or _traveled >= max_distance:
		queue_free()
		return
	var step := direction * speed * delta
	position += step
	_traveled += step.length()
	queue_redraw()


## Procura o que estiver na posição atual. Qualquer coisa sólida apaga a bola,
## e quem tem take_hit recebe o fogo.
func _hit_something() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape
	query.transform = Transform2D(0.0, global_position)
	if is_instance_valid(shooter):
		var excluded: Array[RID] = [shooter.get_rid()]
		query.exclude = excluded
	var results := get_world_2d().direct_space_state.intersect_shape(query, 8)
	for result: Dictionary in results:
		var target: Object = result["collider"]
		if target.has_method("take_hit"):
			target.call("take_hit", damage, direction, Hit.Kind.FIRE)
	if results.is_empty():
		return false
	Sfx.play(&"fire_hit")
	return true


func _draw() -> void:
	# A chama tremula alternando o desenho espelhado.
	var flicker := posmod(Engine.get_physics_frames(), 4) < 2
	draw_rect(Rect2(Vector2(-2.0, -1.0), Vector2(4.0, 2.0)), SHADOW_COLOR)
	var rect := Rect2(Vector2(-4.0, -DRAW_HEIGHT - 4.0), Vector2(8.0, 8.0))
	if flicker:
		rect = Rect2(rect.end.x, rect.position.y, -rect.size.x, rect.size.y)
	draw_texture_rect(TEXTURE, rect, false)
