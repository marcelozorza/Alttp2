extends Node
## Teste de fumaça, rodado pelo Godot sem tela:
##
##     godot --headless --path . --import
##     godot --headless --path . res://tools/smoke_test.tscn
##
## Roda como cena, e não com -s, porque só assim os autoloads Music e Sfx
## existem. O teste fica na raiz e põe outro nó como cena atual, para que as
## trocas de cena não o apaguem.
##
## Confere o áudio (barramentos, os arquivos de cada efeito e a música local,
## se houver), o menu com o botão A e o Start do controle e cada capítulo:
## abre os baús, ganha todas as ferramentas, encosta nas portas, entra em cada
## sala usando os botões, vence o chefe e toca a relíquia. Qualquer erro de
## script aparece na saída como SCRIPT ERROR. Não muda nada no projeto.

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


func _run() -> void:
	var placeholder := Node.new()
	get_tree().root.add_child(placeholder)
	get_tree().current_scene = placeholder
	# Menu: o A do controle precisa iniciar o capítulo 1.
	get_tree().change_scene_to_file("res://ui/title_screen.tscn")
	await _frames(10)
	await _joy(JOY_BUTTON_A)
	await _frames(10)
	print("MENU: depois do A -> ", _scene_path())
	# Start também confirma.
	get_tree().change_scene_to_file("res://ui/title_screen.tscn")
	await _frames(10)
	await _joy(JOY_BUTTON_START)
	await _frames(10)
	print("MENU: depois do Start -> ", _scene_path())

	_check_audio()

	for chapter: int in range(1, ChapterData.count() + 1):
		await _play(chapter)
	print("FIM DO TESTE")
	# Sons tocando no fechamento deixam o Godot acusar recurso preso.
	get_tree().root.get_node("Music").get("_player").stop()
	for voice: Node in get_tree().root.get_node("Sfx").get_children():
		(voice as AudioStreamPlayer).stop()
	await _frames(10)
	get_tree().quit()


func _play(chapter_number: int) -> void:
	RunSettings.chapter = chapter_number
	get_tree().change_scene_to_file("res://world/chapter/chapter.tscn")
	await _frames(20)
	var chapter: Node = get_tree().current_scene
	print("--- capítulo %d: %s" % [chapter_number, chapter.call("mode_text")])
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
				Vector2(door.size.x / 2.0, door.size.y + 5.0), Vector2(door.size.x / 2.0, -3.0)
			]:
				player.global_position = door.global_position + side
				await _frames(6)
			if door.opened:
				doors += 1
	print("portas abertas: %d" % doors)
	# Cada sala com atores: o personagem entra e usa tudo.
	var rooms: Dictionary = chapter.get("_room_actors")
	for room: Rect2i in rooms:
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
	get_tree().paused = false


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
