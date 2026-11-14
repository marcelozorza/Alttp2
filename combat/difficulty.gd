class_name Difficulty
## Ajustes gerais de dificuldade da versão de celular, pedidos por Marcelo em
## 2026-11-14 depois de jogar o primeiro APK ("está desagradável de jogar").
## Valem para todos os inimigos e chefes, por cima dos números de cada um.

## Multiplica todo dano que o Giorgino recebe: metade.
const DAMAGE_TAKEN := 0.5
## Multiplica a velocidade do bote dos inimigos e da investida dos chefes:
## 25% mais lentos. O tempo do bote cresce na mesma proporção, para o
## alcance continuar o mesmo e o bote ficar só mais fácil de ver e desviar.
const LUNGE_SPEED := 0.75


## Velocidade do bote com o ajuste.
static func lunge_speed(speed: float) -> float:
	return speed * LUNGE_SPEED


## Duração do bote com o ajuste, em ticks.
static func lunge_ticks(seconds: float) -> int:
	return GameMath.ticks(seconds / LUNGE_SPEED)
