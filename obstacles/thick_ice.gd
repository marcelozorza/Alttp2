class_name ThickIce
extends IceBlock
## Gelo grosso. Azul profundo com a borda branca de geada, e nos mapas sempre
## com duas casas de fundo, para ser maior que o gelo comum à primeira vista.
## A chama comum só o faz tremer. Só a chama forte derrete, e demora mais.

const THICK_FRONT_TEXTURE := preload("res://art/thick_ice.svg")
const THICK_TOP_TEXTURE := preload("res://art/thick_ice_top.svg")
const THICK_MELT_TICKS := 30


func _opens_with(kind: Hit.Kind) -> bool:
	return kind == Hit.Kind.STRONG_FIRE


func _open_delay() -> int:
	return THICK_MELT_TICKS


func _front_texture() -> Texture2D:
	return THICK_FRONT_TEXTURE


func _top_texture() -> Texture2D:
	return THICK_TOP_TEXTURE


func _melt_ticks() -> int:
	return THICK_MELT_TICKS
