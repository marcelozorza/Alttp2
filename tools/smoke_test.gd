extends Node
## Teste de fumaça, rodado pelo Godot sem tela:
##
##     godot --headless --path . --import
##     godot --headless --fixed-fps 60 --path . res://tools/smoke_test.tscn
##
## Ou, com as mesmas conferências de erro que o GitHub faz a cada push:
##
##     sh tools/run_smoke_test.sh [caminho do godot]
##
## O --fixed-fps 60 avança o tempo do jogo sem esperar o relógio: o teste
## leva uns 10 s em vez de 10 min, com o mesmo resultado, porque tudo roda
## em ticks de física.
##
## Roda como cena, e não com -s, porque só assim os autoloads Music e Sfx
## existem. O teste fica na raiz e põe outro nó como cena atual, para que as
## trocas de cena não o apaguem.
##
## Confere o áudio (barramentos, os arquivos de cada efeito e a música local,
## se houver), o menu com o botão A e o Start do controle, o mundo (entradas
## trancadas e abertas, a pedra de salvamento) e cada capítulo no jogo
## contínuo: abre os baús, ganha todas as ferramentas, encosta nas portas,
## pisa nos interruptores e trava o bloco pesado neles para abrir as grades,
## entra em cada sala usando os botões, vence o chefe, toca a relíquia e
## volta ao mundo. Depois confere o rejogo de um capítulo vencido, o menu de
## pausa, a tela de derrota, o ossinho dos inimigos, o treino, a sala de
## teste e a volta ao mundo com o progresso da sessão. Qualquer erro de script
## aparece na saída como SCRIPT ERROR. Não muda nada no projeto nem grava
## arquivo algum.

