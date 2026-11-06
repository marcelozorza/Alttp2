class_name ToolIcons
## Desenhos provisórios dos itens, usados no HUD e nos baús, e da espada, que
## aparece no HUD. Cada item tem uma forma e uma cor fixas, que se repetem no
## mundo: a bomba é a mesma do chão, a chama tem a cor da bola de fogo e a
## lâmina tem a cor da espada do personagem.

const BOMB_COLOR := Color(0.12, 0.12, 0.17, 1.0)
const FUSE_COLOR := Color(1.0, 0.75, 0.25, 1.0)
const FLAME_OUTER_COLOR := Color(1.0, 0.45, 0.1, 1.0)
const FLAME_INNER_COLOR := Color(1.0, 0.9, 0.4, 1.0)
## A chama forte é maior e tem o miolo branco, como a bola de fogo dela.
const STRONG_FLAME_CORE_COLOR := Color(1.0, 0.98, 0.85, 1.0)
const SPRING_COLOR := Color(0.55, 0.85, 0.45, 1.0)
## A mola forte é mais alta, com a placa de cima reforçada.
const STRONG_SPRING_PLATE_COLOR := Color(0.85, 0.95, 0.7, 1.0)
const HEART_COLOR := Color(0.9, 0.2, 0.25, 1.0)
const KEY_COLOR := Color(0.85, 0.8, 0.7, 1.0)
const BOSS_KEY_COLOR := Color(0.95, 0.4, 0.3, 1.0)
const BLADE_COLOR := Color(0.86, 0.9, 0.95, 1.0)
const HILT_COLOR := Color(0.55, 0.34, 0.16, 1.0)
const FLAME := [Vector2(0, -6), Vector2(4, 0), Vector2(3, 4), Vector2(-3, 4), Vector2(-4, 0)]
const FLAME_CORE := [Vector2(0, -2), Vector2(2, 1), Vector2(1, 3), Vector2(-1, 3), Vector2(-2, 1)]
const STRONG_FLAME := [Vector2(0, -7), Vector2(5, 0), Vector2(4, 5), Vector2(-4, 5), Vector2(-5, 0)]
const STRONG_FLAME_MIDDLE := [
	Vector2(0, -4), Vector2(3, 1), Vector2(2, 4), Vector2(-2, 4), Vector2(-3, 1)
]
const STRONG_FLAME_CORE := [Vector2(0, -1), Vector2(1.5, 2), Vector2(0, 3.5), Vector2(-1.5, 2)]
const COIL := [
	Vector2(-4, 5), Vector2(4, 3), Vector2(-4, 1), Vector2(4, -1), Vector2(-4, -3), Vector2(4, -5)
]
const STRONG_COIL := [
	Vector2(-4, 6),
	Vector2(4, 4.5),
	Vector2(-4, 3),
	Vector2(4, 1.5),
	Vector2(-4, 0),
	Vector2(4, -1.5),
	Vector2(-4, -3),
	Vector2(4, -4.5),
	Vector2(-4, -6),
]
const HEART_TIP := [Vector2(-4.6, -0.2), Vector2(4.6, -0.2), Vector2(0, 5)]


## Desenha o ícone do item centrado em center, num quadrado de cerca de 12
## pixels vezes factor. Só pode ser chamado dentro do _draw de canvas.
static func draw(canvas: CanvasItem, id: int, center: Vector2, factor := 1.0) -> void:
	match id:
		Item.Id.BOMB:
			canvas.draw_circle(center + Vector2(0.0, 1.0) * factor, 4.0 * factor, BOMB_COLOR)
			var fuse := Rect2(center + Vector2(1.0, -5.0) * factor, Vector2(1.0, 2.0) * factor)
			canvas.draw_rect(fuse, FUSE_COLOR)
		Item.Id.FIRE:
			canvas.draw_colored_polygon(_points(FLAME, center, factor), FLAME_OUTER_COLOR)
			canvas.draw_colored_polygon(_points(FLAME_CORE, center, factor), FLAME_INNER_COLOR)
		Item.Id.STRONG_FIRE:
			canvas.draw_colored_polygon(_points(STRONG_FLAME, center, factor), FLAME_OUTER_COLOR)
			var middle := _points(STRONG_FLAME_MIDDLE, center, factor)
			canvas.draw_colored_polygon(middle, FLAME_INNER_COLOR)
			var core := _points(STRONG_FLAME_CORE, center, factor)
			canvas.draw_colored_polygon(core, STRONG_FLAME_CORE_COLOR)
		Item.Id.SPRING:
			canvas.draw_polyline(_points(COIL, center, factor), SPRING_COLOR, maxf(1.0, factor))
			var plate := Rect2(center + Vector2(-4.0, -6.5) * factor, Vector2(8.0, 1.5) * factor)
			canvas.draw_rect(plate, SPRING_COLOR)
		Item.Id.STRONG_SPRING:
			var coil := _points(STRONG_COIL, center, factor)
			canvas.draw_polyline(coil, SPRING_COLOR, maxf(1.0, factor))
			var plate := Rect2(center + Vector2(-5.0, -8.5) * factor, Vector2(10.0, 2.5) * factor)
			canvas.draw_rect(plate, STRONG_SPRING_PLATE_COLOR)
		Item.Id.HEART:
			canvas.draw_circle(center + Vector2(-2.0, -1.0) * factor, 2.6 * factor, HEART_COLOR)
			canvas.draw_circle(center + Vector2(2.0, -1.0) * factor, 2.6 * factor, HEART_COLOR)
			canvas.draw_colored_polygon(_points(HEART_TIP, center, factor), HEART_COLOR)
		Item.Id.KEY:
			_draw_key(canvas, center, factor * 0.8, KEY_COLOR)
		Item.Id.BOSS_KEY:
			_draw_key(canvas, center, factor, BOSS_KEY_COLOR)


## Desenha a espada centrada em center, no mesmo tamanho dos itens. A lâmina
## usa blade_color, que no HUD mostra a espada travada.
static func draw_sword(
	canvas: CanvasItem, center: Vector2, factor := 1.0, blade_color := BLADE_COLOR
) -> void:
	var blade := Rect2(center + Vector2(-1.0, -6.0) * factor, Vector2(2.0, 8.0) * factor)
	var guard := Rect2(center + Vector2(-3.0, 2.0) * factor, Vector2(6.0, 1.5) * factor)
	var grip := Rect2(center + Vector2(-1.0, 3.5) * factor, Vector2(2.0, 2.5) * factor)
	canvas.draw_rect(blade, blade_color)
	canvas.draw_rect(guard, HILT_COLOR)
	canvas.draw_rect(grip, HILT_COLOR)


## Chave de pé: argola em cima, haste e dois dentes. A chave grande usa a mesma
## forma maior e vermelha, a cor da porta do chefe.
static func _draw_key(canvas: CanvasItem, center: Vector2, factor: float, color: Color) -> void:
	canvas.draw_circle(center + Vector2(0.0, -3.0) * factor, 2.5 * factor, color)
	var shaft := Rect2(center + Vector2(-0.75, -1.0) * factor, Vector2(1.5, 7.0) * factor)
	canvas.draw_rect(shaft, color)
	canvas.draw_rect(Rect2(center + Vector2(0.75, 3.0) * factor, Vector2(2.0, 1.2) * factor), color)
	canvas.draw_rect(Rect2(center + Vector2(0.75, 5.0) * factor, Vector2(1.5, 1.0) * factor), color)


static func _points(shape: Array, center: Vector2, factor: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point: Vector2 in shape:
		points.append(center + point * factor)
	return points
