class_name MenuKit
## Peças das telas de menu, montadas em código para manter as cenas simples.
## Botões retos, de cor chapada, com a moldura dourada no foco, e as fontes de
## pixel do jogo (ui/fonts.gd).

const TEXT := Color("f4f1ea")
const FOCUS := Color("f7c53a")
const DISABLED := Color("7c7b99")
const PANEL := Color("262335")
const EDGE := Color("55526f")


static func label(text: String, font_size: int) -> Label:
	var result := Label.new()
	result.text = text
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_override("font", Fonts.for_size(font_size))
	result.add_theme_font_size_override("font_size", Fonts.real_size(font_size))
	result.add_theme_color_override("font_color", TEXT)
	return result


## Botão de menu. Soa ao confirmar e ao receber o foco pelo direcional. O foco
## inicial da tela fica em silêncio. Com small, usa a fonte pequena, para os
## painéis estreitos.
static func button(text: String, action: Callable, small := false) -> Button:
	var result := Button.new()
	result.text = text
	result.add_theme_font_override("font", Fonts.SMALL if small else Fonts.BIG)
	result.add_theme_font_size_override("font_size", Fonts.SMALL_SIZE if small else Fonts.BIG_SIZE)
	result.add_theme_color_override("font_color", TEXT)
	result.add_theme_color_override("font_focus_color", FOCUS)
	result.add_theme_color_override("font_hover_color", TEXT)
	result.add_theme_color_override("font_pressed_color", FOCUS)
	result.add_theme_color_override("font_disabled_color", DISABLED)
	result.add_theme_stylebox_override("normal", _box(PANEL, EDGE, 1))
	result.add_theme_stylebox_override("hover", _box(PANEL, EDGE, 1))
	result.add_theme_stylebox_override("disabled", _box(PANEL, EDGE, 1))
	result.add_theme_stylebox_override("pressed", _box(EDGE, FOCUS, 2))
	result.add_theme_stylebox_override("focus", _box(Color(0.0, 0.0, 0.0, 0.0), FOCUS, 2))
	result.pressed.connect(Sfx.play.bind(&"menu_confirm"))
	result.pressed.connect(action)
	result.focus_entered.connect(_on_focus)
	return result


## Caixa reta de botão: fundo, moldura e folga para o texto.
static func _box(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(width)
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	return box


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
	column.add_theme_constant_override("separation", 8)
	center.add_child(column)
	return column
