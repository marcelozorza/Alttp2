"""Lobo (ugly) no traço de 2026-11-10: 15 quadros na grade fina. Lobo cinza de
pé, grande e pesado, com cabeça larga, orelhas em ponta, focinho claro com
presas, olhos amarelos, barriga clara e rabo peludo. Para lançar a gosma ele
ergue a bola magenta sobre a cabeça.

Todos os quadros têm o mesmo tamanho e os pés na mesma linha, para o corpo
não pular quando o desenho troca.

Uso: python3 tools/art/wolf.py && python3 tools/pixel_svg.py
"""

from canvas import Canvas

INK = "#1e181e"
S0, S1, S2, S3 = "#3a3750", "#55526f", "#7c7b99", "#a9aac2"
L1, L2 = "#d6d8e6", "#ffffff"
PINK, EYE, RED = "#e49aa4", "#f7c53a", "#d83a3f"
M0, M1, M2 = "#7a1a78", "#c038b8", "#ee7fe0"
W, H = 58, 52
CX = 29
GROUND = 50


def ear(c, x, y, s, back=False):
    c.poly([(x - s * 4, y + 1), (x + s * 2, y - 8), (x + s * 4, y + 4)], S1)
    if not back:
        c.poly([(x - s * 1, y + 1), (x + s * 2, y - 4), (x + s * 2, y + 2)], PINK)


def eyes(c, x, y, mood):
    for s in (-1, 1):
        mid = x + s * 6 + (0 if s > 0 else -1)
        if mood == "shut":
            c.rect(mid - 1, y, 3, 1, INK)
        else:
            c.rect(mid - 1, y - 1, 3, 3, EYE)
            c.rect(mid, y - 1, 1, 3, INK)
            # Sobrancelha inclinada: o lobo está sempre bravo.
            c.rect(mid - 2, y - 2, 5, 1, S0)
            c.px(mid - s, y - 1, S0)
            c.px(mid + s * 2, y - 3, S0)


def head_front(c, x, y, mood):
    for s in (-1, 1):
        ear(c, x + s * 9, y - 8, s)
    c.ellipse(x, y, 13, 10, S2)
    c.ellipse(x, y - 5, 9, 3.5, S3)
    # Pelos da bochecha.
    for s in (-1, 1):
        c.poly([(x + s * 10, y + 1), (x + s * 15, y + 4), (x + s * 10, y + 7)], S1)
    c.rect(x - 1, y - 9, 2, 4, S1)
    # Focinho claro e comprido.
    c.ellipse(x, y + 5.5, 6.5, 4.5, L1)
    c.ellipse(x, y + 4.5, 5, 3, L2)
    c.rect(x - 2, y + 2, 4, 2, INK)
    if mood == "bite":
        c.ellipse(x, y + 7.5, 4.5, 3, RED)
        for dx in (-4, -2, 1, 3):
            c.rect(x + dx, y + 5, 1, 2, L2)
    else:
        c.rect(x - 4, y + 7, 8, 1, S0)
        c.rect(x - 4, y + 8, 1, 2, L2)
        c.rect(x + 3, y + 8, 1, 2, L2)
    eyes(c, x, y - 1, mood)


def head_back(c, x, y):
    for s in (-1, 1):
        ear(c, x + s * 9, y - 8, s, True)
    c.ellipse(x, y, 13, 10, S2)
    c.ellipse(x - 2, y - 5, 8, 3.5, S3)
    for dx in (-5, 0, 5):
        c.px(x + dx, y + 5, S1)
        c.px(x + dx - 1, y + 4, S1)
        c.px(x + dx + 1, y + 4, S1)


def head_side(c, x, y, mood):
    """Cabeça de lado, focinho para a direita."""
    ear(c, x - 5, y - 7, -1)
    ear(c, x + 2, y - 8, 1)
    c.ellipse(x, y, 11, 9.5, S2)
    c.ellipse(x - 1, y - 5, 7, 3, S3)
    c.poly([(x - 8, y + 1), (x - 13, y + 5), (x - 7, y + 7)], S1)
    c.poly([(x + 5, y - 1), (x + 14, y + 2), (x + 14, y + 6), (x + 5, y + 8)], L1)
    c.poly([(x + 7, y + 1), (x + 13, y + 2), (x + 13, y + 4), (x + 7, y + 4)], L2)
    c.rect(x + 13, y + 1, 2, 3, INK)
    if mood == "bite":
        c.poly([(x + 5, y + 5), (x + 13, y + 6), (x + 12, y + 10), (x + 5, y + 9)], RED)
        for dx in (7, 10, 12):
            c.rect(x + dx, y + 5, 1, 2, L2)
        c.poly([(x + 4, y + 10), (x + 12, y + 11), (x + 4, y + 12)], S2)
    else:
        c.rect(x + 6, y + 6, 8, 1, S0)
        c.rect(x + 11, y + 7, 1, 2, L2)
    if mood == "shut":
        c.rect(x + 2, y - 1, 3, 1, INK)
    else:
        c.rect(x + 2, y - 2, 3, 3, EYE)
        c.rect(x + 3, y - 2, 1, 3, INK)
        c.rect(x + 1, y - 3, 5, 1, S0)
        c.px(x + 1, y - 4, S0)


