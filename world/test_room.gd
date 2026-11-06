extends Node2D
## Sala de teste da física, do combate e das ferramentas. O personagem começa
## com todas elas, inclusive a chama forte, e há um degrau alto, uma parede
## rachada, um bloco de gelo, um gelo grosso, uma morsa de gelo e um atirador
## de pedras para experimentar. A passagem para a parte de baixo é uma grade:
## abre enquanto o personagem pisa no interruptor e de vez quando o bloco
## pesado é empurrado para cima dele. Os bloqueios voltam ao reabrir a sala. O
## menu de pausa volta ao menu de título.


func _ready() -> void:
	for node: Node in $Switches.get_children():
		if node is FloorSwitch:
			(node as FloorSwitch).changed.connect(_on_switch_changed)


func _on_switch_changed(_pressed: bool) -> void:
	var gates: Array = []
	for node: Node in $Obstacles.get_children():
		if node is SwitchDoor:
			gates.append(node)
	FloorSwitch.sync_gates($Switches.get_children(), gates)
