class_name Sentinel
extends Boss
## Chefe do capítulo 2, a sentinela de pedra. É o exame das três ferramentas
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
func take_hit(amount: int, direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if _state == State.DEAD:
		return
	var now := Engine.get_physics_frames()
	if _shell:
		if kind == Hit.Kind.BLAST:
			_shell = false
			_frost = true
			_shell_break_tick = now
			_hit_tick = now
		else:
			_immune_tick = now
		return
	if _frost:
		if kind == Hit.Kind.FIRE:
			_frost = false
			_hit_tick = now
		else:
			_immune_tick = now
		return
	super(amount, direction, kind)


func _update_state() -> void:
	super()
	if _shell:
		_frost = true


## O desenho mostra a camada de fora: armadura, gelo ou núcleo quente. Amarelo
## piscando no aviso de cada ataque, mais escuro parado depois de atacar, branco
## ao levar dano e cinza quando o golpe não o afeta. Antes de a armadura voltar,
## ela pisca por cima do núcleo.
func _draw() -> void:
	var now := Engine.get_physics_frames()
	var elapsed := now - _state_tick
	var tint := Color.WHITE
	var shake := Vector2.ZERO
	match _state:
		State.SLAM_WINDUP, State.CHARGE_WINDUP:
			var blink := posmod(elapsed, 8) < 4
			shake = Vector2(1.0 if blink else -1.0, 0.0)
			if blink:
				tint = WINDUP_COLOR
		State.SLAM_RECOVER, State.CHARGE_RECOVER:
			tint = RECOVER_TINT
	if now - _hit_tick < FLASH_TICKS:
		tint = HIT_TINT
	elif now - _immune_tick < FLASH_TICKS:
		tint = IMMUNE_COLOR
	var texture := ARMOR_TEXTURE
	if not _shell:
		texture = FROST_TEXTURE if _frost else HOT_CORE_TEXTURE
		var regrow_in := GameMath.ticks(shell_regrow_time) - (now - _shell_break_tick)
		if regrow_in <= GameMath.ticks(REGROW_WARNING_TIME) and posmod(regrow_in, 8) < 4:
			texture = ARMOR_TEXTURE
	draw_texture(texture, TEXTURE_OFFSET + shake, tint)
	var width := float(texture.get_width())
	var bar_width := width * float(maxi(health, 0)) / max_health
	var bar_position := TEXTURE_OFFSET + shake + Vector2(0.0, -4.0)
	draw_rect(Rect2(bar_position, Vector2(bar_width, 2.0)), HEALTH_COLOR)
