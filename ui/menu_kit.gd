class_name MenuKit
## Peças das telas de menu, montadas em código para manter as cenas simples.


static func label(text: String, font_size: int) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	return result


## Botão de menu. Soa ao confirmar e ao receber o foco pelo direcional. O foco
## inicial da tela fica em silêncio.
static func button(text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.add_theme_font_size_override("font_size", 10)
	result.pressed.connect(Sfx.play.bind(&"menu_confirm"))
	result.pressed.connect(action)
	result.focus_entered.connect(_on_focus)
	return result


static func _on_focus() -> void:
	for action: StringName in [&"ui_up", &"ui_down", &"ui_left", &"ui_right"]:
		if Input.is_action_pressed(action):
			Sfx.play(&"menu_move")
			return


## Fundo de cor sólida e uma coluna centralizada para os itens do menu.
static func centered_column(parent: Node, background: Color) -> VBoxContainer:
	var fill := ColorRect.new()
	fill.color = background
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fill)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	center.add_child(column)
	return column
