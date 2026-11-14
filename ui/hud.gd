extends Control
## HUD da versão de celular (decisões de Marcelo em 2026-11-14). Nada fica por
## cima do quadro de jogo: tudo vai para as faixas dos lados (ui/hud_layout.gd).
##
## Faixa esquerda: a vida em corações de dois pontos, o contador de chaves
## pequenas, sempre à vista, mesmo em zero, com a chave grande depois de
## encontrada, e, no capítulo, o minimapa das salas já visitadas. Embaixo fica
## o direcional dos controles de toque (touch/touch_controls.gd).
##
## Faixa direita: os botões de mapa e pausa do toque, o capítulo e o
## cronômetro, e embaixo os quatro botões de face num losango, nas cores do
## Super Famicom. O botão de uma ferramenta que o personagem ainda não tem
## aparece apagado e vazio. Depois de pegar a ferramenta, ele mostra o ícone
## dela, ou o da melhoria, e uma fileira de pontos com as cargas, e escurece
## quando elas acabam. A espada fica sempre no seu botão, com a lâmina magenta
## enquanto está travada. Os botões são os mesmos que o toque aperta, e o
## losango segue o mapa de entrada do projeto: trocar um botão em
## Configurações do Projeto, aba Mapa de Entrada, basta.

## Coração de dois pontos de vida: cheio, pela metade e vazio (Marcelo pediu
## os corações de volta em 2026-11-07, no lugar dos ossos de um dia).
const HEART_TEXTURE := preload("res://art/heart.svg")
const HALF_HEART_TEXTURE := preload("res://art/heart_half.svg")
const EMPTY_HEART_TEXTURE := preload("res://art/heart_empty.svg")
## Passo entre dois corações na linha e entre as linhas.
const HEART_STEP := Vector2(18.0, 16.0)
## Chave e número apagados, quando não há nenhuma.
const NO_KEY_TINT := Color(0.62, 0.62, 0.68, 1.0)
const SIDE_COLOR := Color(0.07, 0.07, 0.09, 1.0)
## Faixa que cobre a borda do jogo, numa tela estreita.
const OVERLAP_COLOR := Color(0.07, 0.07, 0.09, 0.55)
const TEXT_COLOR := Color(0.85, 0.85, 0.8, 1.0)
const BUTTON_RIM := Color(0.05, 0.05, 0.07, 1.0)
## Mistura com o escuro do botão de uma ferramenta que o personagem não tem.
const EMPTY_DIM := 0.65
## Sombra sobre o botão de uma ferramenta sem cargas.
const SPENT_SHADE := Color(0.0, 0.0, 0.0, 0.55)
const CHARGE_COLOR := Color(0.98, 0.95, 0.85, 1.0)
const SPENT_CHARGE_COLOR := Color(0.12, 0.12, 0.14, 0.8)
const CHARGE_SIZE := Vector2(4.0, 4.0)
const CHARGE_STEP := 6.0
## Ferramenta de cada ação. A espada fica de fora, por não ser uma ferramenta.
const TOOL_ACTIONS := {
	&"use_fire": Item.Id.FIRE,
	&"use_bomb": Item.Id.BOMB,
	&"jump": Item.Id.SPRING,
}
const FONT_SIZE := 16
## Altura do texto do capítulo e do cronômetro, abaixo dos botões de mapa e
## pausa.
const TIME_TOP := 50.0

## Ligado, desenha as faixas dos lados (mundo e capítulo).
@export var show_bar := false

## Posição no losango (0 a 3) de cada ação, lida do mapa de entrada.
var _button_slots := {}


func _ready() -> void:
	position = Vector2.ZERO
	_find_button_slot(&"attack")
	for action: StringName in TOOL_ACTIONS:
		_find_button_slot(action)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var screen := get_viewport_rect().size
	if show_bar:
		var color := OVERLAP_COLOR if HudLayout.overlaps(screen) else SIDE_COLOR
		draw_rect(HudLayout.left_side(screen), color)
		draw_rect(HudLayout.right_side(screen), color)
	var player := get_tree().get_first_node_in_group("player") as Player
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	var left := HudLayout.left_side(screen)
	var top := HudLayout.MARGIN
	if player:
		top = _draw_health(player, left)
		top = _draw_keys(player, left, top + 4.0)
		_draw_buttons(player, screen)
	if chapter:
		_draw_minimap(chapter, left, top + 8.0)
	var lines: Array[String] = []
	if chapter:
		lines.append(chapter.mode_text())
		lines.append(
			GameMath.time_text(Progress.run_ticks) if Progress.active else chapter.time_text()
		)
	elif Progress.active:
		lines.append(GameMath.time_text(Progress.run_ticks))
	var right := HudLayout.right_side(screen)
	for i: int in lines.size():
		draw_string(
			Fonts.SMALL,
			Vector2(right.position.x, TIME_TOP + i * 16.0),
			lines[i],
			HORIZONTAL_ALIGNMENT_CENTER,
			right.size.x,
			FONT_SIZE,
			TEXT_COLOR
		)


func _find_button_slot(action: StringName) -> void:
	for event: InputEvent in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if button and button.button_index >= 0 and button.button_index < 4:
			_button_slots[action] = button.button_index
			return


