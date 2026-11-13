"""Monta o mapa do laboratório (world/lab/lab_data.gd) a partir das salas
descritas aqui, uma por mecânica.

Cada sala traz só o miolo, sem as paredes de fora: 18 por 8 casas numa sala
de uma tela, e 20 casas a mais por tela extra de largura. As portas são
abertas pelo script, sempre no meio da parede: no norte e no sul nas colunas
9 e 10 da tela, no oeste e no leste nas linhas 4 e 5. Uma porta com bloqueio
recebe o caractere da vaga uma casa para dentro, com parede dos dois lados.

Para mudar o laboratório, edite as salas abaixo e rode:
    python3 tools/lab/build_lab.py
    python3 tools/check_chapter.py world/lab/lab_data.gd
"""

import os
import shutil
import subprocess

ROOM_W, ROOM_H = 20, 10

# Tipo de cada vaga de bloqueio.
BLOCKS = {
    "1": "LOCKED",
    "2": "LOCKED",
    "3": "LOCKED",
    "4": "BOSS_DOOR",
    "5": "CRACKED",
    "7": "BOARDED",
    "8": "THICK_ICE",
    "9": "ICE",
    "b": "GATE",
    "d": "LEDGE",
    "v": "LEDGE",
    "r": "LEDGE",
    "t": "TALL_LEDGE",
    "e": "SHUTTER",
    "f": "BARRIER",
    "g": "BARRIER_ALT",
    "h": "TORCH_DOOR",
    "j": "BLAST_DOOR",
    "k": "TIMED_GATE",
    "l": "PIT",
    "n": "WIDE_PIT",
    "o": "GAP",
    "p": "WEB",
    "q": "BEAM_DOOR",
    "a": "POWER_DOOR",
}

# Item de cada baú.
ITEMS = {
    "A": "BOMB",
    "B": "KEY",
    "C": "HEART",
    "D": "HEART",
    "E": "FIRE",
    "F": "KEY",
    "G": "SPRING",
    "H": "KEY",
    "I": "STRONG_SPRING",
    "J": "STRONG_FIRE",
    "K": "STRONG_BOMB",
    "L": "BOSS_KEY",
    "M": "HEART",
    "N": "HEART",
    "O": "STRONG_SWORD",
    "P": "HEART",
    "Q": "KEY",
    "R": "HEART",
    "S": "HEART",
    "T": "HEART",
    "U": "HEART",
    "V": "HEART",
    "W": "HEART",
    "X": "HEART",
}