def tail(c, x, y, s, up=0):
    """Rabo peludo saindo de (x, y) para o lado s."""
    c.poly([(x, y - 2), (x + s * 8, y - 6 - up), (x + s * 12, y - 12 - up), (x + s * 9, y - 1 - up), (x, y + 3)], S1)
    c.poly([(x + s * 8, y - 8 - up), (x + s * 12, y - 12 - up), (x + s * 10, y - 6 - up)], L1)


def leg(c, x, y, lift=0):
    c.rect(x - 4, y - 8 - lift, 8, 6, S1)
    c.ellipse(x, y - 2 - lift, 5, 2.5, S3)
    for dx in (-3, 0, 3):
        c.px(x + dx, y - 1 - lift, S0)


def arm(c, x0, y0, x1, y1):
    """Braço grosso do ombro até a pata."""
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for i in range(n + 1):
        c.ellipse(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, 3, 3, S1)
    c.ellipse(x1, y1, 3.5, 3.5, S3)
    c.px(int(x1) - 2, int(y1) + 2, L2)
    c.px(int(x1), int(y1) + 3, L2)
    c.px(int(x1) + 2, int(y1) + 2, L2)


def ball(c, x, y):
    c.ellipse(x, y, 5, 5, M1)
    c.ellipse(x - 1.5, y - 2, 2, 1.5, M2)
    c.ellipse(x + 1, y + 3, 3, 1.2, M0)


def finish(c):
    c.outline(INK)
    return c


def torso(c, dy=0):
    c.ellipse(CX, GROUND - 16 + dy, 12, 11, S1)
    c.ellipse(CX, GROUND - 17 + dy, 11, 10, S2)


def front(step=0, mood="calm", bob=0, arms="down"):
    c = Canvas(W, H)
    tail(c, CX + 9, GROUND - 9, 1, 1 if step == 2 else 0)
    leg(c, CX - 7, GROUND, 2 if step == 1 else 0)
    leg(c, CX + 7, GROUND, 2 if step == 2 else 0)
    torso(c, bob)
    c.ellipse(CX, GROUND - 13 + bob, 7, 8, L1)
    c.ellipse(CX, GROUND - 14 + bob, 5, 6, L2)
    hy = GROUND - 33 + bob
    sy = GROUND - 22 + bob
    if arms == "down":
        a, b = (1, -1) if step == 1 else (-1, 1) if step == 2 else (0, 0)
        arm(c, CX - 11, sy, CX - 15, sy + 10 + a)
        arm(c, CX + 11, sy, CX + 15, sy + 10 + b)
        head_front(c, CX, hy, mood)
    elif arms == "open":
        head_front(c, CX, hy + 3, mood)
        arm(c, CX - 11, sy + 2, CX - 21, sy + 9)
        arm(c, CX + 11, sy + 2, CX + 21, sy + 9)
    elif arms == "up":
        head_front(c, CX, hy + 3, mood)
        arm(c, CX - 12, sy, CX - 9, hy - 11)
        arm(c, CX + 12, sy, CX + 9, hy - 11)
        ball(c, CX, hy - 13)
    elif arms == "thrown":
        head_front(c, CX, hy + 4, mood)
        arm(c, CX - 11, sy + 2, CX - 8, sy + 15)
        arm(c, CX + 11, sy + 2, CX + 8, sy + 15)
    return finish(c)


