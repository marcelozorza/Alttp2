extends Control
## HUD. No alto, numa barra, a vida, um ossinho por ponto, e, no capítulo, o
## número do capítulo e o cronômetro. No canto inferior esquerdo, sobre a tela,
## os quatro botões de face do controle num losango, cada um na posição do
## botão, com o ícone em pixel art do que ele faz. À direita do losango, no
## capítulo, o contador de chaves pequenas, sempre à vista, mesmo em zero, e a
## chave grande depois de encontrada (Marcelo não achava o contador no alto,
## 2026-11-06). A espada fica sempre no seu botão, com a
## lâmina magenta enquanto está travada. O botão de uma ferramenta que o
## personagem ainda não tem aparece apagado. Uma melhoria troca o ícone da
## ferramenta: com a chama forte, o botão da chama mostra a chama maior de
## miolo branco, e com a mola forte, o botão do pulo mostra a mola de placa
## branca. Ao lado do botão de uma ferramenta com cargas, do lado de fora do
## losango, uma coluna de pontos mostra as cargas, que se apagam de cima para
## baixo, e o botão escurece quando elas acabam. A vida são corações de dois
## pontos, cheios, pela metade ou vazios, e com mais de HEALTH_ROW corações
## passa a ocupar duas linhas. Os corações voltaram no lugar dos ossos de um
## dia por pedido de Marcelo em 2026-11-07 ("corações na barra lá em cima,
## mas ossos que dão a energia").
##
## No canto inferior direito, no capítulo, o minimapa das salas já visitadas
## (ui/minimap.gd). No alto, à direita, o cronômetro: no jogo contínuo, o do
## jogo inteiro desde o Novo jogo, e no treino o do capítulo (pedidos de
## Marcelo em 2026-11-07).

## Coração de dois pontos de vida: cheio, pela metade e vazio (Marcelo pediu
## os corações de volta em 2026-11-07, no lugar dos ossos de um dia).
const HEART_TEXTURE := preload("res://art/heart.svg")
const HALF_HEART_TEXTURE := preload("res://art/heart_half.svg")
const EMPTY_HEART_TEXTURE := preload("res://art/heart_empty.svg")
## Passo entre dois corações na linha e entre as duas linhas.
const HEART_STEP := Vector2(18.0, 16.0)
## Corações que cabem numa linha, antes do cronômetro.
const HEALTH_ROW := 12
## Centro do ícone da chave, à direita do losango, na altura do centro dele.
const KEYS_POSITION := Vector2(108.0, 304.0)
## Chave apagada, quando não há nenhuma.
const NO_KEY_TINT := Color(0.45, 0.45, 0.5, 1.0)
const BAR_COLOR := Color(0.07, 0.07, 0.09, 1.0)
const TEXT_COLOR := Color(0.85, 0.85, 0.8, 1.0)
## Disco de um botão com espada ou ferramenta, e disco apagado de um botão
## cuja ferramenta o personagem ainda não tem.
const BUTTON_TEXTURE := preload("res://art/button_pad.svg")
const EMPTY_BUTTON_TEXTURE := preload("res://art/button_pad_empty.svg")
const BUTTON_RADIUS := 16.0
## Sombra sobre o botão de uma ferramenta sem cargas.
const SPENT_SHADE := Color(0.0, 0.0, 0.0, 0.55)
const CHARGE_COLOR := Color(0.95, 0.9, 0.75, 1.0)
const SPENT_CHARGE_COLOR := Color(0.25, 0.25, 0.28, 1.0)
const CHARGE_SIZE := Vector2(4.0, 4.0)
## Distância vertical entre duas cargas.
const CHARGE_STEP := 6.0
## Tamanho da barra do capítulo, a largura toda da tela.
const BAR_SIZE := Vector2(640.0, 40.0)
## Centro do losango dos botões, relativo ao HUD: canto inferior esquerdo da
## tela, com espaço à esquerda para a coluna de cargas do botão da esquerda.
const BUTTONS_CENTER := Vector2(52.0, 304.0)
## Posição de cada botão de face a partir do centro do losango, pelo índice do
## Godot, que segue a posição física do botão: 0 embaixo, 1 à direita, 2 à
## esquerda e 3 em cima.
const FACE_BUTTON_OFFSETS := [
	Vector2(0.0, 24.0), Vector2(24.0, 0.0), Vector2(-24.0, 0.0), Vector2(0.0, -24.0)
]
## Ferramenta de cada ação. A espada fica de fora, por não ser uma ferramenta.
const TOOL_ACTIONS := {
	&"use_fire": Item.Id.FIRE,
	&"use_bomb": Item.Id.BOMB,
	&"jump": Item.Id.SPRING,
}
const FONT_SIZE := 16
## Canto inferior direito do minimapa, relativo ao HUD, a 8 px das bordas.
const MINIMAP_CORNER := Vector2(624.0, 344.0)

## Ligado, desenha a barra de fundo do capítulo, que esconde a sala vizinha.
@export var show_bar := false

## Centro do botão de cada ação, lido do mapa de entrada do projeto. Assim o
## HUD acompanha uma troca de botões feita no editor, em Configurações do
## Projeto, aba Mapa de Entrada. Uma ação sem botão de face fica de fora.
var _button_centers := {}


