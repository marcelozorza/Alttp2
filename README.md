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

## Estrutura

- `player/` personagem do jogador, cena e script.
- `world/` salas e mapas. `test_room.tscn` é a sala de teste atual, com uma porta estreita e uma coluna para testar o andar.

## Ajustar a sensação do andar

Com o jogo rodando (F5), abra a aba **Remoto** no painel de cena do editor, selecione `Player` e altere os valores no Inspetor. O efeito é imediato. Para guardar um valor, altere também em `player/player.tscn`.
- `docs/` documentação de design.