# Cada sala: tela do canto (x, y), largura em telas, portas, miolo e, na
# ordem de leitura, o texto de cada placa "?". Numa sala de várias telas, a
# porta do norte ou do sul leva o número da tela: "N0", "S1".
ROOMS = [
    # --- Entrada e salão central ---
    {
        "name": "Entrada",
        "at": (3, 5),
        "doors": {"N": "."},
        "rows": [
            "..................",
            "..................",
            "....?........?....",
            "..................",
            "..................",
            "........@.........",
            "..................",
            "..................",
        ],
        "messages": [
            "Laboratório: cada sala testa uma mecânica nova. A placa da sala diz qual é.",
            "Os desenhos daqui são provisórios. Vale o que acontece, não a aparência.",
        ],
    },
    {
        "name": "Salão central",
        "at": (3, 4),
        "wide": 2,
        "doors": {"W": ".", "N0": "5", "N1": "9", "E": "l", "S0": ".", "S1": "1"},
        "rows": [
            "......................................",
            "........?...................?.........",
            "......................................",
            "......................................",
            "..?................................?..",
            "......................................",
            "............................?.........",
            "......................................",
        ],
        "messages": [
            "Norte, parede rachada: ala da bomba.",
            "Norte, gelo: ala do fogo.",
            "Oeste, aberta: ala da espada. Comece por ela.",
            "Leste, buraco: ala da mola.",
            "Sul, trancada: sala do feixe de luz. As chaves estão nas alas.",
        ],
    },
    # --- Ala da espada ---
    {
        "name": "Sala de combate",
        "at": (2, 4),
        "doors": {"E": "e", "W": "e", "N": "e", "S": "3"},
        "rows": [
            "..................",
            "...m..........m...",
            "..................",
            "........?.........",
            "..................",
            "..................",
            "....]........u....",
            "..................",
        ],
        "messages": ["Sala de combate: as portas vermelhas só abrem com todos os inimigos mortos."],
    },
    {
        "name": "Cristal",
        "at": (1, 4),
        "doors": {"E": ".", "W": ".", "N": ".", "S": "."},
        "rows": [
            ".....#.....#......",
            ".....#.....#......",
            "..!..#..!..#..!...",
            ".....g.....f......",
            ".....g.....f......",
            ".....#.....#......",
            ".....#.....#..?...",
            ".....#.....#......",
        ],
        "messages": ["Cristal: cada golpe troca as barreiras. A azul abre quando a laranja fecha."],
    },
    {
        "name": "Arena de levas",
        "at": (0, 4),
        "doors": {"E": "e", "N": "e"},
        "rows": [
            "...#..............",
            "...#........_.....",
            ".A.#..............",
            "...e.....?........",
            "...e..............",
            "...#..............",
            "...#..._....._....",
            "...#..............",
        ],
        "messages": ["Arena: três levas de inimigos. As portas abrem depois da última."],
        "waves": ["mmm", "m]u", ")(m"],
    },
    {
        "name": "Torretas e blocos",
        "at": (2, 3),
        "doors": {"S": "."},
        "rows": [
            "........B.........",
            "..................",
            "oooooooooooooooooo",
            "..................",
            "....}...[....}....",
            "..................",
            "......[...?.......",
            "..................",
        ],
        "messages": [
            "Torretas atiram em cruz. O bloco azul para o tiro e tampa o buraco. A bomba o devolve."
        ],
    },
    {
        "name": "Estátua espelhada",
        "at": (1, 3),
        "doors": {"S": "."},
        "rows": [
            ".....#............",
            ".{...#...♜........",
            "..................",
            "##################",
            "..................",
            ".........?....#kk#",
            "..............#C.#",
            "..............#..#",
        ],
        "messages": ["A estátua copia seus passos ao contrário. Leve-a até a placa verde."],
    },
    {
        "name": "Gelo liso",
        "at": (0, 3),
        "doors": {"S": ".", "N": "."},
        "rows": [
            "########..########",
            "~~#~~~~~~~~~~~~~~~",
            "~~~~~~~~~~#~~~~~~~",
            "~~~~~~~~~~~~#~~D~~",
            "~~~~~~~~##~~~~~.~~",
            "~~~~~~~~~~~~~~~~~~",
            "~~~~~#~~~~~~~~~#~~",
            "...?..............",
        ],
        "messages": ["Gelo liso: você desliza reto até bater em algo. Escolha a direção a cada parada."],
    },
    {
        "name": "Inimigos novos",
        "at": (0, 2),
        "doors": {"S": "e", "E": "e"},
        "rows": [
            "..............#O.#",
            "....].........#..#",
            "..............#ee#",
            "..................",
            ".........?........",
            "..................",
            "....(.....)..]....",
            "..................",
        ],
        "messages": [
            "Escudeiro: só leva golpe de lado ou por trás. Soprador: empurra com vento. Rastro: deixa fogo."
        ],
    },
    {
        "name": "Bloco no gelo",
        "at": (1, 2),
        "doors": {"W": "."},
        "rows": [
            "............o#....",
            "...~~~~#~~..o#....",
            "...~~~~~~~..o.....",
            "...~~~~~~~..o#.R..",
            "...~~~~~~~..o#....",
            ".[.~~~~~~~..o#....",
            "...~~~~~~~..o#....",
            ".?..........o#....",
        ],
        "messages": ["No gelo o bloco desliza até bater. Leve-o ao buraco em frente à passagem."],
    },
    # --- Ala da bomba ---
    {
        "name": "Alvo de explosão",
        "at": (3, 3),
        "doors": {"S": ".", "N": "j"},
        "rows": [
            "..................",
            "..................",
            "..+...........m...",
            "..................",
            "..........?.......",
            "..................",
            "..............m...",
            "..................",
        ],
        "messages": ["Alvo roxo: só a explosão da bomba o aciona. Ele abre a porta roxa."],
    },
    {
        "name": "Vento e bomba",
        "at": (3, 2),
        "doors": {"S": ".", "W": ".", "N": "2"},
        "rows": [
            "E.#...........⇓...",
            "..#...............",
            "jj#........#nnnnn#",
            "...........#nnnnn#",
            ".....?.....#nnnnn#",
            "...........#......",
            "...........#..+...",
            "...........#......",
        ],
        "messages": ["O vento carrega a bomba por cima do buraco. Solte-a na frente do ventilador."],
    },
    {
        "name": "Blocos em ordem",
        "at": (2, 2),
        "doors": {"E": "."},
        "rows": [
            "..................",
            "..###.............",
            "..#F#.............",
            "..#.#.............",
            "..#.#.............",
            "...[..............",
            "....[.....?.......",
            "..................",
        ],
        "messages": ["Empurre o bloco para o lado certo. Se travar o corredor, a bomba desfaz."],
    },
    # --- Ala do fogo ---
    {
        "name": "Tochas",
        "at": (4, 3),
        "doors": {"S": ".", "N": "h", "E": "."},
        "rows": [
            "..................",
            "..|............|..",
            "..................",
            "........?.........",
            "..................",
            "......i.....i.....",
            "..|............|..",
            "..................",
        ],
        "messages": ["Acenda as quatro tochas com a chama para abrir a porta amarela."],
    },
    {
        "name": "Tochas com tempo",
        "at": (5, 3),
        "doors": {"W": ".", "N": "h"},
        "rows": [
            "..................",
            "./............/...",
            "..................",
            "..................",
            ".......?..........",
            "..............#pp#",
            "./............#H.#",
            "..............#..#",
        ],
        "messages": ["Estas tochas apagam sozinhas: acenda as três antes. A teia só sai com fogo."],
    },
    {
        "name": "Sala escura",
        "at": (4, 2),
        "doors": {"S": ".", "N": "."},
        "dark": True,
        "rows": [
            "..................",
            ".####.####.####.|.",
            "......#..y...#....",
            ".|.##.#.####.#.##.",
            "...#....#....#..#.",
            ".###.####.##.####.",
            "......|...#...y...",
            "..................",
        ],
        "messages": [],
    },
    {
        "name": "Tochas em ordem",
        "at": (4, 1),
        "doors": {"S": "."},
        "rows": [
            ".......#G.#.......",
            ".......#..#.......",
            ".......#hh#.......",
            "..③..........②....",
            "........?.........",
            "..................",
            "..①..........④....",
            "..................",
        ],
        "messages": ["Acenda na ordem das pedrinhas ao pé de cada tocha. Errou, apagam todas."],
    },
    {
        "name": "Corrida da placa",
        "at": (5, 2),
        "doors": {"S": ".", "N": "."},
        "rows": [
            "..............#P..",
            "..............#.;.",
            ".##############kk#",
            "..................",
            ".#################",
            "..................",
            "......;..?........",
            "..................",
        ],
        "messages": ["A placa abre a grade verde por 4 segundos. Corra."],
    },
    {
        "name": "Buraco largo",
        "at": (5, 1),
        "doors": {"S": ".", "E": ".", "N": "."},
        "rows": [
            "...nnnnn..........",
            ".N.nnnnn..........",
            "...nnnnn..........",
            "...nnnnn....?.....",
            "...nnnnn..........",
            "...nnnnn..........",
            "...nnnnn..........",
            "...nnnnn..........",
        ],
        "messages": ["Buraco largo: só a mola forte, com corrida, chega ao outro lado."],
    },
    {
        "name": "Degrau duplo",
        "at": (6, 1),
        "doors": {"W": "."},
        "rows": [
            ".......#^^^^M^^^^^",
            ".......#^^^^^^^^^^",
            ".......#tttttttttt",
            ".......#tttttttttt",
            "..................",
            "..?...............",
            "..................",
            "..................",
        ],
        "messages": ["Degrau duplo: só a mola forte sobe."],
    },
    # --- Ala da mola ---
    {
        "name": "Buracos e vento",
        "at": (5, 4),
        "doors": {"W": ".", "S": "."},
        "rows": [
            "......ll..........",
            "......ll......(...",
            "......ll..........",
            "......ll..........",
            "..?...ll..........",
            "......ll......(...",
            "......ll..........",
            "......ll..........",
        ],
        "messages": ["Buraco: pule com a mola. Cair custa vida e devolve à entrada da sala."],
    },
    {
        "name": "Corredor sob ataque",
        "at": (5, 5),
        "wide": 2,
        "doors": {"N0": ".", "N1": "."},
        "rows": [
            ":::s:::#..#::::s:::::::u:::#..#:::s:::",
            ":::::::#..#::::::::::::::::#..#:::::::",
            "ddddddd#..##vvvvvvvvvvvvvvv#..#rrrrrrr",
            "..........ll......←←←←................",
            "..........ll..#...←←←←..#...ll........",
            "...?......ll..#...←←←←..#...ll........",
            "..........ll..#...←←←←..#...ll........",
            "..................←←←←..#.............",
        ],
        "messages": ["Corredor sob ataque: atravesse até a outra porta. A esteira puxa para trás."],
    },
    {
        "name": "Piso quebradiço",
        "at": (6, 4),
        "doors": {"S": ".", "N": "."},
        "rows": [
            "...............Q..",
            "..........?.......",
            "▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒##",
            "##############▒▒##",
            "##▒▒▒▒▒▒▒▒▒▒▒▒▒▒##",
            "##▒▒##############",
            "##▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒",
            "..................",
        ],
        "messages": ["Piso quebradiço: racha ao pisar e cai ao sair. Não pise duas vezes na mesma casa."],
    },
    {
        "name": "Esteiras e torretas",
        "at": (6, 3),
        "doors": {"S": ".", "N": "."},
        "rows": [
            "..................",
            "..}............}..",
            "→→→→→→→→→→→→→→→→→→",
            "..................",
            "←←←←←←←←←←←←←←←←←←",
            "..................",
            "..}.....?......}..",
            "..................",
        ],
        "messages": ["Esteiras: carregam quem está no chão. Pular passa por cima."],
    },
    {
        "name": "Portais",
        "at": (6, 2),
        "doors": {"S": "."},
        "rows": [
            ".....#......#.....",
            ".α...#..β...#..I..",
            ".....#......#.....",
            "..γ..#......#..γ..",
            "######......######",
            "..................",
            "...α.....?....β...",
            "..................",
        ],
        "messages": ["Portais: pisar num leva ao outro da mesma cor."],
    },
    # --- Segunda leva ---
    {
        "name": "Eletricidade",
        "at": (1, 5),
        "doors": {"N": ".", "W": "."},
        "rows": [
            "..................",
            "..............#S.#",
            "..........▣...#..#",
            "..............#aa#",
            "..⚡═══.═══.═══⏻...",
            "..................",
            "......▣......?....",
            "..................",
        ],
        "messages": ["Eletricidade: empurre os blocos de metal para fechar as falhas do fio."],
    },
    {
        "name": "Ímã",
        "at": (0, 5),
        "doors": {"E": "."},
        "rows": [
            "........o.........",
            ".T......o.........",
            "........o.........",
            "..▣.....o.....∩...",
            "........o.........",
            "........o....?....",
            "........o.........",
            "........o.........",
        ],
        "messages": ["Ímã: um golpe de espada o liga, e ele puxa o bloco de metal da mesma linha."],
    },
    {
        "name": "Nível de água",
        "at": (5, 0),
        "doors": {"S": ".", "E": ".", "W": "."},
        "rows": [
            ".......U..........",
            "..................",
            "≈≈≈≈≈≈≈≈≈≈≈≈▭≈≈≈≈≈",
            "◢≈≈≈≈≈≈≈≈≈≈≈▭≈≈≈≈◢",
            "◢≈≈≈≈≈≈≈≈≈≈≈▭≈≈≈≈◢",
            "≈≈≈≈≈≈≈≈≈≈≈≈▭≈≈≈≈≈",
            "....◢......!..?...",
            "..................",
        ],
        "messages": ["O cristal troca o nível da água. Cheia, a balsa é ponte. Vazia, o leito é chão."],
    },
    {
        "name": "Clone",
        "at": (6, 0),
        "doors": {"W": "."},
        "rows": [
            "..............#V..",
            "..............#.{.",
            "..............#kk#",
            "..................",
            "....◎....?........",
            "..................",
            "..¦...............",
            "..................",
        ],
        "messages": ["A marca grava 5 segundos dos seus passos. O clone repete e pesa na placa."],
    },
    {
        "name": "Inimigo como peso",
        "at": (4, 0),
        "doors": {"E": "."},
        "rows": [
            "..............#W..",
            "..............#.{.",
            "..............#kk#",
            "........#.........",
            "..m....l;l...?....",
            "........#.........",
            "..m...............",
            "..................",
        ],
        "messages": ["A placa fica numa ilha. Atraia um inimigo por cima dela, sem matá-lo."],
    },
    {
        "name": "Porão",
        "at": (2, 0),
        "doors": {},
        "rows": [
            "..................",
            "........X.........",
            "..................",
            "..................",
            "....ⓐ........Ⓑ....",
            "..........?.......",
            "..................",
            "..................",
        ],
        "messages": ["Porão: o buraco da antessala cai aqui. O outro buraco leva de volta."],
    },
    # --- Salas trancadas ---
    {
        "name": "Feixe de luz",
        "at": (4, 5),
        "doors": {"N": "."},
        "rows": [
            "..............#J..",
            "..............#...",
            "...◉........╱.#qq#",
            "..................",
            ".......?..........",
            "..................",
            ".▶..........╲.....",
            "..................",
        ],
        "messages": ["Feixe de luz: um golpe de espada vira o espelho. Leve a luz até o olho."],
    },
    {
        "name": "Bloco e botão",
        "at": (2, 5),
        "doors": {"N": "."},
        "rows": [
            "..................",
            "..............#K.#",
            "..............#..#",
            "..............#bb#",
            "..................",
            "....=....0........",
            "..................",
            "..................",
        ],
        "messages": [],
    },
    # --- Reta final ---
    {
        "name": "Antessala",
        "at": (3, 1),
        "doors": {"S": ".", "N": "4", "W": "."},
        "rows": [
            "..................",
            "...............Ⓐ..",
            "###########.......",
            ".887..nnnnn.......",
            ".887..nnnnn..?....",
            "###########.......",
            "............ⓑ.ω...",
            "..................",
        ],
        "messages": [
            "Oeste: buraco largo, tábuas e gelo grosso. Depois, a fuga. O portal do cofre chega aqui."
        ],
    },
    {
        "name": "Fuga do fogo",
        "at": (0, 1),
        "wide": 3,
        "doors": {"E": ".", "N0": "."},
        "rows": [
            "........................ll......#...........#...ll.....-..",
            ".............#..........ll......#...........#...ll...#....",
            ".............#..........ll..#...#...............ll...#....",
            ".....?..................ll..#................#..ll........",
            "........................ll..#................#..ll........",
            ".............#..........ll..#...#...........#...ll...#....",
            ".............#..........ll......#...........#...ll...#....",
            "........................ll......#...............ll........",
        ],
        "messages": ["Fim da fuga. O cofre fica ao norte."],
    },
    {
        "name": "Cofre",
        "at": (0, 0),
        "doors": {"S": "."},
        "rows": [
            "..................",
            "........L.........",
            "..................",
            "..................",
            "....δ.............",
            "..................",
            "..................",
            "..................",
        ],
        "messages": [],
    },
    {
        "name": "Arena do chefe",
        "at": (3, 0),
        "doors": {"S": "."},
        "rows": [
            "..................",
            "..................",
            "..................",
            "........&.........",
            "..................",
            "..................",
            "..................",
            "..................",
        ],
        "messages": [],
    },
]


