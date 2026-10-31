class_name MenuKit
## Peças das telas de menu, montadas em código para manter as cenas simples.


static func label(text: String, font_size: int) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	return result


static func button(text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.add_theme_font_size_override("font_size", 10)
	result.pressed.connect(action)
	return result


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
