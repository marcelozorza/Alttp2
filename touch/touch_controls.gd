extends CanvasLayer
## Controles de toque para celular: direcional virtual, os quatro botões de
## face e os botões de pausa e de mapa. Liga sozinho no Android e no iOS. No
## computador, liga com o argumento --toque depois de "--" na linha de comando,
## para testar com o mouse.
##
## Nada aqui muda regra de jogo. Cada toque vira a mesma ação do mapa de
## entrada que o controle já usa (InputEventAction), então o personagem, os
## menus e o HUD não sabem se o comando veio do toque ou do controle.
##
## Direcional: o lado esquerdo da tela, abaixo da barra do alto. O primeiro
## toque marca o centro do direcional onde o dedo encostou, e arrastar escolhe
## uma das 8 direções. Se o dedo passa da borda, o centro vem atrás dele. Voltar
## ao centro conta como soltar, então a corrida (soltar e apertar de novo a
## mesma direção) funciona sem tirar o dedo da tela.
##
## Botões de face: um círculo em volta do losango do HUD, no canto inferior
## direito. O círculo é dividido em quatro fatias, uma por botão, na posição do
## botão no losango. O HUD continua desenhando os ícones, as cargas e o botão
## apagado. Arrastar o dedo para outra fatia troca de botão.

## Raio do direcional, em pixels da tela de 640x360.
const STICK_RADIUS := 34.0
## Fração do raio que conta como centro, sem direção.
const STICK_DEAD_ZONE := 0.3
## Onde o direcional aparece, apagado, enquanto ninguém toca.
const STICK_HOME := Vector2(96.0, 252.0)
## Abaixo desta linha começa a área de jogo (a barra do alto tem 40 px).
const TOP_BAR := 40.0
## Raio da área de toque em volta do centro do losango do HUD.
const FACE_RADIUS := 86.0
## Botões de pausa e de mapa, na barra do alto, entre os corações e o tempo.
const PAUSE_RECT := Rect2(462.0, 6.0, 40.0, 28.0)
const MAP_RECT := Rect2(414.0, 6.0, 40.0, 28.0)
const HUD := preload("res://ui/hud.gd")
## Ação de cada fatia do círculo, pelo índice do botão no losango do HUD:
## 0 embaixo, 1 à direita, 2 à esquerda e 3 em cima.
const FACE_ACTIONS: Array[StringName] = [&"attack", &"jump", &"use_fire", &"use_bomb"]
const MOVE_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
const IDLE_COLOR := Color(1.0, 1.0, 1.0, 0.16)
const ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 0.4)
const PRESSED_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const BUTTON_BACK := Color(0.07, 0.07, 0.09, 0.6)
const BUTTON_EDGE := Color(1.0, 1.0, 1.0, 0.5)

## Ligado quando o aparelho tem toque ou com --toque. Desligado, nada aparece.
var enabled := false
## Escondido depois de um botão de controle ou tecla, até o próximo toque.
var _hidden_by_pad := false
## Dedo do direcional (-1 sem dedo), centro e ponta.
var _stick_finger := -1
var _stick_center := STICK_HOME
var _stick_tip := STICK_HOME
## Direção atual do direcional, uma das 8 ou zero.
var _stick_direction := Vector2.ZERO
## Botão de face (0 a 3) de cada dedo nos botões.
var _face_fingers := {}
## Ações apertadas agora pelo toque, para soltar tudo de uma vez.
var _held := {}
var _canvas := Control.new()


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	enabled = OS.has_feature("mobile") or "--toque" in OS.get_cmdline_user_args()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)
	if "--toque" in OS.get_cmdline_user_args() and not OS.has_feature("mobile"):
		# No computador, o mouse faz o papel do dedo.
		Input.emulate_touch_from_mouse = true


func _process(_delta: float) -> void:
	if not _in_game() or get_tree().paused:
		_release_play_controls()
	_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventJoypadButton or event is InputEventKey:
		if not _hidden_by_pad and event.is_pressed():
			_hidden_by_pad = true
			_release_play_controls()
		return
	var touch := event as InputEventScreenTouch
	if touch:
		_hidden_by_pad = false
		if touch.pressed:
			_on_press(touch.index, touch.position)
		else:
			_on_release(touch.index)
		return
	var drag := event as InputEventScreenDrag
	if drag:
		_on_drag(drag.index, drag.position)


func _notification(what: int) -> void:
	if not enabled:
		return
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# Ao sair do aplicativo no meio do jogo, abre a pausa.
		if _in_game() and not get_tree().paused:
			_tap(&"pause")


func _on_press(finger: int, point: Vector2) -> void:
	if not _in_game():
		return
	if PAUSE_RECT.grow(6.0).has_point(point):
		_tap(&"pause")
		return
	if MAP_RECT.grow(6.0).has_point(point):
		_tap(&"map")
		return
	if get_tree().paused:
		return
	var face := _face_at(point)
	if face >= 0:
		_face_fingers[finger] = face
		_set_action(FACE_ACTIONS[face], true)
	elif _stick_finger < 0 and point.x < 320.0 and point.y > TOP_BAR:
		_stick_finger = finger
		_stick_center = point
		_stick_tip = point
		_set_direction(Vector2.ZERO)


func _on_drag(finger: int, point: Vector2) -> void:
	if finger == _stick_finger:
		var offset := point - _stick_center
		if offset.length() > STICK_RADIUS:
			_stick_center = point - offset.normalized() * STICK_RADIUS
		_stick_tip = point
		_set_direction(_direction_of(point - _stick_center))
	elif _face_fingers.has(finger):
		var face := _face_at(point)
		var old: int = _face_fingers[finger]
		if face >= 0 and face != old:
			_set_action(FACE_ACTIONS[old], false)
			_face_fingers[finger] = face
			_set_action(FACE_ACTIONS[face], true)


