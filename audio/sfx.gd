extends Node
## Efeitos sonoros, carregados o tempo todo como autoload Sfx. Qualquer script
## toca um som com Sfx.play(&"nome").
##
## São 8 vozes, como as 8 do chip de som do Super Nintendo. Com todas
## ocupadas, o som novo corta o mais antigo. O mesmo som pedido duas vezes no
## mesmo tick toca uma vez só, para que dez baús ou dez batidas juntas não
## estourem o volume.
##
## Os arquivos ficam em audio/sfx/ e saem das receitas de tools/sfx.py. O
## som não muda nada no jogo, então o sorteio de tom usa um gerador próprio,
## que nenhuma lógica de jogo lê.

const VOICES := 8
const FOLDER := "res://audio/sfx/"
## Volume em dB e variação de tom, para mais e para menos, de cada som.
const SOUNDS := {
	# Giorgio
	&"step": [-18.0, 0.12],
	&"dash": [-10.0, 0.05],
	&"bump": [-10.0, 0.08],
	&"hurt": [-4.0, 0.05],
	&"down": [-4.0, 0.0],
	&"jump": [-6.0, 0.03],
	&"jump_strong": [-5.0, 0.03],
	&"land": [-12.0, 0.08],
	&"ledge_drop": [-12.0, 0.05],
	# Espada
	&"sword_swing": [-14.0, 0.06],
	&"sword_hit": [-12.0, 0.05],
	&"sword_denied": [-10.0, 0.0],
	&"sword_lock": [-6.0, 0.0],
	&"immune": [-8.0, 0.04],
	&"deny": [-8.0, 0.05],
	# Ferramentas
	&"fire_shoot": [-8.0, 0.05],
	&"fire_hit": [-10.0, 0.06],
	&"bomb_place": [-8.0, 0.04],
	&"explosion": [-2.0, 0.05],
	# Baús, chaves e portas
	&"chest_open": [-6.0, 0.03],
	&"item_tool": [-4.0, 0.0],
	&"item_heart": [-4.0, 0.0],
	&"item_key": [-6.0, 0.0],
	&"door_locked": [-8.0, 0.04],
	&"door_unlock": [-4.0, 0.0],
	# Bloqueios
	&"wall_break": [-4.0, 0.04],
	&"ice_melt": [-6.0, 0.04],
	# Inimigos
	&"enemy_hit": [-6.0, 0.06],
	&"enemy_die": [-6.0, 0.06],
	&"enemy_windup": [-10.0, 0.05],
	&"enemy_lunge": [-10.0, 0.06],
	&"grenade_throw": [-10.0, 0.05],
	&"grenade_burst": [-6.0, 0.04],
	# Chefes
	&"boss_wake": [-4.0, 0.0],
	&"boss_windup": [-8.0, 0.0],
	&"boss_slam": [-2.0, 0.03],
	&"boss_charge": [-6.0, 0.03],
	&"boss_hit": [-4.0, 0.04],
	&"shell_break": [-4.0, 0.03],
	&"armor_break": [-4.0, 0.03],
	&"shell_regrow": [-8.0, 0.0],
	&"boss_die": [-2.0, 0.0],
	&"relic": [-4.0, 0.0],
	&"save": [-5.0, 0.0],
	&"switch_press": [-8.0, 0.0],
	&"switch_release": [-10.0, 0.0],
	# Menus
	&"menu_move": [-12.0, 0.0],
	&"menu_confirm": [-8.0, 0.0],
}

var _streams := {}
var _voices: Array[AudioStreamPlayer] = []
var _started: Array[int] = []
var _last_tick := {}
var _pitch := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound: StringName in SOUNDS:
		_streams[sound] = load("%s%s.wav" % [FOLDER, sound])
	for _i: int in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = &"Sfx"
		add_child(voice)
		_voices.append(voice)
		_started.append(-1)


func play(sound: StringName) -> void:
	if not _streams.has(sound):
		push_error("Som desconhecido: %s" % sound)
		return
	var now := Engine.get_physics_frames()
	if _last_tick.get(sound, -1) == now:
		return
	_last_tick[sound] = now
	var index := _free_voice()
	var settings: Array = SOUNDS[sound]
	var spread: float = settings[1]
	var voice := _voices[index]
	voice.stream = _streams[sound]
	voice.volume_db = settings[0]
	voice.pitch_scale = 1.0 + _pitch.randf_range(-spread, spread)
	voice.play()
	_started[index] = now


## Primeira voz livre ou, com todas ocupadas, a que começou primeiro.
func _free_voice() -> int:
	var oldest := 0
	for index: int in VOICES:
		if not _voices[index].playing:
			return index
		if _started[index] < _started[oldest]:
			oldest = index
	return oldest
