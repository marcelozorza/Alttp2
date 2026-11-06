# Alttp2

Jogo de aventura top-down em Godot 4.7 com GDScript. Visão, princípios e decisões ficam em `docs/design.md`. Atualize esse documento quando uma decisão for tomada ou mudar.

## Convenções

- Identificadores de código em inglês. Comentários e documentação em português.
- GDScript com tipagem estática.
- Arquivos e pastas em snake_case, organizados por funcionalidade (`player/`, `world/`), com cena e script lado a lado.
- Movimento e física rodam em `_physics_process` (passo fixo). Nada que afete o resultado de uma ação pode depender da taxa de quadros.
- Ferramentas, locais de item e bloqueios são dados separados do mapa. A versão linear do jogo é uma distribuição fixa desses dados.
- Tudo usa placeholders (formas e cores simples) até as decisões visuais serem tomadas.

## Verificação

- Rode `gdformat --check .` e `gdlint .` (pacote `gdtoolkit` no PyPI) em todo script alterado.
- Rode `python3 tools/check_chapter.py <arquivo de dados>` em todo capítulo alterado. Nenhuma linha `ERRO` pode aparecer.
- Com o Godot disponível, rode também o teste de fumaça descrito no topo de `tools/smoke_test.gd`. Nenhuma linha com `SCRIPT ERROR` ou `ERROR` pode aparecer.