def build():
    width = max(r["at"][0] + r.get("wide", 1) for r in ROOMS) * ROOM_W
    height = (max(r["at"][1] for r in ROOMS) + 1) * ROOM_H
    grid = [[" "] * width for _ in range(height)]
    messages, waves, dark, big = {}, {}, [], []
    for room in ROOMS:
        sx, sy = room["at"]
        wide = room.get("wide", 1)
        x0, y0 = sx * ROOM_W, sy * ROOM_H
        w = wide * ROOM_W
        inner = w - 2
        rows = room["rows"]
        assert len(rows) == ROOM_H - 2, room["name"]
        for y in range(ROOM_H):
            for x in range(w):
                grid[y0 + y][x0 + x] = "#"
        texts = list(room.get("messages", []))
        for y, row in enumerate(rows):
            assert len(row) == inner, "%s, linha %d: %d casas" % (room["name"], y, len(row))
            for x, character in enumerate(row):
                grid[y0 + 1 + y][x0 + 1 + x] = character
                if character == "?":
                    messages[(x0 + 1 + x, y0 + 1 + y)] = texts.pop(0)
        assert not texts, "%s: sobram textos de placa" % room["name"]
        for side, slot in room["doors"].items():
            screen = int(side[1:]) if len(side) > 1 else 0
            carve(grid, side[0], slot, x0 + screen * ROOM_W, y0, x0, w)
        if wide > 1:
            big.append((sx, sy, wide, 1))
        if "waves" in room:
            waves[(sx, sy)] = room["waves"]
        if room.get("dark"):
            dark.append((sx, sy))
    return ["".join(row).rstrip() for row in grid], messages, waves, dark, big