const ACTIONS := [
	"attack", "use_fire", "use_bomb", "jump", "move_left", "move_right", "move_up", "move_down"
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i: int in n:
		await get_tree().physics_frame


func _joy(button: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.pressed = true
	Input.parse_input_event(ev)
	await _frames(3)
	var up := InputEventJoypadButton.new()
	up.button_index = button
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(3)


func _scene_path() -> String:
	return get_tree().current_scene.scene_file_path if get_tree().current_scene else "<nenhuma>"


func _scene_name() -> String:
	return _scene_path().get_file()


## Primeiro botão com o texto, em qualquer lugar da cena atual.
func _button(text: String, root: Node = null) -> Button:
	if root == null:
		root = get_tree().current_scene
	var button := root as Button
	if button and button.text == text:
		return button
	for child: Node in root.get_children():
		var found := _button(text, child)
		if found:
			return found
	return null


func _press(text: String) -> void:
	var button := _button(text)
	if not button:
		print("BOTÃO NÃO ENCONTRADO: ", text)
		return
	button.pressed.emit()
	await _frames(10)


func _run() -> void:
	var placeholder := Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder
	# Menu: sem jogo salvo, o A do controle começa um jogo novo e abre o mundo.
	get_tree().change_scene_to_file(Flow.TITLE_SCENE)
	await _frames(10)
	await _joy(JOY_BUTTON_A)
	await _frames(10)
	print("MENU: depois do A -> ", _scene_name(), " contínuo: ", Progress.active)
	# Start também confirma.
	get_tree().change_scene_to_file(Flow.TITLE_SCENE)
	await _frames(10)
	await _joy(JOY_BUTTON_START)
	await _frames(10)
	print("MENU: depois do Start -> ", _scene_name())

	_check_audio()
	await _check_overworld()

	for chapter: int in range(1, ChapterData.count() + 1):
		await _play(chapter)
		await _check_after_chapter(chapter)
	await _check_replay()
	await _check_pause_and_defeat()
	await _check_bone_drops()
	await _check_jump_over()
	await _check_training()
	await _check_tutorial()
	await _check_continue()
	await _check_practice()
	_check_logic()
	await _check_randomized()
	print("FIM DO TESTE")
	# Sons tocando no fechamento deixam o Godot acusar recurso preso.
	get_tree().root.get_node("Music").get("_player").stop()
	for voice: Node in get_tree().root.get_node("Sfx").get_children():
		(voice as AudioStreamPlayer).stop()
	await _frames(10)
	get_tree().quit()


func _entrance(chapter: int) -> DungeonEntrance:
	for entrance: DungeonEntrance in get_tree().current_scene.get("_entrances"):
		if entrance.chapter == chapter:
			return entrance
	return null


## Anda para o norte a partir da frente da entrada, até encostar nela.
func _walk_into(entrance: DungeonEntrance, player: Player) -> void:
	player.global_position = entrance.exit_position()
	Input.action_press("move_up")
	await _frames(20)
	Input.action_release("move_up")
	await _frames(10)


## O mundo: entradas na ordem dos capítulos, a trancada treme e segura o
## personagem, a pedra de salvamento grava e enche a vida, e a entrada 1 leva
## ao capítulo 1.
func _check_overworld() -> void:
	Progress.start_new()
	get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)
	await _frames(10)
	var world: Node = get_tree().current_scene
	var player: Player = world.get("_player")
	var modes := []
	for chapter: int in range(1, ChapterData.count() + 1):
		var entrance := _entrance(chapter)
		modes.append(entrance.mode if entrance else -1)
	print("MUNDO: modos das entradas %s (0 trancada, 1 aberta, 2 vencida)" % [modes])
	var locked := _entrance(2)
	await _walk_into(locked, player)
	var shook: bool = locked.get("_shake_tick") > 0
	print("MUNDO: entrada 2 trancada -> %s, tremeu: %s" % [_scene_name(), shook])
	player.health = 1
	var stone: SaveStone = null
	for node: Node in world.get("_objects").get_children():
		if node is SaveStone:
			stone = node
	player.global_position = stone.global_position + Vector2(0.0, 8.0)
	await _frames(10)
	print(
		(
			"MUNDO: pedra gravou: %s, vida %d/%d"
			% [not Progress.checkpoint.is_empty(), player.health, player.max_health]
		)
	)
	await _walk_into(_entrance(1), player)
	print("MUNDO: entrada 1 -> %s, capítulo %d" % [_scene_name(), RunSettings.chapter])


## Depois da relíquia, no jogo contínuo: o capítulo conta, o primeiro botão
## da tela de fim volta ao mundo, a entrada dele fica vencida, a seguinte
## abre e o personagem aparece na entrada.
func _check_after_chapter(chapter_number: int) -> void:
	await _frames(60)
	await _press("Voltar ao mundo")
	var world: Node = get_tree().current_scene
	var player: Player = world.get("_player")
	var done := _entrance(chapter_number)
	var next := _entrance(chapter_number + 1)
	var at_entrance: bool = done != null and player.global_position == done.exit_position()
	var text := "MUNDO: capítulo %d vencido %s, entrada %s, seguinte %s, "
	text += "personagem na entrada %s, vida %d, ferramentas %d"
	print(
		(
			text
			% [
				chapter_number,
				Progress.is_done(chapter_number),
				done.mode if done else -1,
				next.mode if next else -1,
				at_entrance,
				player.max_health,
				Progress.tools,
			]
		)
	)


## Rejogo do capítulo 1: os baús de coração e de ferramenta começam abertos,
## os de chave fechados.
func _check_replay() -> void:
	RunSettings.chapter = 1
	get_tree().change_scene_to_file(Flow.CHAPTER_SCENE)
	await _frames(20)
	var chapter: Node = get_tree().current_scene
	var open_items := []
	var closed_items := []
	for chest: Chest in chapter.get("_chests"):
		var item_name: String = Item.Id.keys()[chest.item]
		if chest.is_open:
			open_items.append(item_name)
		else:
			closed_items.append(item_name)
	var player: Player = chapter.get("_player")
	print(
		(
			"REJOGO: abertos %s, fechados %s, vida %d/%d"
			% [open_items, closed_items, player.health, player.max_health]
		)
	)


## Start abre o menu de pausa e para o jogo, e Start de novo confirma
## continuar. Sem vida, o personagem cai, a tela de derrota aparece e tentar
## de novo recomeça o capítulo do início, numa cena nova, com a vida cheia.
func _check_pause_and_defeat() -> void:
	var chapter: Node = get_tree().current_scene
	var pause: PauseMenu = chapter.get_node("PauseMenu")
	var map_screen: MapScreen = chapter.get_node("MapScreen")
	await _joy(JOY_BUTTON_START)
	print(
		(
			"PAUSA: mapa com menu %s, menu separado escondido %s, jogo parado %s"
			% [
				map_screen.visible and _button("Continuar", map_screen) != null,
				not pause.visible,
				get_tree().paused
			]
		)
	)
	await _frames(10)
	await _joy(JOY_BUTTON_START)
	print("PAUSA: fechada %s, jogo solto %s" % [not map_screen.visible, not get_tree().paused])
	await _joy(JOY_BUTTON_BACK)
	print(
		(
			"MAPA: aberto %s, sem botões %s, jogo parado %s"
			% [
				map_screen.visible,
				_button("Continuar", map_screen) == null,
				get_tree().paused,
			]
		)
	)
	await _frames(10)
	await _joy(JOY_BUTTON_BACK)
	print("MAPA: fechado %s, jogo solto %s" % [not map_screen.visible, not get_tree().paused])
	await _joy(JOY_BUTTON_START)
	var resume := _button("Continuar", map_screen)
	if resume:
		resume.pressed.emit()
	await _frames(10)
	print(
		(
			"PAUSA: Continuar fecha %s, jogo solto %s, escala %d"
			% [
				not map_screen.visible,
				not get_tree().paused,
				MapScreen.scale_for(chapter.get("map")),
			]
		)
	)
	var player: Player = chapter.get("_player")
	var defeat: DefeatScreen = chapter.get_node("DefeatScreen")
	var start := player.global_position
	player.global_position = start + Vector2(80.0, 0.0)
	player.take_hit(99, Vector2.ZERO)
	print("DERROTA: vida %d, caído %s" % [player.health, player.get("_state") == Player.State.DEAD])
	await _frames(70)
	print("DERROTA: tela %s, jogo parado %s" % [defeat.visible, get_tree().paused])
	await _frames(60)
	await _press("Tentar de novo")
	await _frames(20)
	var again: Node = get_tree().current_scene
	var again_player: Player = again.get("_player")
	print(
		(
			"DERROTA: de novo: cena nova %s, capítulo %d, vida %d/%d, no início %s, jogo parado %s"
			% [
				again != chapter,
				again.get("data").number,
				again_player.health,
				again_player.max_health,
				again_player.global_position == start,
				get_tree().paused,
			]
		)
	)


## Treino: capítulo avulso, sem gravar, com as ferramentas dos dados, e a
## sala de teste.
## Ossinho dos inimigos: a cada 3 mortos na dungeon, o último deixa um ossinho
## que recupera vida ao ser tocado.
func _check_bone_drops() -> void:
	RunSettings.chapter = 1
	get_tree().change_scene_to_file(Flow.CHAPTER_SCENE)
	await _frames(20)
	var chapter: Node = get_tree().current_scene
	var player: Player = chapter.get("_player")
	player.take_hit(4, Vector2.ZERO)
	await _frames(2)
	var hurt := player.health
	var enemies: Array[Enemy] = []
	for node: Node in chapter.get("_objects").get_children():
		if node is Enemy and node.get("sword_factor") > 0 and enemies.size() < 3:
			enemies.append(node as Enemy)
	var counts := []
	for enemy: Enemy in enemies:
		enemy.global_position = player.global_position + Vector2(48.0, 0.0)
		enemy.take_hit(99, Vector2.ZERO, Hit.Kind.SWORD)
		await _frames(2)
		counts.append(_bones(chapter).size())
	var bones := _bones(chapter)
	if not bones.is_empty():
		player.global_position = (bones[0] as Node2D).global_position
	await _frames(6)
	print(
		(
			"OSSINHO: ossinhos após cada morte %s, vida %d -> %d de %d, pego %s"
			% [counts, hurt, player.health, player.max_health, _bones(chapter).is_empty()]
		)
	)


## Pular sobre um inimigo: no chão, o inimigo parado barra o caminho. No ar, o
## personagem passa por cima dele e cai do outro lado, sem perder vida.
func _check_jump_over() -> void:
	RunSettings.chapter = 1
	get_tree().change_scene_to_file(Flow.CHAPTER_SCENE)
	await _frames(20)
	var chapter: Node = get_tree().current_scene
	var player: Player = chapter.get("_player")
	var map: ChapterMap = chapter.get("map")
	var enemy: Enemy = null
	for node: Node in chapter.get("_objects").get_children():
		if node is Enemy and not node.get("hover"):
			enemy = node as Enemy
			break
	var cell := _floor_run(map, chapter.call("current_room"), 6)
	var start := (Vector2(cell) + Vector2(0.5, 0.5)) * float(ChapterMap.TILE)
	# O inimigo de outra sala está desligado. Liga a colisão e desliga o
	# movimento, para ele ficar parado no caminho.
	enemy.set_active(true)
	enemy.set_physics_process(false)
	enemy.velocity = Vector2.ZERO
	enemy.global_position = start + Vector2(40.0, 0.0)
	player.global_position = start
	player.velocity = Vector2.ZERO
	await _frames(2)
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	var blocked := player.global_position.x - start.x
	player.global_position = start
	player.velocity = Vector2.ZERO
	# Espera passar a janela da corrida: apertar a mesma direção logo depois
	# de soltar faria o personagem correr, e o teste é do pulo andando.
	await _frames(40)
	var health := player.health
	player.give_item(Item.Id.SPRING)
	Input.action_press("move_right")
	Input.action_press("jump")
	await _frames(2)
	Input.action_release("jump")
	await _frames(38)
	Input.action_release("move_right")
	await _frames(10)
	var jumped := player.global_position.x - start.x
	print(
		(
			"PULO: inimigo a 40 px, no chão parou a %.0f px, com o pulo foi a %.0f px, vida %d -> %d"
			% [blocked, jumped, health, player.health]
		)
	)


## Primeira casa de chão da sala com mais length - 1 casas de chão à direita.
func _floor_run(map: ChapterMap, room: Rect2i, length: int) -> Vector2i:
	var origin := room.position * Vector2i(20, 10)
	var size := room.size * Vector2i(20, 10)
	for y: int in range(origin.y + 1, origin.y + size.y - 1):
		for x: int in range(origin.x + 1, origin.x + size.x - length):
			var free := true
			for i: int in length:
				if map.tile(Vector2i(x + i, y)) != ".":
					free = false
					break
			if free:
				return Vector2i(x, y)
	return Vector2i(-1, -1)


func _bones(chapter: Node) -> Array:
	var bones := []
	for node: Node in chapter.get("_floor_effects").get_children():
		if node is BoneDrop:
			bones.append(node)
	return bones


func _check_training() -> void:
	get_tree().change_scene_to_file(Flow.TRAINING_SCENE)
	await _frames(20)
	print("TREINO: -> ", _scene_name())
	await _press("Capítulo 2")
	await _frames(10)
	var chapter: Node = get_tree().current_scene
	var player: Player = chapter.get("_player")
	print(
		(
			"TREINO: capítulo 2 -> %s, contínuo %s, chama %s, chama forte %s, vida %d"
			% [
				_scene_name(),
				Progress.active,
				player.has_tool(Item.Id.FIRE),
				player.has_tool(Item.Id.STRONG_FIRE),
				player.max_health,
			]
		)
	)
	get_tree().change_scene_to_file(Flow.TEST_ROOM_SCENE)
	await _frames(20)
	print("TREINO: sala de teste -> ", _scene_name())


## Tutorial: o antigo capítulo 1, avulso, a partir do treino, sem gravar.
func _check_tutorial() -> void:
	get_tree().change_scene_to_file(Flow.TRAINING_SCENE)
	await _frames(10)
	await _press("Dungeon de teste")
	await _frames(10)
	var chapter: Node = get_tree().current_scene
	var player: Player = chapter.get("_player")
	print(
		(
			"TUTORIAL: -> %s, nome %s, contínuo %s, bomba %s"
			% [
				_scene_name(),
				chapter.call("mode_text"),
				Progress.active,
				player.has_tool(Item.Id.BOMB)
			]
		)
	)


## Continuar: o jogo salvo volta ao mundo com os capítulos vencidos.
func _check_continue() -> void:
	# Não há arquivo de salvamento: a volta ao mundo usa o estado da sessão.
	Progress.return_entrance = Progress.NO_ENTRANCE
	get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)
	await _frames(20)
	var modes := []
	for chapter: int in range(1, ChapterData.count() + 1):
		var entrance := _entrance(chapter)
		modes.append(entrance.mode if entrance else -1)
	print(
		(
			"CONTINUAR: -> %s, vencidos %d, modos %s, vida %d"
			% [_scene_name(), Progress.chapters_done, modes, Progress.max_health]
		)
	)


