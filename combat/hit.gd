class_name Hit
## Tipos de golpe. Cada alvo decide como reage a cada tipo, e é isso que faz
## cada ferramenta servir para umas coisas e não para outras.
##
## A chama forte é um fogo mais quente: tudo o que o fogo comum afeta, ela
## afeta também, e ainda derrete o gelo grosso, que o fogo comum só faz tremer.

enum Kind { SWORD, FIRE, STRONG_FIRE, BLAST, SHOCKWAVE }


## Diz se o golpe é fogo, comum ou forte.
static func is_fire(kind: Kind) -> bool:
	return kind == Kind.FIRE or kind == Kind.STRONG_FIRE
