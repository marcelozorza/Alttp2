extends Node
## Teste do laboratório, rodado pelo Godot sem tela, junto com o teste de
## fumaça (tools/run_smoke_test.sh):
##
##     godot --headless --fixed-fps 60 --path . res://tools/lab_test.tscn
##
## Abre o laboratório e confere cada mecânica nova na sala dela: leva o
## personagem até lá e aciona os objetos como o jogador faria, pelos golpes,
## pelos botões ou andando. Cada conferência imprime uma linha, e a última
## linha diz quantas falharam. Não muda nada no projeto.

const TILE := float(ChapterMap.TILE)

var _chapter: Chapter
var _player: Player
var _checks := 0
var _failures := 0
## Nome que abre a última linha. O teste que joga as salas (lab_play.gd)
## herda deste e troca o nome e as conferências.
var _title := "LABORATÓRIO"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i: int in n:
		await get_tree().physics_frame


func _expect(what: String, passed: bool) -> void:
	_checks += 1
	if not passed:
		_failures += 1
	print("%s: %s" % ["ok" if passed else "FALHOU", what])


## Centro de uma casa do miolo de uma tela: coluna e linha contadas a partir
## de zero, como nas salas de tools/lab/build_lab.py.
func _at(screen: Vector2i, column: int, row: int) -> Vector2:
	var cell := screen * ChapterRooms.ROOM_TILES + Vector2i(column + 1, row + 1)
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE


func _room(screen: Vector2i) -> Rect2i:
	return _chapter.rooms.room_at(screen)


## Leva o personagem a uma casa e espera a sala ligar.
func _go(screen: Vector2i, column: int, row: int, frames := 12) -> void:
	_player.global_position = _at(screen, column, row)
	_player.velocity = Vector2.ZERO
	_player.health = _player.max_health
	await _frames(frames)


func _hold(action: String, frames: int) -> void:
	Input.action_press(action)
	await _frames(frames)
	Input.action_release(action)


func _doors(screen: Vector2i, kind: ChapterMap.Block) -> Array:
	var all: Dictionary = _chapter.mechanisms.get("_doors")
	var by_kind: Dictionary = all.get(_room(screen), {})
	return by_kind.get(kind, [])


func _all_open(screen: Vector2i, kind: ChapterMap.Block, open := true) -> bool:
	var doors := _doors(screen, kind)
	if doors.is_empty():
		return false
	for door: MechDoor in doors:
		if door.open != open:
			return false
	return true


## Objetos de uma classe dentro de uma tela.
func _in_screen(screen: Vector2i, script: Script) -> Array:
	var found: Array = []
	_collect(_chapter, screen, script, found)
	return found


func _collect(node: Node, screen: Vector2i, script: Script, found: Array) -> void:
	for child: Node in node.get_children():
		if is_instance_of(child, script):
			var point: Vector2 = (child as Node2D).global_position
			var where := Vector2i((point / TILE).floor()) / ChapterRooms.ROOM_TILES
			if where == screen:
				found.append(child)
		_collect(child, screen, script, found)


func _kill_room(screen: Vector2i) -> void:
	var actors: Array = _chapter.rooms.actors.get(_room(screen), [])
	# Cópia da lista: a leva seguinte entra nela durante o laço.
	for actor: Node in actors.duplicate():
		var enemy := actor as Enemy
		var guard := 0
		while enemy and not enemy.is_dead() and guard < 60:
			enemy.take_hit(5, Vector2.DOWN, Hit.Kind.BLAST)
			await _frames(2)
			guard += 1
	await _frames(4)


func _run() -> void:
	var placeholder := Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder
	get_tree().change_scene_to_file(Flow.TITLE_SCENE)
	await _frames(10)
	var button := _find_button(get_tree().current_scene, "Laboratório")
	_expect("menu tem o botão Laboratório", button != null)
	if button:
		button.pressed.emit()
	else:
		RunSettings.chapter = ChapterData.LAB
		get_tree().change_scene_to_file(Flow.CHAPTER_SCENE)
	await _frames(20)
	_chapter = get_tree().current_scene as Chapter
	_expect("abre o laboratório", _chapter != null and _chapter.mode_text() == "Laboratório")
	if not _chapter:
		_finish()
		return
	_player = _chapter.player()
	_expect("chega só com a espada", _player.tool_bits() == 0)
	await _run_checks()
	_finish()


