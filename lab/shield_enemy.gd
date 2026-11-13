class_name ShieldEnemy
extends Enemy
## Escudeiro do laboratório: o golpe de espada que vem pela frente não o
## afeta. É preciso contornar e acertar de lado ou por trás, o que fica mais
## fácil enquanto ele descansa depois do bote, ou usar a bomba ou a chama,
## que o escudo não segura. O escudo aparece do lado para onde ele olha.
## Arte provisória.

const SHIELD_COLOR := Color(0.75, 0.8, 0.9)


func take_hit(amount: int, direction: Vector2, kind := Hit.Kind.SWORD) -> void:
	if kind == Hit.Kind.SWORD and not is_dead() and direction.dot(_look_direction) < -0.5:
		_immune_tick = Clock.tick
		Sfx.play(&"immune")
		return
	super(amount, direction, kind)


func _physics_process(delta: float) -> void:
	super(delta)
	queue_redraw()


func _draw() -> void:
	super()
	if is_dead():
		return
	var look := GameMath.snap_4(_look_direction)
	var center := Vector2(0.0, -12.0) + look * 14.0
	var half := Vector2(3.0, 12.0) if look.x != 0.0 else Vector2(12.0, 3.0)
	draw_rect(
		Rect2(center - half - Vector2.ONE * 2.0, half * 2.0 + Vector2.ONE * 4.0),
		DoorArt.OUTLINE_COLOR
	)
	draw_rect(Rect2(center - half, half * 2.0), SHIELD_COLOR)
