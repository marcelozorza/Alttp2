class_name MomentumBody
extends CharacterBody2D
## Corpo com massa e momento, movido em passo fixo.
##
## Ao bater em algo, troca momento com ele ao longo da normal de contato.
## Paredes e corpos que não são MomentumBody contam como massa infinita.
##
## Abaixo de bounce_threshold, a batida é inelástica: contra uma parede o corpo
## só para, e contra outro corpo os dois seguem juntos, o que permite empurrar.
## Acima, a restituição devolve parte da velocidade, e o corpo ricocheteia.
## Contra algo mais leve, o outro corpo vai embora. Contra algo mais pesado ou
## uma parede, o corpo volta. Um ricochete acima de BUMP_SOUND_SPEED faz o
## som da batida.

## Velocidade de afastamento, em pixels por segundo, a partir da qual a batida
## soa.
const BUMP_SOUND_SPEED := 100.0

@export_group("Física")
## Massa. O personagem tem massa 1, e os objetos são medidos em relação a ele.
@export_range(0.1, 20.0, 0.1) var mass := 1.0
## Fração da velocidade devolvida numa batida forte. 1 devolve a mesma força.
## Numa batida entre dois corpos, vale o produto das duas restituições.
@export_range(0.0, 1.0, 0.05) var restitution := 1.0
## Velocidade mínima de batida, em pixels por segundo, para haver ricochete.
@export_range(0.0, 800.0, 1.0) var bounce_threshold := 240.0
## Desaceleração quando o corpo se move sem controle, em pixels por segundo
## ao quadrado.
@export_range(0.0, 6000.0, 10.0) var friction := 1200.0


## Calcula a troca de momento entre um corpo A que se move e um corpo B em que
## ele bateu. normal aponta de B para A, como em KinematicCollision2D. Devolve
## as variações de velocidade de A e de B, nessa ordem.
static func exchange(
	velocity_a: Vector2,
	mass_a: float,
	velocity_b: Vector2,
	mass_b: float,
	normal: Vector2,
	restitution_ab: float,
	threshold: float
) -> PackedVector2Array:
	var into := -normal
	var a := velocity_a.dot(into)
	var b := velocity_b.dot(into)
	var approach := a - b
	if approach <= 0.0:
		return PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	var e := restitution_ab if approach >= threshold else 0.0
	var a_after := b - e * approach
	var b_after := b
	if not is_inf(mass_b):
		var momentum := mass_a * a + mass_b * b
		a_after = (momentum - mass_b * e * approach) / (mass_a + mass_b)
		b_after = (momentum + mass_a * e * approach) / (mass_a + mass_b)
	return PackedVector2Array([into * (a_after - a), into * (b_after - b)])


## Recebe a variação de velocidade de uma batida causada por outro corpo.
func add_impact_velocity(delta_velocity: Vector2) -> void:
	velocity += delta_velocity


## Move com move_and_slide e resolve as batidas desse movimento.
func move_with_impacts() -> void:
	var pre_velocity := velocity
	move_and_slide()
	var change := Vector2.ZERO
	var rebound := 0.0
	var handled: Array[Object] = []
	for i: int in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var other := collision.get_collider()
		if other in handled:
			continue
		handled.append(other)
		var body := other as MomentumBody
		var normal := collision.get_normal()
		var deltas := exchange(
			pre_velocity,
			mass,
			body.velocity if body else Vector2.ZERO,
			body.mass if body else INF,
			normal,
			restitution * (body.restitution if body else 1.0),
			bounce_threshold
		)
		if body:
			body.add_impact_velocity(deltas[1])
		change += deltas[0]
		rebound = maxf(rebound, (pre_velocity + deltas[0]).dot(normal))
	if not handled.is_empty():
		if rebound > BUMP_SOUND_SPEED:
			Sfx.play(&"bump")
		_on_impacts(pre_velocity + change, rebound)


## Chamado depois das batidas de um movimento, com a velocidade resultante e a
## maior velocidade de afastamento das superfícies atingidas.
func _on_impacts(new_velocity: Vector2, _rebound: float) -> void:
	velocity = new_velocity
