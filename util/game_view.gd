class_name GameView
## Área de jogo da versão de celular (decisões de Marcelo em 2026-11-14): um
## quadro fixo de 640x360, 16:9, com a largura de sala do Windows. Ele fica
## inteiro no meio da tela, e o que sobra dos lados num celular mais largo vira
## as faixas opacas do HUD e dos controles (ui/hud_layout.gd). A câmera conta
## só com este quadro. O caminho até aqui: 4:3 (480x360), 576x360, tela cheia
## com faixas por cima do jogo e 16:9 com faixas por cima. Por cima, a faixa
## escondia a saída das salas.

## Tamanho do quadro de jogo, em pixels.
const SIZE := Vector2(640.0, 360.0)
const HALF := SIZE / 2.0
