class_name Pushable
extends MomentumBody
## Objeto que pode ser empurrado andando e arremessado com batidas fortes.
##
## A massa define o comportamento. Mais leve que o personagem, é empurrado com
## facilidade e voa longe numa batida. Mais pesado, anda devagar quando
## empurrado e devolve a batida para o personagem.


func _physics_process(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	if velocity != Vector2.ZERO:
		move_with_impacts()
