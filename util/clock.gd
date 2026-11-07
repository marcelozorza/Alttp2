extends Node
## Relógio do jogo, em ticks de física, carregado o tempo todo como autoload
## Clock. Para junto com o jogo pausado, ao contrário de
## Engine.get_physics_frames(), que segue contando. Todo tempo de jogo
## (invencibilidade, avisos dos inimigos, cargas, pavio da bomba, item sobre
## o baú) é contado por aqui, para que pausar não adiante nada e nenhum
## desses contadores estoure durante a pausa. Os sons usam o relógio do
## Godot, porque os do menu tocam com o jogo pausado.
##
## O autoload vem antes da cena na árvore, então o tick avança no começo de
## cada passo de física e todos os nós leem o mesmo valor dentro do passo.

## Ticks de física desde o início do jogo, sem contar o tempo pausado.
var tick := 0


func _physics_process(_delta: float) -> void:
	tick += 1
