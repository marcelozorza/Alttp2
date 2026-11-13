class_name Wind
## Faixa de vento do laboratório, usada pelo soprador (lab/blower.gd) e pelo
## ventilador (lab/fan.gd). O vento empurra o personagem sem ferir e carrega
## as bombas soltas no chão, o que leva uma bomba até onde não se chega a pé.

## Alcance e meia largura da faixa, em pixels.
const REACH := 240.0
const HALF_WIDTH := 30.0
## Velocidade do empurrão no personagem, em pixels por segundo. Abaixo da do
## andar: dá para avançar contra o vento, devagar.
const PUSH_SPEED := 150.0
## Velocidade com que o vento carrega uma bomba.
const BOMB_SPEED := 170.0
const COLOR := Color(0.85, 0.95, 1.0, 0.7)


## Diz se o ponto está na faixa que sai de origin na direção dada.
static func covers(origin: Vector2, direction: Vector2, point: Vector2) -> bool:
	var offset := point - origin
	var along := offset.dot(direction)
	var aside := absf(offset.dot(direction.orthogonal()))
	return along > 0.0 and along <= REACH and aside <= HALF_WIDTH


## Empurra o personagem e as bombas que estão na faixa.
static func push(tree: SceneTree, origin: Vector2, direction: Vector2, delta: float) -> void:
	var player := tree.get_first_node_in_group("player") as Player
	if player and not player.is_airborne() and covers(origin, direction, player.global_position):
		player.shove(direction * PUSH_SPEED * delta)
	for bomb: Bomb in tree.get_nodes_in_group("bombs"):
		if covers(origin, direction, bomb.global_position):
			bomb.velocity = direction * BOMB_SPEED


## Riscos de vento correndo pela faixa, a partir da origem do nó.
static func draw(canvas: CanvasItem, direction: Vector2) -> void:
	var side := direction.orthogonal()
	var phase := float(posmod(Clock.tick * 6, 48))
	for lane: float in [-18.0, 0.0, 18.0]:
		var start := 20.0 + phase
		while start < REACH:
			var from := direction * start + side * lane + Vector2(0.0, -10.0)
			canvas.draw_line(from, from + direction * 16.0, COLOR, 2.0)
			start += 48.0
