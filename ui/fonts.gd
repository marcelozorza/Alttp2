class_name Fonts
## As duas fontes de pixel do jogo, geradas por tools/art/font.py: a pequena,
## com maiúsculas de 7 pixels, e a grande, o dobro. São fontes de tamanho
## fixo: o tamanho pedido só escolhe uma das duas.

const SMALL := preload("res://ui/font/giorgino.fnt")
const BIG := preload("res://ui/font/giorgino_big.fnt")
## Tamanho de fonte a partir do qual vale a grande.
const BIG_FROM := 20
const SMALL_SIZE := 12
const BIG_SIZE := 24


static func for_size(font_size: int) -> Font:
	return BIG if font_size >= BIG_FROM else SMALL


## Tamanho real da fonte escolhida para um tamanho pedido.
static func real_size(font_size: int) -> int:
	return BIG_SIZE if font_size >= BIG_FROM else SMALL_SIZE
