class_name MechDoor
extends SwitchDoor
## Porta de mecanismo: a grade de ferro, tingida pela cor do que a abre.
## Quem decide quando ela abre é mechanics/room_mechanisms.gd.
##
## - SHUTTER (vermelha): fecha quando o personagem entra numa arena e abre
##   quando o último inimigo da última leva morre.
## - BARRIER (azul) e BARRIER_ALT (laranja): trocam de estado a cada golpe no
##   cristal da sala. Uma abre quando a outra fecha.
## - TORCH_DOOR (amarela): abre com todas as tochas da sala acesas.
## - TIMED_GATE (verde): aberta por alguns segundos depois de a placa de
##   pressão da sala ser pisada.

const TINTS := {
	ChapterMap.Block.SHUTTER: Color(1.0, 0.45, 0.45),
	ChapterMap.Block.BARRIER: Color(0.5, 0.7, 1.0),
	ChapterMap.Block.BARRIER_ALT: Color(1.0, 0.7, 0.35),
	ChapterMap.Block.TORCH_DOOR: Color(1.0, 0.95, 0.45),
	ChapterMap.Block.TIMED_GATE: Color(0.5, 1.0, 0.6),
}

## Tipo do bloqueio, um ChapterMap.Block.
var kind := ChapterMap.Block.SHUTTER


func _ready() -> void:
	super()
	modulate = TINTS.get(kind, Color.WHITE)


## Abre sem som nem animação, para a porta que começa aberta.
func open_silently() -> void:
	open = true
	_closing = false
	_shape.set_deferred("disabled", true)
	queue_redraw()
