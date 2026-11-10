class_name MessagePlate
extends Area2D
## Placa de mensagem no chão. Enquanto o personagem está em cima dela, uma
## caixa de texto flutua ao lado, e some quando ele sai. Nada para o jogo
## (pedido de Marcelo em 2026-11-10: "enquanto ele passa, a mensagem aparece,
## bem elegante"). A placa pulsa para chamar a atenção.
##
## A origem fica no centro da casa. Ela fica na camada dos interruptores,
## acima do chão e abaixo dos objetos, e a caixa de texto fica por cima de
## tudo. A caixa nunca sai da sala de uma tela em que a placa está.

const TEXTURE := preload("res://art/message_plate.svg")
const LIT_TEXTURE := preload("res://art/message_plate_lit.svg")
const FONT := preload("res://ui/font/giorgino.fnt")
const FONT_SIZE := 12
const SIZE := Vector2(26.0, 26.0)
## Largura do texto dentro da caixa, em pixels.
const TEXT_WIDTH := 196.0
const LINE_HEIGHT := 13.0
const PADDING := Vector2(8.0, 6.0)
## Distância entre o centro da placa e a borda da caixa.
const GAP := 26.0
## Distância quando a caixa fica acima: a altura do personagem a mais.
const GAP_ABOVE := 54.0
## Ticks para a caixa aparecer ou sumir por inteiro.
const FADE_TICKS := 10
## Ticks de um pulso do brilho da placa.
const PULSE_TICKS := 50
const ROOM_PIXELS := Vector2(640.0, 320.0)
const BOX_COLOR := Color("262335")
const BOX_LIGHT := Color("55526f")
const INK := Color("1e181e")
const TEXT_COLOR := Color("f4f1ea")
const GLOW := Color(1.0, 0.95, 0.66, 1.0)

var text := ""

var _shown := 0
var _stood := false
var _box := Node2D.new()


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = SIZE
	shape.shape = rectangle
	add_child(shape)
	monitorable = false
	_box.z_index = 100
	_box.z_as_relative = false
	_box.draw.connect(_draw_box)
	add_child(_box)


func _physics_process(_delta: float) -> void:
	_stood = false
	for body: Node2D in get_overlapping_bodies():
		if body is Player:
			_stood = true
	_shown = clampi(_shown + (1 if _stood else -1), 0, FADE_TICKS)
	queue_redraw()
	_box.queue_redraw()


func _draw() -> void:
	draw_texture(LIT_TEXTURE if _stood else TEXTURE, Vector2(-16.0, -16.0))
	if not _stood:
		var pulse := 0.5 + 0.5 * sin(Clock.tick * TAU / PULSE_TICKS)
		var color := GLOW
		color.a = 0.35 * pulse
		draw_arc(Vector2.ZERO, 14.0 + pulse * 3.0, 0.0, TAU, 24, color, 1.0)


## A caixa fica acima da placa, ou abaixo quando a placa está no alto da
## sala, e é empurrada para dentro da sala nos lados.
func _draw_box() -> void:
	if _shown == 0 or text.is_empty():
		return
	var alpha := float(_shown) / FADE_TICKS
	var lines := FONT.get_multiline_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, TEXT_WIDTH, FONT_SIZE
	)
	var line_count := maxi(1, roundi(lines.y / LINE_HEIGHT))
	var size := Vector2(TEXT_WIDTH, line_count * LINE_HEIGHT) + PADDING * 2.0
	var room := (global_position / ROOM_PIXELS).floor() * ROOM_PIXELS
	var corner := global_position + Vector2(-size.x / 2.0, -GAP_ABOVE - size.y)
	if corner.y < room.y + 8.0:
		corner.y = global_position.y + GAP
	corner.x = clampf(corner.x, room.x + 8.0, room.x + ROOM_PIXELS.x - size.x - 8.0)
	# A caixa sobe um pouco enquanto aparece.
	corner.y += (1.0 - alpha) * 4.0
	var rect := Rect2((corner - global_position).round(), size)
	_box.draw_rect(rect.grow(2.0), Color(INK, alpha))
	_box.draw_rect(rect.grow(1.0), Color(BOX_LIGHT, alpha))
	_box.draw_rect(rect, Color(BOX_COLOR, alpha))
	_box.draw_multiline_string(
		FONT,
		rect.position + PADDING + Vector2(0.0, 10.0),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		TEXT_WIDTH,
		FONT_SIZE,
		-1,
		Color(TEXT_COLOR, alpha)
	)