## A dungeon de teste a partir do mundo: o jogo novo começa na clareira do
## sul, com as placas de mensagem no chão, a entrada 0 leva à dungeon de teste
## como treino (sem as ferramentas nem a vida do jogo), a placa de mensagem
## mostra o texto só com o personagem em cima e sem parar o jogo, e vencer
## grava a dungeon como vencida sem mudar ferramentas nem vida.
func _check_practice() -> void:
	Progress.start_new()
	Progress.tools = Item.bit(Item.Id.BOMB)
	Progress.max_health = 10
	get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)
	await _frames(10)
	var world: Node = get_tree().current_scene
	var player: Player = world.get("_player")
	var world_map: ChapterMap = world.get("map")
	var start := (Vector2(world_map.find("@")) + Vector2(0.5, 0.5)) * ChapterMap.TILE
	var world_plates: Array = world.get("_plates")
	print(
		(
			"TESTE: jogo novo no início %s, placas no mundo %d, entrada 0 modo %d"
			% [
				player.global_position.distance_to(start) < 4.0,
				world_plates.size(),
				_entrance(0).mode
			]
		)
	)
	await _walk_into(_entrance(0), player)
	await _frames(20)
	var chapter: Node = get_tree().current_scene
	player = chapter.get("_player")
	print(
		(
			"TESTE: entrada 0 -> %s, %s, treino %s, bomba %s, vida %d"
			% [
				_scene_name(),
				chapter.call("mode_text"),
				Progress.practice,
				player.has_tool(Item.Id.BOMB),
				player.max_health,
			]
		)
	)
	var plates: Array[MessagePlate] = []
	for node: Node in chapter.get("_switches").get_children():
		if node is MessagePlate:
			plates.append(node)
	var empty := 0
	for plate: MessagePlate in plates:
		if plate.text.is_empty():
			empty += 1
	var plate := plates[0]
	player.global_position = plate.global_position
	await _frames(MessagePlate.FADE_TICKS + 5)
	var shown: bool = plate.get("_shown") == MessagePlate.FADE_TICKS
	var running := not get_tree().paused
	player.global_position = plate.global_position + Vector2(0.0, 64.0)
	await _frames(MessagePlate.FADE_TICKS + 5)
	print(
		(
			"TESTE: placas %d, sem texto %d, em cima mostra %s, jogo solto %s, ao sair some %s"
			% [plates.size(), empty, shown, running, plate.get("_shown") == 0]
		)
	)
	await _play(ChapterData.TUTORIAL)
	await _frames(60)
	await _press("Voltar ao mundo")
	world = get_tree().current_scene
	player = world.get("_player")
	var entrance := _entrance(0)
	print(
		(
			"TESTE: vencida %s, -> %s, na entrada %s, ferramentas %d, vida %d, modo %d"
			% [
				Progress.is_done(ChapterData.TUTORIAL),
				_scene_name(),
				entrance != null and player.global_position == entrance.exit_position(),
				Progress.tools,
				Progress.max_health,
				entrance.mode if entrance else -1,
			]
		)
	)


