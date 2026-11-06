# Referências de dungeons 2D

Estudo das dungeons dos Zelda 2D, feito em 2026-11-06 para orientar o desenho
dos capítulos. O objetivo é extrair padrões de estrutura, não copiar salas,
itens ou mapas. O jogo continua original.

## Fontes

- Mark Brown, série *Boss Keys*: os episódios sobre A Link to the Past e
  Link's Awakening (transcrições). Os episódios sobre Oracle of Ages e Oracle
  of Seasons e sobre The Minish Cap não puderam ser lidos, só um resumo de
  terceiros do episódio dos Oracle (Bryant Francis, Game Developer, 2016).
- Theodore Homdrom, Zelda Dungeon, 2015: análise da Eagle's Tower, de Link's
  Awakening.
- A experiência de Marcelo com o randomizer de A Link to the Past, que já
  orientava o capítulo 2.

## Como as dungeons clássicas funcionam

**O caminho crítico parece maior do que é.** Em A Link to the Past, a maior
parte das dungeons tem um só caminho, mas ele parece aberto porque há salas
opcionais (mapa, rupias), salas que se veem antes de se poder entrar, chaves
que obrigam a um desvio e um trajeto que cruza a dungeon inteira. Brown diz
que as salas desnecessárias existem para o jogador se sentir um grande
resolvedor de quebra-cabeças.

**A chave fica longe da porta.** Uma porta trancada tem a chave numa sala
lateral, e a dificuldade se ajusta afastando a chave da porta. Com mais de
uma chave na mão (Palace of Darkness), o jogador escolhe em que porta gastar,
o que dá sensação de decisão num conjunto de salas fixo.

**Chaves a mais, sem deixar o jogador preso.** Misery Mire tem cinco chaves e
se resolve com duas. Key Cavern, de Link's Awakening, tem nove chaves para
oito fechaduras, com três portas que levam a salas inúteis: quem deixa as
portas certas para o fim fica sem chave. É uma pegadinha que a nossa lógica
proíbe, porque toda ordem de abrir portas precisa chegar ao fim.

**Rampa antes do chefe.** Desert Palace abre com um salão de sete portas para
explorar e termina num corredor reto e cheio de inimigos até a porta do chefe.
A tensão cresce quando a exploração acaba.

**Portal do chefe fora da fórmula só com motivo.** A volta ao castelo de
Hyrule é a única dungeon linear com cada chave na sala da própria porta,
porque a história é uma perseguição e não um quebra-cabeça.

**O item é visto antes de ser alcançado, e muda a dungeon de uma vez.** Em
Link's Awakening, cada dungeon começa cheia de obstáculos que o item ainda
não permite passar: buracos antes da pena, vasos pesados antes da pulseira,
água funda antes das nadadeiras. Quando o item chega, a dungeon inteira abre
"num instante". Brown chama isso de mini Metroidvania. Depois o item serve
de chave várias vezes (o gancho de Catfish's Maw pega duas chaves pequenas, a
chave do chefe e o caminho até ele), e quase todo chefe ou subchefe cai com o
item da própria dungeon.

