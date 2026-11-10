"""Cobra no traço de 2026-11-10: 16 quadros na grade fina. Enrolada em dois
anéis, pescoço em S com a barriga amarela e cabeça de olhos amarelos. No
aviso e no bote ela abre o capuz, que é o sinal de perigo.

Todos os quadros têm o mesmo tamanho e os anéis no mesmo lugar, para o corpo
não pular quando o desenho troca.

Uso: python3 tools/art/snake.py && python3 tools/pixel_svg.py
"""

from canvas import Canvas

INK = "#1e181e"
G0, G1, G2, G3, G4 = "#12332f", "#1f5a3a", "#2f8a45", "#59b84c", "#a4dc5a"
Y0, Y1 = "#d99a1c", "#f7c53a"
RED, WHITE = "#d83a3f", "#ffffff"
W, H = 58, 44
CX = 29
GROUND = 42


def coil(c, flat=False):
    """Os dois anéis do corpo e a ponta do rabo."""
    c.poly([(CX + 10, GROUND - 5), (CX + 17, GROUND - 7), (CX + 19, GROUND - 6), (CX + 11, GROUND - 2)], G2)
    c.ellipse(CX, GROUND - 5, 13, 5, G1)
    c.ellipse(CX, GROUND - 6, 13, 4.5, G2)
    c.ellipse(CX, GROUND - 7.5, 9, 2, G3)
    for x in range(CX - 11, CX + 12, 5):
        c.rect(x, GROUND - 4, 2, 2, G1)
    if not flat:
        c.ellipse(CX, GROUND - 10, 9, 4, G1)
        c.ellipse(CX, GROUND - 11, 9, 3.5, G2)
        c.ellipse(CX, GROUND - 12, 6, 1.5, G3)
        for x in range(CX - 7, CX + 8, 5):
            c.rect(x, GROUND - 9, 2, 1, G1)


def neck(c, points, belly):
    """Pescoço grosso ao longo dos pontos. belly: deslocamento da barriga
    amarela em x, ou None para as costas."""
    steps = []
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            steps.append((x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n))
    for x, y in steps:
        c.ellipse(x, y, 4, 4, G2)
    for x, y in steps:
        c.ellipse(x - 2, y, 1.2, 1.2, G3)
    if belly is None:
        for i, (x, y) in enumerate(steps):
            if i % 5 == 0:
                c.rect(int(x) - 1, int(y), 2, 2, G1)
    else:
        for x, y in steps:
            c.ellipse(x + belly, y, 1.6, 1.6, Y1)
        for i, (x, y) in enumerate(steps):
            if i % 4 == 0:
                c.px(int(x + belly), int(y), Y0)


def hood(c, x, y):
    c.ellipse(x, y + 4, 9, 7, G1)
    c.ellipse(x, y + 4, 7, 5.5, G2)
    c.rect(x - 6, y + 4, 2, 2, Y1)
    c.rect(x + 4, y + 4, 2, 2, Y1)


def head_front(c, x, y, mood):
    c.ellipse(x, y, 6.5, 5.5, G2)
    c.ellipse(x, y - 2.5, 4.5, 2, G3)
    c.ellipse(x, y + 3, 4, 2.5, G3 if mood != "bite" else G2)
    for s in (-1, 1):
        ex = x + s * 4 - (1 if s < 0 else 0)
        if mood == "dizzy":
            c.px(ex, y - 2, INK)
            c.px(ex + 1, y - 1, INK)
            c.px(ex + 1, y - 2, G1)
            c.px(ex, y - 1, G1)
        elif mood == "shut":
            c.rect(ex, y - 1, 2, 1, INK)
        else:
            c.rect(ex, y - 2, 2, 3 if mood == "calm" else 2, Y1)
            c.px(ex + (1 if s < 0 else 0), y - 1, INK)
            if mood != "calm":
                c.px(ex + (0 if s < 0 else 1), y - 3, G0)
    if mood == "bite":
        c.ellipse(x, y + 3, 4, 3, RED)
        c.rect(x - 3, y + 1, 1, 2, WHITE)
        c.rect(x + 2, y + 1, 1, 2, WHITE)
        c.rect(x - 1, y + 4, 2, 2, G0)
    elif mood in ("calm", "angry"):
        c.px(x - 1, y + 1, G0)
        c.px(x + 1, y + 1, G0)
        c.rect(x, y + 5, 1, 3, RED)
        c.px(x - 1, y + 8, RED)
        c.px(x + 1, y + 8, RED)


def head_back(c, x, y):
    c.ellipse(x, y, 6.5, 5.5, G2)
    c.ellipse(x - 1, y - 2.5, 4, 2, G3)
    c.rect(x - 1, y - 1, 2, 2, G1)
    c.rect(x - 1, y + 3, 2, 2, G1)


