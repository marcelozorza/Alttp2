extends CanvasLayer
## Controles de toque para celular: direcional virtual, os quatro botões de
## face e os botões de pausa e de mapa. Liga sozinho no Android e no iOS. No
## computador, liga com o argumento --toque depois de "--" na linha de comando,
## para testar com o mouse.
##
## Cada toque vira a mesma ação do mapa de entrada que o controle já usa
## (InputEventAction), então o personagem, os menus e o HUD não sabem se o
## comando veio do toque ou do controle. As peças ficam nas faixas dos lados
## do quadro de jogo, nas posições de ui/hud_layout.gd.
##
## Direcional que nasce onde o dedo encosta, em qualquer ponto da metade
## esquerda da tela, e vira um joystick ali (pedido de Marcelo em 2026-11-14,
## depois de jogar o direcional fixo). A direção é a do dedo em relação ao
## centro, uma das 8. Se o dedo passa da borda, o centro vem atrás dele, então
## o dedo nunca fica preso dentro do desenho. Voltar ao centro conta como
## soltar.
##
## Botões de ação: o HUD desenha a coluna com os ícones. Cada botão responde
## a toques na sua fileira inteira, da borda da tela até um pouco dentro do
## jogo. Arrastar o dedo para outra fileira troca de botão.

## Fração do raio do direcional que conta como centro, sem direção.
const STICK_DEAD_ZONE := 0.25
## Ação de cada botão, pelo índice do Godot do botão: 0 a espada, 1 o pulo,
## 2 a chama e 3 a bomba.
const FACE_ACTIONS: Array[StringName] = [&"attack", &"jump", &"use_fire", &"use_bomb"]
const STICK_IDLE := Color(1.0, 1.0, 1.0, 0.18)
const STICK_ACTIVE := Color(1.0, 1.0, 1.0, 0.45)
const PRESSED_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const BUTTON_BACK := Color(0.16, 0.16, 0.2, 1.0)
const BUTTON_EDGE := Color(1.0, 1.0, 1.0, 0.7)

## Ligado quando o aparelho tem toque ou com --toque. Desligado, nada aparece.
var enabled := false
## Escondido depois de um botão de controle ou tecla, até o próximo toque.
var _hidden_by_pad := false
## Dedo do direcional (-1 sem dedo), centro e ponta.
var _stick_finger := -1
var _stick_center := Vector2.ZERO
var _stick_tip := Vector2.ZERO
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
	var screen := _screen()
	if HudLayout.pause_rect(screen).grow(6.0).has_point(point):
		_tap(&"pause")
		return
	if HudLayout.map_rect(screen).grow(6.0).has_point(point):
		_tap(&"map")
		return
	if get_tree().paused:
		return
	var face := _face_at(point)
	if face >= 0:
		_face_fingers[finger] = face
		_set_action(FACE_ACTIONS[face], true)
	elif _stick_finger < 0 and HudLayout.stick_area(screen).has_point(point):
		_stick_finger = finger
		_stick_center = point
		_stick_tip = point
		_set_direction(Vector2.ZERO)


func _on_drag(finger: int, point: Vector2) -> void:
	if finger == _stick_finger:
		var offset := point - _stick_center
		if offset.length() > HudLayout.STICK_RADIUS:
			_stick_center = point - offset.normalized() * HudLayout.STICK_RADIUS
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


func _face_at(point: Vector2) -> int:
	return HudLayout.button_at(_screen(), point)


## Uma das 8 direções do deslocamento do dedo, ou zero dentro da zona morta.
func _direction_of(offset: Vector2) -> Vector2:
	if offset.length() < HudLayout.STICK_RADIUS * STICK_DEAD_ZONE:
		return Vector2.ZERO
	var step := roundi(offset.angle() / (PI / 4.0))
	var angle := step * PI / 4.0
	return Vector2(roundf(cos(angle)), roundf(sin(angle)))


func _screen() -> Vector2:
	return _canvas.get_viewport_rect().size


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
	var screen := _screen()
	_draw_small_button(HudLayout.map_rect(screen), false)
	_draw_small_button(HudLayout.pause_rect(screen), true)
	if get_tree().paused:
		return
	_draw_stick(screen)
	var radius := HudLayout.button_radius(screen)
	for face: int in _face_fingers.values():
		_canvas.draw_circle(HudLayout.button_center(screen, face), radius, PRESSED_COLOR)


## Base e ponta do direcional: onde o dedo está, ou apagado no lugar de
## descanso quando ninguém toca.
func _draw_stick(screen: Vector2) -> void:
	var center := _stick_center
	var tip := _stick_tip
	var color := STICK_ACTIVE
	if _stick_finger < 0:
		center = HudLayout.stick_home(screen)
		tip = center
		color = STICK_IDLE
	_canvas.draw_arc(center, HudLayout.STICK_RADIUS, 0.0, TAU, 32, color, 2.0)
	_canvas.draw_circle(tip, HudLayout.STICK_RADIUS * 0.45, color)


## Botão pequeno do alto da faixa direita: pausa (duas barras) ou mapa (folha dobrada).
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
