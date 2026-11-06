"""Confere os dados de um capítulo sem abrir o Godot.

Lê o arquivo de dados em GDScript (MAP, BLOCKS, ITEMS, GOAL, GOAL_TOOLS e, se
houver, STARTING_TOOLS, as ferramentas com que o personagem chega, e ROOMS, as
salas maiores que uma tela), confere a geometria das salas e repete as regras
de alcance do jogo para garantir que o capítulo é vencível em qualquer ordem
de abrir as portas trancadas e que nenhuma combinação de ferramentas e portas
abertas prende o jogador num lugar sem volta.

As regras de alcance são as do jogo: parede rachada passa com a bomba, gelo
passa com a chama ou a chama forte, gelo grosso só com a chama forte, porta
trancada passa depois de aberta com uma chave pequena, porta do chefe passa
com a chave grande, a face de degrau passa de baixo para cima só com a mola e
de cima para baixo sempre, e a face do degrau duplo, de baixo para cima, só
com a mola forte. Um baú conta como alcançado se alguma casa vizinha for
alcançada.

Também confere a leitura visual que o jogo não impõe: todo bloqueio de porta
fica uma casa para dentro da sala, o gelo grosso tem duas casas de fundo, e as
alturas fecham. O chão tem três níveis, "." o comum, ":" o alto e "^" o mais
alto. Casas vizinhas sem uma face de degrau entre elas precisam estar no
mesmo nível, o degrau sobe um nível e o degrau duplo sobe dois.

Como no NES, que guardava o mapa em blocos e não em pixels, a lógica não anda
casa por casa. As casas livres ligadas entre si viram uma região, e cada
bloqueio vira uma região própria. A lógica anda pelo grafo dessas regiões.
Para conferir o próprio grafo, o alcance também é calculado casa por casa, e
os dois precisam dar o mesmo resultado em todas as combinações.

Uso: python3 tools/check_chapter.py world/chapter_one/chapter_one_data.gd
"""

import itertools
import re
import sys
from collections import Counter

ROOM_W, ROOM_H = 20, 10
LOCATIONS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
SLOTS = "123456789abdefghjklnopqrtv"
ACTORS = "muiwsc*&%$@xyz0="
FLOORS = ".:^"
LEVELS = {".": 0, ":": 1, "^": 2}
STEPS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
UP, DOWN = (0, -1), (0, 1)
# A ordem de Item.Id em items/item.gd.
ITEM_IDS = ["NONE", "BOMB", "FIRE", "SPRING", "STRONG_FIRE", "STRONG_SPRING", "HEART", "KEY", "BOSS_KEY"]
PERMANENT = ["BOMB", "FIRE", "SPRING", "STRONG_FIRE", "STRONG_SPRING", "BOSS_KEY"]
BLOCK_TYPES = ["CRACKED", "ICE", "LEDGE", "LOCKED", "BOSS_DOOR", "THICK_ICE", "TALL_LEDGE", "GATE"]
LEDGES = {"LEDGE": 1, "TALL_LEDGE": 2}


def bit(name):
    return 1 << ITEM_IDS.index(name)


def parse(path):
    text = open(path, encoding="utf-8").read()
    map_block = re.search(r"const MAP := \[(.*?)\n\]", text, re.S).group(1)
    rows = re.findall(r'^\t"(.*)",$', map_block, re.M)
    blocks = dict(re.findall(r'"(\w)": ChapterMap\.Block\.(\w+)', text))
    items_block = re.search(r"const ITEMS := \{(.*?)\n\}", text, re.S).group(1)
    items = dict(re.findall(r'"(\w)": Item\.Id\.(\w+)', items_block))
    goal = re.search(r'const GOAL := "(.)"', text).group(1)
    goal_tools = re.search(r"const GOAL_TOOLS := \[(.*?)\]", text).group(1)
    goal_mask = 0
    for name in re.findall(r"Item\.Id\.(\w+)", goal_tools):
        goal_mask |= bit(name)
    starting = 0
    found = re.search(r"const STARTING_TOOLS := \[(.*?)\]", text)
    if found:
        for name in re.findall(r"Item\.Id\.(\w+)", found.group(1)):
            starting |= bit(name)
    rooms = []
    found = re.search(r"const ROOMS := \[(.*?)\n\]", text, re.S)
    if found:
        for match in re.findall(r"Rect2i\((\d+), (\d+), (\d+), (\d+)\)", found.group(1)):
            rooms.append(tuple(int(v) for v in match))
    return rows, blocks, items, goal, goal_mask, starting, rooms


