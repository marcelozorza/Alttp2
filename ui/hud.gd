extends Control
## HUD: a vida, um quadrado por ponto, e os quatro botões de face do controle
## num losango, cada um na posição do botão. A espada fica sempre no seu botão,
## com a lâmina magenta enquanto está travada. O botão de uma ferramenta que o
## personagem ainda não tem aparece vazio e apagado. Uma melhoria troca o
## ícone da ferramenta: com a chama forte, o botão da chama mostra a chama
## maior de miolo branco, e com a mola forte, o botão do pulo mostra a mola
## mais alta. Ao lado do botão de uma
## ferramenta com cargas, do lado de fora do losango, uma coluna de pontos
## mostra as cargas, que se apagam de cima para baixo, e o botão escurece
## quando elas acabam. No capítulo, mostra também o número do capítulo e o
## cronômetro numa barra no alto da tela. À direita do losango ficam as chaves
## pequenas guardadas e, depois de encontrada, a chave grande. Com mais de
## HEALTH_ROW pontos de vida, a vida passa a ocupar duas linhas mais baixas.

const PIP_SIZE := Vector2(6.0, 6.0)
const PIP_GAP := 2.0
## Pontos de vida que cabem numa linha, antes do losango dos botões.
const HEALTH_ROW := 12
## Onde começam as chaves, à direita do losango.
const KEYS_POSITION := Vector2(146.0, 1.0)
const FULL_COLOR := Color(0.9, 0.2, 0.25, 1.0)
const EMPTY_COLOR := Color(0.25, 0.1, 0.12, 1.0)
const BAR_COLOR := Color(0.07, 0.07, 0.09, 1.0)
const TEXT_COLOR := Color(0.85, 0.85, 0.8, 1.0)
## Fundo de um botão com espada ou ferramenta.
const BUTTON_COLOR := Color(0.38, 0.38, 0.42, 1.0)
## Fundo de um botão cuja ferramenta o personagem ainda não tem.
const EMPTY_BUTTON_COLOR := Color(0.18, 0.18, 0.21, 1.0)
const BUTTON_RADIUS := 4.0
## Sombra sobre o botão de uma ferramenta sem cargas.
const SPENT_SHADE := Color(0.0, 0.0, 0.0, 0.55)
const CHARGE_COLOR := Color(0.95, 0.9, 0.75, 1.0)
const SPENT_CHARGE_COLOR := Color(0.25, 0.25, 0.28, 1.0)
const CHARGE_SIZE := Vector2(2.0, 1.0)
## Distância vertical entre duas cargas.
const CHARGE_STEP := 2.0
## Tamanho da barra do capítulo, a largura toda da tela.
const BAR_SIZE := Vector2(320.0, 20.0)
## Centro do botão de cima, relativo ao HUD.
const BUTTONS_TOP := Vector2(124.0, 0.0)
## Posição de cada botão de face a partir do botão de cima, pelo índice do
## Godot, que segue a posição física do botão: 0 embaixo, 1 à direita, 2 à
## esquerda e 3 em cima.
const FACE_BUTTON_OFFSETS := [
	Vector2(0.0, 12.0), Vector2(12.0, 6.0), Vector2(-12.0, 6.0), Vector2(0.0, 0.0)
]
## Ferramenta de cada ação. A espada fica de fora, por não ser uma ferramenta.
const TOOL_ACTIONS := {
	&"use_fire": Item.Id.FIRE,
	&"use_bomb": Item.Id.BOMB,
	&"jump": Item.Id.SPRING,
}
const ICON_FACTOR := 0.6
const FONT_SIZE := 8

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
	if player:
		_draw_health(player)
		_draw_buttons(player)
		_draw_keys(player)
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


func _find_button_center(action: StringName) -> void:
	for event: InputEvent in InputMap.action_get_events(action):
		var button := event as InputEventJoypadButton
		if not button:
			continue
		var index: int = button.button_index
		if index >= 0 and index < FACE_BUTTON_OFFSETS.size():
			var offset: Vector2 = FACE_BUTTON_OFFSETS[index]
			_button_centers[action] = BUTTONS_TOP + offset
			return


func _draw_health(player: Player) -> void:
	var pip_size := PIP_SIZE
	if player.max_health > HEALTH_ROW:
		pip_size.y = (PIP_SIZE.y - 1.0) / 2.0
	for i: int in player.max_health:
		var row := floori(float(i) / HEALTH_ROW)
		var column := i % HEALTH_ROW
		var pip_position := Vector2(column * (pip_size.x + PIP_GAP), row * (pip_size.y + 1.0))
		draw_rect(Rect2(pip_position, pip_size), FULL_COLOR if i < player.health else EMPTY_COLOR)


## Uma chave pequena por ícone, até 4, e um número quando passam disso. A chave
## grande vem depois.
func _draw_keys(player: Player) -> void:
	var x := KEYS_POSITION.x
	var shown := mini(player.keys, 4)
	for i: int in shown:
		ToolIcons.draw(self, Item.Id.KEY, Vector2(x + 3.0, KEYS_POSITION.y + 4.0), ICON_FACTOR)
		x += 5.0
	if player.keys > shown:
		var font := ThemeDB.fallback_font
		var text := "+%d" % (player.keys - shown)
		draw_string(
			font, Vector2(x + 1.0, 9.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, TEXT_COLOR
		)
		x += 14.0
	if player.has_tool(Item.Id.BOSS_KEY):
		var center := Vector2(x + 6.0, KEYS_POSITION.y + 4.0)
		ToolIcons.draw(self, Item.Id.BOSS_KEY, center, ICON_FACTOR)


func _draw_buttons(player: Player) -> void:
	if _button_centers.has(&"attack"):
		var sword_center: Vector2 = _button_centers[&"attack"]
		draw_circle(sword_center, BUTTON_RADIUS, BUTTON_COLOR)
		var blade := Player.SWORD_LOCK_COLOR if player.is_sword_locked() else ToolIcons.BLADE_COLOR
		ToolIcons.draw_sword(self, sword_center, ICON_FACTOR, blade)
	for action: StringName in TOOL_ACTIONS:
		if not _button_centers.has(action):
			continue
		var center: Vector2 = _button_centers[action]
		var id: int = TOOL_ACTIONS[action]
		if not player.has_tool(id):
			draw_circle(center, BUTTON_RADIUS, EMPTY_BUTTON_COLOR)
			continue
		var left := player.charges_left(id)
		draw_circle(center, BUTTON_RADIUS, BUTTON_COLOR)
		ToolIcons.draw(self, _shown_item(player, id), center, ICON_FACTOR)
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
	var x := center.x + BUTTON_RADIUS + 2.0
	if center.x < BUTTONS_TOP.x:
		x = center.x - BUTTON_RADIUS - 2.0 - CHARGE_SIZE.x
	var top := roundf(center.y) - (maximum - 1) * CHARGE_STEP / 2.0
	for i: int in maximum:
		var color := CHARGE_COLOR if i >= maximum - left else SPENT_CHARGE_COLOR
		draw_rect(Rect2(Vector2(x, top + i * CHARGE_STEP), CHARGE_SIZE), color)
