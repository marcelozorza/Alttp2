extends Node
## Música de fundo. As trilhas tocam em fila, em todas as telas, e continuam
## com o jogo pausado. Fica carregada o tempo todo, como autoload Music.
##
## As trilhas são os arquivos .ogg, .mp3 ou .wav de audio/music/tracks/, em
## ordem alfabética: quando um acaba, entra o seguinte, e depois do último a
## fila volta ao primeiro. Com um arquivo só, ele toca em loop. Sem nenhum, o
## jogo fica sem música. As duas trilhas de 2026-11-11 foram escolhidas por
## Marcelo, que informou serem livres de direitos autorais.
##
## O mundo e as dungeons têm trilha própria (pedido de Marcelo em 2026-11-12):
## o arquivo de audio/music/places/ cujo nome começa com "overworld" toca em
## loop no mundo, e o que começa com "dungeon", em todas as dungeons. A troca
## acontece quando a cena muda. Nas outras telas, a fila volta de onde parou.

const TRACKS_FOLDER := "res://audio/music/tracks"
const PLACES_FOLDER := "res://audio/music/places"
const EXTENSIONS := ["ogg", "mp3", "wav"]
## Trecho do caminho da cena de cada lugar com trilha própria, e o começo do
## nome do arquivo da trilha dele.
const PLACE_SCENES := {"overworld.tscn": "overworld", "chapter.tscn": "dungeon"}
const NO_PLACE := ""

var _player := AudioStreamPlayer.new()
var _tracks: Array[AudioStream] = []
var _current := 0
## Trilha de cada lugar, pelo nome do lugar.
var _place_tracks := {}
## Lugar cuja trilha está tocando, ou NO_PLACE na fila.
var _place := NO_PLACE
## Ponto em que a fila parou ao entrar num lugar, em segundos.
var _queue_position := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player.bus = &"Music"
	add_child(_player)
	_tracks = _find_tracks(TRACKS_FOLDER)
	for stream: AudioStream in _find_tracks(PLACES_FOLDER):
		for place: String in PLACE_SCENES.values():
			if stream.resource_path.get_file().begins_with(place):
				if "loop" in stream:
					stream.set("loop", true)
				_place_tracks[place] = stream
	if _tracks.is_empty():
		return
	# Cada trilha toca uma vez, sem loop no próprio arquivo, e o sinal
	# finished chama a seguinte.
	for stream: AudioStream in _tracks:
		if "loop" in stream:
			stream.set("loop", false)
	_player.finished.connect(_play_next)
	_player.stream = _tracks[0]
	_player.play()


## Troca a trilha quando a cena muda de lugar.
func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	# Entre uma cena e outra não há cena: a trilha fica como está, para a
	# dungeon recarregada depois da derrota não recomeçar a música.
	if scene == null:
		return
	var path := scene.scene_file_path
	var place := NO_PLACE
	for part: String in PLACE_SCENES:
		if path.ends_with(part) and _place_tracks.has(PLACE_SCENES[part]):
			place = PLACE_SCENES[part]
	if place == _place:
		return
	if _place == NO_PLACE:
		_queue_position = _player.get_playback_position()
	_place = place
	if place == NO_PLACE:
		_player.stream = _tracks[_current] if not _tracks.is_empty() else null
		if _player.stream:
			_player.play(_queue_position)
	else:
		_player.stream = _place_tracks[place]
		_player.play()


## Pausa a trilha com o menu de pausa e a retoma de onde parou.
func set_paused(paused: bool) -> void:
	_player.stream_paused = paused


## Solta as trilhas ao fechar o jogo, para o Godot não acusar recurso preso.
func _exit_tree() -> void:
	_player.stop()
	_player.stream = null
	_tracks.clear()
	_place_tracks.clear()


func _play_next() -> void:
	if _place != NO_PLACE:
		return
	_current = (_current + 1) % _tracks.size()
	_player.stream = _tracks[_current]
	_player.play()


func _find_tracks(folder: String) -> Array[AudioStream]:
	var found: Array[AudioStream] = []
	if not DirAccess.dir_exists_absolute(folder):
		return found
	var files := Array(ResourceLoader.list_directory(folder))
	files.sort()
	for file: String in files:
		if file.get_extension().to_lower() in EXTENSIONS:
			var stream := load(folder.path_join(file)) as AudioStream
			if stream:
				found.append(stream)
	return found