def carve(grid, side, slot, sx0, y0, x0, w):
    """Abre a porta de um lado. sx0 é a coluna da tela da porta, x0 e w são
    a coluna e a largura da sala."""
    if side in "NS":
        border = y0 if side == "N" else y0 + ROOM_H - 1
        inside = border + (1 if side == "N" else -1)
        for x in (sx0 + 9, sx0 + 10):
            grid[border][x] = "."
            grid[inside][x] = slot
        if slot != ".":
            grid[inside][sx0 + 8] = "#"
            grid[inside][sx0 + 11] = "#"
    else:
        border = x0 if side == "W" else x0 + w - 1
        inside = border + (1 if side == "W" else -1)
        for y in (y0 + 4, y0 + 5):
            grid[y][border] = "."
            grid[y][inside] = slot
        if slot != ".":
            grid[y0 + 3][inside] = "#"
            grid[y0 + 6][inside] = "#"


HEADER = '''class_name LabData
## Dados do laboratório, a dungeon fechada em que as mecânicas novas são
## testadas antes de entrar nas dungeons do jogo. Fica fora do mundo e das
## seeds, e abre pelo botão Laboratório do menu.
##
## Este arquivo é gerado por tools/lab/build_lab.py, que descreve uma sala
## por mecânica. Para mudar o laboratório, edite as salas lá e rode o script.
## A legenda dos objetos novos está em progression/map_legend.gd, e o código
## deles em lab/.
##
## São %d telas de 20 por 10 casas numa grade de 7 por 6. O personagem chega
## só com a espada e acha as ferramentas e as melhorias nas alas.
##
## Salas, pela tela do canto:
%s

# gdlint: disable=max-line-length
'''