func _run_checks() -> void:
	await _check_combat()
	await _check_crystal()
	await _check_waves()
	await _check_blocks_and_turrets()
	await _check_statue()
	await _check_ice()
	await _check_new_enemies()
	await _check_block_on_ice()
	await _check_blast()
	await _check_wind_bomb()
	await _check_torches()
	await _check_dark_room()
	await _check_plate()
	await _check_pits()
	await _check_conveyor()
	await _check_crumble()
	await _check_portals()
	await _check_beam()
	await _check_power()
	await _check_magnet()
	await _check_water()
	await _check_clone()
	await _check_weight()
	await _check_cellar()
	await _check_chase()
	await _check_boss()


func _finish() -> void:
	print("%s: %d conferências, %d falhas" % [_title, _checks, _failures])
	get_tree().root.get_node("Music").get("_player").stop()
	for voice: Node in get_tree().root.get_node("Sfx").get_children():
		(voice as AudioStreamPlayer).stop()
	await _frames(10)
	get_tree().quit()


func _find_button(root: Node, text: String) -> Button:
	var button := root as Button
	if button and button.text == text:
		return button
	for child: Node in root.get_children():
		var found := _find_button(child, text)
		if found:
			return found
	return null


func _check_combat() -> void:
	var screen := Vector2i(2, 4)
	_expect("combate: portas abertas antes", _all_open(screen, ChapterMap.Block.SHUTTER))
	await _go(screen, 9, 4, 20)
	_expect(
		"combate: portas fecham com inimigos", _all_open(screen, ChapterMap.Block.SHUTTER, false)
	)
	var shield: ShieldEnemy = _in_screen(screen, ShieldEnemy)[0]
	var before := shield.health
	shield.take_hit(1, -shield.get("_look_direction"), Hit.Kind.SWORD)
	_expect("escudeiro: golpe de frente não fere", shield.health == before)
	shield.take_hit(1, shield.get("_look_direction"), Hit.Kind.SWORD)
	_expect("escudeiro: golpe por trás fere", shield.health < before)
	await _kill_room(screen)
	await _frames(40)
	_expect("combate: portas abrem com a sala limpa", _all_open(screen, ChapterMap.Block.SHUTTER))


func _check_crystal() -> void:
	var screen := Vector2i(1, 4)
	await _go(screen, 15, 5)
	var blue_closed := _all_open(screen, ChapterMap.Block.BARRIER, false)
	var orange_open := _all_open(screen, ChapterMap.Block.BARRIER_ALT)
	_expect("cristal: azul fechada e laranja aberta no início", blue_closed and orange_open)
	var crystal: Crystal = _in_screen(screen, Crystal)[0]
	crystal.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
	await _frames(40)
	var blue_open := _all_open(screen, ChapterMap.Block.BARRIER)
	var orange_closed := _all_open(screen, ChapterMap.Block.BARRIER_ALT, false)
	_expect("cristal: um golpe troca as duas", blue_open and orange_closed)
	crystal.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
	await _frames(40)
	_expect("cristal: outro golpe destroca", _all_open(screen, ChapterMap.Block.BARRIER, false))


func _check_waves() -> void:
	var screen := Vector2i(0, 4)
	var room := _room(screen)
	await _go(screen, 10, 4, 20)
	_expect("levas: portas fecham", _all_open(screen, ChapterMap.Block.SHUTTER, false))
	var sizes: Array[int] = []
	for wave: int in 3:
		sizes.append(_chapter.rooms.enemies_alive(room))
		await _kill_room(screen)
		await _frames(10)
	_expect("levas: três levas de três inimigos", sizes == [3, 3, 3])
	await _frames(40)
	var cleared := _chapter.rooms.enemies_alive(room) == 0
	_expect(
		"levas: portas abrem depois da última",
		cleared and _all_open(screen, ChapterMap.Block.SHUTTER)
	)