## A lógica do jogo repete a do conferidor: as esferas de cada capítulo
## linear, com todas as portas abertas, têm de ser as que
## tools/check_chapter.py imprime.
func _check_logic() -> void:
	for chapter: int in range(0, ChapterData.count() + 1):
		var data := ChapterData.load_number(chapter)
		var logic := ChapterLogic.new(data)
		var tools := 0
		for id: int in data.starting_tools:
			tools |= Item.bit(id)
		var spheres: Array[String] = []
		for sphere: Array in logic.spheres(data.items, tools):
			spheres.append(",".join(PackedStringArray(sphere)))
		print(
			(
				"LÓGICA: capítulo %d esferas %s, vencível %s"
				% [chapter, " | ".join(spheres), logic.is_beatable(data.items, tools)]
			)
		)


## O modo randomizado: a mesma seed dá a mesma distribuição, cada seed tem as
## cinco ferramentas, o menu leva à seed, as três entradas abrem, um baú
## aberto fica gravado na hora e volta aberto, e continuar carrega a seed.
func _check_randomized() -> void:
	var first := Randomizer.generate(123456)
	var again := Randomizer.generate(123456)
	var other := Randomizer.generate(7)
	print("SEED: 123456 -> %s" % Randomizer.describe(first))
	print("SEED: 7 -> %s" % Randomizer.describe(other))
	var first_spring := Item.progressive(0, Item.Id.STRONG_SPRING)
	var both := Item.collect(Item.collect(0, Item.Id.STRONG_SPRING), Item.Id.STRONG_SPRING)
	print(
		(
			"ITENS: mola forte antes da mola vira %s, duas molas fortes dão mola e mola forte %s"
			% [
				Item.Id.keys()[first_spring],
				Item.has(both, Item.Id.SPRING) and Item.has(both, Item.Id.STRONG_SPRING),
			]
		)
	)
	print(
		(
			"SEED: igual de novo %s, diferente da 7 %s"
			% [Randomizer.describe(first) == Randomizer.describe(again), first != other]
		)
	)
	get_tree().change_scene_to_file(Flow.TITLE_SCENE)
	await _frames(10)
	await _press("Randomizado")
	var field: SeedField = null
	for node: Node in get_tree().current_scene.find_children("*", "SeedField", true, false):
		field = node as SeedField
	field.value = 123456
	await _press("Jogar")
	await _frames(10)
	var modes := []
	for chapter: int in range(1, ChapterData.count() + 1):
		var entrance := _entrance(chapter)
		modes.append(entrance.mode if entrance else -1)
	print(
		(
			"SEED: jogar -> %s, seed %d, contínuo %s, modos %s"
			% [_scene_name(), Progress.seed, Progress.active, modes]
		)
	)
	var player: Player = get_tree().current_scene.get("_player")
	await _walk_into(_entrance(3), player)
	var chapter: Node = get_tree().current_scene
	player = chapter.get("_player")
	var chest: Chest = null
	for candidate: Chest in chapter.get("_chests"):
		if candidate.item in Randomizer.PROGRESSION or candidate.item == Item.Id.HEART:
			chest = candidate
			break
	var location := chest.location_id
	var item_name: String = Item.Id.keys()[chest.item]
	player.global_position = chest.global_position + Vector2(0, 28)
	await _frames(4)
	chest.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
	await _frames(4)
	var recorded := Progress.was_opened(3, location)
	Flow.leave_chapter(get_tree())
	await _frames(10)
	player = get_tree().current_scene.get("_player")
	await _walk_into(_entrance(3), player)
	chapter = get_tree().current_scene
	var reopened := false
	for candidate: Chest in chapter.get("_chests"):
		if candidate.location_id == location:
			reopened = candidate.is_open
	print(
		(
			"SEED: capítulo 3 baú %s=%s gravado %s, de volta aberto %s, ferramentas %d"
			% [location, item_name, recorded, reopened, Progress.tools]
		)
	)
	# Não há arquivo de salvamento: a volta ao mundo usa o estado da sessão.
	Progress.return_entrance = Progress.NO_ENTRANCE
	get_tree().change_scene_to_file(Flow.OVERWORLD_SCENE)
	await _frames(20)
	print(
		(
			"SEED: continuar -> %s, seed %d, mesma distribuição %s"
			% [
				_scene_name(),
				Progress.seed,
				Randomizer.describe(Progress.seed_items) == Randomizer.describe(first)
			]
		)
	)