def head_side(c, x, y, mood):
    """Cabeça de lado, focinho para a direita."""
    c.ellipse(x, y, 6, 5, G2)
    c.poly([(x + 2, y - 4), (x + 9, y - 1), (x + 9, y + 2), (x + 2, y + 4)], G2)
    c.ellipse(x - 1, y - 2.5, 4, 1.5, G3)
    c.rect(x - 2, y + 3, 9, 1, G3)
    if mood == "dizzy":
        c.px(x + 2, y - 2, INK)
        c.px(x + 3, y - 1, INK)
    else:
        c.rect(x + 2, y - 2, 2, 3 if mood == "calm" else 2, Y1)
        c.px(x + 3, y - 1, INK)
        if mood != "calm":
            c.px(x + 2, y - 3, G0)
    c.px(x + 8, y - 1, G0)
    if mood == "bite":
        c.poly([(x + 3, y + 1), (x + 10, y + 1), (x + 9, y + 5), (x + 3, y + 3)], RED)
        c.rect(x + 8, y + 1, 1, 2, WHITE)
        c.rect(x + 5, y + 1, 1, 2, WHITE)
        c.rect(x + 2, y + 5, 8, 2, G2)
    elif mood in ("calm", "angry"):
        c.rect(x + 10, y + 1, 3, 1, RED)
        c.px(x + 13, y, RED)
        c.px(x + 13, y + 2, RED)


def finish(c):
    c.outline(INK)
    return c


def front(points, mood, hooded=False):
    c = Canvas(W, H)
    coil(c)
    x, y = points[-1]
    if hooded:
        hood(c, x, y)
    neck(c, points, 0)
    head_front(c, x, y, mood)
    return finish(c)


def back(points, hooded=False):
    c = Canvas(W, H)
    x, y = points[-1]
    # De costas, o pescoço nasce atrás dos anéis.
    neck(c, points, None)
    if hooded:
        hood(c, x, y)
        c.ellipse(x, y + 4, 5, 4, G1)
    head_back(c, x, y)
    coil(c)
    return finish(c)


def side(points, mood, hooded=False):
    c = Canvas(W, H)
    coil(c)
    x, y = points[-1]
    if hooded:
        c.ellipse(x - 4, y + 4, 5, 7, G1)
    neck(c, points, 2)
    head_side(c, x, y, mood)
    return finish(c)


def flash(c):
    for old, new in [(G3, WHITE), (G2, G4), (G1, G3), (Y1, WHITE), (Y0, Y1)]:
        c.replace(old, new)
    return c


def fallen():
    c = Canvas(W, H)
    coil(c, True)
    neck(c, [(CX + 4, GROUND - 6), (CX + 12, GROUND - 5)], 0)
    head_side(c, CX + 15, GROUND - 5, "dizzy")
    return finish(c)


BASE = (CX, GROUND - 13)


def main():
    note = "\nGerado por tools/art/snake.py."
    up_a = [BASE, (CX - 1, 24), (CX + 1, 19), (CX, 14)]
    up_b = [BASE, (CX + 1, 24), (CX - 1, 20), (CX, 15)]
    side_a = [BASE, (CX - 2, 24), (CX + 1, 19), (CX + 2, 14)]
    side_b = [BASE, (CX - 1, 24), (CX + 2, 20), (CX + 3, 15)]
    reared = [BASE, (CX + 1, 22), (CX - 1, 15), (CX, 9)]
    frames = {
        "snake_down": (front(up_a, "calm"), "Cobra: de frente."),
        "snake_down_step": (front(up_b, "calm"), "Cobra: de frente, segundo quadro."),
        "snake_up": (back(up_a), "Cobra: de costas."),
        "snake_up_step": (back(up_b), "Cobra: de costas, segundo quadro."),
        "snake_side": (side(side_a, "calm"), "Cobra: de lado, olhando para a direita."),
        "snake_side_step": (side(side_b, "calm"), "Cobra: de lado, segundo quadro."),
        "snake_windup": (front(reared, "angry", True), "Cobra: erguida com o capuz aberto, preparando o bote."),
        "snake_lunge_down": (
            front([BASE, (CX, 22), (CX, 27), (CX, 33)], "bite", True),
            "Cobra: bote para a frente.",
        ),
        "snake_lunge_down_step": (
            front([BASE, (CX, 22), (CX, 27), (CX, 31)], "bite", True),
            "Cobra: bote para a frente, segundo quadro.",
        ),
        "snake_lunge_up": (back([BASE, (CX, 20), (CX, 12), (CX, 6)], True), "Cobra: bote de costas."),
        "snake_lunge_up_step": (
            back([BASE, (CX, 20), (CX, 13), (CX, 8)], True),
            "Cobra: bote de costas, segundo quadro.",
        ),
        "snake_lunge_side": (
            side([BASE, (CX + 4, 22), (CX + 11, 20), (CX + 17, 21)], "bite", True),
            "Cobra: bote de lado.",
        ),
        "snake_lunge_side_step": (
            side([BASE, (CX + 4, 22), (CX + 10, 20), (CX + 15, 21)], "bite", True),
            "Cobra: bote de lado, segundo quadro.",
        ),
        "snake_recover": (
            front([BASE, (CX + 2, 25), (CX + 4, 22), (CX + 5, 22)], "dizzy"),
            "Cobra: parada, se recuperando.",
        ),
        "snake_hit": (flash(front(up_b, "shut")), "Cobra: levando dano."),
        "snake_fallen": (fallen(), "Cobra: caída, sem vida."),
    }
    for name, (canvas, text) in frames.items():
        canvas.save(name, text + note)


if __name__ == "__main__":
    main()
