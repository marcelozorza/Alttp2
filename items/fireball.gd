class_name Fireball
extends Node2D
## Bola de fogo da chama. Voa reto na direção da frente até bater em algo ou
## percorrer o alcance. Derrete gelo, acende bombas e queima inimigos.
##
## Com a chama forte, a bola é maior, com o miolo branco, e o golpe é de fogo
## forte: faz tudo o que o fogo comum faz e ainda derrete o gelo grosso.
##
## A posição é a do chão. O desenho fica um pouco acima, com a sombra embaixo.

const TEXTURE := preload("res://art/fireball.svg")
const STRONG_TEXTURE := preload("res://art/fireball_strong.svg")
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
## Altura do desenho acima do chão, em pixels.
const DRAW_HEIGHT := 12.0

## Velocidade, em pixels por segundo.
@export_range(20.0, 800.0, 1.0) var speed := 340.0
## Distância máxima, em pixels.
@export_range(16.0, 640.0, 1.0) var max_distance := 240.0
## Dano por acerto. Os multiplicadores de cada alvo fazem o resto.
@export_range(1, 10, 1) var damage := 1

var direction := Vector2.RIGHT
var shooter: CollisionObject2D
## Ligado, é a bola da chama forte.
var strong := false

var _traveled := 0.0
var _shape := RectangleShape2D.new()


func _ready() -> void:
	add_to_group("fireballs")
	_shape.size = Vector2(16.0, 16.0) if strong else Vector2(12.0, 12.0)


func _physics_process(delta: float) -> void:
	if _hit_something() or _traveled >= max_distance:
		queue_free()
		return
	var step := direction * speed * delta
	position += step
	_traveled += step.length()
	queue_redraw()


## Tipo do golpe desta bola.
func hit_kind() -> Hit.Kind:
	return Hit.Kind.STRONG_FIRE if strong else Hit.Kind.FIRE


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
			target.call("take_hit", damage, direction, hit_kind())
	if results.is_empty():
		return false
	Sfx.play(&"fire_hit")
	return true


func _draw() -> void:
	# A chama tremula alternando o desenho espelhado.
	var flicker := posmod(Clock.tick, 4) < 2
	var texture := STRONG_TEXTURE if strong else TEXTURE
	var half := texture.get_width() / 2.0
	draw_rect(Rect2(Vector2(-half / 2.0, -2.0), Vector2(half, 4.0)), SHADOW_COLOR)
	var rect := Rect2(Vector2(-half, -DRAW_HEIGHT - half), Vector2(half, half) * 2.0)
	if flicker:
		rect = Rect2(rect.end.x, rect.position.y, -rect.size.x, rect.size.y)
	draw_texture_rect(texture, rect, false)
