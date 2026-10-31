"""Confere os dados de um capítulo sem abrir o Godot.

Lê o arquivo de dados em GDScript (MAP, BLOCKS, LINEAR, GOAL e GOAL_TOOLS),
confere a geometria das salas e repete a lógica de alcance de
progression/chapter_map.gd para garantir que a distribuição linear é
vencível, que nenhuma combinação de ferramentas prende o jogador e quantas
distribuições embaralhadas são válidas.

Uso: python3 tools/check_chapter.py world/chapter_one/chapter_one_data.gd
"""

import itertools
import re
import sys
from collections import Counter

ROOM_W, ROOM_H = 20, 10
LOCATIONS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
SLOTS = "123456789"
ACTORS = "lhi*c@"
STEPS = [(0, -1), (0, 1), (-1, 0), (1, 0)]
TOOLS = ["BOMB", "FIRE", "SPRING"]
ITEM_BITS = {"NONE": 0, "BOMB": 1, "FIRE": 2, "SPRING": 3, "HEART": 4}


def bit(name):
    return 1 << ITEM_BITS[name]


def parse(path):
    text = open(path, encoding="utf-8").read()
    map_block = re.search(r"const MAP := \[(.*?)\n\]", text, re.S).group(1)
    rows = re.findall(r'^\t"(.*)",$', map_block, re.M)
    blocks = dict(re.findall(r'"(\d)": ChapterMap\.Block\.(\w+)', text))
    linear_block = re.search(r"const LINEAR := \{(.*?)\n\}", text, re.S).group(1)
    linear = dict(re.findall(r'"(\w)": Item\.Id\.(\w+)', linear_block))
    goal = re.search(r'const GOAL := "(.)"', text).group(1)
    goal_tools = re.search(r"const GOAL_TOOLS := \[(.*?)\]", text).group(1)
    goal_mask = 0
    for name in re.findall(r"Item\.Id\.(\w+)", goal_tools):
        goal_mask |= bit(name)
    return rows, blocks, linear, goal, goal_mask


class Map:
    def __init__(self, rows, blocks):
        self.rows = rows
        self.blocks = blocks
        self.height = len(rows)
        self.width = max(len(r) for r in rows)

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

    def is_walkable(self, cell, tools):
        character = self.tile(cell)
        if character in "# " or character in LOCATIONS:
            return False
        block = self.block_at(cell)
        if block == "CRACKED":
            return bool(tools & bit("BOMB"))
        if block == "ICE":
            return bool(tools & bit("FIRE"))
        if block == "LEDGE":
            return False
        return True

    def step(self, cell, step, tools):
        nxt = (cell[0] + step[0], cell[1] + step[1])
        if self.block_at(nxt) != "LEDGE":
            return nxt if self.is_walkable(nxt, tools) else None
        climbing = step == (0, -1) and bool(tools & bit("SPRING"))
        if not climbing and step != (0, 1):
            return None
        beyond = (nxt[0] + step[0], nxt[1] + step[1])
        return beyond if self.is_walkable(beyond, tools) else None

    def reachable(self, start, tools):
        reached = {start}
        frontier = [start]
        while frontier:
            cell = frontier.pop()
            for step in STEPS:
                nxt = self.step(cell, step, tools)
                if nxt is not None and nxt not in reached:
                    reached.add(nxt)
                    frontier.append(nxt)
        return reached

    def reached_locations(self, reached):
        found = []
        for y, row in enumerate(self.rows):
            for x, character in enumerate(row):
                if character in LOCATIONS and any(
                    (x + dx, y + dy) in reached for dx, dy in STEPS
                ):
                    found.append(character)
        return found

    def spheres(self, distribution):
        """Devolve as esferas (baús abertos a cada rodada) e o estado final."""
        start = self.find("@")
        tools, collected, spheres = 0, set(), []
        while True:
            reached = self.reachable(start, tools)
            new = [l for l in self.reached_locations(reached) if l not in collected]
            if not new:
                return spheres, tools, reached
            spheres.append(new)
            collected.update(new)
            for location in new:
                item = distribution.get(location, "NONE")
                if item in TOOLS:
                    tools |= bit(item)

    def is_beatable(self, distribution, goal, goal_mask):
        _, tools, reached = self.spheres(distribution)
        return self.find(goal) in reached and (tools & goal_mask) == goal_mask


