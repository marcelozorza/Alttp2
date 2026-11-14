extends Node
## Teste dos mecanismos de sala (mechanics/), rodado pelo Godot sem tela,
## junto com o teste de fumaça (tools/run_smoke_test.sh):
##
##     godot --headless --fixed-fps 60 --path . res://tools/mechanics_test.tscn
##
## Abre a bancada (tools/bench/bench_data.gd), que não faz parte do jogo, e
## confere cada mecânica na sala dela. Onde a sala depende de tempo, um piloto
## a atravessa só pelos botões, andando e correndo, como o jogador faria: a
## corrida da placa e as tochas que apagam. Cada conferência imprime uma
## linha, as linhas com dois espaços são medidas de folga, e a última linha
## diz quantas falharam. Não muda nada no projeto.

const BENCH := "res://tools/bench/bench_data.gd"
const TILE := float(ChapterMap.TILE)
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

var _chapter: Chapter
var _player: Player
var _checks := 0
var _failures := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	_chapter = (load(Flow.CHAPTER_SCENE) as PackedScene).instantiate() as Chapter
	_chapter.data = ChapterData.from_source(load(BENCH) as Script, ChapterData.TUTORIAL)
	get_tree().root.add_child(_chapter)
	get_tree().current_scene = _chapter
	await _frames(20)
	_player = _chapter.player()
	_expect("a bancada abre", _player != null)
	await _check_crystal()
	await _check_plate()
	await _check_torches()
	await _check_arena()
	await _check_ice()
	await _check_wind()
	print("MECANISMOS: %d conferências, %d falhas" % [_checks, _failures])
	get_tree().root.get_node("Music").get("_player").stop()
	for voice: Node in get_tree().root.get_node("Sfx").get_children():
		(voice as AudioStreamPlayer).stop()
	await _frames(10)
	get_tree().quit()


func _frames(n: int) -> void:
	for _i: int in n:
		await get_tree().physics_frame


func _expect(what: String, passed: bool) -> void:
	_checks += 1
	if not passed:
		_failures += 1
	print("%s: %s" % ["ok" if passed else "FALHOU", what])


## Ponto do mundo de uma casa do miolo de uma tela, contada a partir de zero.
## Aceita fração.
func _spot(screen: Vector2i, cell: Vector2) -> Vector2:
	var corner := Vector2(screen * ChapterRooms.ROOM_TILES) + Vector2.ONE
	return (corner + cell + Vector2(0.5, 0.5)) * TILE


## Leva o personagem a uma casa, parado e com a vida cheia, e espera a sala
## ligar.
func _go(screen: Vector2i, column: int, row: int, frames := REST) -> void:
	_release_all()
	_player.global_position = _spot(screen, Vector2(column, row))
	_player.velocity = Vector2.ZERO
	_player.health = _player.max_health
	await _frames(frames)


func _hold(action: StringName, frames: int) -> void:
	Input.action_press(action)
	await _frames(frames)
	Input.action_release(action)


func _all_open(screen: Vector2i, kind: ChapterMap.Block, open := true) -> bool:
	var all: Dictionary = _chapter.mechanisms.get("_doors")
	var by_kind: Dictionary = all.get(_chapter.rooms.room_at(screen), {})
	var doors: Array = by_kind.get(kind, [])
	if doors.is_empty():
		return false
	for door: MechDoor in doors:
		if door.open != open:
			return false
	return true


## Objetos de uma classe dentro de uma tela.
func _in_screen(screen: Vector2i, script: Script, node: Node = _chapter) -> Array:
	var found: Array = []
	for child: Node in node.get_children():
		if is_instance_of(child, script):
			var cell := ChapterMap.cell_of((child as Node2D).global_position)
			if cell / ChapterRooms.ROOM_TILES == screen:
				found.append(child)
		found.append_array(_in_screen(screen, script, child))
	return found


func _kill_room(screen: Vector2i) -> void:
	var actors: Array = _chapter.rooms.actors.get(_chapter.rooms.room_at(screen), [])
	# Cópia da lista: a leva seguinte entra nela durante o laço.
	for actor: Node in actors.duplicate():
		var enemy := actor as Enemy
		var guard := 0
		while enemy and not enemy.is_dead() and guard < 60:
			enemy.take_hit(5, Vector2.DOWN, Hit.Kind.BLAST)
			await _frames(2)
			guard += 1
	await _frames(4)


