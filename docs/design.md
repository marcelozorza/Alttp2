# Documento de design

Registro vivo das decisões do projeto. Atualizado a cada conversa.

## Visão

Aventura top-down original, inspirada na jogabilidade de A Link to the Past e na estrutura dos randomizers e dos Metroidvanias. O jogador acumula um arsenal de ferramentas, e cada ferramenta serve como arma e também como chave de bloqueios no mundo. Cada partida usa uma seed que distribui as ferramentas pelo mundo e sempre garante um caminho até o fim.

O jogo deve ser original. A inspiração vem da sensação e da estrutura, sem copiar itens, mapas ou personagens.

## Princípios

1. **Legibilidade sem conhecimento prévio.** O randomizer de ALttP funciona porque o jogador já conhece o jogo original. Aqui, o próprio jogo precisa ensinar o que cada coisa faz.
2. **As regras nunca mudam entre seeds.** A seed decide onde cada ferramenta está. O que cada bloqueio exige é sempre igual.
3. **Linguagem visual fixa.** Cada tipo de bloqueio tem uma aparência que indica a ferramenta que o abre. O jogador aprende uma vez e usa em todas as partidas.
4. **Sem dicas escritas.** Ao ver um bloqueio, o jogador deve saber instintivamente o que fazer.
5. **A seed original é só mais uma seed.** A primeira experiência é linear e planejada, como um jogo tradicional. Tecnicamente ela é uma seed fixa, escolhida para ensinar o caminho de forma segura. Depois disso, as seeds embaralham, e o tempo de conclusão cai conforme o jogador domina o vocabulário.
6. **Técnicas avançadas fazem parte da lógica.** Inspirado nos níveis de lógica do randomizer de ALttP e na cultura de glitches da comunidade. O jogo terá mecânicas com profundidade escondida, que um jogador habilidoso descobre e usa para desviar da rota prevista. O gerador trata cada técnica como mais uma chave. O modo padrão nunca exige técnicas avançadas, e modos avançados podem exigir.
7. **Gameplay antes de conteúdo.** Começar com formas básicas e refinar a sensação de controle até ela ser boa por si só. O mundo é construído depois, para explorar os movimentos que já funcionam. Tudo usa placeholders até as decisões visuais serem tomadas.

## Estrutura de progressão

- **Capítulos.** Áreas pequenas, como uma dungeon com poucas ferramentas-chave. O jogador primeiro joga a área na forma linear e aprende o vocabulário. Depois a mesma área, ou uma nova, aparece embaralhada.
- **Pedra, papel e tesoura.** Cada bloqueio mostra pela aparência qual ferramenta falta, e cada ferramenta é forte contra uma coisa e inútil contra outra. Sem a ferramenta certa, o jogador não passa e precisa encontrá-la. O golpe errado só faz o bloqueio tremer, o que confirma que ali falta outra coisa. A mesma regra vale no combate (ver Inimigos).

## Direção visual (em discussão)

Referência: o mundo de ALttP como uma caixa de brinquedos, um diorama. Elementos identificados até agora:

1. **Perspectiva 3/4.** O chão visto de cima e a fachada dos objetos. Casas, muros e penhascos têm volume de maquete. O jogador passa por trás de objetos altos.
2. **Mundo compacto e denso.** Tudo perto, cada tela com algo a fazer, um mapa que cabe na cabeça.
3. **Mundo manipulável.** Objetos que se levantam, empurram e jogam. Isso dá a sensação de brinquedo.
4. **Camadas de altura.** Penhascos, pontes e plataformas que permitem ver um item antes de conseguir alcançá-lo. Ver o prêmio do outro lado de um bloqueio ensina o jogador a voltar quando tiver a ferramenta certa.

## Movimento

Limitações também definem o jogo. As decisões abaixo podem ser revistas depois de jogadas.

