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

- **Capítulos.** Áreas pequenas, como uma dungeon com cerca de 4 ferramentas-chave. O jogador primeiro joga a área na forma linear e aprende o vocabulário. Depois a mesma área, ou uma nova, aparece embaralhada.

## Direção visual (em discussão)

Referência: o mundo de ALttP como uma caixa de brinquedos, um diorama. Elementos identificados até agora:

1. **Perspectiva 3/4.** O chão visto de cima e a fachada dos objetos. Casas, muros e penhascos têm volume de maquete. O jogador passa por trás de objetos altos.
2. **Mundo compacto e denso.** Tudo perto, cada tela com algo a fazer, um mapa que cabe na cabeça.
3. **Mundo manipulável.** Objetos que se levantam, empurram e jogam. Isso dá a sensação de brinquedo.
4. **Camadas de altura.** Penhascos, pontes e plataformas que permitem ver um item antes de conseguir alcançá-lo. Ver o prêmio do outro lado de um bloqueio ensina o jogador a voltar quando tiver a ferramenta certa.

## Movimento

Limitações também definem o jogo. As decisões abaixo podem ser revistas depois de jogadas.

- **Sem pulo.** O personagem não pula. Desníveis viram bloqueios naturais, o que reforça a ideia de ver o prêmio antes de alcançá-lo.
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

## Combate

- **Curta distância.** O ataque principal é corpo a corpo.
- **Um só botão de ataque.** Sem divisão entre ataque fraco e forte.
- **A arma define a forma do ataque.** Ideias até agora: uma lança que ataca só para frente, com alcance maior, e uma espada que ataca em leque à frente.
- **Ataque giratório.** Segurar o botão de ataque carrega um golpe de 360 graus.
- **Armas também são ferramentas.** Como entram na distribuição da seed, a forma de cada ataque pode servir de chave. Por exemplo, o alcance da lança pode atingir um interruptor do outro lado de um vão. Ainda é só ideia.

## Princípios técnicos

- **Dados separados do mapa.** Ferramentas, locais de item e bloqueios são registrados como dados, por exemplo "este bloqueio exige a ferramenta X". A versão linear é uma distribuição fixa desses dados. Randomizar é gerar outra distribuição válida, sem refazer o mapa.
- **Passo fixo de física.** Movimento e física rodam a 60 ticks por segundo, independentes da taxa de quadros. Técnicas de precisão precisam funcionar do mesmo jeito em qualquer máquina.

## Plataforma

- **Engine:** Godot 4.7 com GDScript.
- **Meta:** Steam e consoles.
- **Renderizador:** Compatibility. Exige menos do hardware e permite exportar para navegador, o que ajuda em testes rápidos. A troca para outro renderizador é simples, se necessária.
- **Resolução base:** 320x180 com escala inteira (4x em 720p, 6x em 1080p, 12x em 4K). Provisória, ver questões em aberto.

## Questões em aberto

- **Proporção da tela.** O SNES mostrava uma área quase quadrada, de 16 por 14 tiles. Em 16:9 a área fica mais larga e mais baixa, o que muda a sensação de diorama. Define o tamanho de toda a arte.
- **Autoria da arte** para o lançamento.
- **Sensação do andar e da corrida.** Arranque e parada instantâneos ou com inércia, velocidade da corrida, janela do duplo toque, tempo até o desequilíbrio, tempo para reagir e tempo caído. Todos esses parâmetros estão expostos no personagem (`player/player.tscn`) e podem ser ajustados com o jogo rodando. Valores iniciais: andar a 90 px/s, correr a 150 px/s, duplo toque em até 0,25 s, 0,6 s de corrida até o desequilíbrio, 0,5 s para reagir, no mínimo 0,8 s caído.
- **Equilíbrio recuperado.** Hoje, ao se equilibrar, o personagem para de correr. A alternativa é continuar correndo com o tempo reiniciado, mais próximo do Tony Hawk's Pro Skater, o que permite corridas longas para quem tem ritmo.
- **Invencibilidade.** Proposta: só depois de tomar dano, com o personagem piscando, para evitar dano em sequência. Na corrida, nenhuma. A esquiva funciona por velocidade e posição, o que preserva a camada de habilidade e dá sentido ao custo do desequilíbrio.
- **Valores da física.** Massa, restituição, velocidade mínima de ricochete e atrito do personagem e dos objetos. Valores iniciais: personagem com massa 1, restituição 1 e ricochete acima de 120 px/s, caixa leve com massa 0,5 e bloco pesado com massa 4.
- **Strafe.** Botão que trava a frente (em teste) ou L e R para andar de lado. Uma terceira opção é a frente ficar travada enquanto o ataque giratório carrega, o que daria o strafe sem botão extra.
- **Armas.** Quais armas existem, como se alternam e quais servem de chave.
- **Primeira área do protótipo.** Quais 4 ferramentas e o que cada uma destrava.
- **Nome do jogo.** O nome Alttp2 é provisório. Ele remete a uma marca registrada e não deve ser usado no lançamento.
