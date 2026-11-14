class_name GameView
## Área de jogo da versão de celular (decisão de Marcelo em 2026-11-14): um
## quadro 4:3 de 480x360 no meio da tela. O que sobra dos lados, num celular
## deitado, são as faixas do HUD e dos controles (ui/hud_layout.gd). A câmera
## conta só com este quadro, então a sala aparece inteira no meio, e as faixas
## cobrem o que a tela larga mostraria além dele.

## Tamanho do quadro de jogo, em pixels.
const SIZE := Vector2(480.0, 360.0)
const HALF := SIZE / 2.0
