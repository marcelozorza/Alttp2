class_name Sentinel
extends Boss
## Chefe do capítulo 1, a dungeon grande: a sentinela, um Rottweiler
## de coleira de pontas. É o exame das três ferramentas juntas, numa ordem que
## o jogador lê pelo próprio desenho.
##
## São três estágios que se leem pela cor (pedido de Marcelo em 2026-11-11).
## Ele começa como uma estátua de cimento rachada, que só cede à bomba. Por
## baixo, o corpo está preso no gelo, com o azul do gelo grosso, e só a chama
## o derrete. Só então aparece o Rottweiler de verdade, preto e fogo, que
## apanha da espada e da bomba. A pedra e o gelo voltam juntos depois de
## shell_regrow_time, contados da explosão, então bomba, chama e espada
## precisam vir em sequência.
##
## Os ataques são os do guardião de gelo: a pancada que solta a onda, evitada
## com a mola, e a investida em linha reta. O ritmo fica nos parâmetros da
## cena. O desenho é de perfil, virado para a direita, e vira para o lado em
## que o personagem está. Desde 2026-11-11 é um Rottweiler, com quadros por
## estado nas três camadas (tools/art/sentinel.py). Este arquivo foi
## regravado em 2026-11-08 para substituir uma cópia local com um caractere
## solto que travava o jogo.

## Quadros do corpo preso no gelo, entre a estátua (shell_frames) e a forma
## original (core_frames).
@export var frost_frames: BossFrames

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
	var now := Clock.tick
	if _shell:
		if Hit.is_blast(kind):
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
## gelo ou a forma original. O resto do desenho (avisos, dano, a pedra piscando
## antes de voltar) é o do chefe comum.
func _core_texture() -> Texture2D:
	return _frame_from(frost_frames if _frost else core_frames)


func _faces_left() -> bool:
	return _look.x < 0.0
