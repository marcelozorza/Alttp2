class_name MapWalls
## Colisão das casas sólidas de um mapa em texto. Junta as casas de cada
## linha em trechos contínuos, uma forma de colisão por trecho, o que dá
## poucas formas mesmo num mapa grande.


static func build(map: ChapterMap, body: StaticBody2D, solid := "#") -> void:
	var tile := float(ChapterMap.TILE)
	for y: int in map.height:
		var x := 0
		while x < map.width:
			if not solid.contains(map.tile(Vector2i(x, y))):
				x += 1
				continue
			var start := x
			while x < map.width and solid.contains(map.tile(Vector2i(x, y))):
				x += 1
			var rectangle := RectangleShape2D.new()
			rectangle.size = Vector2((x - start) * tile, tile)
			var shape := CollisionShape2D.new()
			shape.shape = rectangle
			shape.position = Vector2((start + x) * tile / 2.0, (y + 0.5) * tile)
			body.add_child(shape)
