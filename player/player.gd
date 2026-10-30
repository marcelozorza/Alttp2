class_name Player
extends CharacterBody2D
## Personagem controlado pelo jogador.
##
## O movimento roda em _physics_process, que o Godot executa em passo fixo
## (60 vezes por segundo, padrão de Physics > Common > Physics Ticks Per Second).
## Assim o movimento é idêntico em qualquer máquina e taxa de quadros, condição
## para que técnicas avançadas de precisão sejam reproduzíveis.
##
## A origem do nó fica no centro dos pés, e a colisão cobre só essa área.
## O corpo desenhado se estende para cima, o que permite passar por trás de
## objetos na perspectiva 3/4.
##
## Os parâmetros exportados podem ser ajustados com o jogo rodando, pela aba
## Remoto da árvore de cena, e o efeito é imediato.

@export_group("Andar")
## Velocidade máxima, em pixels por segundo.
@export_range(10.0, 300.0, 1.0) var walk_speed := 90.0
## Segundos para ir do repouso à velocidade máxima. Zero é arranque instantâneo.
@export_range(0.0, 1.0, 0.01) var acceleration_time := 0.0
## Segundos para parar a partir da velocidade máxima. Zero é parada instantânea.
@export_range(0.0, 1.0, 0.01) var deceleration_time := 0.0
## Restringe o movimento a 8 direções, como num direcional. Desligado, o
## analógico move em qualquer ângulo, com velocidade proporcional à inclinação.
@export var snap_to_8_directions := true

@export_group("Quinas")
## Distância máxima, em pixels, para escorregar pela quina ao esbarrar numa
## parede andando em linha reta. Zero desliga.
@export_range(0, 12, 1) var corner_tolerance := 6

## Direção para onde o personagem olha, sempre uma das 4 direções retas.
## Define, no futuro, para onde as ferramentas são usadas.
var facing := Vector2.DOWN

@onready var _facing_marker: ColorRect = $FacingMarker


func _physics_process(delta: float) -> void:
	var direction := _read_direction()
	_update_facing(direction)
	_update_velocity(direction, delta)
	var nudge := _corner_nudge(direction, delta)
	if nudge != Vector2.ZERO:
		velocity = nudge
	move_and_slide()
	_update_facing_marker()


func _read_direction() -> Vector2:
	var raw := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if raw == Vector2.ZERO or not snap_to_8_directions:
		return raw
	var angle := snappedf(raw.angle(), PI / 4.0)
	return Vector2(roundf(cos(angle)), roundf(sin(angle))).normalized()


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	var horizontal := Vector2(signf(direction.x), 0.0)
	var vertical := Vector2(0.0, signf(direction.y))
	if direction.x != 0.0 and direction.y != 0.0:
		# Na diagonal, mantém a frente atual se ela fizer parte da diagonal.
		if facing == horizontal or facing == vertical:
			return
		facing = horizontal if absf(direction.x) > absf(direction.y) else vertical
	else:
		facing = horizontal if direction.x != 0.0 else vertical


func _update_velocity(direction: Vector2, delta: float) -> void:
	var target := direction * walk_speed
	var time_to_full := acceleration_time if direction != Vector2.ZERO else deceleration_time
	if time_to_full <= 0.0:
		velocity = target
	else:
		velocity = velocity.move_toward(target, walk_speed / time_to_full * delta)


## Ao esbarrar numa parede andando em linha reta, procura a abertura mais
## próxima dentro de corner_tolerance pixels para cada lado. Se achar, devolve
## a velocidade que empurra o personagem até ela, limitada para não passar do
## ponto quando falta menos de um passo.
func _corner_nudge(direction: Vector2, delta: float) -> Vector2:
	if corner_tolerance <= 0 or direction == Vector2.ZERO:
		return Vector2.ZERO
	if direction.x != 0.0 and direction.y != 0.0:
		return Vector2.ZERO
	var forward := direction.normalized() * walk_speed * delta
	if not test_move(global_transform, forward):
		return Vector2.ZERO
	var perpendicular := Vector2.DOWN if direction.y == 0.0 else Vector2.RIGHT
	for offset: int in range(1, corner_tolerance + 1):
		for side: float in [-1.0, 1.0]:
			var shift := perpendicular * side * offset
			if test_move(global_transform, shift):
				continue
			if not test_move(global_transform.translated(shift), forward):
				return perpendicular * side * minf(walk_speed, offset / delta)
	return Vector2.ZERO


## Marcador provisório: um quadrado na borda do corpo, do lado para onde o
## personagem olha.
func _update_facing_marker() -> void:
	var body_center := Vector2(0.0, -4.0)
	var center := body_center + facing * Vector2(4.0, 6.0)
	_facing_marker.position = center - _facing_marker.size / 2.0
