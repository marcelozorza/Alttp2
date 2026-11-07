extends Control
## Tela do modo randomizado: a seed, um número de seis dígitos que o jogador
## digita, sorteia e compartilha. O mesmo número dá o mesmo jogo em qualquer
## cópia. Jogar começa um jogo novo no mundo, com as três entradas abertas e
## os itens da seed.

var _field: SeedField
var _play: Button


func _ready() -> void:
	Progress.active = false
	var column := MenuKit.centered_column(self, Color(0.1, 0.11, 0.13, 1.0))
	column.add_child(MenuKit.label("Randomizado", 32))
	column.add_child(
		MenuKit.label(
			(
				"As mesmas dungeons, com os itens embaralhados pela seed.\n"
				+ "O mesmo número dá o mesmo jogo em qualquer cópia."
			),
			16
		)
	)
	_field = SeedField.new()
	_field.value = Randomizer.random_seed()
	_field.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_field)
	column.add_child(
		MenuKit.label("Esquerda e direita escolhem o dígito, cima e baixo mudam, A confirma.", 16)
	)
	_play = MenuKit.button("Jogar", _on_play)
	column.add_child(_play)
	column.add_child(MenuKit.button("Sortear", _on_reroll))
	column.add_child(MenuKit.button("Voltar", _on_back))
	_field.confirmed.connect(_play.grab_focus)
	_play.focus_neighbor_top = _play.get_path_to(_field)
	_field.grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()


func _on_play() -> void:
	Progress.start_seed(maxi(_field.value, Randomizer.MIN_SEED))
	get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)


func _on_reroll() -> void:
	_field.value = Randomizer.random_seed()
	_field.queue_redraw()
	_field.grab_focus()


func _on_back() -> void:
	get_tree().change_scene_to_file(Flow.TITLE_SCENE)
