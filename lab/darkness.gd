class_name Darkness
extends CanvasLayer
## Salas escuras do laboratório (DARK_ROOMS nos dados do capítulo). Nelas a
## tela fica preta, menos um círculo em volta do personagem e um maior em
## volta de cada tocha acesa da sala. Acender as tochas mostra o caminho. O
## HUD fica por cima da escuridão. Arte provisória.

const SHADER := preload("res://lab/darkness.gdshader")
const PLAYER_RADIUS := 78.0
const TORCH_RADIUS := 150.0
const MAX_LIGHTS := 6

## Salas escuras, as chaves de um dicionário de Rect2i.
var rooms := {}

var _cover := ColorRect.new()
var _material := ShaderMaterial.new()


func _ready() -> void:
	_material.shader = SHADER
	_cover.material = _material
	_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.visible = false
	add_child(_cover)


func _process(_delta: float) -> void:
	var chapter := get_tree().get_first_node_in_group("chapter") as Chapter
	var player := get_tree().get_first_node_in_group("player") as Player
	var dark := chapter != null and player != null and rooms.has(chapter.current_room())
	_cover.visible = dark
	if not dark:
		return
	var to_screen := chapter.get_viewport().get_canvas_transform()
	var points: Array[Vector2] = [to_screen * (player.global_position + Vector2(0.0, -14.0))]
	var radii: Array[float] = [PLAYER_RADIUS]
	for torch: LabTorch in get_tree().get_nodes_in_group("lab_torches"):
		if torch.lit and points.size() < MAX_LIGHTS:
			if chapter.rooms.of_point(torch.global_position) == chapter.current_room():
				points.append(to_screen * (torch.global_position + Vector2(0.0, -14.0)))
				radii.append(TORCH_RADIUS)
	var count := points.size()
	while points.size() < MAX_LIGHTS:
		points.append(Vector2.ZERO)
		radii.append(0.0)
	_material.set_shader_parameter("screen_size", _cover.size)
	_material.set_shader_parameter("lights", PackedVector2Array(points))
	_material.set_shader_parameter("radii", PackedFloat32Array(radii))
	_material.set_shader_parameter("count", count)
