class_name DungeonTheme
extends RefCounted
## Tema visual de uma dungeon: os tiles de chão e de parede e os adornos que o
## MapView espalha pelas salas. Cada capítulo tem o seu, para que o jogador
## saiba onde está só de olhar (pedido de Marcelo em 2026-11-07, a partir de
## quatro esboços da mesma sala em estilos diferentes):
##
## - Pedra: o tutorial, a dungeon crua, com tochas e ossos pelo chão.
## - Castelo: o capítulo 1, roxo e dourado, com candelabros, estandartes e
##   um tapete vermelho no centro das salas.
## - Gelo: o capítulo 2, azul, com tochas de chama azul, estalactites, geada no
##   chão e cristais de gelo.
## - Ruínas: o capítulo 3, verde e tomado pelo mato, com trepadeiras, teias nos
##   cantos, musgo e ossos.
##
## Não há vasos: Marcelo os tirou em 2026-11-07, porque eram só enfeite, como
## os potes do A Link to the Past, sem utilidade no jogo.
##
## Os tiles dos temas são trocas de paleta dos tiles de pedra (art/source, com
## "usa"), então a forma das lajotas e dos tijolos é a mesma em todos. Os
## adornos são só desenho: não têm colisão e não mudam o mapa.
##
## O arandela (sconce) é a tocha ou o candelabro na face da parede. A tocha
## tem a chama à parte, em dois quadros, para piscar (world/flames.gd). As
## peças penduradas (hangings) descem da face da parede, e as de chão (floor
## props) ficam no chão encostado numa parede.

const TILE := ChapterMap.TILE
const TORCH := preload("res://art/torch.svg")
const FLAME_1 := preload("res://art/flame_1.svg")
const FLAME_2 := preload("res://art/flame_2.svg")
const FLAME_BLUE_1 := preload("res://art/flame_blue_1.svg")
const FLAME_BLUE_2 := preload("res://art/flame_blue_2.svg")
const CANDELABRA := preload("res://art/candelabra.svg")
const BANNER := preload("res://art/banner.svg")
const VINE := preload("res://art/vine.svg")
const BONES_PILE := preload("res://art/bones_pile.svg")
const ICE_CRYSTAL := preload("res://art/ice_crystal.svg")
const FROST := preload("res://art/frost.svg")
const ICICLES := preload("res://art/icicles.svg")
const MOSS_PATCH := preload("res://art/moss_patch.svg")
const COBWEB := preload("res://art/cobweb.svg")
const CARPET := preload("res://art/carpet.svg")
## Posição da chama a partir do canto da tocha: a base da chama sobre o aro.
const TORCH_FLAME_OFFSET := Vector2(0.0, -10.0)

var name := "stone"
var floor_tile: Texture2D
var floor_alt: Texture2D
var high_floor: Texture2D
var high_floor_alt: Texture2D
var higher_floor: Texture2D
var higher_floor_alt: Texture2D
var wall: Texture2D
var wall_face: Texture2D
## Tocha ou candelabro na face da parede. Nulo, sem arandela.
var sconce: Texture2D
## Quadros da chama da tocha, desenhados sobre a arandela. Vazio, sem chama.
var flames: Array[Texture2D] = []
## Posição da chama a partir do canto da arandela.
var flame_offset := Vector2.ZERO
## A cada quantas faces de parede, mais ou menos, há uma arandela.
var sconce_spacing := 5
## Peças penduradas na face da parede, com a base na base da face.
var hangings: Array[Texture2D] = []
## Chance, em cem, de uma face de parede ter uma peça pendurada.
var hanging_chance := 12
## Peças no chão junto de uma parede.
var floor_props: Array[Texture2D] = []
## Chance, em cem, de uma casa de chão junto de uma parede ter uma peça.
var floor_prop_chance := 5
## Mancha desenhada sobre o chão, como musgo ou geada. Nula, sem mancha.
var overlay: Texture2D
## Chance, em cem, de uma casa de chão ter a mancha.
var overlay_chance := 9
## Estalactites no alto da face da parede. Nula, sem estalactites.
var icicles: Texture2D
var icicle_chance := 30
## Teia no canto de cima à esquerda, espelhada à direita. Nula, sem teia.
var cobweb: Texture2D
var cobweb_chance := 45
## Tapete no centro das salas de chão liso. Nulo, sem tapete.
var carpet: Texture2D
var carpet_border := Color(0.84, 0.66, 0.25, 1.0)
var carpet_edge := Color(0.25, 0.07, 0.1, 1.0)


