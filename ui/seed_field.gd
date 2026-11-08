class_name SeedField
extends Control
## Campo dos seis dígitos da seed. Esquerda e direita escolhem o dígito, cima
## e baixo mudam, os números do teclado digitam, e confirmar avisa a tela.

signal confirmed

const DIGITS := 6
const DIGIT_WIDTH := 28.0
const FONT_SIZE := 32
const HEIGHT := 44.0
const CURSOR_COLOR := Color(1.0, 1.0, 1.0, 0.25)

var value := 0
var cursor := 0


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(DIGITS * DIGIT_WIDTH, HEIGHT)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _gui_input(event: InputEvent) -> void:
	var handled := true
	if event.is_action_pressed("ui_left", true):
		cursor = posmod(cursor - 1, DIGITS)
	elif event.is_action_pressed("ui_right", true):
		cursor = posmod(cursor + 1, DIGITS)
	elif event.is_action_pressed("ui_up", true):
		_add(1)
	elif event.is_action_pressed("ui_down", true):
		_add(-1)
	elif event.is_action_pressed("ui_accept"):
		confirmed.emit()
	elif event is InputEventKey and event.is_pressed() and _is_digit_key(event as InputEventKey):
		_set_digit((event as InputEventKey).unicode - 48)
		cursor = mini(cursor + 1, DIGITS - 1)
	else:
		handled = false
	if handled:
		Sfx.play(&"menu_move")
		accept_event()
		queue_redraw()


func _is_digit_key(event: InputEventKey) -> bool:
	return event.unicode >= 48 and event.unicode <= 57


func _place() -> int:
	return int(pow(10, DIGITS - 1 - cursor))


func _digit() -> int:
	return (value / _place()) % 10


func _set_digit(digit: int) -> void:
	value += (digit - _digit()) * _place()


func _add(delta: int) -> void:
	_set_digit(posmod(_digit() + delta, 10))


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text := "%0*d" % [DIGITS, value]
	for i: int in DIGITS:
		var x := i * DIGIT_WIDTH
		if i == cursor and has_focus():
			draw_rect(Rect2(x, 0.0, DIGIT_WIDTH, HEIGHT), CURSOR_COLOR)
		var glyph := text[i]
		var width := font.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var position := Vector2(x + (DIGIT_WIDTH - width) / 2.0, HEIGHT - 10.0)
		draw_string(font, position, glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