func _release_all() -> void:
	for action: StringName in MOVES:
		Input.action_release(action)


## Aperta os botões de direção que levam ao alvo.
func _steer(target: Vector2) -> void:
	var offset := target - _player.global_position
	for action: StringName in MOVES:
		Input.action_release(action)
	if offset.x < -SLACK:
		Input.action_press(&"move_left")
	if offset.x > SLACK:
		Input.action_press(&"move_right")
	if offset.y < -SLACK:
		Input.action_press(&"move_up")
	if offset.y > SLACK:
		Input.action_press(&"move_down")


## Anda até o alvo sem soltar os botões na chegada. Devolve falso se o tempo
## acabar (caminho fechado).
func _walk_to(target: Vector2) -> bool:
	for _i: int in STEP_LIMIT:
		if _player.global_position.distance_to(target) < ARRIVE:
			return true
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


## Segue um caminho numa tela. Cada passo é uma casa (Vector2) ou &"run"
## (passa a correr rumo à casa seguinte).
func _follow(screen: Vector2i, path: Array) -> bool:
	var arrived := true
	for index: int in path.size():
		var step: Variant = path[index]
		if step is Vector2:
			arrived = await _walk_to(_spot(screen, step))
		else:
			await _start_run(_spot(screen, path[index + 1]))
		if not arrived:
			break
	_release_all()
	return arrived


## Vira o personagem para um lado com um toque curto e solta a chama.
func _fire(action: StringName) -> void:
	_release_all()
	await _frames(4)
	await _hold(action, 2)
	await _hold(&"use_fire", 2)


func _check_crystal() -> void:
	var screen := Vector2i(0, 0)
	var blue_closed := _all_open(screen, ChapterMap.Block.BARRIER, false)
	var orange_open := _all_open(screen, ChapterMap.Block.BARRIER_ALT)
	_expect("cristal: azul fechada e laranja aberta no início", blue_closed and orange_open)
	var crystal: Crystal = _in_screen(screen, Crystal)[0]
	crystal.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
	await _frames(40)
	var blue_open := _all_open(screen, ChapterMap.Block.BARRIER)
	var orange_closed := _all_open(screen, ChapterMap.Block.BARRIER_ALT, false)
	_expect("cristal: um golpe troca as duas", blue_open and orange_closed)
	crystal.take_hit(1, Vector2.UP, Hit.Kind.FIRE)
	await _frames(40)
	_expect("cristal: outro golpe destroca", _all_open(screen, ChapterMap.Block.BARRIER, false))


## A placa fica no sul, e a grade no fim de um corredor que dá a volta pelo
## oeste: andando o tempo acaba, correndo dá.
func _check_plate() -> void:
	var screen := Vector2i(1, 0)
	var limit := GameMath.ticks(4.0)
	var route := [Vector2(0, 6), Vector2(0, 4), Vector2(15.5, 4)]
	await _go(screen, 12, 7)
	await _follow(screen, [Vector2(9, 7)])
	_expect("placa: pisada, abre a grade verde", _all_open(screen, ChapterMap.Block.TIMED_GATE))
	var start := Clock.tick
	var walked := await _follow(screen, route)
	print("  placa, andando: %d ticks de %d" % [Clock.tick - start, limit])
	_expect("placa: andando não dá tempo", not walked)
	_expect("placa: a grade fecha", _all_open(screen, ChapterMap.Block.TIMED_GATE, false))
	await _go(screen, 12, 7)
	await _follow(screen, [Vector2(9, 7)])
	start = Clock.tick
	var ran := await _follow(screen, [&"run", route[0], route[1], route[2]])
	print("  placa, correndo: %d ticks de %d" % [Clock.tick - start, limit])
	_expect("placa: correndo passa pela grade", ran)