## Um coração a cada dois pontos de vida máxima, cheio, pela metade ou vazio,
## em quantas linhas a faixa pedir. Devolve a altura em que os corações acabam.
func _draw_health(player: Player, side: Rect2) -> float:
	var hearts := ceili(player.max_health / 2.0)
	var per_row := maxi(1, floori((side.size.x - HudLayout.MARGIN) / HEART_STEP.x))
	var origin := side.position + Vector2(HudLayout.MARGIN, HudLayout.MARGIN)
	for i: int in hearts:
		var points := clampi(player.health - i * 2, 0, 2)
		var texture := EMPTY_HEART_TEXTURE
		if points == 2:
			texture = HEART_TEXTURE
		elif points == 1:
			texture = HALF_HEART_TEXTURE
		var cell := Vector2(i % per_row, floori(float(i) / per_row))
		draw_texture(texture, origin + cell * HEART_STEP)
	var rows := ceili(float(hearts) / per_row)
	return origin.y + rows * HEART_STEP.y


## O ícone da chave com o número de chaves ao lado, apagado quando é zero, e a
## chave grande depois, quando o personagem a tem. Devolve onde a linha acaba.
func _draw_keys(player: Player, side: Rect2, top: float) -> float:
	var tint := Color.WHITE if player.keys > 0 else NO_KEY_TINT
	var text := "x%d" % player.keys
	var middle := top + 8.0
	var left := side.position.x + HudLayout.MARGIN
	ToolIcons.draw(self, Item.Id.KEY, Vector2(left + 6.0, middle), tint)
	var text_position := Vector2(left + 16.0, middle + 6.0)
	draw_string(Fonts.SMALL, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, tint)
	if player.has_tool(Item.Id.BOSS_KEY):
		var width := Fonts.SMALL.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		ToolIcons.draw(self, Item.Id.BOSS_KEY, Vector2(left + 30.0 + width, middle))
	return top + 16.0


## Os quatro botões de face, na cor do Super Famicom de cada posição.
func _draw_buttons(player: Player, screen: Vector2) -> void:
	var radius := HudLayout.button_radius(screen)
	var icon_scale := 2.0 if radius >= 24.0 else 1.0
	if _button_slots.has(&"attack"):
		var slot: int = _button_slots[&"attack"]
		var center := HudLayout.button_center(screen, slot)
		_draw_disc(center, radius, HudLayout.FACE_COLORS[slot])
		draw_set_transform(center, 0.0, Vector2.ONE * icon_scale)
		ToolIcons.draw_sword(self, Vector2.ZERO, player.is_sword_locked())
		# A espada forte mostra o selo x2, como as outras melhorias.
		if player.has_tool(Item.Id.STRONG_SWORD) and not player.is_sword_locked():
			ToolIcons.draw(self, Item.Id.STRONG_SWORD, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
	for action: StringName in TOOL_ACTIONS:
		if not _button_slots.has(action):
			continue
		var slot: int = _button_slots[action]
		var center := HudLayout.button_center(screen, slot)
		var id: int = TOOL_ACTIONS[action]
		if id == player.denied_tool:
			center += DoorArt.shake_offset(player.denied_tick)
		var color: Color = HudLayout.FACE_COLORS[slot]
		if not player.has_tool(id):
			_draw_disc(center, radius, color.lerp(SIDE_COLOR, EMPTY_DIM))
			continue
		_draw_disc(center, radius, color)
		draw_set_transform(center, 0.0, Vector2.ONE * icon_scale)
		ToolIcons.draw(self, _shown_item(player, id), Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
		var left := player.charges_left(id)
		if left == 0:
			draw_circle(center, radius, SPENT_SHADE)
		_draw_charges(center, radius, left, player.max_charges(id))


func _draw_disc(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, BUTTON_RIM)
	draw_circle(center, radius - 2.0, color)


## Item desenhado no botão da ferramenta: a melhoria, se o personagem a tem.
func _shown_item(player: Player, id: int) -> int:
	if id == Item.Id.BOMB and player.has_tool(Item.Id.STRONG_BOMB):
		return Item.Id.STRONG_BOMB
	if id == Item.Id.FIRE and player.has_tool(Item.Id.STRONG_FIRE):
		return Item.Id.STRONG_FIRE
	if id == Item.Id.SPRING and player.has_tool(Item.Id.STRONG_SPRING):
		return Item.Id.STRONG_SPRING
	return id


## Fileira de cargas dentro do botão, embaixo do ícone. As gastas ficam à
## esquerda.
func _draw_charges(center: Vector2, radius: float, left: int, maximum: int) -> void:
	if maximum <= 0:
		return
	var width := (maximum - 1) * CHARGE_STEP + CHARGE_SIZE.x
	var corner := Vector2(floorf(center.x - width / 2.0), floorf(center.y + radius * 0.55))
	for i: int in maximum:
		var color := CHARGE_COLOR if i >= maximum - left else SPENT_CHARGE_COLOR
		draw_rect(Rect2(corner + Vector2(i * CHARGE_STEP, 0.0), CHARGE_SIZE), color)


## Minimapa das salas já visitadas, na faixa esquerda, abaixo das chaves. A
## casa de cada sala encolhe para a grade caber na largura da faixa.
func _draw_minimap(chapter: Chapter, side: Rect2, top: float) -> void:
	var full := Minimap.rooms_size(chapter, Minimap.HUD_CELL)
	var room_count := full / Minimap.HUD_CELL
	var room_width := side.size.x - 2.0 * HudLayout.MARGIN - 8.0
	var shrink := minf(1.0, room_width / full.x)
	var cell := (Minimap.HUD_CELL * shrink).floor()
	var size := room_count * cell
	var origin := Vector2(side.get_center().x - floorf(size.x / 2.0), top + 4.0)
	draw_rect(Rect2(origin - Vector2(4.0, 4.0), size + Vector2(8.0, 8.0)), Minimap.BACKGROUND)
	Minimap.draw_rooms(self, chapter, origin, cell)
