class_name MapLegend
## Legenda dos atores do mapa em texto: a cena de cada inimigo e de cada
## chefe, pelo caractere. É a única tabela de "letra do mapa para cena" do
## jogo. tools/check_chapter.py e o editor de dungeons leem este arquivo para
## saber que caracteres existem, então um inimigo novo é uma linha aqui.
##
## Os caracteres de objeto (PLAYER a MESSAGE) são montados pela cena do
## capítulo (world/chapter/chapter.gd). Baús e vagas de bloqueio ficam em
## ChapterMap.

const PLAYER := "@"
const LIGHT_CRATE := "c"
const HEAVY_BLOCK := "0"
const FLOOR_SWITCH := "="
const MESSAGE := "?"

## Cena de cada inimigo comum.
const ENEMIES := {
	"m": preload("res://enemies/minion.tscn"),
	"u": preload("res://enemies/ugly.tscn"),
	"i": preload("res://enemies/ice_slime.tscn"),
	"w": preload("res://enemies/walrus.tscn"),
	"s": preload("res://enemies/slinger.tscn"),
	"x": preload("res://enemies/armadillo.tscn"),
	"y": preload("res://enemies/bat.tscn"),
	"z": preload("res://enemies/thorn_plant.tscn"),
	# Rastro: deixa fogo no chão. Arte provisória.
	")": preload("res://mechanics/trail.tscn"),
}

## Cena de cada chefe.
const BOSSES := {
	"*": preload("res://enemies/boss.tscn"),
	"&": preload("res://enemies/sentinel.tscn"),
	"%": preload("res://enemies/elder_guardian.tscn"),
	"$": preload("res://enemies/colossus.tscn"),
}

## Objetos de mecanismo (mechanics/mechanism_builder.gd): o tipo de cada
## caractere e, no ventilador, a direção do vento.
const MECHANISMS := {
	"!": [&"crystal"],
	";": [&"plate"],
	"/": [&"torch"],
	# Marcador de nascimento dos inimigos de uma leva.
	"_": [&"spawn"],
	"~": [&"ice"],
	"⇒": [&"fan", "right"],
	"⇐": [&"fan", "left"],
	"⇑": [&"fan", "up"],
	"⇓": [&"fan", "down"],
}