def back(step=0, bob=0, arms="down"):
    c = Canvas(W, H)
    leg(c, CX - 7, GROUND, 2 if step == 1 else 0)
    leg(c, CX + 7, GROUND, 2 if step == 2 else 0)
    torso(c, bob)
    c.ellipse(CX, GROUND - 22 + bob, 8, 4, S3)
    hy = GROUND - 33 + bob
    sy = GROUND - 22 + bob
    if arms == "open":
        arm(c, CX - 11, sy + 2, CX - 21, sy - 4)
        arm(c, CX + 11, sy + 2, CX + 21, sy - 4)
    else:
        a, b = (1, -1) if step == 1 else (-1, 1) if step == 2 else (0, 0)
        arm(c, CX - 11, sy, CX - 15, sy + 10 + a)
        arm(c, CX + 11, sy, CX + 15, sy + 10 + b)
    head_back(c, CX, hy - (2 if arms == "open" else 0))
    sway = 1 if step == 2 else -1 if step == 1 else 0
    c.poly([(CX - 3, GROUND - 4), (CX - 4 + sway, GROUND - 13), (CX + sway * 2, GROUND - 18), (CX + 4 + sway, GROUND - 13), (CX + 3, GROUND - 4)], S1)
    c.poly([(CX - 2 + sway, GROUND - 14), (CX + sway * 2, GROUND - 18), (CX + 2 + sway, GROUND - 14)], L1)
    return finish(c)


def side(step=0, mood="calm", bob=0):
    """De lado, de pé e curvado, olhando para a direita."""
    c = Canvas(W, H)
    tail(c, CX - 10, GROUND - 10, -1, 1 if step == 2 else 0)
    a, b = (3, -3) if step == 1 else (-3, 3) if step == 2 else (0, 0)
    leg(c, CX - 4 + b, GROUND, 2 if step == 2 else 0)
    c.ellipse(CX - 2, GROUND - 16 + bob, 10, 11, S1)
    c.ellipse(CX - 2, GROUND - 17 + bob, 9, 10, S2)
    c.ellipse(CX + 3, GROUND - 13 + bob, 4, 7, L1)
    leg(c, CX + 1 + a, GROUND, 2 if step == 1 else 0)
    arm(c, CX + 1, GROUND - 22 + bob, CX + 5 + a, GROUND - 12 + bob)
    head_side(c, CX + 5, GROUND - 32 + bob, mood)
    return finish(c)


def pounce_side(step=0):
    """Bote de lado: de quatro, esticado, boca aberta."""
    c = Canvas(W, H)
    base = GROUND - 3 - step
    tail(c, CX - 18, base - 10, -1, 3)
    c.ellipse(CX - 6, base - 11, 15, 8, S1)
    c.ellipse(CX - 6, base - 12, 14, 7, S2)
    c.ellipse(CX - 4, base - 7, 8, 3, L1)
    k = 2 if step else 0
    c.poly([(CX - 16, base - 8), (CX - 23 + k, base - 2), (CX - 20 + k, base + 1), (CX - 11, base - 5)], S1)
    c.ellipse(CX - 22 + k, base - 1, 3, 2.5, S3)
    arm(c, CX + 4, base - 8, CX + 14 - k, base - 2)
    head_side(c, CX + 9, base - 19, "bite")
    return finish(c)


def flash(c):
    for old, new in [(L1, L2), (S3, L2), (S2, L1), (S1, S3), (S0, S2)]:
        c.replace(old, new)
    return c


def main():
    note = "\nGerado por tools/art/wolf.py."
    frames = {
        "wolf_down": (front(1), "Lobo: de frente, passo 1."),
        "wolf_down_step": (front(2, bob=1), "Lobo: de frente, passo 2."),
        "wolf_up": (back(1), "Lobo: de costas, passo 1."),
        "wolf_up_step": (back(2, bob=1), "Lobo: de costas, passo 2."),
        "wolf_side": (side(1), "Lobo: de lado, olhando para a direita, passo 1."),
        "wolf_side_step": (side(2, bob=1), "Lobo: de lado, passo 2."),
        "wolf_lunge_down": (front(1, "bite", 1, "open"), "Lobo: bote de frente, garras abertas."),
        "wolf_lunge_down_step": (front(2, "bite", 2, "open"), "Lobo: bote de frente, segundo quadro."),
        "wolf_lunge_up": (back(1, 0, "open"), "Lobo: bote de costas."),
        "wolf_lunge_up_step": (back(2, 1, "open"), "Lobo: bote de costas, segundo quadro."),
        "wolf_lunge_side": (pounce_side(0), "Lobo: bote de lado, de quatro."),
        "wolf_lunge_side_step": (pounce_side(1), "Lobo: bote de lado, segundo quadro."),
        "wolf_throw_windup": (front(0, "calm", 0, "up"), "Lobo: erguendo a bola de gosma."),
        "wolf_throw": (front(0, "bite", 1, "thrown"), "Lobo: depois de lançar, braços para baixo."),
        "wolf_hit": (flash(front(0, "shut", 1)), "Lobo: levando dano."),
    }
    for name, (canvas, text) in frames.items():
        canvas.save(name, text + note)


if __name__ == "__main__":
    main()
