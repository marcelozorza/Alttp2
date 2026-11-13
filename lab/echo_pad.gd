class_name EchoPad
extends Node2D
## Marca do clone do laboratório. Pisar nela começa a gravar os passos do
## personagem por alguns segundos. Quando a gravação acaba, um clone
## transparente nasce na marca e repete o caminho sem parar, ficando no
## último ponto pelo mesmo tempo que o personagem ficou. O clone pesa sobre
## as placas de pressão (grupo plate_weights), então segura uma placa
## enquanto o personagem vai até a porta. Pisar de novo na marca grava outro
## caminho. Arte provisória.
##
## Liga e desliga com a sala: ao sair, a gravação e o clone somem. A origem
## fica no centro da casa, na camada do chão.

const RECORD_TICKS := 300
const PAD_COLOR := Color(0.55, 0.9, 0.95)
const GHOST_COLOR := Color(0.6, 0.95, 1.0, 0.6)

var _active := false
## Posições gravadas, uma por tick.
var _path: Array[Vector2] = []
var _recording := false
## Tick da gravação ou da repetição.
var _step := 0
## Desligada enquanto o personagem não sai de cima.
var _armed := true
## O clone não tem corpo: nada bate nele. Só pesa nas placas enquanto anda.
var _ghost := Node2D.new()


func _ready() -> void:
	_ghost.top_level = true
	add_child(_ghost)


func set_active(active: bool) -> void:
	_active = active
	_recording = false
	_path.clear()
	_ghost.remove_from_group("plate_weights")
	_armed = true
	queue_redraw()


## Diz se o clone está andando agora.
func is_replaying() -> bool:
	return not _recording and not _path.is_empty()


func ghost_position() -> Vector2:
	return _ghost.global_position


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	queue_redraw()
	var player := get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	var on_pad := player.global_position.distance_to(global_position) < 12.0
	if not on_pad:
		_armed = true
	elif _armed and not player.is_airborne():
		_armed = false
		_recording = true
		_path.clear()
		_ghost.remove_from_group("plate_weights")
		Sfx.play(&"switch_press")
	if _recording:
		_path.append(player.global_position)
		if _path.size() >= RECORD_TICKS:
			_recording = false
			_step = 0
			_ghost.add_to_group("plate_weights")
			Sfx.play(&"relic")
	elif not _path.is_empty():
		_step = (_step + 1) % _path.size()
		_ghost.global_position = _path[_step]


func _draw() -> void:
	draw_circle(Vector2.ZERO, 13.0, DoorArt.OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, 11.0, PAD_COLOR.darkened(0.5))
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 20, PAD_COLOR, 2.0)
	if _recording:
		var left := 1.0 - float(_path.size()) / RECORD_TICKS
		draw_arc(Vector2.ZERO, 16.0, -PI / 2.0, -PI / 2.0 + TAU * left, 32, Color.WHITE, 3.0)
	elif is_replaying():
		var at := _ghost.global_position - global_position
		draw_rect(Rect2(at + Vector2(-8.0, -26.0), Vector2(16.0, 26.0)), GHOST_COLOR)
		draw_rect(Rect2(at + Vector2(-8.0, -26.0), Vector2(16.0, 26.0)), Color.WHITE, false, 1.0)
