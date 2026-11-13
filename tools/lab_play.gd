extends "res://tools/lab_test.gd"
## Teste que joga o laboratório, rodado pelo Godot sem tela depois do teste
## das mecânicas (tools/run_smoke_test.sh):
##
##     godot --headless --fixed-fps 60 --path . res://tools/lab_play.tscn
##
## O teste das mecânicas (lab_test.gd) confere se cada objeto funciona. Este
## confere se a sala dá para vencer: um piloto entra pela porta e atravessa a
## sala só pelos botões, andando, correndo e pulando, como o jogador faria.
## Serve para as salas que dependem de tempo ou de distância: a corrida da
## placa, o clone, o buraco largo, a fuga do fogo, o corredor sob ataque, o
## piso quebradiço, as tochas com tempo, os buracos com vento, o nível de
## água, o inimigo como peso, a fonte de blocos, o lago congelado e o disparo
## rebatido. Onde a sala pede uma ferramenta ou
## a corrida, ele também confere que sem ela não passa.
##
## As linhas que começam com dois espaços são medidas (folga de tempo, vida
## perdida), para regular a dificuldade. Não muda nada no projeto.

const MOVES: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down"]
## Distância do alvo, em cada eixo, abaixo da qual o piloto solta o botão.
const SLACK := 2.0
## Distância do alvo que conta como chegada. Maior que a diagonal de SLACK,
## para o piloto nunca soltar todos os botões antes de chegar: soltar e
## apertar de novo seria o toque duplo da corrida.
const ARRIVE := 6.0
## Quadros de espera por ponto do caminho antes de desistir.
const STEP_LIMIT := 420
## Quadros parado que zeram a janela do toque duplo.
const REST := 24

## Vida no começo do caminho: perder vida interrompe o piloto.
var _health_mark := 0
## Parede de fogo vigiada durante o caminho, e a menor distância dela até o
## personagem depois que ela começa a andar, em pixels.
var _chaser: Chaser
var _closest := INF


func _init() -> void:
	_title = "PILOTO"


func _run_checks() -> void:
	await _play_plate()
	await _play_clone()
	await _play_wide_pit()
	await _play_chase()
	await _play_corridor()
	await _play_crumble()
	await _play_torches()
	await _play_wind()
	await _play_water()
	await _play_weight()
	await _play_maker()
	await _play_lake()
	await _play_volley()


## Ponto do mundo de uma casa do miolo da sala, contada a partir do canto da
## sala. Aceita fração: (9.75, 3) fica a um quarto de casa da borda direita.
func _spot(screen: Vector2i, cell: Vector2) -> Vector2:
	var corner := Vector2(screen * ChapterRooms.ROOM_TILES) + Vector2.ONE
	return (corner + cell + Vector2(0.5, 0.5)) * TILE


func _press(action: StringName, down: bool) -> void:
	if down:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _release_all() -> void:
	for action: StringName in MOVES:
		Input.action_release(action)


## Aperta os botões de direção que levam ao alvo.
func _steer(target: Vector2) -> void:
	var offset := target - _player.global_position
	_press(&"move_left", offset.x < -SLACK)
	_press(&"move_right", offset.x > SLACK)
	_press(&"move_up", offset.y < -SLACK)
	_press(&"move_down", offset.y > SLACK)


## Anda até o alvo sem soltar os botões na chegada. Devolve falso se o tempo
## acabar (caminho fechado) ou se o personagem perder vida.
func _walk_to(target: Vector2) -> bool:
	for _i: int in STEP_LIMIT:
		if _player.health < _health_mark:
			return false
		if _player.global_position.distance_to(target) < ARRIVE:
			return true
		var waited: int = Clock.tick - _chaser.get("_start_tick") if _chaser else 0
		if waited > GameMath.ticks(Chaser.START_DELAY):
			var front: float = _chaser.get("_front")
			_closest = minf(_closest, absf(front - _player.global_position.x))
		_steer(target)
		await get_tree().physics_frame
	return false


## Começa a correr na direção do alvo: solta e aperta de novo. Antes anda
## alguns quadros, para a direção já ser a do alvo nos dois toques.
func _start_run(target: Vector2) -> void:
	for _i: int in 6:
		_steer(target)
		await _frames(1)
	_release_all()
	await _frames(3)
	_steer(target)
	await _frames(1)


## Entra na sala por uma casa, parado, com a vida cheia.
func _enter(screen: Vector2i, column: int, row: int) -> void:
	_release_all()
	await _go(screen, column, row, REST)