def write(path):
    rows, messages, waves, dark, big = build()
    screens = sum(r.get("wide", 1) for r in ROOMS)
    names = "\n".join(
        "## - (%d, %d) %s" % (r["at"][0], r["at"][1], r["name"])
        for r in sorted(ROOMS, key=lambda r: (r["at"][1], r["at"][0]))
    )
    out = [HEADER % (screens, names)]
    out.append("const MAP := [\n")
    for row in rows:
        out.append('\t"%s",\n' % row)
    out.append("]\n\n## Telas que formam uma sala maior, em unidades de tela.\n")
    out.append("const ROOMS := [\n")
    for room in big:
        out.append("\tRect2i(%d, %d, %d, %d),\n" % room)
    out.append("]\n\n## O personagem chega só com a espada.\n")
    out.append("const STARTING_TOOLS := []\n\n## Tipo de cada vaga de bloqueio.\n")
    out.append("const BLOCKS := {\n")
    for slot, kind in BLOCKS.items():
        out.append('\t"%s": ChapterMap.Block.%s,\n' % (slot, kind))
    out.append("}\n\n## Item de cada baú.\nconst ITEMS := {\n")
    for location, item in ITEMS.items():
        out.append('\t"%s": Item.Id.%s,\n' % (location, item))
    out.append("}\n\n## Texto de cada placa, pela casa dela.\nconst MESSAGES := {\n")
    for (x, y), text in sorted(messages.items(), key=lambda m: (m[0][1], m[0][0])):
        out.append('\tVector2i(%d, %d):\n\t"%s",\n' % (x, y, text))
    out.append("}\n\n## Levas de inimigos de cada arena, pela tela: um inimigo por letra.\n")
    out.append("const WAVES := {\n")
    for (x, y), wave in waves.items():
        out.append("\tVector2i(%d, %d): [%s],\n" % (x, y, ", ".join('"%s"' % w for w in wave)))
    out.append("}\n\n## Telas das salas escuras.\nconst DARK_ROOMS := [\n")
    for x, y in dark:
        out.append("\tVector2i(%d, %d),\n" % (x, y))
    out.append("]\n\n## Alvo da lógica, para tools/check_chapter.py: a sentinela e o que ela exige.\n")
    out.append('const GOAL := "&"\n')
    out.append("const GOAL_TOOLS := [Item.Id.BOMB, Item.Id.FIRE, Item.Id.SPRING]\n")
    with open(path, "w", encoding="utf-8") as output:
        output.write("".join(out))
    # O arquivo sai no formato do gdformat, o mesmo que o GitHub confere.
    if shutil.which("gdformat"):
        subprocess.run(["gdformat", path], check=True, stdout=subprocess.DEVNULL)
    else:
        print("AVISO: gdformat não encontrado, rode gdformat no arquivo gerado")
    print("%s: %d telas, %d salas" % (os.path.normpath(path), screens, len(ROOMS)))


if __name__ == "__main__":
    root = os.path.join(os.path.dirname(__file__), "..", "..")
    write(os.path.join(root, "world", "lab", "lab_data.gd"))
