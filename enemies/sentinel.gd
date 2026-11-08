class_name Sentinel
extends Boss
## Chefe do capítulo 1, a dungeon grande: a sentinela, um buldogue de pedra
## com coleira de pontas (desenho a partir da referência que Marcelo mandou
## fazer em 2026-11-07). É o exame das três ferramentas juntas, numa ordem que
## o jogador lê pelo próprio desenho.
##
## A pele de pedra cinza só cede à bomba. Por baixo, o corpo está congelado,
## com o azul do gelo grosso, e só a chama o derrete. Só então o núcleo quente
## apanha do latido e da bomba. A pedra e o gelo voltam juntos depois de
## shell_regrow_time, contados da explosão, então bomba, chama e latido
## precisam vir em sequência.
##
## Os ataques são os do guardião de gelo: a pancada que solta a onda, evitada
## com a mola, e a investida em linha reta. O ritmo fica nos parâmetros da
## cena. O desenho é de perfil, virado para a direita, e vira para o lado em
## que o personagem está.

const ARMOR_TEXTURE := preload("res://art/sentinel_shell.svg")
const FROST_TEXTURE := preload("res://art/sentinel_frost.svg")
const HOT_CORE_TEXTURE := preload("res://art/sentinel_core.svg")

## Ligado enquanto o núcleo está congelado, depois que a armadura caiu.
var _frost := true


func reset() -> void:
	super()
	_frost = true


## Fechada, a armadura só cede à explosão. Aberta, o gelo do núcleo só cede ao
## fogo. Depois disso, cada golpe causa dano conforme o multiplicador.
func take_hit(amount: int, _direction: Vector2, kind := Hit.Kind.BARK) -> void:
	if _state == State.DEAD:
		return
	var now := Clock.tick
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


## O desenho mostra a camada de fora: a pedra enquanto fechada, e por baixo o
## gelo ou o núcleo quente. O resto do desenho (avisos, dano, a pedra piscando
## antes de voltar) é o do chefe comum.
func _shell_texture() -> Texture2D:
	return ARMOR_TEXTURE


func _core_texture() -> Texture2D:
	return FROST_TEXTURE if _frost else HOT_CORE_TEXTURE


func _faces_left() -> bool:
	return _look.x < 0.0
