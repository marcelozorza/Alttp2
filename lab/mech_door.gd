class_name MechDoor
extends SwitchDoor
## Porta de mecanismo do laboratório: a grade de ferro, tingida pela cor do
## que a abre. Quem decide quando ela abre é lab/room_mechanisms.gd.
##
## - SHUTTER (vermelha): fecha quando o personagem entra numa sala com
##   inimigos e abre quando o último morre.
## - BARRIER (azul) e BARRIER_ALT (laranja): trocam de estado a cada golpe no
##   cristal da sala. Uma abre quando a outra fecha.
## - TORCH_DOOR (amarela): abre com todas as tochas da sala acesas.
## - BLAST_DOOR (roxa): abre quando uma explosão acerta o alvo da sala.
## - TIMED_GATE (verde): abre enquanto uma placa de pressão da sala está
##   ligada, por alguns segundos ou de vez.
## - BEAM_DOOR (branca): abre quando o feixe de luz chega ao receptor.

const TINTS := {
	ChapterMap.Block.SHUTTER: Color(1.0, 0.45, 0.45),
	ChapterMap.Block.BARRIER: Color(0.5, 0.7, 1.0),
	ChapterMap.Block.BARRIER_ALT: Color(1.0, 0.7, 0.35),
	ChapterMap.Block.TORCH_DOOR: Color(1.0, 0.95, 0.45),
	ChapterMap.Block.BLAST_DOOR: Color(0.8, 0.5, 1.0),
	ChapterMap.Block.TIMED_GATE: Color(0.5, 1.0, 0.6),
	ChapterMap.Block.BEAM_DOOR: Color(1.6, 1.6, 1.6),
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
