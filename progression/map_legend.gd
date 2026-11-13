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
	# Inimigos genéricos do laboratório, de arte provisória.
	"(": preload("res://lab/blower.tscn"),
	")": preload("res://lab/trail.tscn"),
	"]": preload("res://lab/shield_enemy.tscn"),
}

## Cena de cada chefe.
const BOSSES := {
	"*": preload("res://enemies/boss.tscn"),
	"&": preload("res://enemies/sentinel.tscn"),
	"%": preload("res://enemies/elder_guardian.tscn"),
	"$": preload("res://enemies/colossus.tscn"),
}

## Objetos do laboratório (lab/lab_builder.gd): o tipo de cada caractere e,
## quando há, o parâmetro dele. Na placa, os segundos ligada (zero, de vez).
## Na tocha, a vez na sequência, zero sem sequência e -1 com tempo.
const LAB := {
	"!": [&"crystal"],
	"+": [&"target"],
	";": [&"plate", 4.0],
	"{": [&"plate", 0.0],
	"|": [&"torch", 0],
	"/": [&"torch", -1],
	"①": [&"torch", 1],
	"②": [&"torch", 2],
	"③": [&"torch", 3],
	"④": [&"torch", 4],
	"[": [&"free_block"],
	"}": [&"turret"],
	"-": [&"chaser"],
	"_": [&"spawn"],
	"♜": [&"statue"],
	"~": [&"ice"],
	"▒": [&"crumble"],
	"→": [&"conveyor", "right"],
	"←": [&"conveyor", "left"],
	"↑": [&"conveyor", "up"],
	"↓": [&"conveyor", "down"],
	"⇒": [&"fan", "right"],
	"⇐": [&"fan", "left"],
	"⇑": [&"fan", "up"],
	"⇓": [&"fan", "down"],
	"α": [&"teleporter", 0],
	"β": [&"teleporter", 1],
	"γ": [&"teleporter", 2],
	"δ": [&"teleporter", 3],
	# Chegada de mão única do portal 3: pisar nela não leva a lugar nenhum.
	"ω": [&"teleporter_exit", 3],
	"▶": [&"emitter", "right"],
	"◀": [&"emitter", "left"],
	"▲": [&"emitter", "up"],
	"▼": [&"emitter", "down"],
	"╱": [&"mirror", true],
	"╲": [&"mirror", false],
	"◉": [&"receptor"],
}
