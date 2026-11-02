# Alttp2 (nome provisório)

Aventura top-down original, inspirada na jogabilidade de A Link to the Past e na estrutura dos randomizers e dos Metroidvanias. Cada ferramenta é arma e chave. Cada partida usa uma seed que redistribui as ferramentas e sempre garante um caminho até o fim.

Visão, princípios e decisões estão em [docs/design.md](docs/design.md).

## Como abrir

1. Instale o [Godot 4.7](https://godotengine.org/download), na versão padrão (a versão .NET não é necessária).
2. No gerenciador de projetos do Godot, clique em **Importar** e selecione o arquivo `project.godot` desta pasta.
3. Pressione **F5** para rodar. O jogo abre no menu.

## Menu

- **Capítulo 1: linear.** A distribuição pensada para aprender: bomba, chama e mola, nessa ordem.
- **Capítulo 1: seed aleatória.** Sorteia uma seed de seis dígitos, mostrada no alto da tela. Os itens trocam de baú, e sempre há caminho até o chefe.
- **Sala de teste.** A sala da física e do combate, com todas as ferramentas desde o início, um degrau alto, uma parede rachada e um bloco de gelo.

No menu, use as setas ou o direcional para escolher e Enter, Espaço ou o botão de baixo do controle para confirmar. Esc, ou o botão Back do controle, volta ao menu de dentro do jogo.

## Controles

O jogo é feito para o controle, com uma coisa em cada botão de face. O teclado serve para testar. O losango no alto da tela repete a posição dos quatro botões.

- **Mover:** analógico esquerdo ou direcional. No teclado, WASD ou setas. Sempre em 8 direções.
- **Correr:** dois toques rápidos na mesma direção, segurando no segundo. Correndo demais, o personagem perde o equilíbrio e pisca em vermelho. Aperte a direção oposta para se equilibrar, ou ele cai.
- **Andar de lado:** segure L ou R, ou Shift no teclado, para manter a direção de frente.
- **Espada:** botão de baixo (A no padrão Xbox). No teclado, J ou Z. O golpe também abre os baús.
- **Pulo, com a mola:** botão da direita (B no padrão Xbox). No teclado, Espaço ou V.
- **Chama:** botão da esquerda (X no padrão Xbox). No teclado, K ou X.
- **Bomba:** botão de cima (Y no padrão Xbox). No teclado, L ou C.

O botão de uma ferramenta só funciona depois de o personagem encontrá-la. No ar, só a espada funciona.

## Ferramentas

- **Bomba:** fica no chão à frente e explode em 1,5 s. Abre paredes rachadas e também machuca o personagem. A espada empurra a bomba. Dá para soltar 2 seguidas, e as duas voltam 5 s depois da última.
- **Chama:** bola de fogo reta. Derrete gelo e acende bombas. Dá para lançar 5 seguidas, uma de cada vez na tela, e todas voltam 3 s depois da última.
- **Mola:** pulo vertical, sem limite e sem ganhar distância. Encostado na face de um degrau alto, no alto do pulo e apertando para cima, o personagem sobe. Para descer, basta andar contra a face vindo de cima.
- **Cargas:** os pontos ao lado do botão, no alto da tela, mostram quantas bombas e chamas restam. O botão escurece quando acabam.

## Estrutura

- `player/` personagem do jogador e a espada.
- `physics/` física de massa e momento usada pelo personagem e pelos objetos.
- `combat/` tipos de golpe, que decidem o que cada ferramenta afeta.
- `items/` itens e ferramentas: baú, bomba, bola de fogo e a relíquia do fim.
- `obstacles/` bloqueios: parede rachada, gelo e a face do degrau alto.
- `objects/` objetos do mundo, como a caixa leve e o bloco pesado.
- `enemies/` inimigos: o minion, o ugly com a granada, o de gelo e o chefe com a onda de choque.
- `progression/` lógica de alcance, gerador de seeds e as escolhas da partida.
- `ui/` menu, HUD, tela de fim e os ícones das ferramentas.
- `util/` funções compartilhadas, como a conversão de segundos em ticks.
- `world/` salas e mapas. `chapter_one/` tem o capítulo 1, com o mapa em texto e as distribuições separadas do mapa. `test_room.tscn` é a sala de teste.
- `tools/` ferramentas de desenvolvimento que rodam fora do Godot.
- `docs/` documentação de design.

## Conferir um capítulo sem o Godot

```
python3 tools/check_chapter.py world/chapter_one/chapter_one_data.gd
```

Confere a geometria das salas e das portas, garante que a distribuição linear é vencível e que nenhuma combinação de ferramentas prende o jogador, e conta quantas distribuições embaralhadas são vencíveis.

## Cores provisórias do personagem

- **Vermelho:** andando.
- **Laranja:** correndo.
- **Pisca em vermelho e treme:** desequilibrado. Aperte a direção oposta.
- **Cinza e deitado:** caído, se arrastando até parar.
- **Branco:** arremessado por uma batida, sem controle.
- **Transparente piscando:** invencível depois de tomar dano.
- **Maior, com uma sombra embaixo:** no ar, pulando com a mola.
- **Barra magenta acima da cabeça:** espada travada pela granada do ugly. A barra encolhe até a trava acabar, e as ferramentas seguem funcionando.

## Cores provisórias dos inimigos

- **Amarelo piscando e tremendo:** preparando o bote. Saia da linha.
- **Amarelo piscando com uma bola magenta acima da cabeça:** o ugly vai jogar a granada.
- **Área magenta de 3 por 3 casas no chão:** onde a granada vai cair. Saia antes de o quadrado de dentro encher a área.
- **Vermelho:** dando o bote. Só aqui ele causa dano.
- **Escuro:** parado e vulnerável depois do bote.
- **Branco:** acabou de levar um golpe.
- **Cinza:** o golpe não o afeta. Falta outra ferramenta.
- **Azul claro:** de gelo. Só o fogo funciona.
- **Chefe azul claro:** com a casca de gelo. A chama quebra a casca e deixa o núcleo, vinho, exposto. Amarelo piscando avisa a pancada no chão, que solta uma onda (pule com a mola), e a investida.

## Cores provisórias do mundo

- **Parede escura com rachaduras claras:** abre com a bomba.
- **Bloco azul claro com brilhos:** derrete com a chama.
- **Faixa marrom listrada com chão mais claro acima:** degrau alto. Sobe com a mola.
- **Baú marrom com faixa dourada:** abre com a espada.
- **Losango dourado:** relíquia que o chefe deixa. Tocar nela encerra o capítulo.

## Ajustar a sensação do andar

Com o jogo rodando (F5), abra a aba **Remoto** no painel de cena do editor, selecione `Player` e altere os valores no Inspetor. O efeito é imediato. Para guardar um valor, altere também em `player/player.tscn`.
