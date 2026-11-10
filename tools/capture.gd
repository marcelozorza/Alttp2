extends Node
## Captura de tela para conferir a arte sem jogar. Roda com um servidor de
## vídeo de mentira (xvfb), numa cópia do projeto fora do repositório:
##
##     xvfb-run -a godot --path . res://tools/capture.tscn -- overworld saida.png
##     ... -- chapter 2 saida.png
##     ... -- scene res://ui/title_screen.tscn saida.png
##
## "overworld" e "chapter" mostram o mapa inteiro numa imagem só, com a câmera
## do jogo desligada. "scene" mostra a tela como o jogador a vê, em 640x360.
## O capítulo -1 é a Galeria.

const WAIT_FRAMES := 20


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var kind: String = args[0]
	var output: String = args[args.size() - 1]
	var path := Flow.OVERWORLD_SCENE
	if kind == "chapter":
		RunSettings.chapter = int(args[1])
		path = Flow.CHAPTER_SCENE
	elif kind == "scene":
		path = args[1]
	var scene: Node = (load(path) as PackedScene).instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	await _frames(3)
	if kind != "scene":
		_show_whole_map(scene)
	await _frames(WAIT_FRAMES)
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png(output)
	print("CAPTURA: ", output)
	get_tree().quit()


## Abre a janela no tamanho do mapa e põe uma câmera própria no centro dele.
func _show_whole_map(scene: Node) -> void:
	var map: ChapterMap = scene.get("map")
	var size := Vector2i(map.width, map.height) * ChapterMap.TILE
	var window := get_tree().root
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	window.size = size
	var camera := Camera2D.new()
	camera.position = Vector2(size) / 2.0
	scene.add_child(camera)
	camera.make_current()
	for child: Node in scene.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false


func _frames(n: int) -> void:
	for _i: int in n:
		await get_tree().physics_frame
