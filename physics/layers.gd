class_name Layers
## Camadas de colisão do jogo.
##
## Tudo o que é sólido no chão fica em SCENERY: paredes, blocos, baús, portas,
## bombas, chefes e o personagem com os pés no chão. Os inimigos comuns ficam
## em ENEMY, e o personagem no ar em AIR. Os inimigos veem SCENERY e ENEMY,
## nunca AIR, e o personagem no ar vê só SCENERY: assim ele passa por cima
## dos inimigos, e só deles (pedido de Marcelo em 2026-11-07). Os chefes veem
## as três camadas, porque ninguém pula por cima de um chefe.

const SCENERY := 1
const ENEMY := 2
const AIR := 4
## Disparos das torretas do laboratório (lab/bolt.gd). Ninguém colide com
## esta camada: ela existe para o golpe de espada achar o disparo e rebatê-lo.
const SHOT := 8
