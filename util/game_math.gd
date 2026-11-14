class_name GameMath
## Utilitários compartilhados pelo personagem, pelas armas e pelos inimigos.


## Reduz um vetor a uma das 8 direções, com as diagonais normalizadas.
static func snap_8(vector: Vector2) -> Vector2:
	if vector == Vector2.ZERO:
		return vector
	var angle := snappedf(vector.angle(), PI / 4.0)
	return Vector2(roundf(cos(angle)), roundf(sin(angle))).normalized()


## Converte segundos em ticks de física. Todos os tempos de jogo são contados
## em ticks, para que o resultado não dependa da taxa de quadros.
static func ticks(seconds: float) -> int:
	return roundi(seconds * Engine.physics_ticks_per_second)


## Tempo de jogo no formato minutos:segundos.centésimos, a partir de ticks.
static func time_text(ticks: int) -> String:
	var seconds := float(ticks) / Engine.physics_ticks_per_second
	var minutes := floori(seconds / 60.0)
	return "%02d:%05.2f" % [minutes, seconds - minutes * 60.0]
