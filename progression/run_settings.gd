class_name RunSettings
## Escolhas da partida, guardadas entre a tela de título e o capítulo.

## Ligado, os baús seguem a seed. Desligado, seguem a distribuição linear.
static var randomized := false
## Seed da partida aleatória.
static var run_seed := 0


## Sorteia uma seed nova, de seis dígitos.
static func new_seed() -> int:
	return randi_range(100000, 999999)
