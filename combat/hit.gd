class_name Hit
## Tipos de golpe. Cada alvo decide como reage a cada tipo, e é isso que faz
## cada ferramenta servir para umas coisas e não para outras.
##
## A chama forte é um fogo mais quente: tudo o que o fogo comum afeta, ela
## afeta também, e ainda derrete o gelo grosso, que o fogo comum só faz tremer.
## A explosão forte, da bomba forte, segue a mesma regra: faz tudo o que a
## explosão comum faz e ainda abre a parede rachada com tábua.

enum Kind { SWORD, FIRE, STRONG_FIRE, BLAST, SHOCKWAVE, STRONG_BLAST }


## Diz se o golpe é fogo, comum ou forte.
static func is_fire(kind: Kind) -> bool:
	return kind == Kind.FIRE or kind == Kind.STRONG_FIRE


## Diz se o golpe é explosão, comum ou forte.
static func is_blast(kind: Kind) -> bool:
	return kind == Kind.BLAST or kind == Kind.STRONG_BLAST


## Multiplicador de dano de um alvo para o tipo de golpe, a partir dos
## multiplicadores dele. A onda de choque nunca fere inimigos, e a explosão
## forte causa o dobro da comum.
static func factor(kind: Kind, sword: int, fire: int, strong_fire: int, blast: int) -> int:
	match kind:
		Kind.FIRE:
			return fire
		Kind.STRONG_FIRE:
			return strong_fire
		Kind.BLAST:
			return blast
		Kind.STRONG_BLAST:
			return blast * 2
		Kind.SHOCKWAVE:
			return 0
	return sword


## Personagem dentro da área de ataque de um corpo, ou null: a base do corpo
## com uma margem de 4 px em volta. Serve para o bote dos inimigos e a
## investida dos chefes. Com dodged_in_air, o personagem no ar não conta: o
## bote de um inimigo comum passa por baixo dele. A investida de um chefe
## acerta de qualquer jeito.
static func player_in_reach(
	body: PhysicsBody2D, base: CollisionShape2D, reach: RectangleShape2D, dodged_in_air := true
) -> Player:
	var base_shape := base.shape as RectangleShape2D
	reach.size = base_shape.size + Vector2(8.0, 8.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = reach
	query.transform = Transform2D(0.0, base.global_position)
	var excluded: Array[RID] = [body.get_rid()]
	query.exclude = excluded
	for result: Dictionary in body.get_world_2d().direct_space_state.intersect_shape(query):
		var target := result["collider"] as Player
		if target and not (dodged_in_air and target.is_airborne()):
			return target
	return null