- **Sem pulo no movimento base.** O personagem não pula sozinho. Desníveis viram bloqueios naturais, o que reforça a ideia de ver o prêmio antes de alcançá-lo. O pulo existe como ferramenta, a mola, que destrava esses desníveis (ver Ferramentas).
- **8 direções fixas.** Norte, sul, leste, oeste e as quatro diagonais, inclusive no analógico. Não há movimento livre em ângulo.
- **Frente em 4 direções.** Na diagonal, o personagem mantém a frente atual quando ela faz parte da diagonal.
- **Corrida com dois toques.** Dois toques rápidos na mesma direção fazem o personagem correr enquanto a direção estiver pressionada. Serve para esquivar de ataques e adiciona uma camada de habilidade. Correndo, dá para mudar para os lados e para as diagonais à frente. Apertar uma direção com componente para trás cancela a corrida na hora, como uma freada. Ele nunca corre de volta.
- **Correr demais tem custo.** Inspirado no jeito da Nintendo de punir o exagero, como rodar no Mario Kart ao segurar a curva demais. Depois de um tempo correndo, o personagem perde o equilíbrio e cambaleia. Apertar a direção oposta o equilibra de novo, como no equilíbrio do Tony Hawk's Pro Skater. Sem reação, ele tropeça e cai, se arrasta pelo chão com o embalo da corrida, sem controle, e só se levanta depois de parar. A ideia é correr pouco e ficar atento. Soltar e dar dois toques de novo reinicia o tempo de corrida, o que já cria uma técnica natural para quem domina o ritmo.
- **Andar de lado (strafe).** Manter a frente enquanto se move. Em teste: segurar um botão (Shift no teclado, L ou R no controle) trava a frente.

## Física

Algo raro em ALttP e central aqui: o personagem e os objetos têm massa, momento e inércia em tempo real.

- **Ação e reação.** Toda batida troca momento entre os dois corpos. Contra uma parede ou algo mais pesado, o personagem volta. Contra algo mais leve, o objeto vai embora e o personagem segue mais devagar.
- **Momento.** Um impulso externo, como uma batida ou um golpe, desloca o personagem até o atrito pará-lo. Nesse intervalo, o controle fica suspenso.
- **Limite de velocidade para o ricochete.** Abaixo de uma velocidade mínima, a batida é inelástica: andando contra uma parede, o personagem só para, e andando contra um objeto, ele o empurra (rápido se for leve, devagar se for pesado). Acima dela, como correndo, há ricochete. Sem esse limite, encostar numa parede jogaria o personagem para trás o tempo todo.
- **Uso estratégico.** Bater na parede correndo vira uma fuga rápida numa luta. Bater numa parede durante o desequilíbrio também evita a queda. Isso abre espaço para técnicas que os jogadores vão descobrir.
- **Física própria.** A física das batidas é nossa (`physics/momentum_body.gd`) e roda em passo fixo, para que todo truque descoberto funcione sempre da mesma forma.

## Ferramentas

As ferramentas ficam num botão próprio, e outro botão troca a ferramenta escolhida. A escolhida aparece numa moldura no alto da tela, com as outras ao lado. Uma ferramenta nova já entra escolhida. No ar, só a espada funciona.

- **Bomba.** Fica no chão um pouco à frente do personagem e explode depois de 1,5 s, num raio de 26 px. Abre paredes rachadas, causa dano, empurra os corpos pela física e machuca o próprio personagem. No máximo 2 no chão ao mesmo tempo. O personagem atravessa as próprias bombas, e a espada as empurra, o que permite chutá-las. Fogo e outras explosões acendem o pavio na hora, o que permite reações em cadeia.
- **Chama.** Lança uma bola de fogo reta na direção da frente, com alcance de 120 px, uma de cada vez. Derrete gelo, acende bombas e queima inimigos. Qualquer coisa sólida apaga a bola.
- **Mola.** Pulo vertical, inspirado na pena de Link's Awakening. O personagem sobe no eixo da câmera e cresce na tela, porque fica mais perto dela, e a sombra fica no chão. Ele não ganha distância: o controle no ar é o mesmo do chão. O pulo dura 0,5 s e sobe cerca de 20 px, acima dos 16 px de um degrau. Serve para subir degraus altos e para escapar das ondas de choque do chefe. Pular correndo mantém a velocidade da corrida, sem ganho extra. Saltos longos sobre buracos, como pena e botas no Link's Awakening, ficam para depois.

## Bloqueios

Cada bloqueio tem uma aparência fixa, que se repete em todos os capítulos e seeds.

- **Parede rachada.** Escura, com rachaduras claras. Só a explosão da bomba abre.
- **Gelo.** Azul claro, com brilhos. Só o fogo derrete, em 0,25 s. O mesmo azul marca o inimigo de gelo e a casca do chefe, que também só cedem ao fogo.
- **Degrau alto.** A face de um desnível de 16 px, marrom com listras, com o chão de cima mais claro. Ninguém atravessa a face andando. Com a mola, o personagem sobe se estiver alto o bastante ao encostar nela vindo de baixo. De cima, ele desce num salto ao andar contra ela, sem ferramenta. Sem a mola o degrau é de mão única, o que cria atalhos de volta.
- **Como o degrau funciona.** A altura do chão não é simulada. A face é uma parede, e a travessia leva o personagem de um lado ao outro de uma vez, trocando posição por altura. O desenho alcança a nova posição em poucos ticks, o que esconde o salto.

