class_name Chaser
extends Node2D
## Parede de fogo da cena de fuga do laboratório. Quando o personagem entra
## na sala, ela espera um instante e avança de uma ponta à outra, na
## horizontal, a uma velocidade abaixo da corrida e pouco abaixo do andar.
## Quem fica para trás da frente de fogo leva dano. Ela para a algumas casas
## da parede do fim, onde fica a saída. Ela parte da ponta por onde o
## personagem entrou. Arte provisória.
##
## Liga e desliga com a sala (set_active) e recomeça a cada entrada. A origem
## fica na casa do mapa em que ela nasce, encostada numa das paredes.

## Segundos parada depois que o personagem entra.
const START_DELAY := 1.2
## Casas livres que sobram no fim da sala.
const SAFE_TILES := 11
const DAMAGE := 1
const FIRE_COLOR := Color(1.0, 0.45, 0.1, 0.55)
const FRONT_COLOR := Color(1.0, 0.9, 0.4, 0.95)

## Velocidade da frente de fogo, em pixels por segundo.
var speed := 150.0
## Área da sala sem as paredes, em pixels do mundo. Quem monta a sala define.
var arena := Rect2()

var _active := false
var _start_tick := 0
var _direction := 1.0
## Posição da frente de fogo no eixo x, em pixels do mundo.
var _front := 0.0


func set_active(active: bool) -> void:
	_active = active
	_start_tick = Clock.tick
	# Nasce encostada na parede mais próxima do personagem e avança para a
	# outra: a fuga vale nos dois sentidos.
	var player := get_tree().get_first_node_in_group("player") as Player
	var near := player.global_position.x if player else global_position.x
	var from_left := near - arena.position.x < arena.end.x - near
	_direction = 1.0 if from_left else -1.0
	_front = arena.position.x if from_left else arena.end.x
	queue_redraw()


func _physics_process(delta: float) -> void:
	if not _active:
		return
	queue_redraw()
	if Clock.tick - _start_tick < GameMath.ticks(START_DELAY):
		return
	var limit := SAFE_TILES * float(ChapterMap.TILE)
	if _direction > 0.0:
		_front = minf(_front + speed * delta, arena.end.x - limit)
	else:
		_front = maxf(_front - speed * delta, arena.position.x + limit)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and (player.global_position.x - _front) * _direction < 0.0:
		player.take_hit(DAMAGE, Vector2(_direction, 0.0), Hit.Kind.FIRE)


func _draw() -> void:
	if not _active:
		return
	var start := arena.position.x if _direction > 0.0 else arena.end.x
	var left := minf(start, _front)
	var burning := Rect2(left, arena.position.y, absf(_front - start), arena.size.y)
	burning.position -= global_position
	draw_rect(burning, FIRE_COLOR)
	var wobble := 3.0 if posmod(Clock.tick, 10) < 5 else -3.0
	var x := _front - global_position.x + wobble
	var top := arena.position.y - global_position.y
	draw_line(Vector2(x, top), Vector2(x, top + arena.size.y), FRONT_COLOR, 6.0)
