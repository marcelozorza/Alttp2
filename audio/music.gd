extends Node
## Música de fundo. As trilhas tocam em fila, em todas as telas, e continuam
## com o jogo pausado. Fica carregada o tempo todo, como autoload Music.
##
## As trilhas não entram no repositório, que é público. Basta pôr arquivos
## .ogg, .mp3 ou .wav em audio/music/local/ para eles tocarem em ordem
## alfabética: quando um acaba, entra o seguinte, e depois do último a fila
## volta ao primeiro. Com um arquivo só, ele toca em loop. Sem nenhum, o
## jogo fica sem música.

const LOCAL_FOLDER := "res://audio/music/local"
const EXTENSIONS := ["ogg", "mp3", "wav"]

var _player := AudioStreamPlayer.new()
var _tracks: Array[AudioStream] = []
var _current := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player.bus = &"Music"
	add_child(_player)
	_tracks = _find_tracks()
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


## Pausa a trilha com o menu de pausa e a retoma de onde parou.
func set_paused(paused: bool) -> void:
	_player.stream_paused = paused


## Solta as trilhas ao fechar o jogo, para o Godot não acusar recurso preso.
func _exit_tree() -> void:
	_player.stop()
	_player.stream = null
	_tracks.clear()


func _play_next() -> void:
	_current = (_current + 1) % _tracks.size()
	_player.stream = _tracks[_current]
	_player.play()


func _find_tracks() -> Array[AudioStream]:
	var found: Array[AudioStream] = []
	if not DirAccess.dir_exists_absolute(LOCAL_FOLDER):
		return found
	var files := Array(ResourceLoader.list_directory(LOCAL_FOLDER))
	files.sort()
	for file: String in files:
		if file.get_extension().to_lower() in EXTENSIONS:
			var stream := load(LOCAL_FOLDER.path_join(file)) as AudioStream
			if stream:
				found.append(stream)
	return found