## Combate

- **Curta distância.** O ataque principal é corpo a corpo.
- **Um só botão de ataque.** Sem divisão entre ataque fraco e forte.
- **A arma define a forma do ataque.** Ideias até agora: uma lança que ataca só para frente, com alcance maior, e uma espada que ataca em leque à frente.
- **Ataque giratório.** Segurar o botão de ataque carrega um golpe de 360 graus.
- **Armas também são ferramentas.** Como entram na distribuição da seed, a forma de cada ataque pode servir de chave. Por exemplo, o alcance da lança pode atingir um interruptor do outro lado de um vão. Ainda é só ideia.
- **Espada de estocada, a primeira arma.** Inspirada na espada do primeiro Zelda. Golpeia na direção da frente e entrega o golpe no mesmo instante do aperto, com a lâmina toda estendida. Não há espera pela animação: um novo aperto cancela o recolhimento e golpeia de novo. O dano vale em toda a lâmina que sai do corpo, cada golpe acerta cada alvo uma vez e empurra o alvo conforme a massa dele. O personagem fica parado por um instante (0,1 s) a cada golpe, mas pode virar para o próximo.
- **Golpe no plano do chão.** A área de dano parte dos pés do personagem, então o golpe acerta o que está encostado e não muda durante o pulo, quando a lâmina desenhada sobe junto com o corpo.
- **Fraquezas.** Cada inimigo tem um multiplicador de dano para espada, fogo e explosão. Multiplicador zero torna o inimigo imune: o golpe só o empurra, e ele pisca em cinza.
- **Baús.** Abrem com um golpe de espada, e o item vai direto para o personagem. Fogo e explosões não abrem baús, para que nenhum baú seja aberto do outro lado de uma parede.
- **Sem dano por contato.** Encostar num inimigo não machuca. Só o ataque do inimigo causa dano, e cada inimigo tem um padrão de ataque que o jogador precisa observar.
- **Vida e invencibilidade.** O personagem começa com 6 pontos de vida, mostrados no canto da tela. Depois de tomar dano, fica 1 s invencível, piscando. Cada coração de baú dá 2 pontos de vida máxima e enche a vida. Ao perder toda a vida, ele volta à entrada da sala com a vida cheia e mantém ferramentas e baús abertos. Ainda não há tela de derrota.
- **Espada travada.** A granada do ugly trava a espada por 3 s. Uma barra magenta acima da cabeça encolhe até a trava acabar, e apertar o ataque só faz a barra piscar em branco. As ferramentas seguem funcionando. A invencibilidade depois de tomar dano também protege da trava, e perder toda a vida acaba com ela.

## Inimigos

Os inimigos comuns seguem o mesmo padrão: percebe o personagem, se aproxima, prepara o bote (pisca em amarelo e treme, com a direção já travada), dá o bote em linha reta e fica parado e vulnerável. Quem sai da linha durante a preparação escapa. Eles só agem na sala do personagem e voltam ao ponto inicial quando ele entra ou sai da sala, ou quando reaparece.

- **Ugly (massa 3, 8 de vida).** O grande, lento e perigoso. Prepara o bote por 0,7 s, em qualquer uma das 8 direções, causa 2 de dano e arremessa o personagem. A forma de vencê-lo é esperar ele escolher a direção, sair da linha e atacar enquanto ele se recupera. Morre com 8 golpes de espada. A espada quase não o move e não interrompe o que ele está fazendo, e a bomba causa o triplo do dano, então 3 bombas bastam.
- **Granada do ugly.** O ataque de longe. Com o personagem entre 64 e 160 px, ele para, ergue uma granada magenta acima da cabeça e pisca em amarelo por 0,6 s. A granada sai da mão e cai 0,7 s depois no centro da casa onde o personagem estava ao ser jogada. A área de 3 por 3 casas aparece no chão assim que ela sai da mão, e um quadrado cresce dentro da área até o estouro. Quem estiver com os pés na área no estouro fica com a espada travada por 3 s. Ela não causa dano nem empurra. Ele espera 2,5 s entre uma granada e outra, e 1 s depois de o personagem entrar na sala antes da primeira. Andando, sair da área a partir do centro leva cerca de 0,33 s, e correndo, 0,2 s. A granada pune quem fica parado de longe, e o bote pune quem fica parado de perto.
- **Minion (massa 0,5, 2 de vida).** O pequeno. Rápido, prepara o bote por 0,35 s, causa 1 de dano e empurra pouco. A espada o arremessa longe e o deixa atordoado por um instante. Fogo e bomba causam o dobro do dano.
- **De gelo (massa 1, 3 de vida).** Azul claro, como o bloco de gelo. Imune à espada e à bomba. Uma bola de fogo o derrete. No capítulo 1 ele aparece primeiro na sala da chama, antes de o jogador ter como vencê-lo.
- **Chefe, o guardião de gelo (massa 8, 12 de vida).** O exame das três ferramentas. Coberto pela casca de gelo, ignora espada e bomba. A chama quebra a casca, que volta depois de 6 s e pisca antes de voltar. Sem a casca, o núcleo apanha da espada e o triplo da bomba. Alterna dois ataques avisados em amarelo: uma pancada no chão que solta uma onda de choque, que só se evita no ar com a mola, e uma investida de 2 de dano em linha reta, na direção travada durante o aviso. Ele não sai da sala.

