class_name SwitchDoor
extends Obstacle
## Grade de ferro. Nenhuma ferramenta a abre: qualquer golpe só a faz tremer.
## Ela abre enquanto um interruptor da mesma sala estiver pressionado, e de
## vez quando um bloco pesado trava num interruptor. Ao abrir, afunda no chão
## como a porta trancada, e ao fechar volta a subir. Fechando com alguém na
## passagem, ela só volta a ser sólida quando a passagem esvazia, para não
## prender ninguém dentro das barras.
##
## A origem fica no canto superior esquerdo. O construtor do mapa define o
## tamanho antes de adicionar a grade à cena.

const TEXTURE := preload("res://art/gate_door.svg")
const MOVE_TICKS := 12
## Folga, em pixels, entre a borda da grade e a área que confere a passagem.
const OCCUPIED_MARGIN := 2.0

var open := false

var _move_tick := -1000
var _closing := false


func set_open(value: bool) -> void:
	if value == open:
		return
	open = value
	_move_tick = Clock.tick
	_closing = not open
	if open:
		_shape.set_deferred("disabled", true)
	Sfx.play(&"door_unlock" if open else &"bump")
	queue_redraw()


## Aberta, a grade não reage a golpes. Fechada, só treme, como todo bloqueio
## com o golpe errado.
func take_hit(amount: int, direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if open:
		return
	super(amount, direction, kind)


func _physics_process(delta: float) -> void:
	super(delta)
	if _closing and not _occupied():
		_closing = false
		_shape.disabled = false
	if Clock.tick - _move_tick <= MOVE_TICKS:
		queue_redraw()


## Nenhum golpe abre a grade.
func _opens_with(_kind: Hit.Kind) -> bool:
	return false


## Diz se algum corpo está na passagem da grade. A área conferida é um pouco
## menor que a grade: do tamanho exato, ela encosta nas paredes vizinhas, a
## passagem parecia sempre ocupada e a grade nunca voltava a ser sólida.
func _occupied() -> bool:
	var inner := RectangleShape2D.new()
	inner.size = size - Vector2(OCCUPIED_MARGIN, OCCUPIED_MARGIN) * 2.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = inner
	query.transform = Transform2D(0.0, global_position + size / 2.0)
	var excluded: Array[RID] = [get_rid()]
	query.exclude = excluded
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


## Desenha a grade casa por casa. Aberta, ela fica afundada no chão.
func _draw() -> void:
	var progress := minf(float(Clock.tick - _move_tick) / MOVE_TICKS, 1.0)
	var height := 1.0 - progress if open else progress
	if height >= 1.0:
		_draw_shadow()
	DoorArt.draw_sunk(self, TEXTURE, size, height, _shake_offset())