## Segue um caminho. Cada passo é uma casa (Vector2), &"jump" (pula sem
## soltar a direção) ou &"run" (passa a correr rumo à casa seguinte).
func _follow(screen: Vector2i, path: Array) -> bool:
	_health_mark = _player.health
	var arrived := true
	for index: int in path.size():
		var step: Variant = path[index]
		if step is Vector2:
			arrived = await _walk_to(_spot(screen, step))
		elif step == &"jump":
			await _hold("jump", 3)
		elif step == &"run":
			await _start_run(_spot(screen, path[index + 1]))
		if not arrived:
			break
	_release_all()
	return arrived


## Vira o personagem para um lado com um toque curto.
func _face(action: StringName) -> void:
	_release_all()
	await _frames(REST)
	await _hold(action, 2)


func _play_plate() -> void:
	var screen := Vector2i(5, 2)
	var limit := GameMath.ticks(4.0)
	await _enter(screen, 9, 7)
	await _follow(screen, [Vector2(6, 6)])
	var start := Clock.tick
	var walked := await _follow(
		screen, [Vector2(0, 6), Vector2(0, 3), Vector2(15, 3), Vector2(15, 1)]
	)
	print("  placa, andando: %d ticks de %d" % [Clock.tick - start, limit])
	_expect("corrida da placa: andando não dá tempo", not walked)
	await _frames(limit)
	await _enter(screen, 9, 7)
	await _follow(screen, [Vector2(6, 6)])
	start = Clock.tick
	var ran := await _follow(
		screen, [Vector2(0, 6), Vector2(0, 3), &"run", Vector2(15, 3), Vector2(15, 1)]
	)
	print("  placa, correndo: %d ticks de %d" % [Clock.tick - start, limit])
	_expect("corrida da placa: correndo passa pela grade", ran)


func _play_clone() -> void:
	var screen := Vector2i(6, 0)
	await _enter(screen, 0, 4)
	await _follow(screen, [Vector2(4, 4), Vector2(2, 6)])
	var pad: EchoPad = _in_screen(screen, EchoPad)[0]
	var guard := 0
	while not pad.is_replaying() and guard < EchoPad.RECORD_TICKS + 30:
		await _frames(1)
		guard += 1
	var start := Clock.tick
	# Dá a volta na marca: pisar nela de novo apagaria o clone.
	var passed := await _follow(screen, [Vector2(6, 6), Vector2(15, 3), Vector2(15, 1)])
	print("  clone: %d ticks de %d" % [Clock.tick - start, EchoPad.RECORD_TICKS])
	_expect("clone: segura a placa enquanto o personagem passa", passed)


func _play_wide_pit() -> void:
	var screen := Vector2i(5, 1)
	var running := [&"run", Vector2(8.25, 3), &"jump", Vector2(1, 3)]
	_player.give_item(Item.Id.SPRING)
	await _enter(screen, 16, 3)
	var common := await _follow(screen, running)
	_expect("buraco largo: mola comum com corrida não passa", not common)
	_player.give_item(Item.Id.STRONG_SPRING)
	await _enter(screen, 12, 3)
	var walking := await _follow(screen, [Vector2(8.25, 3), &"jump", Vector2(1, 3)])
	_expect("buraco largo: mola forte andando não passa", not walking)
	await _enter(screen, 16, 3)
	var strong := await _follow(screen, running)
	_expect("buraco largo: mola forte com corrida passa", strong)


func _play_chase() -> void:
	var screen := Vector2i(0, 1)
	var path := [
		Vector2(54, 4),
		Vector2(50.25, 4),
		&"jump",
		Vector2(47, 4),
		Vector2(46, 2),
		Vector2(43, 2),
		Vector2(33, 3),
		Vector2(31, 3),
		Vector2(29, 1),
		Vector2(26.25, 1),
		&"jump",
		Vector2(23, 1),
		Vector2(14, 3),
		Vector2(12, 3),
		Vector2(9, 0),
	]
	await _enter(screen, 57, 4)
	_chaser = _in_screen(Vector2i(2, 1), Chaser)[0]
	var escaped := await _follow(screen, path)
	_chaser = null
	print("  fuga, andando: o fogo chega a %.1f casas do personagem" % (_closest / TILE))
	_expect("fuga do fogo: andando sem parar, escapa ileso", escaped)


func _play_corridor() -> void:
	var screen := Vector2i(5, 5)
	await _enter(screen, 9, 0)
	var health := _player.max_health
	var path := [
		Vector2(9, 3),
		Vector2(9.25, 3),
		&"jump",
		Vector2(13, 3),
		Vector2(17, 3),
		Vector2(23, 3),
		Vector2(28, 3),
		Vector2(28, 0),
	]
	# O piloto não desiste ao levar um tiro: a sala é de atravessar sob ataque.
	var crossed := true
	for step: Variant in path:
		if step is Vector2:
			_health_mark = 0
			crossed = crossed and await _walk_to(_spot(screen, step))
		else:
			await _hold("jump", 3)
	_release_all()
	print("  corredor: perdeu %d de %d de vida" % [health - _player.health, health])
	_expect("corredor sob ataque: atravessa vivo", crossed and _player.health > 0)