**Chave grande separada do item.** Link's Awakening inverte A Link to the
Past: primeiro o item, que dá acesso à chave do pesadelo, que abre o chefe. O
item faz o trabalho de bloqueio, e a chave grande vira o selo final. Em A
Link to the Past, a chave grande abre o baú do item ou a porta da segunda
metade (Misery Mire, Thieves' Town), o que dá uma volta com propósito.

**Cada bloqueio é uma fechadura, e cada ferramenta é um tipo de chave.**
Brown resume: chave pequena, muitas chaves para muitas fechaduras. Chave do
pesadelo, uma chave para uma fechadura. Item, uma chave para muitas
fechaduras. Interruptores de cristal, muitas chaves para uma fechadura gigante.
A bola de ferro da Eagle's Tower, uma chave para quatro fechaduras.

**Um mecanismo, repetido em versões mais difíceis.** Palace of Darkness ensina
os blocos laranja e azul: acionar o interruptor fecha a escada e obriga a dar
a volta. Ice Palace repete a ideia mais difícil, com o desvio escondido. A
Eagle's Tower repete a mesma bola em quatro pilares cada vez mais distantes.

**Verticalidade como quebra-cabeça.** Tower of Hera tem um baú no quarto
andar que só se alcança caindo de um ponto exato do quinto. A Eagle's Tower é
a única dungeon de Link's Awakening com vários andares: o quarto andar
desaba sobre o terceiro, a bola não desce escadas e não se pula com ela nas
mãos, então o jogador a joga à frente, dá a volta e a recolhe. O jogador
passa a pensar na dungeon como um prédio.

**Ajudas que informam sem entregar.** O compasso de Link's Awakening mostra
os baús e toca ao entrar numa sala com chave, o que tira a frustração de uma
chave perdida. As corujas dão dicas opcionais em enigmas. As paredes
bombáveis têm poucas rachaduras visíveis, às vezes marcadas por tochas ou
setas, para manter a descoberta.

**Portas de mão única.** A parede que gira e leva o jogador para a sala
seguinte sem volta obriga a decidir quando avançar.

**Quebra-cabeça justo.** Da análise da Eagle's Tower: o traçado é intuitivo,
cada sala ensina uma ideia em segurança antes de combiná-las, o tema (águias,
pássaros, poços) é coerente, e nada exige decorar para sobreviver.

**Oracle.** Jabu-Jabu's Belly se desenha melhor como uma lista de obstáculos
e do nível da água exigido para cada chave e item do que como mapa de salas.
A ordem documentada deixa o jogador planejar onde voltar.

## Regras adotadas no Alttp2

As regras abaixo valem para todo capítulo, e `tools/check_chapter.py`
confere as que são mecânicas (caminho em qualquer ordem de portas, nenhuma
armadilha, bloqueios fora da beira da tela).

1. **O caminho crítico cruza a dungeon e parece aberto.** Salas opcionais com
   corações, baús à vista antes de alcançáveis e chaves em salas laterais.
2. **Toda ferramenta é vista como bloqueio antes de ser ganha.** O jogador
   encontra o gelo antes da chama, o gelo grosso antes da chama forte. O golpe
   errado faz o bloqueio tremer, o que confirma que falta outra coisa.
3. **A ferramenta nova tem um uso por perto e vários depois.** Logo ao sair do
   baú há um bloqueio dela, e a dungeon inteira abre a partir dali.
4. **O item da dungeon também derrota o chefe.** O chefe é o exame da
   ferramenta e, no capítulo 3 em diante, da melhoria.
5. **Chave grande separada do item.** O item abre o caminho até a chave grande,
   e a chave grande abre a porta do chefe. A chave grande fica depois do item.
6. **Chaves a mais, nunca de menos.** Pode haver mais chaves que portas, mas
   toda ordem de gastar chaves precisa chegar ao fim. É o que a lógica garante.
7. **Escolha entre portas.** Pelo menos um ponto em que o jogador tem uma chave
   e duas portas à vista, e as duas levam a algo.
8. **Um mecanismo por capítulo, repetido mais difícil.** A sala que ensina é
   segura. As seguintes combinam o mecanismo com inimigos ou com outra
   ferramenta.
9. **Rampa antes do chefe.** Depois da chave grande, um trecho mais linear e
   mais cheio de inimigos até a porta do chefe.
10. **Verticalidade visível.** Degraus altos com um prêmio em cima, e descidas
    de mão única que servem de atalho de volta. As alturas precisam ser
    coerentes: num circuito fechado de salas, não pode haver uma descida sem a
    subida correspondente. Foi esse erro que tirava a leitura de altura no
    capítulo 1 e no estrado do capítulo 2, corrigidos em 2026-11-06. Desde o
    capítulo 4 o chão tem três níveis, e o conferidor recusa um mapa em que a
    altura não fecha.
11. **Bloqueio sempre inteiro na tela.** Um bloqueio de porta fica uma casa
    para dentro da sala, num nicho entre duas paredes, nunca na beira da tela.
12. **Tema coerente.** O capítulo 3 é de gelo: gelo grosso, morsas de gelo e o
    guardião antigo têm a mesma paleta azul profunda, e a chama forte é a
    resposta a tudo isso. O capítulo 4 é de pedra: degrau duplo, atiradores
    de pedras nos estrados e o colosso de arenito, e a mola forte sobe tudo.
14. **Salas maiores que a tela** (capítulo 4). Uma arena de duas telas dá ao
    chefe espaço para correr, e uma pedreira de quatro telas deixa o jogador
    ver o platô e os atiradores de longe, como as salas grandes de ALttP.
13. **Sem dicas escritas.** O mapa é a dica. Quem precisa de ajuda tem o som
    do golpe errado e o tremor do bloqueio.

## O que fica de fora

- Mapa, compasso e corujas: o jogo não tem tela de mapa ainda. Fica como
  questão em aberto em `design.md`.
- Interruptores de estado (blocos laranja e azul): bom candidato a mecanismo
  de um capítulo futuro, com a mola ou a bomba como gatilho. O capítulo 4
  ficou com o degrau duplo.
- Objetos carregados com restrições (a bola da Eagle's Tower): depende de
  pegar e carregar, que o Giorgio ainda não faz.
