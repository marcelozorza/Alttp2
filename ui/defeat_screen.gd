class_name DefeatScreen
extends CanvasLayer
## Tela de derrota. Quando o personagem perde toda a vida, ele cai, e depois
## de um instante o jogo para e a tela aparece: tentar de novo, que o faz
## reaparecer na entrada da sala com a vida cheia e com tudo o que já
## conseguiu, ou sair.
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
	column.add_child(MenuKit.label("Derrota", 16))
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
	for button: Button in _buttons:
		button.disabled = true
	await get_tree().create_timer(INPUT_DELAY).timeout
	for button: Button in _buttons:
		button.disabled = false
	_buttons[0].grab_focus()


func _on_retry() -> void:
	visible = false
	get_tree().paused = false
	_player.respawn()


func _on_exit() -> void:
	if exit_to_title:
		Flow.go_to_title(get_tree())
	else:
		Flow.leave_chapter(get_tree())
