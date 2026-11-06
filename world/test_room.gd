extends Node2D
## Sala de teste da física, do combate e das ferramentas. O personagem começa
## com todas elas, inclusive a chama forte, e há um degrau alto, uma parede
## rachada, um bloco de gelo, um gelo grosso, uma morsa de gelo e um atirador
## de pedras para experimentar. A passagem para a parte de baixo é uma grade:
## abre enquanto o personagem pisa no interruptor e de vez quando o bloco
## pesado é empurrado para cima dele. Os bloqueios voltam ao reabrir a sala. O
## menu de pausa volta ao menu de título.


func _ready() -> void:
	for node: Node in $FloorEffects.get_children():
		if node is FloorSwitch:
			(node as FloorSwitch).changed.connect(_on_switch_changed)


## A grade abre enquanto algum interruptor da sala estiver pressionado.
func _on_switch_changed(_pressed: bool) -> void:
	var any_pressed := false
	for node: Node in $FloorEffects.get_children():
		if node is FloorSwitch and (node as FloorSwitch).pressed:
			any_pressed = true
	for node: Node in $Obstacles.get_children():
		if node is SwitchDoor:
			(node as SwitchDoor).set_open(any_pressed)
