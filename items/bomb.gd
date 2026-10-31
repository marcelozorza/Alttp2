class_name Bomb
extends MomentumBody
## Bomba com pavio. Explode sozinha depois de fuse_time e atinge tudo num raio:
## causa dano, empurra os corpos pela física e abre paredes rachadas. Fogo e
## outras explosões acendem o pavio na hora. A espada só empurra a bomba, o que
## permite chutá-la para longe.
##
## O personagem atravessa as próprias bombas, para poder soltá-las aos pés.

const BODY_COLOR := Color(0.12, 0.12, 0.17, 1.0)
const WARNING_COLOR := Color(0.95, 0.25, 0.2, 1.0)
const SPARK_COLOR := Color(1.0, 0.75, 0.25, 1.0)
const BLAST_COLOR := Color(1.0, 0.85, 0.5, 1.0)
## Centro do desenho e da explosão, a partir da origem na base.
const CENTER := Vector2(0.0, -4.0)
## Ticks em que a explosão fica visível.
const BLAST_TICKS := 10
## Segundos finais do pavio em que a bomba pisca, como aviso.
const WARNING_TIME := 0.5

@export_group("Bomba")
## Segundos até explodir.
@export_range(0.2, 5.0, 0.05) var fuse_time := 1.5
## Raio da explosão, em pixels.
@export_range(4.0, 64.0, 1.0) var blast_radius := 26.0
## Dano em quem estiver no raio, inclusive o personagem.
@export_range(1, 10, 1) var damage := 1
## Empurrão da explosão, em pixels por segundo para massa 1.
@export_range(0.0, 800.0, 10.0) var blast_impulse := 240.0

var _spawn_tick := 0
var _blast_tick := -1
var _blast_shape := CircleShape2D.new()

@onready var _base: CollisionShape2D = $Base


func _ready() -> void:
	add_to_group("bombs")
	_spawn_tick = Engine.get_physics_frames()


## Fogo e explosões acendem o pavio. A bomba explode no tick seguinte, fora da
## consulta de física que a atingiu.
func take_hit(_amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if kind == Hit.Kind.FIRE or kind == Hit.Kind.BLAST:
		var lit := Engine.get_physics_frames() - GameMath.ticks(fuse_time) + 1
		_spawn_tick = mini(_spawn_tick, lit)


func _physics_process(delta: float) -> void:
	var now := Engine.get_physics_frames()
	if _blast_tick >= 0:
		if now - _blast_tick >= BLAST_TICKS:
			queue_free()
		queue_redraw()
		return
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	if velocity != Vector2.ZERO:
		move_with_impacts()
	if now - _spawn_tick >= GameMath.ticks(fuse_time):
		_explode()
	queue_redraw()


func _explode() -> void:
	_blast_tick = Engine.get_physics_frames()
	remove_from_group("bombs")
	_base.set_deferred("disabled", true)
	for body: PhysicsBody2D in get_collision_exceptions():
		body.remove_collision_exception_with(self)
	_blast_shape.radius = blast_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _blast_shape
	query.transform = Transform2D(0.0, global_position + CENTER)
	var excluded: Array[RID] = [get_rid()]
	query.exclude = excluded
	var handled: Array[Object] = []
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 64):
		var target: Object = result["collider"]
		if target in handled:
			continue
		handled.append(target)
		var target_node := target as Node2D
		var away := (target_node.global_position - global_position) if target_node else Vector2.ZERO
		var direction := away.normalized() if away != Vector2.ZERO else Vector2.DOWN
		if target.has_method("take_hit"):
			target.call("take_hit", damage, direction, Hit.Kind.BLAST)
		var body := target as MomentumBody
		if body:
			body.add_impact_velocity(direction * blast_impulse / body.mass)


func _draw() -> void:
	var now := Engine.get_physics_frames()
	if _blast_tick >= 0:
		var progress := float(now - _blast_tick) / BLAST_TICKS
		var radius := blast_radius * (0.6 + 0.4 * progress)
		draw_circle(CENTER, radius, Color(BLAST_COLOR, 1.0 - progress))
		return
	var remaining := GameMath.ticks(fuse_time) - (now - _spawn_tick)
	var warning := remaining <= GameMath.ticks(WARNING_TIME) and posmod(remaining, 6) < 3
	draw_circle(CENTER, 4.0, WARNING_COLOR if warning else BODY_COLOR)
	if posmod(now, 4) < 2:
		draw_rect(Rect2(CENTER + Vector2(1.0, -6.0), Vector2(1.0, 2.0)), SPARK_COLOR)
