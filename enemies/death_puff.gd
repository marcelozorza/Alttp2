class_name DeathPuff
extends Node2D
## Nuvem de quando um inimigo é vencido (pedido de Marcelo em 2026-11-11:
## nenhum inimigo tinha animação de morte, o gato só desaparecia).
##
## O inimigo some na hora, como antes, e a nuvem fica no lugar dele: primeiro
## o último desenho do inimigo pisca em branco, depois a nuvem estoura em
## quatro quadros desenhados (art/source/death_puff_*.txt). Nada aqui muda o
## jogo: o inimigo já deixou de existir para a física quando a nuvem aparece.

const FRAMES: Array[Texture2D] = [
	preload("res://art/death_puff_1.svg"),
	preload("res://art/death_puff_2.svg"),
	preload("res://art/death_puff_3.svg"),
	preload("res://art/death_puff_4.svg"),
]
## Ticks em que o desenho do inimigo pisca antes da nuvem.
const BODY_TICKS := 8
## Ticks de cada quadro da nuvem.
const FRAME_TICKS := 4
const BODY_TINT := Color(1.8, 1.8, 1.8, 1.0)
## Centro da nuvem quando o inimigo não tem desenho, acima dos pés.
const DEFAULT_CENTER := Vector2(0.0, -12.0)

## Último desenho do inimigo, o canto dele a partir dos pés e se estava
## espelhado. Sem desenho, só a nuvem aparece.
var body_texture: Texture2D
var body_corner := Vector2.ZERO
var body_flipped := false
## Ticks de espera antes de começar, para os chefes soltarem várias nuvens
## em sequência.
var delay := 0

var _born_tick := 0


## Cria a nuvem no lugar de um inimigo, na camada dos efeitos do chão, ou ao
## lado do inimigo se a cena não tiver essa camada. texture é o último desenho
## dele, corner o canto desse desenho a partir dos pés, e flipped diz se
## estava espelhado. Sem desenho, a nuvem fica acima dos pés. Com wait, a
## nuvem espera esses ticks e não mostra o desenho, e shift a desloca.
static func spawn(
	enemy: Node2D,
	texture: Texture2D,
	corner: Vector2,
	flipped: bool,
	wait := 0,
	shift := Vector2.ZERO
) -> void:
	var puff := DeathPuff.new()
	puff.delay = wait
	var center := DEFAULT_CENTER
	if texture:
		var half := texture.get_size() / 2.0
		center = corner + half
		if wait == 0:
			puff.body_texture = texture
			puff.body_corner = -half
			puff.body_flipped = flipped
	var layer := enemy.get_tree().get_first_node_in_group("floor_effects") as Node2D
	if layer == null:
		layer = enemy.get_parent() as Node2D
	layer.add_child(puff)
	puff.global_position = enemy.global_position + center + shift


func _ready() -> void:
	_born_tick = Clock.tick
	# Por cima dos objetos da sala.
	z_as_relative = false
	z_index = 50


func _physics_process(_delta: float) -> void:
	if _age() >= BODY_TICKS + FRAMES.size() * FRAME_TICKS:
		queue_free()
		return
	queue_redraw()


func _age() -> int:
	return Clock.tick - _born_tick - delay


func _draw() -> void:
	var age := _age()
	if age < 0:
		return
	if age < BODY_TICKS:
		if body_texture and posmod(age, 4) < 2:
			var size := body_texture.get_size()
			var rect := Rect2(body_corner, size)
			if body_flipped:
				# Largura negativa espelha no próprio lugar.
				rect = Rect2(body_corner, Vector2(-size.x, size.y))
			draw_texture_rect(body_texture, rect, false, BODY_TINT)
		return
	var frame := FRAMES[mini((age - BODY_TICKS) / FRAME_TICKS, FRAMES.size() - 1)]
	draw_texture(frame, -frame.get_size() / 2.0)
