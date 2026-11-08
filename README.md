# Giorgino

Giorgino é um cachorro, e este é o jogo dele: uma aventura top-down original, inspirada na jogabilidade de A Link to the Past e nas dungeons dos Zelda 2D. Cada ferramenta é arma e chave. O jogo é linear, capítulo a capítulo, e cada capítulo tem um mapa e uma distribuição fixa de ferramentas, chaves e bloqueios, sempre conferida para ter caminho até o fim. Um mundo pequeno liga as dungeons, e o progresso fica salvo. Esse modo original ensina as quatro dungeons do jogo, a inicial e as três do mundo. O jogo de verdade será o modo randomizado, ainda por fazer, em que uma seed embaralha os itens entre elas.

Visão, princípios e decisões estão em [docs/design.md](docs/design.md). O estudo das dungeons de referência e as regras tiradas dele estão em [docs/referencias.md](docs/referencias.md).

## Como abrir

1. Instale o [Godot 4.7](https://godotengine.org/download), na versão padrão (a versão .NET não é necessária).
2. No gerenciador de projetos do Godot, clique em **Importar** e selecione o arquivo `project.godot` desta pasta.
3. Pressione **F5** para rodar. O jogo abre no menu.

## Menu

- **Continuar.** Volta ao mundo com o jogo salvo, na pedra de salvamento. Só aparece quando há jogo salvo.
- **Novo jogo.** Começa no mundo, uma clareira com a entrada de cada dungeon ao norte, na ordem dos capítulos. Um cronômetro no canto superior direito conta o tempo de jogo desde o começo, para na pausa e fica gravado. Vencida a terceira dungeon, a tela de vitória mostra o tempo total e convida ao modo randomizado. Cada entrada abre quando o capítulo anterior foi vencido, e a de um capítulo vencido mostra a relíquia dele. Ferramentas, melhorias e vida máxima passam de um capítulo ao outro. Vencer um capítulo grava o progresso, e encostar na pedra de salvamento grava de novo e enche a vida. Sair de um capítulo no meio perde o que foi feito nele.
- **Randomizado.** O jogo de verdade: as mesmas três dungeons do mundo, com as ferramentas e as melhorias embaralhadas entre os baús delas por uma seed, um número de 1 a 999999. Na tela da seed, esquerda e direita escolhem o dígito, cima e baixo mudam, os números do teclado digitam, Sortear sorteia outro e Jogar começa. O mesmo número dá o mesmo jogo em qualquer cópia, então dá para compartilhar. As três entradas abrem de início, as chaves ficam nas dungeons delas e cada baú de ferramenta, melhoria ou coração fica gravado na hora em que abre. A primeira mola encontrada é a mola e a segunda é a mola forte, seja qual for a ordem dos baús, e o mesmo vale para a chama. Morrer na seed perde tudo: ela recomeça do zero, no mundo. O número da seed aparece na pausa e na tela de vitória.
- **Tutorial.** A dungeon de aprendizado, fora do mundo e sem gravar nada.
- **Treino.** O tutorial, cada capítulo avulso com as ferramentas dos dados dele, sem gravar nada, e a sala de teste.

O tutorial e os capítulos:

- **Tutorial.** A dungeon de aprendizado, com 8 salas: bomba, chama e mola, nessa ordem, e o guardião de gelo no fim.
- **Capítulo 1.** A dungeon grande, com 17 salas, chaves pequenas, portas trancadas, a chave grande e a sentinela no fim. Nenhuma ordem de abrir portas prende o jogador.
- **Capítulo 2.** A geleira, com 15 salas. O personagem chega com as três ferramentas e encontra a primeira melhoria, a chama forte, que derrete o gelo grosso. No fim, o guardião antigo.
- **Capítulo 3.** A pedreira, com 17 salas em 22 telas: a arena, a pedreira e o pátio são maiores que a tela, e a câmera acompanha o personagem dentro delas. O personagem chega com as três ferramentas e a chama forte e encontra a mola forte, cujo pulo sobe o degrau duplo. Atiradores de pedras nos estrados e o colosso no fim.
- **Sala de teste.** A sala da física e do combate, com todas as ferramentas e a chama forte desde o início, um degrau alto, uma parede rachada, um bloco de gelo, um gelo grosso, uma morsa de gelo e um atirador de pedras. A passagem para a parte de baixo é uma grade: pise no interruptor para abri-la enquanto fica ali, ou empurre o bloco pesado para cima dele para abri-la de vez.

No menu, use as setas ou o direcional para escolher e Enter, Espaço, o botão de baixo (A) ou o Start do controle para confirmar. Dentro do jogo, Start ou Esc abrem o menu de pausa, com continuar, mapa e sair. Back no controle de Xbox, Select no de SNES, M ou Tab abrem direto o mapa da dungeon, e o mesmo botão fecha. A música para junto e volta de onde estava. Sem vida, o personagem cai e aparece a tela de derrota: tentar de novo recomeça a dungeon do início, com o que o personagem tinha ao entrar nela.

## Controles

O jogo é feito para o controle, com uma coisa em cada botão de face. O teclado serve para testar. O losango no canto inferior esquerdo da tela repete a posição dos quatro botões, com o ícone do que cada um faz.

- **Mover:** analógico esquerdo ou direcional. No teclado, WASD ou setas. Sempre em 8 direções.
- **Correr:** dois toques rápidos na mesma direção, segurando no segundo. Correndo, nenhum ataque tira vida: a corrida é a esquiva. Ela dura enquanto a direção estiver pressionada e houver fôlego: depois de 3 s correndo o personagem cansa, para de correr e só corre de novo depois de 4 s de descanso. Nada disso aparece na tela.
- **Andar de lado:** segure L ou R, ou Shift no teclado, para manter a direção de frente.
- **Latido:** botão de baixo (A no padrão Xbox, B no SNES). No teclado, J ou Z. Late na direção da cabeça e alcança a casa à frente. Com um baú na casa à frente, o mesmo botão estica a pata e abre o baú, sem latir.
- **Bomba:** botão de cima (Y no padrão Xbox, X no SNES). No teclado, L ou C.
- **Chama:** botão da esquerda (X no padrão Xbox, Y no SNES). No teclado, K ou X.
- **Pulo, com a mola:** botão da direita (B no padrão Xbox, A no SNES). No teclado, Espaço ou V. No ar, o personagem passa por cima dos inimigos comuns, e o bote deles não o alcança. Os chefes continuam sólidos.

O botão de uma ferramenta só funciona depois de o personagem encontrá-la. No ar, só o latido funciona.

- **Vida:** os corações no alto, um a cada dois pontos, pela metade ou vazios conforme você perde vida. Cada inimigo morto tem 30% de chance de deixar um ossinho, que enche 2 pontos ao ser pego e some em 10 s, e com 3 pontos ou menos todo inimigo deixa um. Com 4 pontos ou menos, um beep discreto avisa.
- **Minimapa e mapa:** no canto inferior direito, dentro das dungeons, um bloco por sala já visitada, com a sala atual piscando. O botão de mapa abre o mapa inteiro da dungeon numa tela própria: nas salas já vistas aparecem baús fechados e abertos, portas trancadas, porta do chefe, paredes rachadas, gelo, degraus e grades, as salas não vistas são blocos sombreados, o chefe tem uma caveira desde o começo e o Giorgino pisca. Uma legenda fica embaixo.
- **Chaves:** encoste numa porta trancada para gastar uma chave pequena. A porta vermelha do chefe pede a chave grande. O contador de chaves fica à direita do losango, e a chave grande aparece ao lado dele.

## Ferramentas

- **Bomba:** fica no chão à frente e explode em 1,5 s. Abre paredes rachadas e também machuca o personagem. O latido empurra a bomba. Dá para soltar 2 seguidas, e as duas voltam 3 s depois da última.
- **Chama:** bola de fogo reta. Derrete gelo e acende bombas. Dá para lançar 5 seguidas, uma de cada vez na tela, e todas voltam 3 s depois da última.
- **Chama forte:** melhoria da chama, encontrada no capítulo 3, sem botão próprio. A bola de fogo fica maior e com o miolo branco. Faz tudo o que a chama faz, derrete o gelo grosso, causa o dobro do dano nos inimigos que o fogo afeta e é a única coisa que vence a morsa de gelo e a casca do guardião antigo.
- **Mola:** pulo vertical, sem limite e sem ganhar distância. Encostado na face de um degrau alto, no alto do pulo e apertando para cima, o personagem sobe. Para descer, basta andar contra a face vindo de cima.
- **Mola forte:** melhoria da mola, encontrada no capítulo 4, sem botão próprio. O pulo fica mais alto e mais longo e sobe o degrau duplo, de duas casas, que o pulo comum não vence. Também pula a onda alta do colosso.
- **Cargas:** os pontos ao lado do botão, no alto da tela, mostram quantas bombas e chamas restam. O botão escurece quando acabam.

## Estrutura

- `player/` personagem do jogador e o latido (`bark.gd`), que também estica a pata nos baús.
- `physics/` física de massa e momento usada pelo personagem e pelos objetos.
- `combat/` tipos de golpe, que decidem o que cada ferramenta afeta.
- `items/` itens e ferramentas: baú, bomba, bola de fogo e a relíquia do fim.
- `obstacles/` bloqueios: parede rachada, gelo, gelo grosso, portas, a grade de ferro e a face do degrau alto, comum ou duplo.
- `objects/` objetos do mundo: a caixa leve, o bloco pesado e o interruptor no chão.
- `enemies/` inimigos: o minion, o ugly com a granada, o de gelo, a morsa de gelo, o atirador de pedras, o morcego, o tatu de pedra, a planta de espinhos e os chefes com a onda de choque.
- `progression/` leitura dos dados de cada capítulo, o mapa em texto, as escolhas da partida, o progresso salvo (`progress.gd`) e o caminho entre as telas (`flow.gd`).
- `ui/` menu de título, treino, HUD, menu de pausa, tela de derrota, tela de fim e os ícones das ferramentas.
- `util/` funções compartilhadas, como a conversão de segundos em ticks.
- `world/` salas e mapas. `chapter/` tem a cena que monta qualquer capítulo. `tutorial/`, `chapter_one/`, `chapter_two/` e `chapter_three/` têm os dados do tutorial e de cada capítulo, com o mapa em texto e as tabelas de bloqueios e de itens separadas do mapa. Uma lista `ROOMS` nos dados junta telas vizinhas numa sala maior que a tela. `overworld/` tem o mundo que liga os capítulos, com o mapa em texto, a entrada de dungeon e a pedra de salvamento. `map_view.gd` desenha os dois, e `map_walls.gd` monta a colisão. `test_room.tscn` é a sala de teste.
- `audio/` música e efeitos sonoros. `music.gd` e `sfx.gd` são os autoloads Music e Sfx. `sfx/` tem os efeitos gerados e `music/local/` recebe a trilha provisória, fora do Git.
- `art/` a pixel art em SVG. `art/source/` tem os desenhos em texto, uma letra por pixel, de onde os SVG são gerados.
- `tools/` ferramentas de desenvolvimento que rodam fora do Godot.
- `docs/` documentação de design.

## Conferir um capítulo sem o Godot

```
python3 tools/check_chapter.py world/tutorial/tutorial_data.gd
python3 tools/check_chapter.py world/chapter_one/chapter_one_data.gd
python3 tools/check_chapter.py world/chapter_two/chapter_two_data.gd
python3 tools/check_chapter.py world/chapter_three/chapter_three_data.gd
```

Confere a geometria das salas e das portas, as regras de leitura visual (bloqueio de porta num nicho uma casa para dentro da sala, gelo grosso com duas casas de fundo, degrau com chão alto logo ao norte, degrau duplo com duas casas de face, altura do chão que fecha em todo o mapa, e grade com um interruptor na mesma sala e um bloco pesado alinhado com ele) e garante que o capítulo é vencível em qualquer ordem de abrir as portas trancadas e que nenhuma combinação de ferramentas prende o jogador. Qualquer linha `ERRO` precisa ser corrigida antes de publicar.

## Verificação automática

A cada push e a cada pull request, o GitHub roda as três conferências do projeto (`.github/workflows/verificar.yml`): formatação e lint dos scripts com o gdtoolkit, o conferidor dos quatro capítulos e o teste de fumaça no Godot 4.7.2 sem tela. O resultado aparece na aba **Actions** do repositório e na marca ao lado de cada commit: verde passou, vermelho falhou, e a página da falha mostra qual conferência quebrou e a linha do erro.

Para rodar o teste de fumaça no seu computador, com o Godot no PATH ou com o caminho dele:

```
sh tools/run_smoke_test.sh
sh tools/run_smoke_test.sh "C:/caminho/do/Godot_v4.7.2-stable_win64_console.exe"
```

Ele importa o projeto, roda `tools/smoke_test.gd` e falha se aparecer `SCRIPT ERROR`, erro do motor ou se o teste não chegar ao fim.

## Editar a pixel art

Cada desenho fica em `art/source/` como texto: uma paleta de letras e cores e uma grade com uma letra por pixel, em que `.` é transparente. Depois de editar, gere os SVG:

```
python3 tools/pixel_svg.py
```

O Godot reimporta os SVG ao voltar para o editor. Uma linha `usa outro_desenho` no lugar da grade reaproveita os pixels de outro desenho com a paleta nova: é assim que os tiles do castelo, do gelo e das ruínas (`floor_castle`, `wall_ice`, `wall_face_moss` e os demais) saem dos tiles de pedra, e a chama azul da chama comum. Os quatro quadros da explosão da bomba (`explosion_1` a `explosion_4`) não se editam à mão: saem de `python3 tools/explosion_art.py`, que gera o texto deles antes do passo acima.

## Som

**Música.** Ponha um arquivo .ogg, .mp3 ou .wav em `audio/music/local/` e ele toca em loop em todas as telas. Essa pasta fica fora do Git, porque o repositório é público e a trilha provisória não é nossa. O volume da música fica no barramento Music, na aba Áudio, embaixo no editor.

**Efeitos.** Os 49 efeitos são originais, montados por receitas de ruído, osciladores e filtros em `tools/sfx.py`, a 32 kHz, como o chip de som do Super Nintendo. Para mudar um som, edite a receita e gere de novo:

```
python3 tools/sfx.py              todos os sons
python3 tools/sfx.py jump land    só os nomes dados
python3 tools/sfx.py --reel x.wav todos num arquivo só, para ouvir em sequência
```

O volume e a variação de tom de cada efeito ficam na tabela `SOUNDS` de `audio/sfx.gd`. O volume geral dos efeitos fica no barramento Sfx. Os sons tocam em 8 vozes, como no Super Nintendo, e com as 8 ocupadas o som novo corta o mais antigo.

## Tons do Giorgino

- **De pé, sem tom:** andando, com os itens na pata (as sprites atuais ainda mostram a espada, que sai no redesenho).
- **Inclinado para a frente, alaranjado:** correndo, sem tomar dano. Atacar encerra a corrida.
- **Clarão branco:** arremessado por uma batida, sem controle.
- **Transparente piscando:** invencível depois de tomar dano.
- **Maior, com uma sombra embaixo:** no ar, pulando com a mola. Com a mola forte, cresce mais e fica mais tempo no ar.
- **Barra magenta acima da cabeça:** latido travado pela granada do ugly. A barra encolhe até a trava acabar, e as ferramentas seguem funcionando.

## Cores dos inimigos

Nos inimigos com desenho, as cores viram um tom sobre ele. O minion, o gatinho laranja de listras, tem um quadro para cada momento: dois passos ao andar, de costas ao subir, agachado preparando o bote, esticado no bote, recuperando e apanhando.

- **Amarelo piscando e tremendo:** preparando o bote. Saia da linha.
- **Amarelo piscando com uma bola magenta acima da cabeça:** o ugly vai jogar a granada.
- **Área magenta de 3 por 3 casas no chão:** onde a granada vai cair. Saia antes de o quadrado de dentro encher a área.
- **Vermelho:** dando o bote. Só aqui ele causa dano.
- **Escuro:** parado e vulnerável depois do bote.
- **Branco:** acabou de levar um golpe.
- **Cinza:** o golpe não o afeta. Falta outra ferramenta.
- **Azul claro:** de gelo. Só o fogo funciona.
- **Azul profundo com presas e borda de geada:** morsa de gelo. Só a chama forte derrete, em duas bolas.
- **Cor de areia, parado, com uma pedra acima da cabeça:** atirador de pedras. A pedra cai na casa marcada no chão e causa dano a quem estiver nela. Ele não sai do lugar.
- **Roxo escuro voando em ziguezague, com uma sombra no chão:** morcego. Um golpe basta. A sombra diz onde ele está.
- **Casca redonda de pedra rachada:** tatu de pedra. Só a bomba o abre, e uma basta. Ele nunca corre: avança devagar e sem parar, e machuca ao encostar.
- **Bulbo verde com boca de dentes:** planta de espinhos. Não sai do lugar e morde quem chega perto. Três latidos a vencem, e uma bola de fogo basta.
- **Chefe azul claro:** com a casca de gelo. A chama quebra a casca e deixa o núcleo, vinho, exposto. Amarelo piscando avisa a pancada no chão, que solta uma onda (pule com a mola), e a investida.
- **Chefe azul profundo com borda de geada:** o guardião antigo, com a casca de gelo grosso. Só a chama forte quebra a casca. Os ataques são os do guardião de gelo.
- **Sentinela, o buldogue de pedra:** a bomba quebra a pele de pedra. O corpo congelado, azul, derrete com a chama. O núcleo quente, vermelho, apanha do latido e da bomba. A pedra volta 8 s depois da explosão.
- **Colosso de arenito rachado:** a bomba abre a casca, que volta em 6 s. O núcleo de pedra derretida apanha do latido, da chama forte e da bomba. A pancada no chão solta uma onda alta, cor de areia, que só a mola forte pula.

## Cores do mundo

Cada dungeon tem um tema: o tutorial é a pedra azulada com tochas, o capítulo 1 é o castelo roxo com candelabros, estandartes e tapete vermelho, o capítulo 2 é a geleira azul com chamas azuis, estalactites e geada, e o capítulo 3 são as ruínas verdes com trepadeiras, teias e musgo. Os adornos são só enfeite: nada deles bloqueia ou esconde um caminho. O que muda o jogo é isto:

- **Parede escura com rachaduras claras:** abre com a bomba.
- **Bloco azul claro com brilhos:** derrete com a chama.
- **Bloco azul profundo com a borda branca de geada, duas casas de fundo:** gelo grosso. A chama comum só o faz tremer. Derrete com a chama forte.
- **Pedra escurecendo para baixo, com sombra no chão e o chão de cima mais claro:** degrau alto. Sobe com a mola e desce andando contra a face.
- **Face de duas casas, em pedra mais escura, com sombra mais longa e o chão de cima mais claro ainda:** degrau duplo. O pulo comum bate na face. Sobe com a mola forte e desce andando contra a face.
- **Bloqueio num nicho entre duas paredes:** todo bloqueio de porta fica uma casa para dentro da sala, para aparecer inteiro na tela. As paredes projetam sombra no chão para o sul e para o leste.
- **Grade de ferro escura numa passagem:** só o interruptor da sala abre. Golpes só a fazem tremer.
- **Placa de pedra com um losango, no chão:** interruptor. Pisar abre a grade enquanto você fica em cima. Empurrar o bloco pesado, que tem o mesmo losango, até ele parar em cima abre de vez.
- **Baú vermelho com faixa dourada:** abre com a pata, pelo botão de ataque com o baú na casa à frente.
- **Porta de madeira com faixas de ferro e fechadura:** gasta uma chave pequena.
- **Porta vermelha com selo dourado:** porta do chefe. Abre com a chave grande.
- **Losango dourado:** relíquia que o chefe deixa. Tocar nela encerra o capítulo.
- **Portal de pedra na mata, no mundo:** entrada de uma dungeon. Com grade, ainda fechada: abre ao vencer o capítulo anterior. Com a relíquia em cima, capítulo vencido.
- **Estela azulada com um losango, no mundo:** pedra de salvamento. Encostar grava o progresso e enche a vida.

## Ajustar a sensação do andar

Com o jogo rodando (F5), abra a aba **Remoto** no painel de cena do editor, selecione `Player` e altere os valores no Inspetor. O efeito é imediato. Para guardar um valor, altere também em `player/player.tscn`.
