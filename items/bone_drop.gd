class_name BoneDrop
extends Node2D
## Ossinho que um inimigo deixa ao morrer, a cada tantos mortos (pedido de
## Marcelo em 2026-11-07, para a morte, que recomeça a dungeon, não ficar dura
## demais). Recupera vida quando o personagem passa por cima e some sozinho
## depois de um tempo, piscando antes. Fica na camada dos efeitos do chão,
## então some ao trocar de sala.

const TEXTURE := preload("res://art/bone.svg")
## Ticks do pulo ao aparecer e altura dele, em pixels.
const POP_TICKS := 24
const POP_HEIGHT := 24.0
## Ticks até sumir, e quantos antes do fim ele pisca.
const LIFE_TICKS := 600
const BLINK_TICKS := 120
## Distância do personagem, em pixels, em que o ossinho é pego.
const PICK_RADIUS := 20.0

## Quanto de vida o ossinho devolve.
@export_range(1, 6, 1) var heal_amount := 2

var _born_tick := 0


func _ready() -> void:
	_born_tick = Clock.tick


func _physics_process(_delta: float) -> void:
	var age := Clock.tick - _born_tick
	if age >= LIFE_TICKS:
		queue_free()
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player and not player.is_dead():
		if global_position.distance_to(player.global_position) <= PICK_RADIUS:
			player.heal(heal_amount)
			queue_free()
			return
	queue_redraw()


## Pula ao aparecer e pisca antes de sumir. A origem fica nos pés do inimigo
## que o deixou, e o desenho fica logo acima dela.
func _draw() -> void:
	var age := Clock.tick - _born_tick
	if age > LIFE_TICKS - BLINK_TICKS and floori(age / 4.0) % 2 == 1:
		return
	var rise := 0.0
	if age < POP_TICKS:
		var t := float(age) / POP_TICKS
		rise = POP_HEIGHT * 4.0 * t * (1.0 - t)
	ToolIcons.draw_centered(self, TEXTURE, Vector2(0.0, -6.0 - floorf(rise)))
