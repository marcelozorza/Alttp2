extends SceneTree
## Teste de fumaça, rodado pelo Godot sem tela:
##
##     godot --headless --path . --import
##     godot --headless --path . -s res://tools/smoke_test.gd
##
## Confere o menu com o botão A e o Start do controle, o tempo do sorteio de
## seeds e cada capítulo, linear e com seed: abre os baús, ganha todas as
## ferramentas, encosta nas portas, entra em cada sala usando os botões, vence
## o chefe e toca a relíquia. Qualquer erro de script aparece na saída como
## SCRIPT ERROR. Não muda nada no projeto.

const ACTIONS := [
	"attack", "use_fire", "use_bomb", "jump", "move_left", "move_right", "move_up", "move_down"
]


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i: int in n:
		await physics_frame


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
	return current_scene.scene_file_path if current_scene else "<nenhuma>"


func _run() -> void:
	# Menu: o A do controle precisa iniciar o capítulo 1 linear.
	change_scene_to_file("res://ui/title_screen.tscn")
	await _frames(10)
	await _joy(JOY_BUTTON_A)
	await _frames(10)
	print("MENU: depois do A -> ", _scene_path())
	# Start também confirma.
	change_scene_to_file("res://ui/title_screen.tscn")
	await _frames(10)
	await _joy(JOY_BUTTON_START)
	await _frames(10)
	print("MENU: depois do Start -> ", _scene_path())

	# Tempo do sorteio de seeds.
	for chapter: int in [1, 2]:
		var data := ChapterData.load_number(chapter)
		var map := ChapterMap.new(data.rows, data.blocks)
		var worst := 0
		var total := 0
		for i: int in 20:
			var t := Time.get_ticks_usec()
			var dist := Randomizer.shuffled(map, data.linear, 1000 + i, data.goal, data.goal_tools)
			var dt := Time.get_ticks_usec() - t
			worst = maxi(worst, dt)
			total += dt
			if not map.is_beatable(dist, data.goal, data.goal_tools):
				print("SEED INVÁLIDA cap ", chapter, " seed ", 1000 + i)
		print(
			(
				"SORTEIO cap %d: média %.1f ms, pior %.1f ms"
				% [chapter, total / 20000.0, worst / 1000.0]
			)
		)
		print(
			(
				"LINEAR cap %d vencível: %s"
				% [chapter, map.is_beatable(data.linear, data.goal, data.goal_tools)]
			)
		)

	for chapter: int in [1, 2]:
		for randomized: bool in [false, true]:
			await _play(chapter, randomized)
	print("FIM DO TESTE")
	quit()


func _play(chapter_number: int, randomized: bool) -> void:
	RunSettings.chapter = chapter_number
	RunSettings.randomized = randomized
	RunSettings.run_seed = 424242 + chapter_number
	change_scene_to_file("res://world/chapter/chapter.tscn")
	await _frames(20)
	var chapter: Node = current_scene
	print(
		(
			"--- capítulo %d %s: %s"
			% [chapter_number, "seed" if randomized else "linear", chapter.call("mode_text")]
		)
	)
	var player: Player = chapter.get("_player")
	var map: ChapterMap = chapter.get("map")
	# Baús: encosta e dá a espada em cada um.
	var opened := 0
	for chest: Chest in chapter.get("_chests"):
		player.global_position = chest.global_position + Vector2(0, 14)
		await _frames(4)
		chest.take_hit(1, Vector2.UP, Hit.Kind.SWORD)
		await _frames(4)
		if chest.is_open:
			opened += 1
	print("baús abertos: %d/%d  chaves: %d" % [opened, chapter.get("_chests").size(), player.keys])
	for id: int in [Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING, Item.Id.BOSS_KEY]:
		player.give_item(id)
	for _i: int in 8:
		player.give_item(Item.Id.KEY)
	# Portas: encosta em cada uma pelo sul e pelo norte.
	var doors := 0
	for obstacle: Node in chapter.get("_obstacles").get_children():
		if obstacle is LockedDoor:
			var door := obstacle as LockedDoor
			for side: Vector2 in [
				Vector2(door.size.x / 2.0, door.size.y + 5.0), Vector2(door.size.x / 2.0, -3.0)
			]:
				player.global_position = door.global_position + side
				await _frames(6)
			if door.opened:
				doors += 1
	print("portas abertas: %d" % doors)
	# Cada sala com atores: o personagem entra e usa tudo.
	var rooms: Dictionary = chapter.get("_room_actors")
	for room: Vector2i in rooms:
		var cell := _floor_cell(map, room)
		if cell == Vector2i(-1, -1):
			print("sala sem chão livre: ", room)
			continue
		player.global_position = (Vector2(cell) + Vector2(0.5, 0.5)) * 16.0
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
	print("terminou: %s  fim: %s" % [chapter.get("finished"), chapter.get("_end_screen").visible])
	paused = false


func _beat_boss(boss: Boss) -> void:
	var kinds := [Hit.Kind.BLAST, Hit.Kind.FIRE, Hit.Kind.SWORD, Hit.Kind.SWORD, Hit.Kind.BLAST]
	var guard := 0
	while boss.health > 0 and guard < 400:
		for kind: int in kinds:
			boss.take_hit(1, Vector2.DOWN, kind)
			await _frames(2)
		guard += 1
	print("chefe %s vencido: %s (vida %d)" % [boss.name, boss.health <= 0, boss.health])


func _floor_cell(map: ChapterMap, room: Vector2i) -> Vector2i:
	var origin := room * Vector2i(20, 10)
	for radius: int in 10:
		for dy: int in range(-radius, radius + 1):
			for dx: int in range(-radius, radius + 1):
				var cell := origin + Vector2i(10 + dx, 5 + dy)
				if map.tile(cell) == "." or map.tile(cell) == ":":
					return cell
	return Vector2i(-1, -1)
