class_name EndScreen
extends CanvasLayer
## Tela de fim do capítulo, com o tempo, o capítulo e os baús abertos.
## Funciona com o jogo pausado. No jogo contínuo, o primeiro botão volta ao
## mundo, na entrada da dungeon. No treino, volta ao menu de título.
##
## Ao vencer a última dungeon no jogo contínuo, vira a tela de vitória: mostra
## o tempo do jogo inteiro e convida ao modo randomizado, o jogo de verdade
## (pedido de Marcelo em 2026-11-07). Numa seed vencida, mostra o número dela
## e convida a outra.
##
## Os botões só respondem depois de um instante, para que o botão de ataque,
## que no teclado e no controle também confirma, não reinicie o capítulo por
## acidente.

## Segundos com os botões desligados depois que a tela aparece.
const INPUT_DELAY := 0.8

var _title: Label
var _summary: Label
var _random_button: Button
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var column := MenuKit.centered_column(self, Color(0.05, 0.05, 0.08, 0.85))
	var title := "Capítulo concluído"
	if RunSettings.chapter == ChapterData.TUTORIAL:
		title = "Tutorial concluído"
	elif RunSettings.chapter == ChapterData.GALLERY:
		title = "Galeria"
	_title = MenuKit.label(title, 32)
	column.add_child(_title)
	_summary = MenuKit.label("", 20)
	column.add_child(_summary)
	_random_button = MenuKit.button("Jogar randomizado", _on_random)
	_random_button.visible = false
	column.add_child(_random_button)
	if Progress.active:
		_buttons.append(MenuKit.button("Voltar ao mundo", _on_leave))
		_buttons.append(MenuKit.button("Jogar de novo", _on_replay))
	else:
		_buttons.append(MenuKit.button("Jogar de novo", _on_replay))
		_buttons.append(MenuKit.button("Menu", _on_leave))
	for button: Button in _buttons:
		column.add_child(button)


func show_results(time_text: String, chapter_text: String, chests_text: String) -> void:
	_summary.text = "Tempo %s\n%s\nBaús abertos %s" % [time_text, chapter_text, chests_text]
	await _appear()


## Vitória: o tempo do jogo inteiro desde o Novo jogo, o da última dungeon e o
## convite ao modo randomizado. Numa seed, o número dela para compartilhar.
func show_victory(
	run_time_text: String, time_text: String, chests_text: String, seed_value: int
) -> void:
	var summary := (
		"Tempo total %s\nÚltima dungeon em %s, baús abertos %s\n\n"
		% [run_time_text, time_text, chests_text]
	)
	if seed_value == 0:
		_title.text = "Você venceu as três dungeons"
		summary += (
			"O jogo de verdade começa agora: as mesmas dungeons\n"
			+ "com os itens embaralhados por uma seed."
		)
		_random_button.text = "Jogar randomizado"
	else:
		_title.text = "Seed %06d vencida" % seed_value
		summary += "Compartilhe o número da seed: quem jogar\na mesma seed joga o mesmo jogo."
		_random_button.text = "Jogar outra seed"
	_summary.text = summary
	_random_button.visible = true
	await _appear()


func _appear() -> void:
	visible = true
	for button: Button in _buttons + [_random_button]:
		button.disabled = true
	await get_tree().create_timer(INPUT_DELAY).timeout
	for button: Button in _buttons + [_random_button]:
		button.disabled = false
	_buttons[0].grab_focus()


func _on_random() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(Flow.SEED_SCENE)


func _on_replay() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_leave() -> void:
	Flow.leave_chapter(get_tree())