func _check_blocks_and_turrets() -> void:
	var screen := Vector2i(2, 3)
	await _go(screen, 9, 6)
	await _frames(130)
	var bolts := 0
	for node: Node in get_tree().get_first_node_in_group("floor_effects").get_children():
		if node is Bolt:
			bolts += 1
	_expect("torreta: dispara em cruz", bolts > 0)
	var pit: Pit = _in_screen(screen, Pit)[0]
	var block: FreeBlock = null
	for candidate: FreeBlock in _in_screen(screen, FreeBlock):
		if Pit.cell_of(candidate.global_position).x == Pit.cell_of(_at(screen, 8, 4)).x:
			block = candidate
	# Empurra o bloco para o norte, andando contra ele, até o buraco.
	_player.global_position = _at(screen, 8, 5) + Vector2(0.0, 8.0)
	await _hold("move_up", 150)
	_expect("bloco solto: empurrado, tampa o buraco", pit.filled.size() == 1 and block.locked)
	await _go(screen, 8, 3)
	await _hold("move_up", 40)
	_expect(
		"ponte: passa por cima da casa tampada",
		Pit.cell_of(_player.global_position).y < Pit.cell_of(_at(screen, 8, 2)).y
	)
	await _go(screen, 3, 3)
	var health := _player.health
	await _hold("move_up", 30)
	var fell := _player.health == health - 1
	_expect("buraco: cair custa vida e devolve à entrada", fell)


func _check_statue() -> void:
	var screen := Vector2i(1, 3)
	await _go(screen, 9, 6)
	var statue: MirrorStatue = _in_screen(screen, MirrorStatue)[0]
	var start := statue.global_position
	await _hold("move_right", 30)
	_expect("estátua: anda ao contrário na horizontal", statue.global_position.x < start.x - 20.0)
	_expect(
		"estátua: grade fechada antes da placa",
		_all_open(screen, ChapterMap.Block.TIMED_GATE, false)
	)
	var plate: TimedPlate = _in_screen(screen, TimedPlate)[0]
	statue.global_position = plate.global_position + Vector2(0.0, 6.0)
	await _frames(40)
	_expect(
		"estátua: em cima da placa, a grade abre de vez",
		_all_open(screen, ChapterMap.Block.TIMED_GATE)
	)


func _check_ice() -> void:
	var screen := Vector2i(0, 3)
	await _go(screen, 2, 7)
	await _hold("move_up", 12)
	await _frames(70)
	var first := Pit.cell_of(_player.global_position) == Pit.cell_of(_at(screen, 2, 2))
	_expect("gelo: desliza reto até a pedra", first)
	await _hold("move_right", 6)
	await _frames(70)
	var second := Pit.cell_of(_player.global_position) == Pit.cell_of(_at(screen, 9, 2))
	_expect("gelo: segunda deslizada para na pedra seguinte", second)
	await _hold("move_up", 6)
	await _frames(40)
	_expect("gelo: sai pela porta do norte", _player.global_position.y < _at(screen, 9, 1).y)


func _check_new_enemies() -> void:
	var screen := Vector2i(0, 2)
	await _go(screen, 9, 4, 20)
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
	_expect("inimigos novos: sala limpa abre o baú", _all_open(screen, ChapterMap.Block.SHUTTER))


func _check_block_on_ice() -> void:
	var screen := Vector2i(1, 2)
	await _go(screen, 0, 5)
	var block: FreeBlock = _in_screen(screen, FreeBlock)[0]
	await _hold("move_right", 200)
	var pit: Pit = _in_screen(screen, Pit)[0]
	# Dois empurrões no chão, a deslizada pelo gelo e mais dois até o buraco.
	_player.global_position = _at(screen, 9, 5)
	await _hold("move_right", 200)
	_expect("bloco no gelo: desliza e tampa o buraco", pit.filled.size() == 1)


