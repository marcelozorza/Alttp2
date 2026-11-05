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
- **Capítulo 2: linear e seed aleatória.** A dungeon grande, com 17 salas, chaves pequenas, portas trancadas, a chave grande e a sentinela no fim. Na seed, as chaves também trocam de baú, e nenhuma ordem de abrir portas prende o jogador.
- **Sala de teste.** A sala da física e do combate, com todas as ferramentas desde o início, um degrau alto, uma parede rachada e um bloco de gelo.

No menu, use as setas ou o direcional para escolher e Enter, Espaço, o botão de baixo (A) ou o Start do controle para confirmar. Esc, ou o botão Back do controle, volta ao menu de dentro do jogo.

## Controles

O jogo é feito para o controle, com uma coisa em cada botão de face. O teclado serve para testar. O losango no alto da tela repete a posição dos quatro botões.

- **Mover:** analógico esquerdo ou direcional. No teclado, WASD ou setas. Sempre em 8 direções.
- **Correr:** dois toques rápidos na mesma direção, segurando no segundo. Correndo demais, o personagem perde o equilíbrio e pisca em vermelho. Aperte a direção oposta para se equilibrar, ou ele cai.
- **Andar de lado:** segure L ou R, ou Shift no teclado, para manter a direção de frente.
- **Espada:** botão de baixo (A no padrão Xbox). No teclado, J ou Z. O golpe também abre os baús.
- **Bomba:** botão da direita (B no padrão Xbox). No teclado, L ou C.
- **Chama:** botão da esquerda (X no padrão Xbox). No teclado, K ou X.
- **Pulo, com a mola:** botão de cima (Y no padrão Xbox). No teclado, Espaço ou V.

O botão de uma ferramenta só funciona depois de o personagem encontrá-la. No ar, só a espada funciona.

- **Chaves:** encoste numa porta trancada para gastar uma chave pequena. A porta vermelha do chefe pede a chave grande. As chaves guardadas aparecem à direita do losango.

## Ferramentas

- **Bomba:** fica no chão à frente e explode em 1,5 s. Abre paredes rachadas e também machuca o personagem. A espada empurra a bomba. Dá para soltar 2 seguidas, e as duas voltam 3 s depois da última.
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
- `world/` salas e mapas. `chapter/` tem a cena que monta qualquer capítulo. `chapter_one/` e `chapter_two/` têm os dados de cada capítulo, com o mapa em texto e as distribuições separadas do mapa. `test_room.tscn` é a sala de teste.
- `art/` a pixel art em SVG. `art/source/` tem os desenhos em texto, uma letra por pixel, de onde os SVG são gerados.
- `tools/` ferramentas de desenvolvimento que rodam fora do Godot.
- `docs/` documentação de design.

## Conferir um capítulo sem o Godot

```
python3 tools/check_chapter.py world/chapter_one/chapter_one_data.gd
python3 tools/check_chapter.py world/chapter_two/chapter_two_data.gd
```

Confere a geometria das salas e das portas, garante que a distribuição linear é vencível em qualquer ordem de abrir as portas trancadas e que nenhuma combinação de ferramentas prende o jogador, e conta quantas distribuições embaralhadas são vencíveis.

## Editar a pixel art

Cada desenho fica em `art/source/` como texto: uma paleta de letras e cores e uma grade com uma letra por pixel, em que `.` é transparente. Depois de editar, gere os SVG:

```
python3 tools/pixel_svg.py
```

O Godot reimporta os SVG ao voltar para o editor.

## Tons do Giorgio

- **De pé, sem tom:** andando, com a espada e os itens na pata.
- **Nas 4 patas, alaranjado:** correndo. Atacar faz ele ficar de pé e encerra a corrida.
- **Pisca em vermelho e treme:** desequilibrado. Aperte a direção oposta.
- **Deitado e acinzentado:** caído, se arrastando até parar.
- **Clarão branco:** arremessado por uma batida, sem controle.
- **Transparente piscando:** invencível depois de tomar dano.
- **Maior, com uma sombra embaixo:** no ar, pulando com a mola.
- **Barra magenta acima da cabeça:** espada travada pela granada do ugly. A barra encolhe até a trava acabar, e as ferramentas seguem funcionando.

## Cores dos inimigos

Nos inimigos com desenho, as cores viram um tom sobre ele.


- **Amarelo piscando e tremendo:** preparando o bote. Saia da linha.
- **Amarelo piscando com uma bola magenta acima da cabeça:** o ugly vai jogar a granada.
- **Área magenta de 3 por 3 casas no chão:** onde a granada vai cair. Saia antes de o quadrado de dentro encher a área.
- **Vermelho:** dando o bote. Só aqui ele causa dano.
- **Escuro:** parado e vulnerável depois do bote.
- **Branco:** acabou de levar um golpe.
- **Cinza:** o golpe não o afeta. Falta outra ferramenta.
- **Azul claro:** de gelo. Só o fogo funciona.
- **Chefe azul claro:** com a casca de gelo. A chama quebra a casca e deixa o núcleo, vinho, exposto. Amarelo piscando avisa a pancada no chão, que solta uma onda (pule com a mola), e a investida.
- **Sentinela de pedra rachada:** a bomba abre a armadura. O núcleo congelado, azul, derrete com a chama. O núcleo quente, vermelho, apanha da espada e da bomba. A armadura volta 8 s depois da explosão.

## Cores do mundo

- **Parede escura com rachaduras claras:** abre com a bomba.
- **Bloco azul claro com brilhos:** derrete com a chama.
- **Faixa marrom listrada com chão mais claro acima:** degrau alto. Sobe com a mola.
- **Baú marrom com faixa dourada:** abre com a espada.
- **Porta de madeira com faixas de ferro e fechadura:** gasta uma chave pequena.
- **Porta vermelha com selo dourado:** porta do chefe. Abre com a chave grande.
- **Losango dourado:** relíquia que o chefe deixa. Tocar nela encerra o capítulo.

## Ajustar a sensação do andar

Com o jogo rodando (F5), abra a aba **Remoto** no painel de cena do editor, selecione `Player` e altere os valores no Inspetor. O efeito é imediato. Para guardar um valor, altere também em `player/player.tscn`.
