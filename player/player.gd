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

## Velocidade de caminhada, em pixels por segundo.
@export var walk_speed := 90.0


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * walk_speed
	move_and_slide()
