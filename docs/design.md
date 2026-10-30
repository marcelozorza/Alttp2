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
- **Ação básica.** Ainda não está decidido se haverá espada ou outro tipo de ataque.
- **Sensação do andar.** Arranque e parada instantâneos ou com inércia, deslizar em quinas, número de direções.
- **Primeira área do protótipo.** Quais 4 ferramentas e o que cada uma destrava.
- **Nome do jogo.** O nome Alttp2 é provisório. Ele remete a uma marca registrada e não deve ser usado no lançamento.
