# Alttp2 (nome provisório)

Aventura top-down original, inspirada na jogabilidade de A Link to the Past e na estrutura dos randomizers e dos Metroidvanias. Cada ferramenta é arma e chave. Cada partida usa uma seed que redistribui as ferramentas e sempre garante um caminho até o fim.

Visão, princípios e decisões estão em [docs/design.md](docs/design.md).

## Como abrir

1. Instale o [Godot 4.7](https://godotengine.org/download), na versão padrão (a versão .NET não é necessária).
2. No gerenciador de projetos do Godot, clique em **Importar** e selecione o arquivo `project.godot` desta pasta.
3. Pressione **F5** para rodar.

## Controles

- **Mover:** WASD, setas, analógico esquerdo ou direcional do controle. Sempre em 8 direções.
- **Correr:** dois toques rápidos na mesma direção, segurando no segundo. Correndo demais, o personagem perde o equilíbrio e pisca em vermelho. Aperte a direção oposta para se equilibrar, ou ele cai.
- **Andar de lado:** segure Shift, ou L ou R no controle, para manter a direção de frente.
- **Atacar:** J, Z ou Espaço no teclado, botão de baixo ou da esquerda no controle (A ou X no padrão Xbox).

## Estrutura

- `player/` personagem do jogador, cena e script.
- `physics/` física de massa e momento usada pelo personagem e pelos objetos.
- `objects/` objetos do mundo, como a caixa leve e o bloco pesado.
- `enemies/` inimigos de teste, um pesado e um leve.
- `ui/` interface, por enquanto só a vida no canto da tela.
- `util/` funções compartilhadas, como a conversão de segundos em ticks.
- `world/` salas e mapas. `test_room.tscn` é a sala de teste atual, com uma porta estreita, uma coluna, uma caixa leve, um bloco pesado e os dois inimigos.
- `docs/` documentação de design.

## Cores provisórias do personagem

- **Vermelho:** andando.
- **Laranja:** correndo.
- **Pisca em vermelho e treme:** desequilibrado. Aperte a direção oposta.
- **Cinza e deitado:** caído, se arrastando até parar.
- **Branco:** arremessado por uma batida, sem controle.
- **Transparente piscando:** invencível depois de tomar dano.

## Cores provisórias dos inimigos

- **Amarelo piscando e tremendo:** preparando o bote. Saia da linha.
- **Vermelho:** dando o bote. Só aqui ele causa dano.
- **Escuro:** parado e vulnerável depois do bote.
- **Branco:** acabou de levar um golpe.

## Ajustar a sensação do andar

Com o jogo rodando (F5), abra a aba **Remoto** no painel de cena do editor, selecione `Player` e altere os valores no Inspetor. O efeito é imediato. Para guardar um valor, altere também em `player/player.tscn`.
