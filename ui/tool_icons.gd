class_name ToolIcons
## Ícones dos itens e da espada, em pixel art (`art/source/icon_*.txt`),
## usados no HUD e nos baús. Cada item tem um desenho de 12 pixels, e as
## chaves, de 7 por 12. A chave grande é a chave pequena em vermelho, a cor da
## porta do chefe, e a espada travada é a espada com a lâmina magenta, como a
## troca de paleta do Super Nintendo.
##
## As melhorias (chama forte e mola forte) usam o ícone da ferramenta comum com
## o selo x2 ao lado, pedido de Marcelo em 2026-11-08.

const SWORD := preload("res://art/icon_sword.svg")
const SWORD_LOCKED := preload("res://art/icon_sword_locked.svg")
const FIRE := preload("res://art/icon_fire.svg")
const SPRING := preload("res://art/icon_spring.svg")
const TEXTURES := {
	Item.Id.BOMB: preload("res://art/icon_bomb.svg"),
	Item.Id.FIRE: FIRE,
	Item.Id.STRONG_FIRE: FIRE,
	Item.Id.SPRING: SPRING,
	Item.Id.STRONG_SPRING: SPRING,
	Item.Id.HEART: preload("res://art/icon_heart.svg"),
	Item.Id.KEY: preload("res://art/icon_key.svg"),
	Item.Id.BOSS_KEY: preload("res://art/icon_boss_key.svg"),
}
const LEVEL_TWO := preload("res://art/icon_x2.svg")
const UPGRADES := [Item.Id.STRONG_FIRE, Item.Id.STRONG_SPRING]


## Desenha o ícone do item centrado em center. Só pode ser chamado dentro do
## _draw de um canvas. Numa melhoria, o selo x2 vai no canto de baixo à
## direita do ícone, ampliado badge_scale vezes. No HUD ele fica dentro do
## botão, e no baú, maior, ao lado do ícone.
static func draw(
	canvas: CanvasItem, id: int, center: Vector2, tint := Color.WHITE, badge_scale := 1
) -> void:
	var texture: Texture2D = TEXTURES.get(id)
	if texture:
		draw_centered(canvas, texture, center, tint)
	if id in UPGRADES:
		var size := LEVEL_TWO.get_size() * badge_scale
		var corner := (
			center + Vector2(2.0, 6.0) if badge_scale == 1 else center + Vector2(13.0, -2.0)
		)
		canvas.draw_texture_rect(LEVEL_TWO, Rect2(corner.floor(), size), false, tint)


## Desenha a espada centrada em center, travada ou não.
static func draw_sword(canvas: CanvasItem, center: Vector2, locked := false) -> void:
	draw_centered(canvas, SWORD_LOCKED if locked else SWORD, center)


## Desenha a textura com o centro em center, em pixels inteiros, para que a
## pixel art fique nítida.
static func draw_centered(
	canvas: CanvasItem, texture: Texture2D, center: Vector2, tint := Color.WHITE
) -> void:
	canvas.draw_texture(texture, (center - texture.get_size() / 2.0).floor(), tint)