## Tema do capítulo pelo número. O tutorial é a pedra.
static func for_chapter(chapter: int) -> DungeonTheme:
	match chapter:
		1:
			return castle()
		2:
			return ice()
		3:
			return moss()
		_:
			return stone()


static func stone() -> DungeonTheme:
	var theme := DungeonTheme.new()
	theme.load_tiles("")
	theme.sconce = TORCH
	theme.flames.assign([FLAME_1, FLAME_2])
	theme.flame_offset = TORCH_FLAME_OFFSET
	theme.floor_props.assign([BONES_PILE])
	return theme


static func castle() -> DungeonTheme:
	var theme := DungeonTheme.new()
	theme.name = "castle"
	theme.load_tiles("_castle")
	theme.sconce = CANDELABRA
	theme.sconce_spacing = 6
	theme.hangings.assign([BANNER])
	theme.hanging_chance = 18
	theme.carpet = CARPET
	return theme


static func ice() -> DungeonTheme:
	var theme := DungeonTheme.new()
	theme.name = "ice"
	theme.load_tiles("_ice")
	theme.sconce = TORCH
	theme.flames.assign([FLAME_BLUE_1, FLAME_BLUE_2])
	theme.flame_offset = TORCH_FLAME_OFFSET
	theme.floor_props.assign([ICE_CRYSTAL])
	theme.overlay = FROST
	theme.icicles = ICICLES
	return theme


static func moss() -> DungeonTheme:
	var theme := DungeonTheme.new()
	theme.name = "moss"
	theme.load_tiles("_moss")
	theme.sconce = TORCH
	theme.flames.assign([FLAME_1, FLAME_2])
	theme.flame_offset = TORCH_FLAME_OFFSET
	theme.sconce_spacing = 7
	theme.hangings.assign([VINE])
	theme.hanging_chance = 22
	theme.floor_props.assign([BONES_PILE])
	theme.overlay = MOSS_PATCH
	theme.overlay_chance = 12
	theme.cobweb = COBWEB
	return theme


## Carrega os oito tiles com o sufixo do tema ("" para a pedra).
func load_tiles(suffix: String) -> void:
	floor_tile = load("res://art/floor%s.svg" % suffix)
	floor_alt = load("res://art/floor_alt%s.svg" % suffix)
	high_floor = load("res://art/high_floor%s.svg" % suffix)
	high_floor_alt = load("res://art/high_floor_alt%s.svg" % suffix)
	higher_floor = load("res://art/higher_floor%s.svg" % suffix)
	higher_floor_alt = load("res://art/higher_floor_alt%s.svg" % suffix)
	wall = load("res://art/wall%s.svg" % suffix)
	wall_face = load("res://art/wall_face%s.svg" % suffix)


## Tile de chão pelo nível e pela alternância do tabuleiro.
func floor_texture(level: int, alternate: bool) -> Texture2D:
	match level:
		2:
			return higher_floor_alt if alternate else higher_floor
		1:
			return high_floor_alt if alternate else high_floor
		_:
			return floor_alt if alternate else floor_tile


## Canto de uma peça centrada numa casa, para a arandela.
static func centered(texture: Texture2D, origin: Vector2) -> Vector2:
	var size := texture.get_size()
	return origin + Vector2(floorf((TILE - size.x) / 2.0), floorf((TILE - size.y) / 2.0))


## Canto de uma peça pendurada, com a base na base da casa e centrada.
static func hanging_origin(texture: Texture2D, origin: Vector2) -> Vector2:
	var size := texture.get_size()
	return origin + Vector2(floorf((TILE - size.x) / 2.0), TILE - size.y)


## Canto de uma peça de chão, centrada na casa e com a base um pouco acima da
## base da casa.
static func floor_prop_origin(texture: Texture2D, origin: Vector2) -> Vector2:
	var size := texture.get_size()
	return origin + Vector2(floorf((TILE - size.x) / 2.0), TILE - size.y - 4.0)