func _on_release(finger: int) -> void:
	if finger == _stick_finger:
		_stick_finger = -1
		_stick_center = STICK_HOME
		_stick_tip = STICK_HOME
		_set_direction(Vector2.ZERO)
	elif _face_fingers.has(finger):
		var face: int = _face_fingers[finger]
		_face_fingers.erase(finger)
		if not face in _face_fingers.values():
			_set_action(FACE_ACTIONS[face], false)


## Voltar do Android: no jogo, abre e fecha a pausa. Na tela de título, sai do
## jogo. Nas outras telas, volta como o botão de cancelar.
func _on_back() -> void:
	if _in_game():
		_tap(&"pause")
	elif get_tree().current_scene and get_tree().current_scene.scene_file_path == Flow.TITLE_SCENE:
		get_tree().quit()
	else:
		_tap(&"ui_cancel")


## Fatia do círculo dos botões de face sob o ponto, ou -1 fora dele.
func _face_at(point: Vector2) -> int:
	var offset := point - HUD.BUTTONS_CENTER
	if offset.length() > FACE_RADIUS:
		return -1
	var best := -1
	var best_dot := -INF
	for i: int in HUD.FACE_BUTTON_OFFSETS.size():
		var dot := offset.dot((HUD.FACE_BUTTON_OFFSETS[i] as Vector2).normalized())
		if dot > best_dot:
			best_dot = dot
			best = i
	return best


## Uma das 8 direções, ou zero dentro da zona morta.
func _direction_of(offset: Vector2) -> Vector2:
	if offset.length() < STICK_RADIUS * STICK_DEAD_ZONE:
		return Vector2.ZERO
	var step := roundi(offset.angle() / (PI / 4.0))
	var angle := step * PI / 4.0
	return Vector2(roundf(cos(angle)), roundf(sin(angle)))


func _set_direction(direction: Vector2) -> void:
	if direction == _stick_direction:
		return
	_stick_direction = direction
	_set_action(&"move_left", direction.x < 0.0)
	_set_action(&"move_right", direction.x > 0.0)
	_set_action(&"move_up", direction.y < 0.0)
	_set_action(&"move_down", direction.y > 0.0)


func _set_action(action: StringName, pressed: bool) -> void:
	if _held.get(action, false) == pressed:
		return
	_held[action] = pressed
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


## Aperta e solta uma ação, para o que reage só ao aperto (pausa e mapa).
func _tap(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _release_play_controls() -> void:
	_stick_finger = -1
	_stick_center = STICK_HOME
	_stick_tip = STICK_HOME
	_set_direction(Vector2.ZERO)
	_face_fingers.clear()
	for action: StringName in FACE_ACTIONS:
		_set_action(action, false)


## Há um personagem em cena: mundo, capítulo ou sala de teste.
func _in_game() -> bool:
	return get_tree().get_first_node_in_group("player") != null


func _draw_controls() -> void:
	if not enabled or _hidden_by_pad or not _in_game():
		return
	_draw_small_button(MAP_RECT, false)
	_draw_small_button(PAUSE_RECT, true)
	if get_tree().paused:
		return
	var stick_color := ACTIVE_COLOR if _stick_finger >= 0 else IDLE_COLOR
	_canvas.draw_arc(_stick_center, STICK_RADIUS, 0.0, TAU, 32, stick_color, 2.0)
	_canvas.draw_circle(_stick_tip, STICK_RADIUS * 0.42, stick_color)
	_canvas.draw_arc(HUD.BUTTONS_CENTER, FACE_RADIUS - 30.0, 0.0, TAU, 40, IDLE_COLOR, 1.0)
	for face: int in _face_fingers.values():
		var center: Vector2 = HUD.BUTTONS_CENTER + (HUD.FACE_BUTTON_OFFSETS[face] as Vector2)
		_canvas.draw_circle(center, HUD.BUTTON_RADIUS + 3.0, PRESSED_COLOR)


## Botão pequeno da barra do alto: pausa (duas barras) ou mapa (folha dobrada).
func _draw_small_button(rect: Rect2, pause: bool) -> void:
	_canvas.draw_rect(rect, BUTTON_BACK)
	_canvas.draw_rect(rect, BUTTON_EDGE, false, 1.0)
	var middle := rect.get_center()
	if pause:
		_canvas.draw_rect(Rect2(middle + Vector2(-7.0, -8.0), Vector2(5.0, 16.0)), BUTTON_EDGE)
		_canvas.draw_rect(Rect2(middle + Vector2(2.0, -8.0), Vector2(5.0, 16.0)), BUTTON_EDGE)
	else:
		var points := PackedVector2Array(
			[
				middle + Vector2(-12.0, -7.0),
				middle + Vector2(-4.0, -9.0),
				middle + Vector2(4.0, -7.0),
				middle + Vector2(12.0, -9.0),
				middle + Vector2(12.0, 7.0),
				middle + Vector2(4.0, 9.0),
				middle + Vector2(-4.0, 7.0),
				middle + Vector2(-12.0, 9.0),
				middle + Vector2(-12.0, -7.0),
			]
		)
		_canvas.draw_polyline(points, BUTTON_EDGE, 1.0)
		_canvas.draw_line(middle + Vector2(-4.0, -9.0), middle + Vector2(-4.0, 7.0), BUTTON_EDGE)
		_canvas.draw_line(middle + Vector2(4.0, -7.0), middle + Vector2(4.0, 9.0), BUTTON_EDGE)