func _check_blast() -> void:
	var screen := Vector2i(3, 3)
	_player.give_item(Item.Id.BOMB)
	await _go(screen, 3, 3)
	var target: Crystal = _in_screen(screen, Crystal)[0]
	target.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
	await _frames(20)
	_expect("alvo: a espada não aciona", _all_open(screen, ChapterMap.Block.BLAST_DOOR, false))
	_player.facing = Vector2.LEFT
	await _hold("use_bomb", 3)
	await _frames(130)
	_expect("alvo: a bomba abre a porta roxa", _all_open(screen, ChapterMap.Block.BLAST_DOOR))


func _check_wind_bomb() -> void:
	var screen := Vector2i(3, 2)
	await _go(screen, 13, 1, 200)
	_player.facing = Vector2.RIGHT
	await _hold("use_bomb", 3)
	await _frames(150)
	_expect("vento: carrega a bomba até o alvo", _all_open(screen, ChapterMap.Block.BLAST_DOOR))
	await _go(screen, 14, 1, 1)
	var from := _player.global_position.y
	await _frames(6)
	_expect("vento: empurra o personagem", _player.global_position.y > from + 10.0)


func _check_torches() -> void:
	var screen := Vector2i(4, 3)
	await _go(screen, 9, 4)
	for torch: LabTorch in _in_screen(screen, LabTorch):
		torch.take_hit(1, Vector2.UP, Hit.Kind.FIRE)
	await _frames(40)
	_expect(
		"tochas: todas acesas abrem a porta amarela", _all_open(screen, ChapterMap.Block.TORCH_DOOR)
	)
	screen = Vector2i(5, 3)
	await _go(screen, 9, 4)
	var timed := _in_screen(screen, LabTorch)
	(timed[0] as LabTorch).take_hit(1, Vector2.UP, Hit.Kind.FIRE)
	await _frames(GameMath.ticks(LabBuilder.TORCH_BURN_TIME) + 10)
	_expect("tocha com tempo: apaga sozinha", not (timed[0] as LabTorch).lit)
	for torch: LabTorch in timed:
		torch.take_hit(1, Vector2.UP, Hit.Kind.FIRE)
	await _frames(GameMath.ticks(LabBuilder.TORCH_BURN_TIME) + 10)
	var held := (timed[0] as LabTorch).lit
	_expect(
		"tocha com tempo: as três juntas abrem e ficam",
		held and _all_open(screen, ChapterMap.Block.TORCH_DOOR)
	)
	var web: Web = _in_screen(screen, Web)[0]
	web.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
	var after_sword := web.cleared
	web.take_hit(1, Vector2.UP, Hit.Kind.FIRE)
	_expect("teia: só o fogo remove", not after_sword and web.cleared)
	screen = Vector2i(4, 1)
	await _go(screen, 9, 5)
	var ordered := _in_screen(screen, LabTorch)
	ordered.sort_custom(func(a: LabTorch, b: LabTorch) -> bool: return a.order < b.order)
	(ordered[1] as LabTorch).take_hit(1, Vector2.UP, Hit.Kind.FIRE)
	await _frames(4)
	_expect("tochas em ordem: fora da vez, apaga", not (ordered[1] as LabTorch).lit)
	for torch: LabTorch in ordered:
		torch.take_hit(1, Vector2.UP, Hit.Kind.FIRE)
		await _frames(4)
	await _frames(40)
	_expect("tochas em ordem: na ordem, abre", _all_open(screen, ChapterMap.Block.TORCH_DOOR))


func _check_dark_room() -> void:
	var darkness: Darkness = null
	for child: Node in _chapter.get_children():
		if child is Darkness:
			darkness = child
	await _go(Vector2i(4, 2), 9, 7)
	await get_tree().process_frame
	var dark: bool = darkness != null and (darkness.get("_cover") as ColorRect).visible
	await _go(Vector2i(4, 3), 9, 4)
	await get_tree().process_frame
	var bright: bool = darkness != null and not (darkness.get("_cover") as ColorRect).visible
	_expect("sala escura: escurece só nela", dark and bright)


func _check_plate() -> void:
	var screen := Vector2i(5, 2)
	await _go(screen, 6, 6, 20)
	_expect("placa: pisada, abre a grade verde", _all_open(screen, ChapterMap.Block.TIMED_GATE))
	await _go(screen, 12, 6, 250)
	_expect(
		"placa: fecha depois de 4 segundos", _all_open(screen, ChapterMap.Block.TIMED_GATE, false)
	)


