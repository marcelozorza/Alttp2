class_name ToolIcons
## Ícones dos itens e da espada, em pixel art (`art/source/icon_*.txt`),
## usados no HUD e nos baús. Cada item tem um desenho de 12 pixels, e as
## chaves, de 7 por 12. A chave grande é a chave pequena em vermelho, a cor da
## porta do chefe, e a espada travada é a espada com a lâmina magenta, como a
## troca de paleta do Super Nintendo.

const SWORD := preload("res://art/icon_sword.svg")
const SWORD_LOCKED := preload("res://art/icon_sword_locked.svg")
const TEXTURES := {
	Item.Id.BOMB: preload("res://art/icon_bomb.svg"),
	Item.Id.FIRE: preload("res://art/icon_fire.svg"),
	Item.Id.STRONG_FIRE: preload("res://art/icon_fire_strong.svg"),
	Item.Id.SPRING: preload("res://art/icon_spring.svg"),
	Item.Id.STRONG_SPRING: preload("res://art/icon_spring_strong.svg"),
	Item.Id.HEART: preload("res://art/icon_heart.svg"),
	Item.Id.KEY: preload("res://art/icon_key.svg"),
	Item.Id.BOSS_KEY: preload("res://art/icon_boss_key.svg"),
}


## Desenha o ícone do item centrado em center. Só pode ser chamado dentro do
## _draw de um canvas.
static func draw(canvas: CanvasItem, id: int, center: Vector2) -> void:
	var texture: Texture2D = TEXTURES.get(id)
	if texture:
		draw_centered(canvas, texture, center)


## Desenha a espada centrada em center, travada ou não.
static func draw_sword(canvas: CanvasItem, center: Vector2, locked := false) -> void:
	draw_centered(canvas, SWORD_LOCKED if locked else SWORD, center)


## Desenha a textura com o centro em center, em pixels inteiros, para que a
## pixel art fique nítida.
static func draw_centered(canvas: CanvasItem, texture: Texture2D, center: Vector2) -> void:
	canvas.draw_texture(texture, (center - texture.get_size() / 2.0).floor())
