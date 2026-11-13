class_name Cart
extends Node2D
## Carrinho de mina do laboratório. Fica parado numa ponta do trilho
## (lab/cart_track.gd). Quando o personagem encosta nele, embarca: o
## carrinho o leva até a outra ponta, por cima do vazio, sem parar. Durante a
## viagem o personagem não anda, mas vira e golpeia com a espada, o que
## permite acertar um cristal ao passar. Na ponta ele desembarca, e o
## carrinho só parte de novo depois que ele se afasta e volta. Arte
## provisória.
##
## Liga e desliga com a sala: ao entrar na sala, o carrinho volta ao começo
## do trilho. A origem fica no centro da casa, na camada dos objetos.

## Velocidade no trilho, em pixels por segundo.
const SPEED := 160.0
## Distância do carrinho em que o personagem embarca, em pixels.
const BOARD_DISTANCE := 14.0
const BODY_COLOR := Color(0.5, 0.36, 0.22)
const RIM_COLOR := Color(0.7, 0.7, 0.75)

var track: CartTrack

## Centro de cada casa do trilho, do começo ao fim.
var _path: Array[Vector2] = []
## Distância percorrida a partir do começo, em pixels.
var _traveled := 0.0
## Sentido da próxima viagem: 1 para o fim, -1 para o começo.
var _heading := 1.0
var _riding := false
## Desligado enquanto o personagem não se afasta depois de desembarcar.
var _armed := true
var _active := false


func _ready() -> void:
	# Depois do personagem, para a posição do carrinho valer no quadro.
	process_physics_priority = 10
	_build_path.call_deferred()


func set_active(active: bool) -> void:
	_active = active
	if _riding:
		_stop_ride()
	_traveled = 0.0
	_heading = 1.0
	_armed = true
	if not _path.is_empty():
		global_position = _path[0]


func is_riding() -> bool:
	return _riding


func _physics_process(delta: float) -> void:
	if not _active or _path.size() < 2:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	if _riding:
		_ride(player, delta)
		return
	if player.global_position.distance_to(global_position) > BOARD_DISTANCE:
		_armed = true
	elif _armed and not player.is_airborne() and not player.is_dead():
		_riding = true
		player.add_to_group(CartTrack.RIDERS)
		Sfx.play(&"block_drag")


func _ride(player: Player, delta: float) -> void:
	var length := float(_path.size() - 1) * ChapterMap.TILE
	_traveled = clampf(_traveled + SPEED * delta * _heading, 0.0, length)
	var at := _traveled / ChapterMap.TILE
	var index := mini(int(at), _path.size() - 2)
	global_position = _path[index].lerp(_path[index + 1], at - index)
	player.global_position = global_position
	player.velocity = Vector2.ZERO
	player.slide_direction = Vector2.ZERO
	if player.is_dead() or _traveled <= 0.0 or _traveled >= length:
		_stop_ride()
		_heading = -_heading
		_armed = false
		Sfx.play(&"land")


func _stop_ride() -> void:
	_riding = false
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.remove_from_group(CartTrack.RIDERS)


## Segue o trilho a partir da casa do carrinho, de vizinha em vizinha.
func _build_path() -> void:
	var cell := Pit.cell_of(global_position)
	var seen := {}
	while true:
		seen[cell] = true
		_path.append((Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE)
		var found := false
		for step: Vector2i in ChapterMap.STEPS:
			if track.has(cell + step) and not seen.has(cell + step):
				cell += step
				found = true
				break
		if not found:
			break


func _draw() -> void:
	draw_rect(Rect2(-14.0, -6.0, 28.0, 18.0), DoorArt.OUTLINE_COLOR)
	draw_rect(Rect2(-12.0, -4.0, 24.0, 14.0), BODY_COLOR)
	draw_rect(Rect2(-12.0, -4.0, 24.0, 3.0), RIM_COLOR)
	draw_circle(Vector2(-8.0, 12.0), 3.0, DoorArt.OUTLINE_COLOR)
	draw_circle(Vector2(8.0, 12.0), 3.0, DoorArt.OUTLINE_COLOR)