func _check_pits() -> void:
	var screen := Vector2i(5, 4)
	_player.give_item(Item.Id.SPRING)
	await _go(screen, 4, 3)
	_player.invulnerable = true
	Input.action_press("move_right")
	await _frames(8)
	await _hold("jump", 3)
	await _frames(50)
	Input.action_release("move_right")
	_player.invulnerable = false
	_expect(
		"mola: pula o buraco de duas casas", _player.global_position.x > _at(screen, 8, 3).x - 16.0
	)


func _check_conveyor() -> void:
	var screen := Vector2i(6, 3)
	await _go(screen, 9, 2)
	_player.invulnerable = true
	var from := _player.global_position.x
	await _frames(30)
	_player.invulnerable = false
	_expect("esteira: carrega o personagem", _player.global_position.x > from + 30.0)


func _check_crumble() -> void:
	var screen := Vector2i(6, 4)
	await _go(screen, 6, 6)
	await _go(screen, 7, 6)
	var health := _player.health
	_player.global_position = _at(screen, 6, 6)
	await _frames(6)
	_expect("piso quebradiço: pisar de novo é queda", _player.health == health - 1)


func _check_portals() -> void:
	var screen := Vector2i(6, 2)
	await _go(screen, 3, 6, 20)
	_expect("portal: leva ao par", _player.global_position.distance_to(_at(screen, 1, 1)) < 8.0)
	await _go(Vector2i(3, 1), 14, 6, 20)
	var stays := _player.global_position.distance_to(_at(Vector2i(3, 1), 14, 6)) < 8.0
	_expect("portal de chegada: não leva a lugar nenhum", stays)
	await _go(Vector2i(0, 0), 4, 4, 20)
	var back := _player.global_position.distance_to(_at(Vector2i(3, 1), 14, 6)) < 8.0
	_expect("portal do cofre: volta à antessala", back)


func _check_beam() -> void:
	var screen := Vector2i(4, 5)
	await _go(screen, 9, 4, 20)
	var receptor: BeamReceptor = null
	for candidate: BeamReceptor in _in_screen(screen, BeamReceptor):
		if not candidate.emitter:
			receptor = candidate
	_expect("feixe: começa sem chegar ao olho", not receptor.lit)
	for mirror: BeamMirror in _in_screen(screen, BeamMirror):
		mirror.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
	await _frames(40)
	_expect(
		"feixe: espelhos virados, a porta branca abre",
		receptor.lit and _all_open(screen, ChapterMap.Block.BEAM_DOOR)
	)
	await _go(screen, 6, 2, 20)
	_expect("feixe: o personagem corta a luz", not receptor.lit)


func _check_power() -> void:
	var screen := Vector2i(1, 5)
	await _go(screen, 9, 6, 20)
	_expect(
		"eletricidade: porta fechada com o fio falho",
		_all_open(screen, ChapterMap.Block.POWER_DOOR, false)
	)
	# Empurra cada bloco, andando contra ele, até a falha do fio.
	var wire_row := Pit.cell_of(_at(screen, 0, 4)).y
	var top: FreeBlock = null
	for block: FreeBlock in _in_screen(screen, FreeBlock):
		var above := block.cell().y < wire_row
		if above:
			top = block
		var side := Vector2(0.0, -40.0) if above else Vector2(0.0, 24.0)
		_player.global_position = block.global_position + side
		Input.action_press("move_down" if above else "move_up")
		for _i: int in 200:
			await _frames(1)
			if block.cell().y == wire_row and not block.is_tumbling():
				break
		Input.action_release("move_down" if above else "move_up")
	await _frames(40)
	_expect(
		"eletricidade: blocos de metal fecham o circuito",
		_all_open(screen, ChapterMap.Block.POWER_DOOR)
	)
	top.take_hit(1, Vector2.UP, Hit.Kind.BLAST)
	await _frames(40)
	_expect(
		"eletricidade: circuito cortado, a porta fecha",
		_all_open(screen, ChapterMap.Block.POWER_DOOR, false)
	)