func _play(chapter_number: int) -> void:
	get_tree().paused = false
	RunSettings.chapter = chapter_number
	get_tree().change_scene_to_file(Flow.CHAPTER_SCENE)
	await _frames(20)
	var chapter: Node = get_tree().current_scene
	print("--- capítulo %d: %s" % [chapter_number, chapter.call("mode_text")])
	var player: Player = chapter.get("_player")
	var map: ChapterMap = chapter.get("map")
	# Baús: encosta e dá a espada em cada um.
	var opened := 0
	for chest: Chest in chapter.get("_chests"):
		player.global_position = chest.global_position + Vector2(0, 28)
		await _frames(4)
		chest.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
		await _frames(4)
		if chest.is_open:
			opened += 1
	print("baús abertos: %d/%d  chaves: %d" % [opened, chapter.get("_chests").size(), player.keys])
	for id: int in Item.PERMANENT:
		player.give_item(id)
	for _i: int in 8:
		player.give_item(Item.Id.KEY)
	# Portas: encosta em cada uma pelo sul e pelo norte.
	var doors := 0
	for obstacle: Node in chapter.get("_obstacles").get_children():
		if obstacle is LockedDoor:
			var door := obstacle as LockedDoor
			for side: Vector2 in [
				Vector2(door.size.x / 2.0, door.size.y + 10.0), Vector2(door.size.x / 2.0, -6.0)
			]:
				player.global_position = door.global_position + side
				await _frames(6)
			if door.opened:
				doors += 1
	print("portas abertas: %d" % doors)
	# Grades: o personagem em cima do interruptor abre as grades da sala só
	# enquanto fica ali, e o bloco pesado travado nele abre de vez.
	var room_switches: Dictionary = (chapter as Chapter).gates.room_switches
	var room_gates: Dictionary = (chapter as Chapter).gates.room_gates
	var gates_total := 0
	var gates_by_player := 0
	var gates_closed_again := 0
	var gates_by_block := 0
	var blocks_locked := 0
	for room: Rect2i in room_switches:
		var gates: Array = room_gates.get(room, [])
		gates_total += gates.size()
		var switch: FloorSwitch = room_switches[room][0]
		player.global_position = switch.global_position
		await _frames(4)
		for gate: SwitchDoor in gates:
			if gate.open:
				gates_by_player += 1
		player.global_position = switch.global_position + Vector2(0.0, 20.0)
		await _frames(4)
		for gate: SwitchDoor in gates:
			if not gate.open:
				gates_closed_again += 1
		var block: HeavyBlock = null
		for node: Node in chapter.get("_objects").get_children():
			if node is HeavyBlock and not (node as HeavyBlock).locked:
				var candidate := node as HeavyBlock
				var closer := (
					not block
					or (
						candidate.global_position.distance_to(switch.global_position)
						< block.global_position.distance_to(switch.global_position)
					)
				)
				if closer:
					block = candidate
		if block:
			block.global_position = switch.global_position + FloorSwitch.BLOCK_OFFSET
			await _frames(4)
			if block.locked:
				blocks_locked += 1
		for gate: SwitchDoor in gates:
			if gate.open:
				gates_by_block += 1
	print("interruptores: %d  grades: %d" % [room_switches.size(), gates_total])
	print(
		(
			"grades: pelo personagem %d  fechadas ao sair %d  blocos travados %d  pelo bloco %d"
			% [gates_by_player, gates_closed_again, blocks_locked, gates_by_block]
		)
	)
	# Cada sala com atores: o personagem entra e usa tudo.
	var rooms: Dictionary = (chapter as Chapter).rooms.actors
	for room: Rect2i in rooms:
		var cell := _floor_cell(map, room)
		if cell == Vector2i(-1, -1):
			print("sala sem chão livre: ", room)
			continue
		player.global_position = (Vector2(cell) + Vector2(0.5, 0.5)) * ChapterMap.TILE
		await _frames(10)
		for step: int in 16:
			var action: String = ACTIONS[step % ACTIONS.size()]
			Input.action_press(action)
			await _frames(4)
			Input.action_release(action)
			await _frames(4)
		for actor: Node in rooms[room]:
			if actor is Boss and is_instance_valid(actor):
				await _beat_boss(actor as Boss)
		player.health = player.max_health
	await _frames(30)
	var relic: Node = null
	for node: Node in chapter.get("_objects").get_children():
		if node is Relic:
			relic = node
	if relic:
		player.global_position = relic.global_position
		await _frames(20)
	print(
		(
			"terminou: %s  fim: %s  salas visitadas: %d  tempo total: %s"
			% [
				chapter.get("finished"),
				chapter.get("_end_screen").visible,
				chapter.call("visited_rooms").size(),
				GameMath.time_text(Progress.run_ticks),
			]
		)
	)


