class_name Bolt
extends Area2D
## Disparo da torreta do laboratório: voa reto até bater em algo. Fere o
## personagem no chão e some em qualquer coisa sólida, o que faz de um bloco
## empurrado um escudo. O personagem no ar passa por cima. Arte provisória.
##
## Um golpe de espada o rebate: ele muda de cor, passa a voar na direção do
## golpe e não fere mais o personagem. Rebatido, ele vale como um golpe de
## espada à distância em quem acertar (um cristal do outro lado de um
## buraco, por exemplo), e desliga a torreta que acertar (lab/turret.gd).
## Ele é uma área na camada dos disparos só para a espada o achar.

const COLOR := Color(1.0, 0.35, 0.3)
const CORE_COLOR := Color(1.0, 0.9, 0.7)
const RETURNED_COLOR := Color(0.4, 0.8, 1.0)

var direction := Vector2.RIGHT
var speed := 200.0
var damage := 1
var shooter: CollisionObject2D
## Ligado depois que a espada o rebate.
var returned := false

var _shape := RectangleShape2D.new()
var _traveled := 0.0


func _ready() -> void:
	_shape.size = Vector2(10.0, 10.0)
	collision_layer = Layers.SHOT
	collision_mask = 0
	monitoring = false
	var shape := CollisionShape2D.new()
	shape.shape = _shape
	add_child(shape)


## A espada rebate o disparo na direção do golpe.
func take_hit(_amount: int, toward: Vector2, kind := Hit.Kind.SWORD) -> void:
	if returned or kind != Hit.Kind.SWORD:
		return
	returned = true
	direction = GameMath.snap_4(toward)
	shooter = null
	_traveled = 0.0
	Sfx.play(&"sword_hit")
	queue_redraw()


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
	var excluded: Array[RID] = []
	if is_instance_valid(shooter):
		excluded.append(shooter.get_rid())
	var hero := get_tree().get_first_node_in_group("player") as Player
	if returned and hero:
		excluded.append(hero.get_rid())
	query.exclude = excluded
	var results := get_world_2d().direct_space_state.intersect_shape(query, 4)
	for result: Dictionary in results:
		var collider: Object = result["collider"]
		var player := collider as Player
		if player:
			player.take_hit(damage, direction)
		elif returned and collider.has_method("bolt_returned"):
			collider.call("bolt_returned")
		elif returned and collider.has_method("take_hit"):
			collider.call("take_hit", damage, direction, Hit.Kind.SWORD)
	return not results.is_empty()


func _draw() -> void:
	draw_circle(Vector2(0.0, -8.0), 6.0, RETURNED_COLOR if returned else COLOR)
	draw_circle(Vector2(0.0, -8.0), 3.0, CORE_COLOR)
	draw_rect(Rect2(-5.0, -2.0, 10.0, 4.0), Color(0.0, 0.0, 0.0, 0.35))