func _check_torches() -> void:
	var screen := Vector2i(2, 0)
	await _go(screen, 9, 4)
	var torches := _in_screen(screen, TimedTorch)
	var first: TimedTorch = torches[0]
	first.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
	_expect("tocha: a espada não acende", not first.lit)
	first.take_hit(1, Vector2.UP, Hit.Kind.FIRE)
	await _frames(GameMath.ticks(4.0) - 10)
	var still := first.lit
	await _frames(20)
	_expect("tocha: apaga sozinha em 4 segundos", still and not first.lit)
	_expect("tocha: uma só não abre a porta", _all_open(screen, ChapterMap.Block.TORCH_DOOR, false))
	# O piloto acende as três com a chama, andando de uma à outra.
	await _go(screen, 4, 1)
	var start := Clock.tick
	await _fire(&"move_left")
	await _follow(screen, [Vector2(9, 1)])
	await _fire(&"move_right")
	await _follow(screen, [Vector2(4, 6)])
	await _fire(&"move_left")
	await _frames(40)
	print("  tochas: %d ticks de %d" % [Clock.tick - start - 40, GameMath.ticks(4.0)])
	_expect(
		"tochas: três chamas a tempo abrem a porta amarela",
		_all_open(screen, ChapterMap.Block.TORCH_DOOR)
	)
	await _frames(GameMath.ticks(4.0))
	_expect("tochas: com a porta aberta, ficam acesas", first.lit)


func _check_arena() -> void:
	var screen := Vector2i(3, 0)
	var room := _chapter.rooms.room_at(screen)
	_expect("arena: portas abertas antes", _all_open(screen, ChapterMap.Block.SHUTTER))
	await _go(screen, 9, 4)
	_expect("arena: portas fecham", _all_open(screen, ChapterMap.Block.SHUTTER, false))
	var first := _chapter.rooms.enemies_alive(room)
	await _kill_room(screen)
	await _frames(10)
	var second := _chapter.rooms.enemies_alive(room)
	_expect("arena: duas levas de dois inimigos", first == 2 and second == 2)
	_expect(
		"arena: portas fechadas entre as levas", _all_open(screen, ChapterMap.Block.SHUTTER, false)
	)
	_player.invulnerable = true
	await _frames(200)
	var patches := 0
	for node: Node in get_tree().get_first_node_in_group("floor_effects").get_children():
		if node is FirePatch:
			patches += 1
	_expect("rastro: deixa fogo no chão", patches > 0)
	_player.invulnerable = false
	await _kill_room(screen)
	await _frames(40)
	var cleared := _chapter.rooms.enemies_alive(room) == 0
	_expect(
		"arena: portas abrem depois da última leva",
		cleared and _all_open(screen, ChapterMap.Block.SHUTTER)
	)


func _check_ice() -> void:
	var screen := Vector2i(4, 0)
	await _go(screen, 1, 3)
	Input.action_press(&"move_right")
	await _frames(10)
	var slow_start := _player.velocity.x < _player.walk_speed * 0.5
	await _frames(40)
	Input.action_release(&"move_right")
	var from := _player.global_position.x
	await _frames(90)
	var slid := _player.global_position.x - from
	print("  gelo: escorrega %d pixels depois de soltar o botão" % roundi(slid))
	_expect("gelo: demora a pegar velocidade", slow_start)
	_expect("gelo: escorrega depois de soltar o botão", slid > 40.0 and _player.on_ice)
	await _go(screen, 2, 7)
	await _hold(&"move_right", 20)
	from = _player.global_position.x
	await _frames(20)
	_expect("fora do gelo: para na hora", absf(_player.global_position.x - from) < 4.0)


func _check_wind() -> void:
	var screen := Vector2i(4, 0)
	_expect(
		"vento: barreira azul fechada antes", _all_open(screen, ChapterMap.Block.BARRIER, false)
	)
	# No canal, diante do ventilador, solta a bomba e sai de lado.
	await _go(screen, 12, 1, 1)
	_player.facing = Vector2.DOWN
	await _hold(&"use_bomb", 2)
	await _follow(screen, [Vector2(9, 1)])
	await _frames(150)
	_expect(
		"vento: carrega a bomba até o cristal, que abre a barreira",
		_all_open(screen, ChapterMap.Block.BARRIER)
	)
	await _go(screen, 12, 1, 1)
	var from := _player.global_position.y
	await _frames(6)
	_expect("vento: empurra o personagem", _player.global_position.y > from + 10.0)
