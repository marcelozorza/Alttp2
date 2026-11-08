extends Node
## Música de fundo. A mesma trilha toca em loop em todas as telas e continua
## com o jogo pausado. Fica carregada o tempo todo, como autoload Music.
##
## A trilha provisória não é nossa, então não entra no repositório, que é
## público. Basta pôr um arquivo .ogg, .mp3 ou .wav em audio/music/local/
## para ele tocar. Com mais de um, toca o primeiro em ordem alfabética. Sem
## nenhum, o jogo fica sem música.

const LOCAL_FOLDER := "res://audio/music/local"
const EXTENSIONS := ["ogg", "mp3", "wav"]

var _player := AudioStreamPlayer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player.bus = &"Music"
	add_child(_player)
	var stream := _find_track()
	if not stream:
		return
	# Com loop no próprio arquivo, a volta não tem pausa. O sinal finished
	# cobre os formatos sem essa opção.
	if "loop" in stream:
		stream.set("loop", true)
	_player.finished.connect(_player.play)
	_player.stream = stream
	_player.play()


## Pausa a trilha com o menu de pausa e a retoma de onde parou.
func set_paused(paused: bool) -> void:
	_player.stream_paused = paused


## Solta a trilha ao fechar o jogo, para o Godot não acusar recurso preso.
func _exit_tree() -> void:
	_player.stop()
	_player.stream = null


func _find_track() -> AudioStream:
	if not DirAccess.dir_exists_absolute(LOCAL_FOLDER):
		return null
	var files := Array(ResourceLoader.list_directory(LOCAL_FOLDER))
	files.sort()
	for file: String in files:
		if file.get_extension().to_lower() in EXTENSIONS:
			return load(LOCAL_FOLDER.path_join(file)) as AudioStream
	return null