func _beat_boss(boss: Boss) -> void:
	var kinds := [
		Hit.Kind.BLAST,
		Hit.Kind.FIRE,
		Hit.Kind.STRONG_FIRE,
		Hit.Kind.SWORD,
		Hit.Kind.SWORD,
		Hit.Kind.BLAST,
	]
	var guard := 0
	while boss.health > 0 and guard < 400:
		for kind: int in kinds:
			boss.take_hit(1, Vector2.DOWN, kind)
			await _frames(2)
		guard += 1
	print("chefe %s vencido: %s (vida %d)" % [boss.name, boss.health <= 0, boss.health])


## Casa de chão mais perto do centro da sala, que pode ter mais de uma tela.
func _floor_cell(map: ChapterMap, room: Rect2i) -> Vector2i:
	var center := (room.position * 2 + room.size) * Vector2i(20, 10) / 2
	for radius: int in 20:
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				var cell := center + Vector2i(dx, dy)
				if map.tile(cell) in [".", ":", "^"]:
					return cell
	return Vector2i(-1, -1)


## Barramentos, um arquivo para cada efeito da tabela, nenhum arquivo sobrando
## e a música local, se houver.
func _check_audio() -> void:
	var buses := [AudioServer.get_bus_index(&"Music"), AudioServer.get_bus_index(&"Sfx")]
	print("ÁUDIO: barramentos Music e Sfx em ", buses)
	var sfx: Node = get_tree().root.get_node("Sfx")
	var sounds: Dictionary = sfx.get("SOUNDS")
	var streams: Dictionary = sfx.get("_streams")
	var missing := []
	for sound: StringName in sounds:
		if streams.get(sound) == null:
			missing.append(sound)
	var extra := []
	for file: String in ResourceLoader.list_directory("res://audio/sfx"):
		if file.ends_with(".wav") and not sounds.has(StringName(file.get_basename())):
			extra.append(file)
	print("ÁUDIO: %d efeitos, sem arquivo: %s, sem uso: %s" % [sounds.size(), missing, extra])
	var music: AudioStreamPlayer = get_tree().root.get_node("Music").get("_player")
	var track := music.stream.resource_path if music.stream else "<nenhuma>"
	print("ÁUDIO: música %s, tocando: %s" % [track, music.playing])
