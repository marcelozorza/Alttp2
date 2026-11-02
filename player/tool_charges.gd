class_name ToolCharges
extends RefCounted
## Cargas de uma ferramenta, como a chama e a bomba. Cada uso gasta uma carga,
## e todas voltam juntas quando a ferramenta passa um tempo sem ser usada. Dá
## para usar várias em sequência, mas, depois de gastar todas, é preciso
## esperar.
##
## O máximo e o tempo de recarga chegam a cada chamada, para que os valores
## exportados no personagem possam ser ajustados com o jogo rodando.

var _spent := 0
var _last_use_tick := 0


## Cargas que restam, com o máximo atual.
func left(maximum: int) -> int:
	return maxi(maximum - _spent, 0)


## Gasta uma carga. Só deve ser chamada quando left() for maior que zero.
func spend(now: int) -> void:
	_spent += 1
	_last_use_tick = now


## Devolve todas as cargas quando a ferramenta fica recharge_ticks sem uso.
## Chamada uma vez por tick.
func recharge(now: int, recharge_ticks: int) -> void:
	if _spent > 0 and now - _last_use_tick >= recharge_ticks:
		_spent = 0


func refill() -> void:
	_spent = 0
