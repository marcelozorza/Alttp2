extends Control
## HUD: a vida, um quadrado por ponto, e a ferramenta escolhida numa moldura,
## com as outras ferramentas que o personagem já tem ao lado. No capítulo,
## mostra também o modo da partida e o cronômetro numa barra no alto da tela.

const PIP_SIZE := Vector2(6.0, 6.0)
const PIP_GAP := 2.0
const FULL_COLOR := Color(0.9, 0.2, 0.25, 1.0)
const EMPTY_COLOR := Color(0.25, 0.1, 0.12, 1.0)
const BAR_COLOR := Color(0.07, 0.07, 0.09, 1.0)
const FRAME_COLOR := Color(0.85, 0.8, 0.65, 1.0)
const TEXT_COLOR := Color(0.85, 0.85, 0.8, 1.0)
## Tamanho da barra do capítulo, a largura toda da tela.
const BAR_SIZE := Vector2(320.0, 20.0)
## Moldura da ferramenta escolhida, relativa ao HUD.
const TOOL_BOX := Rect2(104.0, -3.0, 14.0, 14.0)
const FONT_SIZE := 8

## Ligado, desenha a barra de fundo do capítulo, que esconde a sala vizinha.
@export var show_bar := false


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if show_bar:
		draw_rect(Rect2(-position, BAR_SIZE), BAR_COLOR)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		_draw_health(player)
		_draw_tools(player)
	var chapter := get_tree().get_first_node_in_group("chapter")
	if chapter:
		var text := "%s   %s" % [chapter.call("mode_text"), chapter.call("time_text")]
		var font := ThemeDB.fallback_font
		draw_string(
			font,
			Vector2(150.0, 9.0),
			text,
			HORIZONTAL_ALIGNMENT_RIGHT,
			162.0,
			FONT_SIZE,
			TEXT_COLOR
		)


func _draw_health(player: Player) -> void:
	for i: int in player.max_health:
		var pip_position := Vector2(i * (PIP_SIZE.x + PIP_GAP), 0.0)
		draw_rect(Rect2(pip_position, PIP_SIZE), FULL_COLOR if i < player.health else EMPTY_COLOR)


func _draw_tools(player: Player) -> void:
	var owned := player.owned_tools()
	if owned.is_empty():
		return
	draw_rect(TOOL_BOX, FRAME_COLOR, false, 1.0)
	ToolIcons.draw(self, player.selected_tool, TOOL_BOX.get_center())
	var x := TOOL_BOX.end.x + 7.0
	for id: int in owned:
		if id != player.selected_tool:
			ToolIcons.draw(self, id, Vector2(x, TOOL_BOX.get_center().y), 0.6)
			x += 9.0