## Capítulo 1

- **Mapa.** 8 salas de uma tela (20 por 10 casas de 16 px), numa grade de 3 por 4, com portas de duas casas no meio das paredes. A câmera desliza de sala em sala, e uma barra no alto da tela mostra a vida, as ferramentas, o modo e o cronômetro.
- **Baús.** 6 baús: as 3 ferramentas e 3 corações.
- **Ordem linear.** A bomba fica na sala a leste do início, com uma parede rachada ao lado escondendo um coração. A chama fica a oeste, atrás de uma parede rachada, na sala do primeiro inimigo de gelo. A mola fica a nordeste, atrás do gelo, com um degrau ao lado e um coração em cima dele. O chefe fica ao norte, atrás de um degrau alto, de um bloco de gelo e de uma parede rachada, nessa ordem. Cada bloqueio aparece antes da ferramenta que o resolve, e cada ferramenta nova tem um uso por perto.
- **Seeds.** O menu oferece a linear e uma seed aleatória de seis dígitos. A seed embaralha os itens entre os mesmos 6 baús, e o gerador só aceita a distribuição se a lógica do mapa garante caminho até o chefe com as ferramentas que ele exige. A mesma seed gera sempre a mesma distribuição, em qualquer máquina. Das 120 distribuições distintas, 64 são vencíveis.
- **Lógica.** Parede rachada passa com a bomba, gelo com a chama, e o degrau sobe com a mola e desce sempre. Um baú conta como alcançado se alguma casa vizinha for alcançada.
- **Regra dos baús.** Todo baú tem chão logo ao sul. A estocada para cima é a única que passa um pouco além de uma parede de uma casa, e a regra impede abrir um baú através dela.
- **Fim.** Derrotado o chefe, aparece uma relíquia. Tocar nela encerra o capítulo e mostra o tempo, o modo e os baús abertos, com as opções de jogar de novo, nova seed ou voltar ao menu.

## Princípios técnicos

- **Dados separados do mapa.** Ferramentas, locais de item e bloqueios são registrados como dados, por exemplo "este bloqueio exige a ferramenta X". A versão linear é uma distribuição fixa desses dados. Randomizar é gerar outra distribuição válida, sem refazer o mapa.
- **Como os dados ficam.** O mapa do capítulo é texto, um caractere por casa, só com a geometria e as vagas de baús, bloqueios e inimigos (`world/chapter_one/chapter_one_data.gd`). O tipo de cada bloqueio e o item de cada baú ficam em tabelas à parte, e a versão linear é uma dessas tabelas. A lógica de alcance (`progression/chapter_map.gd`) e o gerador de seeds (`progression/randomizer.gd`) só leem esses dados.
- **Conferência fora do Godot.** `tools/check_chapter.py` lê os mesmos dados, confere a geometria das salas e das portas, repete a lógica de alcance, garante que a linear é vencível e que nenhuma combinação de ferramentas prende o jogador num lugar sem volta, e conta as distribuições vencíveis.
- **Tipos de golpe.** Espada, fogo, explosão e onda de choque (`combat/hit.gd`). Cada alvo decide como reage a cada tipo, e é isso que faz cada ferramenta servir para umas coisas e não para outras.
- **Passo fixo de física.** Movimento e física rodam a 60 ticks por segundo, independentes da taxa de quadros. Técnicas de precisão precisam funcionar do mesmo jeito em qualquer máquina.

## Plataforma