class Map:
    def __init__(self, rows, blocks, starting=0, rooms=()):
        self.rows = rows
        self.blocks = blocks
        self.starting = starting
        self.rooms = list(rooms)
        self.height = len(rows)
        self.width = max(len(r) for r in rows)
        self.locked = sorted(s for s, t in blocks.items() if t == "LOCKED")
        self.gates = sorted(s for s, t in blocks.items() if t == "GATE")
        self.build_graph()

    def room_of_cell(self, cell):
        return room_of((cell[0] // ROOM_W, cell[1] // ROOM_H), self.rooms)

    def cells_of(self, character):
        return [(x, y) for y, row in enumerate(self.rows) for x, c in enumerate(row) if c == character]

    def tile(self, cell):
        x, y = cell
        if y < 0 or y >= self.height or x < 0 or x >= len(self.rows[y]):
            return " "
        return self.rows[y][x]

    def find(self, character):
        for y, row in enumerate(self.rows):
            x = row.find(character)
            if x >= 0:
                return (x, y)
        return None

    def block_at(self, cell):
        return self.blocks.get(self.tile(cell))

    def is_ledge(self, cell):
        return self.block_at(cell) in LEDGES

    def is_space(self, cell):
        character = self.tile(cell)
        if character in "# " or character in LOCATIONS:
            return False
        return not self.is_ledge(cell)

    def slot_of(self, cell):
        character = self.tile(cell)
        return character if character in SLOTS else ""

    def can_enter_slot(self, slot, tools, opened, reached_nodes=None, open_gates=()):
        if slot == "":
            return True
        kind = self.blocks.get(slot)
        if kind == "GATE":
            # A grade abre de vez quando o jogador chega ao interruptor dela,
            # então ela passa, de qualquer lado, assim que a região do
            # interruptor é alcançada, ou se já foi aberta antes.
            if slot in open_gates:
                return True
            source = self.gate_source.get(slot)
            return reached_nodes is not None and source is not None and source in reached_nodes
        if kind == "CRACKED":
            return bool(tools & bit("BOMB"))
        if kind == "ICE":
            return bool(tools & (bit("FIRE") | bit("STRONG_FIRE")))
        if kind == "THICK_ICE":
            return bool(tools & bit("STRONG_FIRE"))
        if kind == "LOCKED":
            return slot in opened
        if kind == "BOSS_DOOR":
            return bool(tools & bit("BOSS_KEY"))
        return False

    def block_reaches(self, block, switch):
        """O bloco chega ao interruptor empurrado em linha reta: os dois na
        mesma linha ou coluna, chão de verdade entre eles e atrás do bloco."""
        dx, dy = switch[0] - block[0], switch[1] - block[1]
        if (dx == 0) == (dy == 0):
            return False
        step = (dx // abs(dx) if dx else 0, dy // abs(dy) if dy else 0)
        cell = (block[0] + step[0], block[1] + step[1])
        while cell != switch:
            if self.tile(cell) not in FLOORS:
                return False
            cell = (cell[0] + step[0], cell[1] + step[1])
        behind = (block[0] - step[0], block[1] - step[1])
        return self.tile(behind) in FLOORS

    def step_target(self, cell, step):
        """Casa de chegada e a ferramenta que o passo exige, como bit, ou
        None. Uma face de degrau só se cruza na vertical: subir exige a mola,
        e no degrau duplo a mola forte. Descer é sempre livre."""
        nxt = (cell[0] + step[0], cell[1] + step[1])
        kind = self.block_at(nxt)
        if kind not in LEDGES:
            return (nxt, 0) if self.is_space(nxt) else None
        if step not in (UP, DOWN):
            return None
        slot = self.tile(nxt)
        beyond = nxt
        while self.tile(beyond) == slot:
            beyond = (beyond[0] + step[0], beyond[1] + step[1])
        if not self.is_space(beyond):
            return None
        need = 0
        if step == UP:
            need = bit("STRONG_SPRING") if kind == "TALL_LEDGE" else bit("SPRING")
        return (beyond, need)

    # Grafo de regiões.

    def build_graph(self):
        self.node_of = {}
        self.node_slot = []
        for y, row in enumerate(self.rows):
            for x in range(len(row)):
                cell = (x, y)
                if not self.is_space(cell) or cell in self.node_of:
                    continue
                node = len(self.node_slot)
                slot = self.slot_of(cell)
                self.node_slot.append(slot)
                self.node_of[cell] = node
                frontier = [cell]
                while frontier:
                    c = frontier.pop()
                    for dx, dy in STEPS:
                        n = (c[0] + dx, c[1] + dy)
                        if n in self.node_of or not self.is_space(n):
                            continue
                        if self.slot_of(n) != slot:
                            continue
                        self.node_of[n] = node
                        frontier.append(n)
        self.find_gate_sources()
        edges = set()
        for cell, node in self.node_of.items():
            for step in STEPS:
                target = self.step_target(cell, step)
                if target is None:
                    continue
                to = self.node_of[target[0]]
                if to != node:
                    edges.add((node, to, target[1]))
        self.edges = sorted(edges)
        self.location_nodes = {}
        for y, row in enumerate(self.rows):
            for x, character in enumerate(row):
                if character in LOCATIONS:
                    self.location_nodes[character] = [
                        self.node_of[(x + dx, y + dy)]
                        for dx, dy in STEPS
                        if (x + dx, y + dy) in self.node_of
                    ]

    def find_gate_sources(self):
        """Região do interruptor de cada grade: um interruptor na mesma sala,
        numa região vizinha da grade. Sem ele, a grade nunca abre."""
        self.gate_source = {}
        self.gate_switches = {}
        for slot in self.gates:
            cells = self.cells_of(slot)
            room = self.room_of_cell(cells[0])
            neighbors = set()
            for cell in cells:
                for dx, dy in STEPS:
                    n = (cell[0] + dx, cell[1] + dy)
                    if n in self.node_of and self.tile(n) != slot:
                        neighbors.add(self.node_of[n])
            self.gate_switches[slot] = [
                s for s in self.cells_of("=") if self.room_of_cell(s) == room
            ]
            for switch in self.gate_switches[slot]:
                node = self.node_of.get(switch)
                if node in neighbors:
                    self.gate_source[slot] = node
                    break

    def can_pass(self, edge, tools, opened, reached, open_gates=()):
        if edge[2] and not tools & edge[2]:
            return False
        return self.can_enter_slot(self.node_slot[edge[1]], tools, opened, reached, open_gates)

    def reachable_nodes(self, start, tools, opened, open_gates=()):
        reached = {start}
        changed = True
        while changed:
            changed = False
            for edge in self.edges:
                if edge[0] in reached and edge[1] not in reached:
                    if self.can_pass(edge, tools, opened, reached, open_gates):
                        reached.add(edge[1])
                        changed = True
        return reached

    def open_gates_from(self, reached):
        """Grades que já abriram de vez, com a região do interruptor alcançada."""
        return {slot for slot in self.gates if self.gate_source.get(slot) in reached}

    def reachable_cells(self, start, tools, opened):
        """Alcance casa por casa, só para conferir o grafo. Uma grade cujo
        interruptor acaba de ser alcançado reabre a busca a partir das casas
        vizinhas dela."""
        reached = {start}
        nodes = {self.node_of[start]}
        frontier = [start]
        while True:
            while frontier:
                cell = frontier.pop()
                for step in STEPS:
                    target = self.step_target(cell, step)
                    if target is None or target[0] in reached:
                        continue
                    if target[1] and not tools & target[1]:
                        continue
                    if not self.can_enter_slot(self.slot_of(target[0]), tools, opened, nodes):
                        continue
                    reached.add(target[0])
                    nodes.add(self.node_of[target[0]])
                    frontier.append(target[0])
            for slot in self.gates:
                if self.gate_source.get(slot) not in nodes:
                    continue
                for cell in self.cells_of(slot):
                    if cell in reached:
                        continue
                    for dx, dy in STEPS:
                        n = (cell[0] + dx, cell[1] + dy)
                        if n in reached and n not in frontier:
                            frontier.append(n)
            if not frontier:
                return reached

    def settle(self, items, opened):
        """Abre tudo o que alcança com as portas dadas, ganha os itens e
        repete até não haver novidade. Devolve também a ordem em que os baús
        se tornam alcançáveis, em esferas."""
        start = self.node_of[self.find("@")]
        tools, keys, collected = self.starting, 0, set()
        order = []
        while True:
            reached = self.reachable_nodes(start, tools, opened)
            new = [
                loc
                for loc, nodes in sorted(self.location_nodes.items())
                if loc not in collected and any(n in reached for n in nodes)
            ]
            if not new:
                return reached, tools, keys, order
            order.append(new)
            collected.update(new)
            for location in new:
                item = items.get(location, "NONE")
                if item == "KEY":
                    keys += 1
                elif item in PERMANENT:
                    tools |= bit(item)

    def doors_in_reach(self, reached, tools, opened):
        doors = []
        for edge in self.edges:
            slot = self.node_slot[edge[1]]
            if edge[0] not in reached or slot in doors or slot in opened:
                continue
            if self.blocks.get(slot) != "LOCKED":
                continue
            if edge[2] and not tools & edge[2]:
                continue
            doors.append(slot)
        return doors

    def is_beatable(self, items, goal, goal_mask, stuck=None):
        """Vencível em qualquer ordem de abrir portas.

        Cada estado é o conjunto de portas já abertas. Num estado, o jogador
        abre todos os baús que alcança, porque abrir um baú nunca atrapalha, e
        depois pode gastar uma chave em qualquer porta trancada que alcança. O
        capítulo só vale se todo estado sem saída já tiver o alvo alcançado com
        as ferramentas exigidas. Em stuck, se dado, ficam as portas abertas do
        primeiro estado sem saída."""
        goal_node = self.node_of.get(self.find(goal))
        seen = set()
        stack = [frozenset()]
        while stack:
            opened = stack.pop()
            if opened in seen:
                continue
            seen.add(opened)
            reached, tools, keys, _ = self.settle(items, opened)
            doors = []
            if keys - len(opened) > 0:
                doors = self.doors_in_reach(reached, tools, opened)
            if not doors:
                if goal_node not in reached or tools & goal_mask != goal_mask:
                    if stuck is not None:
                        stuck.extend(sorted(opened))
                    return False
            for door in doors:
                stack.append(opened | {door})
        return True


def room_of(screen, rooms):
    """Sala maior que contém a tela, como (x, y, w, h), ou a própria tela."""
    for room in rooms:
        x, y, w, h = room
        if x <= screen[0] < x + w and y <= screen[1] < y + h:
            return room
    return (screen[0], screen[1], 1, 1)


def check_geometry(m, blocks, items, goal, rooms, errors):
    rooms_x = (m.width + ROOM_W - 1) // ROOM_W
    rooms_y = m.height // ROOM_H
    if m.height % ROOM_H:
        errors.append("altura do mapa não é múltipla de %d" % ROOM_H)
    counts = Counter("".join(m.rows))
    for character in counts:
        allowed = "# " + FLOORS + LOCATIONS + SLOTS + ACTORS
        if character not in allowed:
            errors.append("caractere desconhecido %r" % character)
    if counts["@"] != 1:
        errors.append("o mapa precisa de exatamente um @")
    if counts[goal] != 1:
        errors.append("o mapa precisa de exatamente um alvo %r" % goal)
    present = set()
    for ry in range(rooms_y):
        for rx in range(rooms_x):
            cells = [
                (rx * ROOM_W + x, ry * ROOM_H + y)
                for y in range(ROOM_H)
                for x in range(ROOM_W)
            ]
            if all(m.tile(c) == " " for c in cells):
                continue
            present.add((rx, ry))
            if any(m.tile(c) == " " for c in cells):
                errors.append("sala %s tem casas vazias" % ((rx, ry),))
            room = room_of((rx, ry), rooms)
            for x in range(ROOM_W):
                for y in range(ROOM_H):
                    border = x in (0, ROOM_W - 1) or y in (0, ROOM_H - 1)
                    cell = (rx * ROOM_W + x, ry * ROOM_H + y)
                    if not border or m.tile(cell) == "#":
                        continue
                    # Abertura na borda: precisa continuar na sala vizinha.
                    if x == 0:
                        other, neighbor = (cell[0] - 1, cell[1]), (rx - 1, ry)
                    elif x == ROOM_W - 1:
                        other, neighbor = (cell[0] + 1, cell[1]), (rx + 1, ry)
                    elif y == 0:
                        other, neighbor = (cell[0], cell[1] - 1), (rx, ry - 1)
                    else:
                        other, neighbor = (cell[0], cell[1] + 1), (rx, ry + 1)
                    if room_of(neighbor, rooms) == room:
                        # Dentro de uma sala maior, a borda da tela não é borda.
                        continue
                    if m.tile(other) in "# ":
                        errors.append("porta sem continuação em %s" % (cell,))
                    # Bloqueio na borda fica na beira da tela, onde não se vê
                    # direito. Ele vai uma casa para dentro, num nicho.
                    if m.tile(cell) in SLOTS:
                        errors.append(
                            "bloqueio %s na borda da sala em %s: ponha uma casa para dentro"
                            % (m.tile(cell), cell)
                        )
    # Salas maiores: todas as telas existem, e cada duas telas vizinhas se
    # comunicam por dentro da sala.
    for room in rooms:
        x, y, w, h = room
        screens = [(x + dx, y + dy) for dy in range(h) for dx in range(w)]
        for screen in screens:
            if screen not in present:
                errors.append("sala maior %s inclui a tela vazia %s" % (room, screen))
        for sx, sy in screens:
            if sx + 1 < x + w:
                column = (sx + 1) * ROOM_W - 1
                if all(m.tile((column, sy * ROOM_H + i)) == "#" for i in range(ROOM_H)):
                    errors.append("sala maior %s tem parede inteira entre as telas em x=%d" % (room, column))
            if sy + 1 < y + h:
                line = (sy + 1) * ROOM_H - 1
                if all(m.tile((sx * ROOM_W + i, line)) == "#" for i in range(ROOM_W)):
                    errors.append("sala maior %s tem parede inteira entre as telas em y=%d" % (room, line))
    # Vagas: cada caractere forma um retângulo cheio, e o tipo existe.
    for slot in sorted(set(c for c in "".join(m.rows) if c in SLOTS)):
        cells = [(x, y) for y, row in enumerate(m.rows) for x, c in enumerate(row) if c == slot]
        xs = [c[0] for c in cells]
        ys = [c[1] for c in cells]
        w = max(xs) - min(xs) + 1
        h = max(ys) - min(ys) + 1
        if w * h != len(cells):
            errors.append("vaga %s não é um retângulo" % slot)
        if slot not in blocks:
            errors.append("vaga %s sem tipo em BLOCKS" % slot)
            continue
        kind = blocks[slot]
        if kind not in BLOCK_TYPES:
            errors.append("vaga %s com tipo desconhecido %s" % (slot, kind))
        if kind == "THICK_ICE" and min(w, h) < 2:
            errors.append("gelo grosso %s precisa de duas casas de fundo" % slot)
        if kind in LEDGES:
            if h != LEDGES[kind]:
                errors.append(
                    "degrau %s precisa ocupar %d linha(s), ocupa %d" % (slot, LEDGES[kind], h)
                )
            for x in range(min(xs), max(xs) + 1):
                above = m.tile((x, min(ys) - 1))
                below = m.tile((x, max(ys) + 1))
                # Um inimigo em cima do chão alto toma o caractere da casa, e
                # aí o nível fica a cargo de check_heights.
                if above in FLOORS and LEVELS[above] < LEDGES[kind]:
                    errors.append("degrau %s sem chão alto o bastante logo ao norte em %s" % (slot, (x, min(ys))))
                elif above not in FLOORS and above not in ACTORS:
                    errors.append("degrau %s sem chão logo ao norte em %s" % (slot, (x, min(ys))))
                if below in "# " or below in SLOTS or below in LOCATIONS:
                    errors.append("degrau %s sem chão logo ao sul em %s" % (slot, (x, max(ys))))
    for slot in blocks:
        if slot not in "".join(m.rows):
            errors.append("BLOCKS cita a vaga %s, que não está no mapa" % slot)
    check_switches(m, errors)
    # Baús: chão logo ao sul, para que a espada nunca alcance um baú através de
    # uma parede ou de um bloqueio.
    map_locations = set(c for c in "".join(m.rows) if c in LOCATIONS)
    for location in map_locations:
        x, y = m.find(location)
        if m.tile((x, y + 1)) not in FLOORS:
            errors.append("baú %s precisa de chão logo ao sul" % location)
        if counts[location] != 1:
            errors.append("baú %s aparece mais de uma vez" % location)
    if map_locations != set(items):
        errors.append(
            "baús do mapa %s e de ITEMS %s diferem" % (sorted(map_locations), sorted(items))
        )
    for location, item in items.items():
        if item not in ITEM_IDS:
            errors.append("baú %s com item desconhecido %s" % (location, item))
    return present


def check_switches(m, errors):
    """Mecanismo do bloco sobre o interruptor. Toda grade tem na mesma sala
    um interruptor numa região vizinha dela e um bloco pesado alinhado com o
    interruptor, com chão livre entre os dois e atrás do bloco, para o
    personagem ter de onde empurrar. Todo interruptor e todo bloco servem a
    uma grade da sala."""
    used_switches, used_blocks = set(), set()
    for slot in m.gates:
        if slot not in m.gate_source:
            errors.append("grade %s sem interruptor numa região vizinha, na mesma sala" % slot)
            continue
        room = m.room_of_cell(m.cells_of(slot)[0])
        blocks = [b for b in m.cells_of("0") if m.room_of_cell(b) == room]
        solved = False
        for switch in m.gate_switches[slot]:
            if m.node_of.get(switch) != m.gate_source[slot]:
                continue
            for block in blocks:
                if m.block_reaches(block, switch):
                    solved = True
                    used_switches.add(switch)
                    used_blocks.add(block)
        if not solved:
            errors.append(
                "grade %s: nenhum bloco pesado alinhado com o interruptor, com chão "
                "livre entre eles e atrás do bloco" % slot
            )
    for switch in m.cells_of("="):
        if switch not in used_switches:
            errors.append("interruptor em %s sem grade que ele abra" % (switch,))
    for block in m.cells_of("0"):
        if block not in used_blocks:
            errors.append("bloco pesado em %s sem interruptor que ele alcance" % (block,))


def check_heights(m, errors):
    """As alturas fecham: casas vizinhas sem face de degrau entre elas estão
    no mesmo nível, e cada face separa dois níveis com a diferença certa."""
    component = {}
    levels = []
    firsts = []
    for y, row in enumerate(m.rows):
        for x, character in enumerate(row):
            cell = (x, y)
            if character in "# " or m.is_ledge(cell) or cell in component:
                continue
            index = len(levels)
            found = set()
            frontier = [cell]
            component[cell] = index
            while frontier:
                c = frontier.pop()
                if m.tile(c) in LEVELS:
                    found.add(LEVELS[m.tile(c)])
                for dx, dy in STEPS:
                    n = (c[0] + dx, c[1] + dy)
                    if n in component or m.tile(n) in "# " or m.is_ledge(n):
                        continue
                    component[n] = index
                    frontier.append(n)
            if len(found) > 1:
                errors.append(
                    "alturas misturadas %s na região que começa em %s: falta uma face de degrau"
                    % (sorted(found), cell)
                )
            levels.append(found.pop() if len(found) == 1 else None)
            firsts.append(cell)
    for slot in sorted(set(c for c in "".join(m.rows) if c in SLOTS)):
        kind = m.blocks.get(slot)
        if kind not in LEDGES:
            continue
        cells = [(x, y) for y, row in enumerate(m.rows) for x, c in enumerate(row) if c == slot]
        top = min(c[1] for c in cells)
        bottom = max(c[1] for c in cells)
        for x in sorted(set(c[0] for c in cells)):
            above = component.get((x, top - 1))
            below = component.get((x, bottom + 1))
            if above is None or below is None:
                continue
            if levels[above] is None or levels[below] is None:
                errors.append("degrau %s entre regiões sem nível de chão em %s" % (slot, (x, top)))
            elif levels[above] - levels[below] != LEDGES[kind]:
                errors.append(
                    "degrau %s sobe de %d para %d em %s, precisa subir %d"
                    % (slot, levels[below], levels[above], (x, top), LEDGES[kind])
                )


def check_logic(m, items, goal, goal_mask, errors):
    start = m.find("@")
    start_node = m.node_of[start]
    permanent_bits = [bit(t) for t in PERMANENT]
    # Para toda combinação de ferramentas e portas abertas: o grafo concorda
    # com o alcance casa por casa, e de toda casa alcançável dá para voltar ao
    # início, ou seja, nada prende o jogador.
    trap_found = False
    tested = set()
    for count in range(len(PERMANENT) + 1):
        for combo in itertools.combinations(permanent_bits, count):
            tools = sum(combo) | m.starting
            if tools in tested:
                continue
            tested.add(tools)
            for size in range(len(m.locked) + 1):
                for opened in itertools.combinations(m.locked, size):
                    opened = set(opened)
                    cells = m.reachable_cells(start, tools, opened)
                    nodes = m.reachable_nodes(start_node, tools, opened)
                    if {m.node_of[c] for c in cells} != nodes:
                        errors.append("grafo e casas discordam com %s %s" % (tools, opened))
                    if trap_found:
                        continue
                    open_gates = m.open_gates_from(nodes)
                    for node in nodes:
                        if start_node not in m.reachable_nodes(node, tools, opened, open_gates):
                            cell = next(c for c, n in m.node_of.items() if n == node)
                            errors.append(
                                "armadilha perto de %s com ferramentas %d e portas %s"
                                % (cell, tools, sorted(opened))
                            )
                            trap_found = True
                            break
    _, _, _, order = m.settle(items, frozenset(m.locked))
    stuck = []
    if not m.is_beatable(items, goal, goal_mask, stuck):
        errors.append("o capítulo não é vencível, preso com as portas %s" % stuck)
    keys = sum(1 for item in items.values() if item == "KEY")
    if keys < len(m.locked):
        errors.append("%d chaves para %d portas trancadas" % (keys, len(m.locked)))
    return order, keys


def main(path):
    rows, blocks, items, goal, goal_mask, starting, rooms = parse(path)
    m = Map(rows, blocks, starting, rooms)
    errors = []
    present = check_geometry(m, blocks, items, goal, rooms, errors)
    check_heights(m, errors)
    order, keys = check_logic(m, items, goal, goal_mask, errors)
    big = sum(r[2] * r[3] for r in rooms)
    print("telas: %d, salas: %d, maiores: %s" % (len(present), len(present) - big + len(rooms), rooms))
    print(
        "regiões: %d, passagens: %d, portas trancadas: %d, chaves: %d"
        % (len(m.node_slot), len(m.edges), len(m.locked), keys)
    )
    print("esferas dos baús, com todas as portas abertas:")
    for i, sphere in enumerate(order):
        print("  %d: %s" % (i, ", ".join("%s=%s" % (l, items[l]) for l in sorted(sphere))))
    for error in errors:
        print("ERRO:", error)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
