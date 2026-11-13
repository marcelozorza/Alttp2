class_name BoardedWall
extends CrackedWall
## Parede rachada com uma tábua pregada. A bomba comum só a faz tremer: a
## tábua segura a parede. Só a explosão da bomba forte abre a passagem.

const BOARDED_TEXTURES := {
	"stone": preload("res://art/boarded_wall.svg"),
	"castle": preload("res://art/boarded_wall_castle.svg"),
	"ice": preload("res://art/boarded_wall_ice.svg"),
	"moss": preload("res://art/boarded_wall_moss.svg"),
}


func _opens_with(kind: Hit.Kind) -> bool:
	return kind == Hit.Kind.STRONG_BLAST


func _texture() -> Texture2D:
	return BOARDED_TEXTURES.get(theme_name, BOARDED_TEXTURES["stone"])