func _check_magnet() -> void:
	var screen := Vector2i(0, 5)
	await _go(screen, 12, 5, 20)
	var magnet: Magnet = _in_screen(screen, Magnet)[0]
	var pit: Pit = _in_screen(screen, Pit)[0]
	magnet.take_hit(1, Vector2.RIGHT, Hit.Kind.SWORD)
	await _frames(Magnet.PULL_TICKS)
	_expect("ímã: puxa o bloco de metal até o buraco", pit.filled.size() == 1)


func _check_water() -> void:
	var screen := Vector2i(5, 0)
	await _go(screen, 6, 6, 20)
	await _hold("move_up", 40)
	_expect("água cheia: não dá para andar nela", _player.global_position.y > _at(screen, 6, 5).y)
	await _go(screen, 12, 6)
	await _hold("move_up", 60)
	_expect("água cheia: a balsa é ponte", _player.global_position.y < _at(screen, 12, 1).y + 16.0)
	var crystal: Crystal = _in_screen(screen, Crystal)[0]
	crystal.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
	await _go(screen, 4, 6, 20)
	await _hold("move_up", 30)
	_expect(
		"água vazia: a rampa desce ao leito", _player.global_position.y < _at(screen, 4, 5).y + 8.0
	)
	await _hold("move_up", 60)
	_expect(
		"água vazia: a margem sem rampa segura",
		_player.global_position.y > _at(screen, 4, 1).y + 16.0
	)
	var health := _player.health
	crystal.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
	await _frames(20)
	_expect("água: quem está no leito quando ela volta é levado", _player.health == health - 1)


func _check_clone() -> void:
	var screen := Vector2i(6, 0)
	await _go(screen, 4, 4, 20)
	_player.global_position = _at(screen, 2, 6)
	await _frames(EchoPad.RECORD_TICKS)
	await _go(screen, 12, 4, 60)
	var far := _player.global_position.distance_to(_at(screen, 2, 6)) > 200.0
	_expect(
		"clone: segura a placa com o personagem longe",
		far and _all_open(screen, ChapterMap.Block.TIMED_GATE)
	)


func _check_weight() -> void:
	var screen := Vector2i(4, 0)
	await _go(screen, 12, 4, 20)
	_player.invulnerable = true
	var opened := false
	for _i: int in 400:
		await _frames(1)
		opened = opened or _all_open(screen, ChapterMap.Block.TIMED_GATE)
	_player.invulnerable = false
	_expect("peso: o inimigo atraído pisa na placa e abre a grade", opened)


func _check_cellar() -> void:
	var up := Vector2i(3, 1)
	var down := Vector2i(2, 0)
	await _go(up, 15, 1, 20)
	_expect("buraco: cai no porão", _player.global_position.distance_to(_at(down, 4, 4)) < 8.0)
	await _go(down, 13, 4, 20)
	_expect(
		"porão: o outro buraco leva de volta",
		_player.global_position.distance_to(_at(up, 12, 6)) < 8.0
	)


func _check_chase() -> void:
	var screen := Vector2i(2, 1)
	await _go(screen, 16, 4)
	var health := _player.health
	await _frames(240)
	_expect("fuga: quem fica parado se queima", _player.health < health)


func _check_boss() -> void:
	var screen := Vector2i(3, 0)
	await _go(screen, 9, 6, 20)
	_player.invulnerable = true
	for actor: Node in _chapter.rooms.actors.get(_room(screen), []):
		var boss := actor as Boss
		var guard := 0
		while boss and boss.health > 0 and guard < 600:
			for kind: int in [Hit.Kind.BLAST, Hit.Kind.FIRE, Hit.Kind.SWORD]:
				boss.take_hit(1, Vector2.DOWN, kind)
				await _frames(2)
			guard += 1
	await _frames(40)
	for node: Node in _chapter.get_node("Objects").get_children():
		if node is Relic:
			_player.global_position = (node as Relic).global_position
	await _frames(20)
	_expect("chefe: vencido, a relíquia encerra o laboratório", _chapter.finished)