func _ready() -> void:
	_find_button_center(&"attack")
	for action: StringName in TOOL_ACTIONS:
		_find_button_center(action)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if show_bar:
		draw_rect(Rect2(-position, BAR_SIZE), BAR_COLOR)
	var player := get_tree().get_first_node_in_group("player") as Player
	var chapter := get_tree().get_first_node_in_group("chapter")
	if player:
		_draw_health(player)
		_draw_buttons(player)
		if chapter:
			_draw_keys(player)
	var text := ""
	if chapter:
		var time: String = chapter.call("time_text")
		if Progress.active:
			time = GameMath.time_text(Progress.run_ticks)
		text = "%s   %s" % [chapter.call("mode_text"), time]
		_draw_minimap(chapter)
	elif Progress.active:
		text = GameMath.time_text(Progress.run_ticks)
	if not text.is_empty():
		draw_string(
			Fonts.SMALL,
			Vector2(300.0, 18.0),
			text,
			HORIZONTAL_ALIGNMENT_RIGHT,
			324.0,
			FONT_SIZE,
			TEXT_COLOR
		)


func _find_button_center(action: StringName) -> void:
	for event: InputEvent in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if not button:
			continue
		var index: int = button.button_index
		if index >= 0 and index < FACE_BUTTON_OFFSETS.size():
			var offset: Vector2 = FACE_BUTTON_OFFSETS[index]
			_button_centers[action] = BUTTONS_CENTER + offset
			return


## Um coração a cada dois pontos de vida máxima, cheio, pela metade ou vazio.
func _draw_health(player: Player) -> void:
	var hearts := ceili(player.max_health / 2.0)
	for i: int in hearts:
		var points := clampi(player.health - i * 2, 0, 2)
		var texture := EMPTY_HEART_TEXTURE
		if points == 2:
			texture = HEART_TEXTURE
		elif points == 1:
			texture = HALF_HEART_TEXTURE
		var row := floori(float(i) / HEALTH_ROW)
		var column := i % HEALTH_ROW
		draw_texture(texture, Vector2(column * HEART_STEP.x, row * HEART_STEP.y))


## O ícone da chave com o número de chaves ao lado, apagado quando é zero, e a
## chave grande depois, quando o personagem a tem.
func _draw_keys(player: Player) -> void:
	var tint := Color.WHITE if player.keys > 0 else NO_KEY_TINT
	ToolIcons.draw(self, Item.Id.KEY, KEYS_POSITION, tint)
	var font := Fonts.SMALL
	var text := "x%d" % player.keys
	var text_position := KEYS_POSITION + Vector2(12.0, 8.0)
	draw_string(font, text_position, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, tint)
	if player.has_tool(Item.Id.BOSS_KEY):
		ToolIcons.draw(self, Item.Id.BOSS_KEY, KEYS_POSITION + Vector2(52.0, 0.0))


func _draw_buttons(player: Player) -> void:
	if _button_centers.has(&"attack"):
		var sword_center: Vector2 = _button_centers[&"attack"]
		ToolIcons.draw_centered(self, BUTTON_TEXTURE, sword_center)
		ToolIcons.draw_sword(self, sword_center, player.is_sword_locked())
	for action: StringName in TOOL_ACTIONS:
		if not _button_centers.has(action):
			continue
		var center: Vector2 = _button_centers[action]
		var id: int = TOOL_ACTIONS[action]
		if not player.has_tool(id):
			ToolIcons.draw_centered(self, EMPTY_BUTTON_TEXTURE, center)
			continue
		var left := player.charges_left(id)
		ToolIcons.draw_centered(self, BUTTON_TEXTURE, center)
		ToolIcons.draw(self, _shown_item(player, id), center)
		if left == 0:
			draw_circle(center, BUTTON_RADIUS, SPENT_SHADE)
		_draw_charges(center, left, player.max_charges(id))


## Item desenhado no botão da ferramenta: a melhoria, se o personagem a tem.
func _shown_item(player: Player, id: int) -> int:
	if id == Item.Id.FIRE and player.has_tool(Item.Id.STRONG_FIRE):
		return Item.Id.STRONG_FIRE
	if id == Item.Id.SPRING and player.has_tool(Item.Id.STRONG_SPRING):
		return Item.Id.STRONG_SPRING
	return id


## Coluna de cargas ao lado do botão, do lado de fora do losango. Os botões do
## meio, de cima e de baixo, usam o lado direito. As cargas gastas ficam no
## alto da coluna.
func _draw_charges(center: Vector2, left: int, maximum: int) -> void:
	if maximum <= 0:
		return
	var x := center.x + BUTTON_RADIUS + 4.0
	if center.x < BUTTONS_CENTER.x:
		x = center.x - BUTTON_RADIUS - 4.0 - CHARGE_SIZE.x
	var top := floorf(center.y - ((maximum - 1) * CHARGE_STEP + CHARGE_SIZE.y) / 2.0)
	for i: int in maximum:
		var color := CHARGE_COLOR if i >= maximum - left else SPENT_CHARGE_COLOR
		draw_rect(Rect2(Vector2(x, top + i * CHARGE_STEP), CHARGE_SIZE), color)


## Minimapa das salas já visitadas, no canto inferior direito, sobre um fundo
## escuro.
func _draw_minimap(chapter: Node) -> void:
	var size := Minimap.rooms_size(chapter, Minimap.HUD_CELL)
	var origin := MINIMAP_CORNER - size
	draw_rect(Rect2(origin - Vector2(4.0, 4.0), size + Vector2(8.0, 8.0)), Minimap.BACKGROUND)
	Minimap.draw_rooms(self, chapter, origin, Minimap.HUD_CELL)
