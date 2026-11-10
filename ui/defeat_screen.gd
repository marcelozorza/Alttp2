class_name DefeatScreen
extends CanvasLayer
## Tela de derrota. Quando o personagem perde toda a vida, ele cai, e depois
## de um instante o jogo para e a tela aparece: tentar de novo, que recomeça
## a dungeon do início, com o que o personagem tinha ao entrar (decisão de
## Marcelo em 2026-11-06), ou sair.
##
## No modo randomizado a morte perde tudo (decisão dele em 2026-11-07): a seed
## é zerada e gravada assim que a tela aparece, e os botões são recomeçar a
## seed, no mundo e sem nada, ou voltar ao menu.
##
## Os botões só respondem depois de um instante, para que o botão de ataque,
## que também confirma, não escolha nada por acidente.

## Segundos entre a queda e a tela.
const SHOW_DELAY := 0.9
## Segundos com os botões desligados depois que a tela aparece.
const INPUT_DELAY := 0.8

## Texto do botão de sair.
@export var exit_text := "Sair do capítulo"
## Ligado, sair leva sempre ao menu de título.
@export var exit_to_title := false

var _player: Player
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var column := MenuKit.centered_column(self, Color(0.12, 0.02, 0.04, 0.85))
	column.add_child(MenuKit.label("Derrota", 32))
	if _seed_mode():
		column.add_child(MenuKit.label("Na seed, a morte perde tudo.", 16))
		_buttons.append(MenuKit.button("Recomeçar a seed", _on_retry))
		_buttons.append(MenuKit.button("Menu", _on_exit))
	else:
		_buttons.append(MenuKit.button("Tentar de novo", _on_retry))
		_buttons.append(MenuKit.button(exit_text, _on_exit))
	for button: Button in _buttons:
		column.add_child(button)
	_connect_player.call_deferred()


## O personagem é criado pela cena depois desta tela, então a ligação espera
## a cena ficar pronta.
func _connect_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player
	if _player:
		_player.died.connect(_on_player_died)


func _on_player_died() -> void:
	await get_tree().create_timer(SHOW_DELAY).timeout
	if not is_instance_valid(_player) or get_tree().paused:
		return
	get_tree().paused = true
	visible = true
	if _seed_mode():
		Progress.restart_seed()
	for button: Button in _buttons:
		button.disabled = true
	await get_tree().create_timer(INPUT_DELAY).timeout
	for button: Button in _buttons:
		button.disabled = false
	_buttons[0].grab_focus()


func _on_retry() -> void:
	visible = false
	if _seed_mode():
		Flow.go_to_overworld(get_tree())
	else:
		Flow.restart_scene(get_tree())


func _on_exit() -> void:
	if exit_to_title or _seed_mode():
		Flow.go_to_title(get_tree())
	else:
		Flow.leave_chapter(get_tree())


static func _seed_mode() -> bool:
	return Progress.active and Progress.seed != 0 and not Progress.practice
