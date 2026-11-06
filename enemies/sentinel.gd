class_name Sentinel
extends Boss
## Chefe do capítulo 1, a dungeon grande: a sentinela de pedra. É o exame das três ferramentas
## juntas, numa ordem que o jogador lê pelo próprio desenho.
##
## A armadura de pedra tem as rachaduras claras da parede rachada, então só a
## bomba a abre. Por baixo, o núcleo está congelado, com o azul do bloco de
## gelo, e só a chama o derrete. Só então o núcleo quente apanha da espada e da
## bomba. A armadura e o gelo voltam juntos depois de shell_regrow_time,
## contados da explosão, então bomba, chama e espada precisam vir em sequência.
##
## Os ataques são os do guardião de gelo: a pancada que solta a onda, evitada
## com a mola, e a investida em linha reta. O ritmo fica nos parâmetros da
## cena.

const ARMOR_TEXTURE := preload("res://art/sentinel_shell.svg")
const FROST_TEXTURE := preload("res://art/sentinel_frost.svg")
const HOT_CORE_TEXTURE := preload("res://art/sentinel_core.svg")
## Canto do desenho em relação à origem, nos pés.
const TEXTURE_OFFSET := Vector2(-14.0, -27.0)

## Ligado enquanto o núcleo está congelado, depois que a armadura caiu.
var _frost := true


func reset() -> void:
	super()
	_frost = true


## Fechada, a armadura só cede à explosão. Aberta, o gelo do núcleo só cede ao
## fogo. Depois disso, cada golpe causa dano conforme o multiplicador.
func take_hit(amount: int, _direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if _state == State.DEAD:
		return
	var now := Engine.get_physics_frames()
	if _shell:
		if kind == Hit.Kind.BLAST:
			_shell = false
			_frost = true
			_shell_break_tick = now
			_hit_tick = now
			Sfx.play(&"armor_break")
		else:
			_immune_tick = now
			Sfx.play(&"immune")
		return
	if _frost:
		if Hit.is_fire(kind):
			_frost = false
			_hit_tick = now
			Sfx.play(&"ice_melt")
		else:
			_immune_tick = now
			Sfx.play(&"immune")
		return
	_take_damage(amount, kind)


func _update_state() -> void:
	super()
	if _shell:
		_frost = true


## O desenho mostra a camada de fora: a armadura enquanto fechada, e por
## baixo o gelo ou o núcleo quente. O resto do desenho (avisos, dano, a
## armadura piscando antes de voltar) é o do chefe comum.
func _shell_texture() -> Texture2D:
	return ARMOR_TEXTURE


func _core_texture() -> Texture2D:
	return FROST_TEXTURE if _frost else HOT_CORE_TEXTURE


func _texture_offset(_texture: Texture2D) -> Vector2:
	return TEXTURE_OFFSET
