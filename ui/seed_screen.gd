extends Control
## Tela do modo randomizado: a seed, um número de seis dígitos que o jogador
## sorteia, digita e compartilha. A tela abre com uma seed sorteada e o cursor
## em Jogar. Digitar um número é uma opção à parte. O mesmo número dá o mesmo
## jogo em qualquer cópia. Jogar começa um jogo novo no mundo, com as três entradas abertas e
## os itens da seed.

var _field: SeedField
var _play: Button
## Botões da tela comum e os da digitação, que nunca aparecem juntos.
var _menu: Array[Control] = []
var _entry: Array[Control] = []
## Semente de antes da digitação, para o Cancelar.
var _kept_seed := 0


func _ready() -> void:
	Progress.active = false
	var column := MenuKit.centered_column(self, Color("1b1926"))
	column.add_child(MenuKit.label("Randomizado", 32))
	column.add_child(
		MenuKit.label(
			(
				"As mesmas dungeons, com os itens embaralhados pela semente.\n"
				+ "O mesmo número dá o mesmo jogo em qualquer cópia."
			),
			16
		)
	)
	_field = SeedField.new()
	_field.value = Randomizer.random_seed()
	_field.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_field)
	_play = MenuKit.button("Jogar", _on_play)
	_menu = [
		_play,
		MenuKit.button("Sortear de novo", _on_reroll),
		MenuKit.button("Digitar número", _on_type),
		MenuKit.button("Voltar", _on_back),
	]
	# Na digitação o campo usa as quatro direções, então não há botão para
	# alcançar: confirmar fecha a digitação e cancelar devolve a semente.
	_entry = [
		MenuKit.label("Esquerda e direita escolhem o dígito, cima e baixo mudam.", 16),
		MenuKit.label("B confirma.", 16),
	]
	for control: Control in _menu + _entry:
		column.add_child(control)
	_field.confirmed.connect(_on_typed)
	_show_entry(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _field.focus_mode == Control.FOCUS_ALL:
			_on_type_cancelled()
		else:
			_on_back()


## Troca entre a tela comum, com o cursor em Jogar, e a digitação, com o
## cursor nos dígitos. Fora da digitação o número não recebe o cursor: Marcelo
## apertava para baixo querendo chegar em Jogar e mudava a semente
## (2026-11-12).
func _show_entry(typing: bool) -> void:
	for control: Control in _menu:
		control.visible = not typing
	for control: Control in _entry:
		control.visible = typing
	_field.focus_mode = Control.FOCUS_ALL if typing else Control.FOCUS_NONE
	if typing:
		_field.grab_focus.call_deferred()
	else:
		_play.grab_focus.call_deferred()
	_field.queue_redraw()


func _on_play() -> void:
	Progress.start_seed(maxi(_field.value, Randomizer.MIN_SEED))
	get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)


func _on_reroll() -> void:
	_field.value = Randomizer.random_seed()
	_field.queue_redraw()


func _on_type() -> void:
	_kept_seed = _field.value
	_field.cursor = 0
	_show_entry(true)


func _on_typed() -> void:
	_show_entry(false)


func _on_type_cancelled() -> void:
	_field.value = _kept_seed
	_show_entry(false)


func _on_back() -> void:
	get_tree().change_scene_to_file(Flow.TITLE_SCENE)
