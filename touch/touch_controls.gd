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
## Direcional fixo, embaixo na faixa esquerda (decisão de Marcelo em
## 2026-11-14, depois de jogar o direcional que nascia onde o dedo encostava e
## recentrava a cada toque). A direção é a do dedo em relação ao centro, uma
## das 8, e o dedo pode sair e voltar sem recalibrar nada. O toque vale numa
## área um pouco maior que o desenho.
##
## Botões de face: o HUD desenha o losango, com as cores do Super Famicom e os
## ícones. Cada botão responde a toques dentro de uma área maior que o
## desenho, a fatia do losango mais perto do dedo. Arrastar o dedo para outra
## fatia troca de botão.

## Fração do raio do direcional que conta como centro, sem direção.
const STICK_DEAD_ZONE := 0.25
## Quanto além do desenho o toque ainda vale, em raios.
const TOUCH_REACH := 1.5
## Ação de cada fatia do losango, pelo índice do botão no losango:
## 0 embaixo, 1 à direita, 2 à esquerda e 3 em cima.
const FACE_ACTIONS: Array[StringName] = [&"attack", &"jump", &"use_fire", &"use_bomb"]
const DPAD_COLOR := Color(0.24, 0.23, 0.29, 1.0)
const DPAD_PRESSED := Color(0.5, 0.48, 0.58, 1.0)
const PRESSED_COLOR := Color(1.0, 1.0, 1.0, 0.35)
const BUTTON_BACK := Color(0.16, 0.16, 0.2, 1.0)
const BUTTON_EDGE := Color(1.0, 1.0, 1.0, 0.7)

## Ligado quando o aparelho tem toque ou com --toque. Desligado, nada aparece.
var enabled := false
## Escondido depois de um botão de controle ou tecla, até o próximo toque.
var _hidden_by_pad := false
## Dedo do direcional, -1 sem dedo.
var _stick_finger := -1
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
	elif _stick_finger < 0 and _on_dpad(point):
		_stick_finger = finger
		_set_direction(_direction_of(point))


func _on_drag(finger: int, point: Vector2) -> void:
	if finger == _stick_finger:
		_set_direction(_direction_of(point))
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


## Botão do losango sob o ponto, o mais perto do dedo, ou -1 longe dele.
func _face_at(point: Vector2) -> int:
	var screen := _screen()
	var radius := HudLayout.button_radius(screen)
	var best := -1
	var best_distance := radius * TOUCH_REACH
	for i: int in FACE_ACTIONS.size():
		var distance := point.distance_to(HudLayout.button_center(screen, i))
		if distance < best_distance:
			best_distance = distance
			best = i
	return best


func _on_dpad(point: Vector2) -> bool:
	var screen := _screen()
	var reach := HudLayout.dpad_radius(screen) * TOUCH_REACH
	return point.distance_to(HudLayout.dpad_center(screen)) <= reach


## Uma das 8 direções do dedo em relação ao centro do direcional, ou zero
## dentro da zona morta.
func _direction_of(point: Vector2) -> Vector2:
	var screen := _screen()
	var offset := point - HudLayout.dpad_center(screen)
	if offset.length() < HudLayout.dpad_radius(screen) * STICK_DEAD_ZONE:
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
	_draw_dpad(screen)
	var radius := HudLayout.button_radius(screen)
	for face: int in _face_fingers.values():
		_canvas.draw_circle(HudLayout.button_center(screen, face), radius, PRESSED_COLOR)


## Direcional em cruz, com o braço apertado aceso.
func _draw_dpad(screen: Vector2) -> void:
	var center := HudLayout.dpad_center(screen)
	var radius := HudLayout.dpad_radius(screen)
	var arm := floorf(radius * 0.36)
	_canvas.draw_rect(Rect2(center.x - arm, center.y - radius, arm * 2.0, radius * 2.0), DPAD_COLOR)
	_canvas.draw_rect(Rect2(center.x - radius, center.y - arm, radius * 2.0, arm * 2.0), DPAD_COLOR)
	if _stick_direction == Vector2.ZERO:
		return
	for axis: Vector2 in [Vector2(_stick_direction.x, 0.0), Vector2(0.0, _stick_direction.y)]:
		if axis == Vector2.ZERO:
			continue
		var tip := center + axis * (radius - arm)
		_canvas.draw_rect(Rect2(tip - Vector2(arm, arm), Vector2(arm, arm) * 2.0), DPAD_PRESSED)


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