func _play_crumble() -> void:
	var screen := Vector2i(6, 4)
	await _enter(screen, 9, 0)
	var path := [
		Vector2(14, 1),
		Vector2(14, 4),
		Vector2(2, 4),
		Vector2(2, 7),
	]
	var crossed := await _follow(screen, path)
	_expect("piso quebradiço: o caminho sem repetir casa passa", crossed)


func _play_torches() -> void:
	var screen := Vector2i(5, 3)
	_player.give_item(Item.Id.FIRE)
	await _enter(screen, 0, 4)
	await _follow(screen, [Vector2(4, 1)])
	await _face(&"move_left")
	await _hold("use_fire", 2)
	# A chama alcança sete casas e meia: chega mais perto da segunda tocha.
	await _follow(screen, [Vector2(8, 1)])
	await _face(&"move_right")
	await _hold("use_fire", 2)
	await _follow(screen, [Vector2(4, 6)])
	await _face(&"move_left")
	await _hold("use_fire", 2)
	await _frames(60)
	_expect(
		"tochas com tempo: três chamas a tempo abrem a porta",
		_all_open(screen, ChapterMap.Block.TORCH_DOOR)
	)


func _play_wind() -> void:
	var screen := Vector2i(5, 4)
	await _enter(screen, 0, 4)
	var crossed := await _follow(screen, [Vector2(5.25, 4), &"jump", Vector2(9, 4), Vector2(9, 7)])
	_expect("buracos e vento: pula o buraco e chega à porta do sul", crossed)


func _play_water() -> void:
	var screen := Vector2i(5, 0)
	var bridge := [Vector2(12, 7), Vector2(12, 1)]
	await _enter(screen, 9, 7)
	var full := await _follow(screen, bridge)
	_expect("nível de água: cheia, a balsa é ponte", full)
	await _follow(screen, [Vector2(12, 7), Vector2(11, 7)])
	await _face(&"move_up")
	await _hold("attack", 2)
	await _frames(30)
	var drained := await _follow(screen, bridge)
	_expect("nível de água: vazia, a margem não deixa passar pela balsa", not drained)
	var bed := await _follow(screen, [Vector2(4, 7), Vector2(4, 5), Vector2(1, 4), Vector2(0, 4)])
	_expect("nível de água: vazia, a rampa leva pelo leito à porta do oeste", bed)


func _play_weight() -> void:
	var screen := Vector2i(4, 0)
	await _enter(screen, 17, 4)
	await _follow(screen, [Vector2(12, 4)])
	# Espera, parado, o inimigo vir por cima da placa.
	var guard := 0
	while not _all_open(screen, ChapterMap.Block.TIMED_GATE) and guard < 400:
		await _frames(1)
		guard += 1
	_health_mark = 0
	var passed := await _walk_to(_spot(screen, Vector2(15, 3)))
	passed = passed and await _walk_to(_spot(screen, Vector2(15, 1)))
	_release_all()
	print("  peso: esperou %d ticks, saiu com %d de vida" % [guard, _player.health])
	_expect("inimigo como peso: atrai, passa pela grade e sai vivo", passed and _player.health > 0)


## Anda contra o bloco até ele afundar num buraco.
func _push_until_locked(block: FreeBlock, action: StringName) -> bool:
	Input.action_press(action)
	for _i: int in 900:
		if block.locked:
			break
		await _frames(1)
	Input.action_release(action)
	return block.locked


## Bloco inteiro da sala, o que a fonte acabou de criar.
func _loose_block(screen: Vector2i) -> FreeBlock:
	for block: FreeBlock in _in_screen(screen, FreeBlock):
		if not block.locked:
			return block
	return null


