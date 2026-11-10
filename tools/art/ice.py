"""Inimigos de gelo no traço de 2026-11-10: o cubo e a estalactite, 16 e 15
quadros na grade fina. Formas grandes e redondas, olhos grandes com brilho,
bochecha rosada e contorno na tinta do Giorgino, como o minion e o lobo.

O cubo é um bloco de gelo de cantos redondos, com o topo mais claro e dois
pezinhos. A estalactite é um cristal em ponta com dois cristais menores na
base e presas de gelo, que lembram a morsa.

Em cada família, todos os quadros têm o mesmo tamanho e os pés na mesma
linha, para o corpo não pular quando o desenho troca.

Uso: python3 tools/art/ice.py && python3 tools/pixel_svg.py
"""

from canvas import Canvas

INK = "#1e181e"
B1, B2, B3, B4, B5 = "#1a2452", "#27409a", "#3b7bdc", "#6cc3f2", "#c6efff"
WHITE, PINK, RED = "#ffffff", "#e49aa4", "#d83a3f"


def finish(c):
    c.outline(INK)
    return c


def flash(c):
    for old, new in [(B5, WHITE), (B4, B5), (B3, B4), (B2, B3)]:
        c.replace(old, new)
    return c


def eye(c, x, y, mood):
    """Olho grande de 3 por 4 com brilho em cima à esquerda."""
    if mood == "shut":
        c.rect(x, y + 2, 3, 1, INK)
    elif mood == "dizzy":
        c.px(x, y + 1, INK)
        c.px(x + 2, y + 1, INK)
        c.px(x + 1, y + 2, INK)
        c.px(x, y + 3, INK)
        c.px(x + 2, y + 3, INK)
    else:
        c.rect(x, y, 3, 4, INK)
        c.px(x, y, WHITE)
        if mood in ("angry", "bite"):
            c.rect(x - 1, y - 1, 5, 1, B2)


def face(c, x, y, mood, gap=5):
    """Cara de frente centrada em x: olhos, bochechas e boca."""
    eye(c, x - gap - 2, y, mood)
    eye(c, x + gap - 1, y, mood)
    if mood in ("angry", "bite"):
        c.px(x - gap + 1, y, B2)
        c.px(x + gap - 1, y, B2)
    c.rect(x - gap - 4, y + 4, 2, 2, PINK)
    c.rect(x + gap + 2, y + 4, 2, 2, PINK)
    if mood == "bite":
        c.rect(x - 3, y + 4, 6, 4, INK)
        c.rect(x - 2, y + 6, 4, 2, RED)
        c.px(x - 2, y + 4, WHITE)
        c.px(x + 1, y + 4, WHITE)
    elif mood == "angry":
        c.rect(x - 3, y + 5, 6, 2, WHITE)
        c.rect(x - 3, y + 4, 6, 1, INK)
        c.rect(x - 3, y + 7, 6, 1, INK)
        c.px(x - 1, y + 5, INK)
        c.px(x + 1, y + 6, INK)
    elif mood == "dizzy":
        c.rect(x - 2, y + 6, 4, 1, INK)
    else:
        c.px(x - 2, y + 5, INK)
        c.rect(x - 1, y + 6, 2, 1, INK)
        c.px(x + 1, y + 5, INK)


def face_side(c, x, y, mood):
    """Cara de lado, olhando para a direita: um olho e a boca na beira."""
    eye(c, x, y, mood)
    c.rect(x - 4, y + 4, 2, 2, PINK)
    if mood == "bite":
        c.rect(x + 3, y + 4, 4, 4, INK)
        c.rect(x + 4, y + 6, 3, 2, RED)
        c.px(x + 5, y + 4, WHITE)
    elif mood == "angry":
        c.rect(x + 3, y + 5, 4, 2, WHITE)
        c.rect(x + 3, y + 4, 4, 1, INK)
        c.rect(x + 3, y + 7, 4, 1, INK)
    else:
        c.rect(x + 4, y + 6, 3, 1, INK)


# ---------------------------------------------------------------- cubo

CW, CH = 40, 40
CCX, CGROUND = 20, 38


