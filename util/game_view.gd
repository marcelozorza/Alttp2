class_name GameView
## Área de jogo da versão de celular (decisões de Marcelo em 2026-11-14): um
## quadro fixo de 640x360, 16:9. Começou em 4:3 (480x360), passou a 576x360 e
## depois à tela cheia. Na tela cheia o celular dele ficou pesado, então o jogo
## voltou ao 16:9 original e não estica mais: num celular mais largo sobram
## barras pretas dos lados. O HUD e os controles ficam dentro do quadro, por
## cima do jogo, em faixas meio transparentes (ui/hud_layout.gd).

## Tamanho do quadro de jogo, em pixels.
const SIZE := Vector2(640.0, 360.0)
const HALF := SIZE / 2.0