- **Engine:** Godot 4.7 com GDScript.
- **Meta:** Steam e consoles.
- **Renderizador:** Compatibility. Exige menos do hardware e permite exportar para navegador, o que ajuda em testes rápidos. A troca para outro renderizador é simples, se necessária.
- **Resolução base:** 320x180 com escala inteira (4x em 720p, 6x em 1080p, 12x em 4K). Provisória, ver questões em aberto.

## Questões em aberto

- **Proporção da tela.** O SNES mostrava uma área quase quadrada, de 16 por 14 tiles. Em 16:9 a área fica mais larga e mais baixa, o que muda a sensação de diorama. Define o tamanho de toda a arte.
- **Autoria da arte** para o lançamento.
- **Sensação do andar e da corrida.** Arranque e parada instantâneos ou com inércia, velocidade da corrida, janela do duplo toque, tempo até o desequilíbrio, tempo para reagir e tempo caído. Todos esses parâmetros estão expostos no personagem (`player/player.tscn`) e podem ser ajustados com o jogo rodando. Valores iniciais: andar a 90 px/s, correr a 150 px/s, duplo toque em até 0,25 s, 0,4 s de corrida até o desequilíbrio, 0,5 s para reagir, no mínimo 0,8 s caído. Com esses valores, quem sai correndo encostado numa parede começa a cair no meio da tela.
- **Equilíbrio recuperado.** Hoje, ao se equilibrar, o personagem para de correr. A alternativa é continuar correndo com o tempo reiniciado, mais próximo do Tony Hawk's Pro Skater, o que permite corridas longas para quem tem ritmo.
- **Invencibilidade na corrida.** Hoje não há. A esquiva funciona por velocidade e posição, o que preserva a camada de habilidade e dá sentido ao custo do desequilíbrio.
- **Valores da física.** Massa, restituição, velocidade mínima de ricochete e atrito do personagem e dos objetos. Valores iniciais: personagem com massa 1, restituição 1 e ricochete acima de 120 px/s, caixa leve com massa 0,5 e bloco pesado com massa 4.
- **Strafe.** Botão que trava a frente (em teste) ou L e R para andar de lado. Uma terceira opção é a frente ficar travada enquanto o ataque giratório carrega, o que daria o strafe sem botão extra.
- **Armas.** Quais armas existem, como se alternam e quais servem de chave.
- **Detalhes da espada.** Dano em toda a lâmina ou só na ponta. Recuo no personagem ao acertar uma parede ou algo pesado. Golpe durante a corrida como ataque especial em vez de encerrar a corrida.
- **Invencibilidade dos inimigos.** Hoje cada aperto acerta de novo, sem pausa entre golpes no mesmo inimigo.
- **Quarta ferramenta.** A ideia inicial era cerca de 4 ferramentas por capítulo. O capítulo 1 tem 3.
- **Bomba.** Hoje ela machuca o próprio personagem, como no ALttP, é infinita e tem limite de 2 no chão. Bombas contadas mudariam o ritmo.
- **Pulo e ataques.** Hoje o pulo só evita as ondas de choque. Os botes dos inimigos e a granada do ugly acertam no ar.
- **Ataques só em quatro direções.** Em espera desde 2026-10-31. A ideia era que todos os inimigos atacassem só em norte, sul, leste e oeste. Hoje o bote segue em 8 direções, e o ugly ficou bom assim.
- **Minion com lança.** Em espera desde 2026-10-31. Uma lança na mão apontando para onde ele vai atacar, e um bote que trava a direção e passa direto pelo personagem. A forma ideal de matá-lo seria esperar a direção travar, sair da linha e acertá-lo de lado enquanto ele passa.
- **Dano do bote do ugly.** Hoje são 2 de 6 pontos de vida. A ideia inicial era tirar metade da barra.
- **Pulo correndo contra o degrau.** Correndo, um pulo que começa perto demais da face bate nela e ricocheteia, porque o personagem chega antes de estar alto o bastante. É coerente com a física, mas pode frustrar.
- **Ajuste do chefe.** Vida, tempo da casca e ritmo dos ataques ainda não foram jogados.
- **Texto no menu e no HUD.** O princípio de não ter dicas escritas vale para o mundo. O menu, o cronômetro e a tela de fim usam texto por enquanto.
- **Voltar ao menu.** Esc, ou o botão Back do controle, volta ao menu na hora e perde a partida, sem confirmação.
- **Nome do jogo.** O nome Alttp2 é provisório. Ele remete a uma marca registrada e não deve ser usado no lançamento.