func _play_maker() -> void:
	var screen := Vector2i(3, 6)
	await _enter(screen, 9, 0)
	await _follow(screen, [Vector2(9, 2)])
	await _face(&"move_left")
	await _hold("attack", 2)
	await _frames(REST)
	var first := _loose_block(screen)
	_expect("fonte de blocos: o golpe cria um bloco ao sul dela", first != null)
	if not first:
		return
	# Um pouco abaixo do meio da casa, para ficar de frente para a face do bloco.
	await _follow(screen, [Vector2(9, 3.15)])
	var west := await _push_until_locked(first, &"move_left")
	west = west and await _follow(screen, [Vector2(0, 3)])
	_expect("fonte de blocos: o primeiro bloco tampa o buraco do oeste", west)
	await _follow(screen, [Vector2(9, 3), Vector2(9, 2)])
	await _face(&"move_left")
	await _hold("attack", 2)
	await _frames(REST)
	var second := _loose_block(screen)
	_expect("fonte de blocos: com o primeiro afundado, cria outro", second != null)
	if not second:
		return
	await _follow(screen, [Vector2(9, 4), Vector2(7, 4), Vector2(7, 3.15)])
	var east := await _push_until_locked(second, &"move_right")
	east = east and await _follow(screen, [Vector2(17, 3)])
	_expect("fonte de blocos: o segundo tampa o buraco do leste", east)


## Aperta uma direção no gelo e espera a deslizada parar.
func _slide(action: StringName) -> void:
	Input.action_press(action)
	var still := 0
	var last := _player.global_position
	for _i: int in 300:
		await _frames(1)
		still = still + 1 if _player.global_position.distance_to(last) < 0.5 else 0
		last = _player.global_position
		if still >= 6:
			break
	Input.action_release(action)


func _cell_in(screen: Vector2i) -> Vector2i:
	return Pit.cell_of(_player.global_position) - screen * ChapterRooms.ROOM_TILES - Vector2i.ONE


func _play_lake() -> void:
	var screen := Vector2i(2, 6)
	await _enter(screen, 17, 3)
	var health := _player.health
	await _follow(screen, [Vector2(13, 6)])
	await _hold("move_left", 30)
	_expect("lago líquido: não dá para andar nele", _cell_in(screen).x == 13)
	await _follow(screen, [Vector2(14, 3)])
	await _face(&"move_up")
	await _hold("attack", 2)
	var start := Clock.tick
	await _follow(screen, [Vector2(13, 1)])
	await _slide(&"move_left")
	var first := _cell_in(screen) == Vector2i(4, 1)
	await _slide(&"move_down")
	var second := _cell_in(screen) == Vector2i(4, 5)
	var crossed := await _follow(screen, [Vector2(1, 5)])
	var limit := GameMath.ticks(FrostField.FREEZE_TIME)
	print("  lago: atravessou em %d ticks de %d" % [Clock.tick - start, limit])
	_expect(
		"lago congelado: três deslizadas levam à outra margem a tempo",
		first and second and crossed and _player.health == health
	)
	await _frames(limit)
	# A volta: o cristal da outra margem, três deslizadas.
	await _follow(screen, [Vector2(0, 6)])
	await _face(&"move_down")
	await _hold("attack", 2)
	await _follow(screen, [Vector2(3, 5)])
	await _slide(&"move_right")
	await _slide(&"move_up")
	await _slide(&"move_right")
	var back := await _follow(screen, [Vector2(15, 0)])
	_expect("lago congelado: a volta também passa", back and _player.health == health)
	await _frames(limit)
	# Parado no gelo até derreter.
	await _follow(screen, [Vector2(16, 3), Vector2(14, 3)])
	await _face(&"move_up")
	await _hold("attack", 2)
	await _follow(screen, [Vector2(13, 6)])
	await _slide(&"move_left")
	await _frames(limit)
	_expect("lago congelado: quem fica nele quando derrete cai", _player.health == health - 1)


func _play_volley() -> void:
	var screen := Vector2i(4, 6)
	await _enter(screen, 0, 3)
	await _follow(screen, [Vector2(5, 6)])
	await _face(&"move_right")
	# Espera o disparo chegar perto e bate.
	var effects := get_tree().get_first_node_in_group("floor_effects")
	var swings := 0
	for _i: int in 1200:
		if _all_open(screen, ChapterMap.Block.VOLLEY_DOOR):
			break
		for node: Node in effects.get_children():
			var bolt := node as Bolt
			if not bolt or bolt.returned or bolt.direction != Vector2.LEFT:
				continue
			var gap := bolt.global_position.x - _player.global_position.x
			if gap > 0.0 and gap < 44.0 and not Input.is_action_pressed("attack"):
				Input.action_press("attack")
				swings += 1
		await _frames(1)
		if Input.is_action_pressed("attack"):
			await _frames(1)
			Input.action_release("attack")
	print("  rebate: %d golpes, %d de vida" % [swings, _player.health])
	_expect(
		"rebater: o disparo devolvido desliga a torreta e abre a porta rosa",
		_all_open(screen, ChapterMap.Block.VOLLEY_DOOR)
	)
	var inside := await _follow(screen, [Vector2(15, 3), Vector2(15, 1)])
	_expect("rebater: a porta aberta leva ao baú", inside)
