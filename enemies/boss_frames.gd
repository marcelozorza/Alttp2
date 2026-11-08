class_name BossFrames
extends Resource
## Quadros de um chefe num estado da casca: com a casca ou com o núcleo
## exposto. O chefe (enemies/boss.gd) tem um destes para cada estado e troca o
## quadro pelo que está fazendo. Feito em 2026-11-08 para o caranguejo e o
## cérbero, das folhas de IA de Marcelo.

## Andando, alternando os passos. O primeiro é também o quadro parado.
@export var walk_frames: Array[Texture2D] = []
## Preparando a pancada no chão.
@export var slam_windup_frame: Texture2D
## Batendo no chão, mostrado enquanto ele se recupera da pancada.
@export var slam_frame: Texture2D
## Agachado, preparando a investida.
@export var charge_windup_frame: Texture2D
## Correndo na investida, alternando os passos.
@export var charge_frames: Array[Texture2D] = []
## Parado depois da investida.
@export var recover_frame: Texture2D