def cube_body(c, w, h, lift=0, top=7):
    """Bloco de cantos redondos. Devolve o canto de cima à esquerda."""
    x0 = CCX - w // 2
    y0 = CGROUND - 2 - lift - h
    # Pezinhos.
    c.ellipse(CCX - w / 4, CGROUND - 1.5 - min(lift, 1), 3.5, 2, B2)
    c.ellipse(CCX + w / 4, CGROUND - 1.5 - min(lift, 1), 3.5, 2, B2)
    c.rect(x0, y0, w, h, B4)
    c.rect(x0, y0, w, top, B5)
    c.rect(x0 + w - 3, y0 + top, 3, h - top, B3)
    c.rect(x0, y0 + h - 2, w, 2, B3)
    for dx, dy in [(0, 0), (1, 0), (0, 1), (w - 1, 0), (w - 2, 0), (w - 1, 1)]:
        c.p[y0 + dy][x0 + dx] = None
    for dx, dy in [(0, h - 1), (1, h - 1), (0, h - 2), (w - 1, h - 1), (w - 2, h - 1), (w - 1, h - 2)]:
        c.p[y0 + dy][x0 + dx] = None
    # Brilho do topo e reflexo em diagonal na frente.
    c.rect(x0 + 3, y0 + 2, w // 3, 2, WHITE)
    c.rect(x0 + w - 7, y0 + 3, 3, 1, WHITE)
    c.line(x0 + 2, y0 + top + 5, x0 + 5, y0 + top + 2, B5)
    c.line(x0 + 2, y0 + top + 8, x0 + 3, y0 + top + 7, B5)
    return x0, y0 + top


def cube_front(mood="calm", w=24, h=24, lift=0):
    c = Canvas(CW, CH)
    x0, fy = cube_body(c, w, h, lift)
    face(c, CCX, fy + (h - 7) // 2 - 4, mood)
    return finish(c)


def cube_back(w=24, h=24, lift=0):
    c = Canvas(CW, CH)
    x0, fy = cube_body(c, w, h, lift)
    # Bolhas presas no gelo.
    c.rect(x0 + w - 9, fy + 4, 2, 2, B5)
    c.px(x0 + w - 6, fy + 8, B5)
    c.rect(x0 + 7, fy + 9, 2, 2, B3)
    c.line(x0 + w // 2, fy + 3, x0 + w // 2 + 3, fy + 7, B3)
    return finish(c)


def cube_side(mood="calm", w=24, h=24, lift=0):
    c = Canvas(CW, CH)
    x0, fy = cube_body(c, w, h, lift)
    face_side(c, x0 + w - 11, fy + (h - 7) // 2 - 4, mood)
    return finish(c)


def cube_recover():
    c = Canvas(CW, CH)
    c.ellipse(CCX, CGROUND - 2, 16, 2.5, B5)
    x0, fy = cube_body(c, 26, 21)
    face(c, CCX, fy + 3, "dizzy")
    c.rect(x0 + 21, fy - 3, 2, 3, WHITE)
    return finish(c)


def cube_fallen():
    c = Canvas(CW, CH)
    c.ellipse(CCX, CGROUND - 3, 16, 3.5, B4)
    c.ellipse(CCX - 3, CGROUND - 4, 9, 1.5, B5)
    for x, y, s in [(CCX - 9, CGROUND - 7, 4), (CCX + 3, CGROUND - 9, 5), (CCX + 10, CGROUND - 6, 3)]:
        c.poly([(x, y + s), (x + s // 2, y), (x + s, y + s)], B5)
        c.px(x + s // 2, y + 1, WHITE)
    return finish(c)


def cube_frames():
    return {
        "ice_cube_down": (cube_front(), "Cubo de gelo: de frente, parado."),
        "ice_cube_down_step": (cube_front(w=26, h=22), "Cubo de gelo: de frente, achatado no passo."),
        "ice_cube_up": (cube_back(), "Cubo de gelo: de costas."),
        "ice_cube_up_step": (cube_back(26, 22), "Cubo de gelo: de costas, achatado no passo."),
        "ice_cube_side": (cube_side(), "Cubo de gelo: de lado, olhando para a direita."),
        "ice_cube_side_step": (cube_side(w=26, h=22), "Cubo de gelo: de lado, achatado no passo."),
        "ice_cube_windup": (cube_front("angry", 28, 19), "Cubo de gelo: achatado e bravo, preparando o bote."),
        "ice_cube_lunge_down": (cube_front("bite", 22, 27, 4), "Cubo de gelo: bote de frente, esticado no ar."),
        "ice_cube_lunge_down_step": (cube_front("bite", 22, 26, 2), "Cubo de gelo: bote de frente, segundo quadro."),
        "ice_cube_lunge_up": (cube_back(22, 27, 4), "Cubo de gelo: bote de costas."),
        "ice_cube_lunge_up_step": (cube_back(22, 26, 2), "Cubo de gelo: bote de costas, segundo quadro."),
        "ice_cube_lunge_side": (cube_side("bite", 22, 27, 4), "Cubo de gelo: bote de lado."),
        "ice_cube_lunge_side_step": (cube_side("bite", 22, 26, 2), "Cubo de gelo: bote de lado, segundo quadro."),
        "ice_cube_recover": (cube_recover(), "Cubo de gelo: tonto, derretendo um pouco."),
        "ice_cube_hit": (flash(cube_front("shut", 26, 22)), "Cubo de gelo: levando dano."),
        "ice_cube_fallen": (cube_fallen(), "Cubo de gelo: derretido, sem vida."),
    }


# ---------------------------------------------------------- estalactite

SW, SH = 48, 52
SCX, SGROUND = 24, 50


def shard(c, x, y, s, size=9):
    """Cristal pequeno da base, inclinado para o lado s."""
    c.poly([(x - 3, y), (x + s * 5, y - size), (x + 4, y)], B4)
    c.poly([(x + (1 if s > 0 else -3), y), (x + s * 5, y - size), (x + (4 if s > 0 else -1), y)], B3 if s > 0 else B5)


def crystal(c, tip, height, half, lift=0):
    """Cristal principal em ponta, com a face esquerda clara e a direita
    escura. tip é o desvio da ponta em x. Devolve o y da base."""
    base = SGROUND - 7 - lift
    top = base - height
    tx = SCX + tip
    c.ellipse(SCX, base, half, 4.5, B3)
    c.poly([(SCX - half, base), (tx, top), (SCX + half, base)], B4)
    c.poly([(SCX + 2, base), (tx, top), (SCX + half, base)], B3)
    c.poly([(SCX - half + 2, base), (tx, top), (SCX - half // 2, base)], B5)
    c.line(SCX - 1 + tip // 2, base - 17, tx, top + 2, WHITE)
    c.ellipse(SCX - 2, base + 1, half - 2, 3, B4)
    c.ellipse(SCX + half / 2, base + 1.5, half / 2 - 1, 2.5, B3)
    c.px(tx, top, WHITE)
    c.px(tx, top + 1, WHITE)
    return base


def feet(c, lift=0):
    y = SGROUND - 2 - min(lift, 1)
    c.ellipse(SCX - 6, y, 4, 2.5, B2)
    c.ellipse(SCX + 6, y, 4, 2.5, B2)


def tusks(c, x, y):
    """Presas de gelo, que caem dos lados da boca."""
    for dx in (-4, 3):
        c.rect(x + dx, y, 2, 3, WHITE)
        c.px(x + dx + (0 if dx < 0 else 1), y + 3, WHITE)


def spike_front(mood="calm", height=34, half=13, lift=0, tip=0):
    c = Canvas(SW, SH)
    feet(c, lift)
    shard(c, SCX - 12, SGROUND - 6 - lift, -1)
    shard(c, SCX + 12, SGROUND - 6 - lift, 1)
    base = crystal(c, tip, height, half, lift)
    face(c, SCX, base - 12, mood, 4)
    tusks(c, SCX, base - 5 if mood in ("calm", "shut", "dizzy") else base - 3)
    return finish(c)


def spike_back(height=34, half=13, lift=0, tip=0):
    c = Canvas(SW, SH)
    feet(c, lift)
    shard(c, SCX - 12, SGROUND - 6 - lift, -1)
    shard(c, SCX + 12, SGROUND - 6 - lift, 1)
    base = crystal(c, tip, height, half, lift)
    c.line(SCX + 4, base - 3, SCX + 2 + tip // 2, base - 14, B2)
    c.line(SCX - 6, base - 3, SCX - 4 + tip // 2, base - 10, WHITE)
    return finish(c)


def spike_side(mood="calm", height=34, half=13, lift=0, tip=2):
    c = Canvas(SW, SH)
    feet(c, lift)
    shard(c, SCX - 11, SGROUND - 6 - lift, -1)
    base = crystal(c, tip, height, half, lift)
    face_side(c, SCX + 3, base - 12, mood)
    if mood != "bite":
        c.rect(SCX + 8, base - 5, 2, 3, WHITE)
        c.px(SCX + 9, base - 2, WHITE)
    return finish(c)


def spear_side(step=0):
    """Bote de lado: o cristal deita e voa de ponta para a direita."""
    c = Canvas(SW, SH)
    y = SGROUND - 16 - step
    x0 = SCX - 16 + step * 2
    c.ellipse(x0, y, 4.5, 11, B3)
    c.poly([(x0, y - 11), (x0 + 36, y + 2), (x0, y + 11)], B4)
    c.poly([(x0, y + 3), (x0 + 36, y + 2), (x0, y + 11)], B3)
    c.poly([(x0, y - 9), (x0 + 36, y + 2), (x0, y - 5)], B5)
    c.line(x0 + 2, y - 2, x0 + 33, y + 1, WHITE)
    c.ellipse(x0 - 1, y - 1, 3, 9, B4)
    face_side(c, x0 + 9, y - 6, "bite")
    for dy in (-9, 0, 9):
        c.rect(x0 - 12 - step * 2, y + dy, 5, 1, B5)
    return finish(c)


def spike_recover():
    c = Canvas(SW, SH)
    feet(c)
    shard(c, SCX - 12, SGROUND - 6, -1, 6)
    shard(c, SCX + 12, SGROUND - 6, 1, 6)
    base = crystal(c, 5, 29, 14)
    face(c, SCX, base - 11, "dizzy", 4)
    tusks(c, SCX, base - 4)
    c.rect(SCX + 14, base - 22, 2, 3, WHITE)
    return finish(c)


def spike_frames():
    return {
        "stalactite_down": (spike_front(), "Estalactite: de frente, parada."),
        "stalactite_down_step": (spike_front(height=32, half=14, tip=1), "Estalactite: de frente, passo."),
        "stalactite_up": (spike_back(), "Estalactite: de costas."),
        "stalactite_up_step": (spike_back(32, 14, tip=1), "Estalactite: de costas, passo."),
        "stalactite_side": (spike_side(), "Estalactite: de lado, olhando para a direita."),
        "stalactite_side_step": (spike_side(height=32, half=14, tip=3), "Estalactite: de lado, passo."),
        "stalactite_windup": (
            spike_front("angry", 27, 15, tip=-2),
            "Estalactite: agachada e brava, preparando o bote.",
        ),
        "stalactite_lunge_down": (spike_front("bite", 38, 12, 5), "Estalactite: bote de frente, esticada no ar."),
        "stalactite_lunge_down_step": (spike_front("bite", 37, 12, 3), "Estalactite: bote de frente, segundo quadro."),
        "stalactite_lunge_up": (spike_back(38, 12, 5), "Estalactite: bote de costas."),
        "stalactite_lunge_up_step": (spike_back(37, 12, 3), "Estalactite: bote de costas, segundo quadro."),
        "stalactite_lunge_side": (spear_side(0), "Estalactite: bote de lado, deitada e de ponta."),
        "stalactite_lunge_side_step": (spear_side(1), "Estalactite: bote de lado, segundo quadro."),
        "stalactite_recover": (spike_recover(), "Estalactite: tonta, com a ponta torta."),
        "stalactite_hit": (flash(spike_front("shut", 32, 14)), "Estalactite: levando dano."),
    }


def main():
    note = "\nGerado por tools/art/ice.py."
    for frames in (cube_frames(), spike_frames()):
        for name, (canvas, text) in frames.items():
            canvas.save(name, text + note)


if __name__ == "__main__":
    main()
