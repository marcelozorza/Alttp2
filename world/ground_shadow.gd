class_name GroundShadow
## Sombra no chão sob os pés de um personagem: uma mancha oval escura e
## difusa, proporcional à largura dele. Mostra onde ele pisa e, no pulo e no
## voo, a que altura está (pedido de Marcelo em 2026-11-12, aprovado numa
## prévia). É desenhada em três ovais, uma dentro da outra, para a borda ficar
## mais clara que o meio.

const COLOR := Color(0.055, 0.043, 0.05, 0.14)
## Altura da oval em relação à largura.
const FLATNESS := 0.38
## Parte da largura do desenho que a sombra ocupa.
const WIDTH_FACTOR := 1.0
const RINGS := 3
## Altura máxima da oval. Sem o teto, a sombra de um bicho largo e baixo, como
## o tatu ou o lobo, fica alta demais e ele parece flutuar (Marcelo,
## 2026-11-12).
const MAX_HEIGHT := 9.0

## Parte pintada de cada textura já medida, para não medir a cada quadro.
static var _used := {}


## Desenha a sombra centrada em center, para um desenho com art_width pixels
## de largura. Só pode ser chamado dentro do _draw de canvas.
static func draw(canvas: CanvasItem, center: Vector2, art_width: float) -> void:
	var radius := art_width * WIDTH_FACTOR / 2.0
	var flatness := minf(FLATNESS, MAX_HEIGHT / (radius * 2.0)) if radius > 0.0 else FLATNESS
	canvas.draw_set_transform(center, 0.0, Vector2(1.0, flatness))
	for i: int in RINGS:
		canvas.draw_circle(Vector2.ZERO, radius * (1.0 - 0.2 * i), COLOR)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Retângulo da parte pintada da textura, sem as margens transparentes. Um
## desenho com margem larga, como o do lobo, teria a sombra maior que o corpo.
static func used_rect(texture: Texture2D) -> Rect2i:
	if not _used.has(texture):
		var image := texture.get_image()
		var rect := Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))
		if image:
			rect = image.get_used_rect()
		_used[texture] = rect
	return _used[texture]