def check_geometry(m, blocks, linear, goal, errors):
    rooms_x = (m.width + ROOM_W - 1) // ROOM_W
    rooms_y = m.height // ROOM_H
    if m.height % ROOM_H:
        errors.append("altura do mapa não é múltipla de %d" % ROOM_H)
    counts = Counter("".join(m.rows))
    for character, total in counts.items():
        allowed = "#.: " + LOCATIONS + SLOTS + ACTORS
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
            for x in range(ROOM_W):
                for y in range(ROOM_H):
                    border = x in (0, ROOM_W - 1) or y in (0, ROOM_H - 1)
                    cell = (rx * ROOM_W + x, ry * ROOM_H + y)
                    if not border or m.tile(cell) == "#":
                        continue
                    # Abertura na borda: precisa continuar na sala vizinha.
                    if x == 0:
                        other = (cell[0] - 1, cell[1])
                    elif x == ROOM_W - 1:
                        other = (cell[0] + 1, cell[1])
                    elif y == 0:
                        other = (cell[0], cell[1] - 1)
                    else:
                        other = (cell[0], cell[1] + 1)
                    if m.tile(other) in "# ":
                        errors.append("porta sem continuação em %s" % (cell,))
    # Vagas: cada número forma um retângulo cheio, e o tipo existe.
    for slot in sorted(set(c for c in "".join(m.rows) if c in SLOTS)):
        cells = [(x, y) for y, row in enumerate(m.rows) for x, c in enumerate(row) if c == slot]
        xs = [c[0] for c in cells]
        ys = [c[1] for c in cells]
        area = (max(xs) - min(xs) + 1) * (max(ys) - min(ys) + 1)
        if area != len(cells):
            errors.append("vaga %s não é um retângulo" % slot)
        if slot not in blocks:
            errors.append("vaga %s sem tipo em BLOCKS" % slot)
            continue
        if blocks[slot] == "LEDGE":
            if len(set(ys)) != 1:
                errors.append("degrau %s precisa ocupar uma linha só" % slot)
            for x, y in cells:
                for side in (-1, 1):
                    neighbor = m.tile((x, y + side))
                    if neighbor in "# " or neighbor in SLOTS or neighbor in LOCATIONS:
                        errors.append("degrau %s sem chão acima e abaixo em %s" % (slot, (x, y)))
    for slot in blocks:
        if slot not in "".join(m.rows):
            errors.append("BLOCKS cita a vaga %s, que não está no mapa" % slot)
    # Baús: chão logo ao sul, para que a espada nunca alcance um baú através de
    # uma parede ou de um bloqueio.
    map_locations = set(c for c in "".join(m.rows) if c in LOCATIONS)
    for location in map_locations:
        x, y = m.find(location)
        if m.tile((x, y + 1)) not in ".:":
            errors.append("baú %s precisa de chão logo ao sul" % location)
        if counts[location] != 1:
            errors.append("baú %s aparece mais de uma vez" % location)
    if map_locations != set(linear):
        errors.append("baús do mapa %s e de LINEAR %s diferem" % (sorted(map_locations), sorted(linear)))
    return present


def check_logic(m, linear, goal, goal_mask, errors):
    start = m.find("@")
    # Nenhuma combinação de ferramentas pode prender o jogador: de toda casa
    # alcançável, tem de dar para voltar ao início.
    for count in range(len(TOOLS) + 1):
        for combo in itertools.combinations(TOOLS, count):
            tools = sum(bit(t) for t in combo)
            for cell in m.reachable(start, tools):
                if start not in m.reachable(cell, tools):
                    errors.append("armadilha em %s com %s" % (cell, combo or "nada"))
                    break
    spheres, _, _ = m.spheres(linear)
    if not m.is_beatable(linear, goal, goal_mask):
        errors.append("a distribuição linear não é vencível")
    items = sorted(linear.values())
    total, valid = 0, 0
    for perm in set(itertools.permutations(items)):
        total += 1
        distribution = dict(zip(sorted(linear), perm))
        if m.is_beatable(distribution, goal, goal_mask):
            valid += 1
    return spheres, total, valid


def main(path):
    rows, blocks, linear, goal, goal_mask = parse(path)
    m = Map(rows, blocks)
    errors = []
    present = check_geometry(m, blocks, linear, goal, errors)
    spheres, total, valid = check_logic(m, linear, goal, goal_mask, errors)
    print("salas:", len(present), sorted(present))
    print("esferas da linear:")
    for i, sphere in enumerate(spheres):
        print("  %d: %s" % (i, ", ".join("%s=%s" % (l, linear[l]) for l in sorted(sphere))))
    print("distribuições distintas: %d, vencíveis: %d" % (total, valid))
    for error in errors:
        print("ERRO:", error)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
