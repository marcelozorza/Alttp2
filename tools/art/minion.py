"""Minion no traço de 2026-11-10: o gatinho laranja que Marcelo desenhou em
2026-11-06, refeito na grade fina. Cabeça grande e redonda, orelhas em ponta
com o rosa por dentro, listras na testa e nas costas, focinho e peito claros,
olhos amarelos e rabo listrado.

Todos os quadros têm o mesmo tamanho e os pés na mesma linha, para o corpo
não pular quando o desenho troca.

Uso: python3 tools/art/minion.py && python3 tools/pixel_svg.py
"""

from canvas import Canvas

INK = "#1e181e"
O0, O1, O2, O3 = "#8a5a3c", "#c85a1e", "#f08c2e", "#f7c53a"
C1, C2 = "#ddb277", "#f3dfa6"
PINK, EYE, RED, WHITE = "#e49aa4", "#f7c53a", "#d83a3f", "#ffffff"
W, H = 40, 38
CX = 20
GROUND = 36


def ear(c, x, y, s, back=False, low=False):
    """Orelha em ponta. s é -1 para a esquerda e 1 para a direita."""
    tip = (x + s * 2, y - (4 if low else 7))
    c.poly([(x - s * 3, y), tip, (x + s * 4, y + 3)], O1)
    if not back:
        c.poly([(x - s * 1, y), (tip[0], tip[1] + 3), (x + s * 2, y + 1)], PINK)


def eyes_front(c, x, y, mood):
    for s in (-1, 1):
        ex = x + s * 5 - (1 if s < 0 else 0)
        if mood == "shut":
            c.rect(ex, y, 2, 1, INK)
        elif mood == "dizzy":
            c.px(ex, y - 1, INK)
            c.px(ex + 1, y, INK)
            c.px(ex + 1, y - 1, O0)
            c.px(ex, y, O0)
        else:
            mid = x + s * 5 + (0 if s > 0 else -1)
            c.rect(mid - 1, y - 1, 3, 3, EYE)
            c.rect(mid, y - 1, 1, 3, INK)
            if mood == "angry":
                c.rect(mid - 1, y - 2, 3, 1, O0)
                c.px(mid - s, y - 1, O0)


def head_front(c, x, y, mood, ears_low=False):
    for s in (-1, 1):
        ear(c, x + s * 7, y - 6, s, low=ears_low)
    c.ellipse(x, y, 10.5, 8.5, O2)
    c.ellipse(x, y - 4, 7, 3, O3 if mood == "flash" else O2)
    c.ellipse(x - 8, y + 3, 2.5, 3, O1)
    c.ellipse(x + 8, y + 3, 2.5, 3, O1)
    # Listras da testa.
    c.rect(x - 1, y - 8, 2, 4, O0)
    c.rect(x - 5, y - 7, 2, 3, O0)
    c.rect(x + 3, y - 7, 2, 3, O0)
    # Listras da bochecha.
    c.rect(x - 10, y + 1, 3, 1, O0)
    c.rect(x + 7, y + 1, 3, 1, O0)
    # Focinho claro.
    c.ellipse(x, y + 4.5, 4.5, 3, C2)
    c.rect(x - 1, y + 2, 2, 1, PINK)
    if mood == "bite":
        c.ellipse(x, y + 5.5, 3, 2.5, RED)
        c.px(x - 2, y + 4, WHITE)
        c.px(x + 1, y + 4, WHITE)
    else:
        c.px(x - 2, y + 4, O0)
        c.px(x - 1, y + 5, O0)
        c.px(x, y + 5, O0)
        c.px(x + 1, y + 4, O0)
    eyes_front(c, x, y, "angry" if mood == "bite" else mood)


def head_back(c, x, y, ears_low=False):
    for s in (-1, 1):
        ear(c, x + s * 7, y - 6, s, True, ears_low)
    c.ellipse(x, y, 10.5, 8.5, O2)
    c.ellipse(x, y + 5, 8, 3, O1)
    for dx in (-5, -1, 3):
        c.rect(x + dx, y - 7, 2, 5 if dx == -1 else 4, O0)
    c.rect(x - 8, y, 3, 1, O0)
    c.rect(x + 5, y, 3, 1, O0)


def head_side(c, x, y, mood, ears_low=False):
    """Cabeça de lado, focinho para a direita."""
    ear(c, x - 3, y - 6, -1, low=ears_low)
    ear(c, x + 3, y - 6, 1, low=ears_low)
    c.ellipse(x, y, 9.5, 8, O2)
    c.ellipse(x + 7, y + 3.5, 4, 3, C2)
    c.ellipse(x - 6, y + 4, 2.5, 2.5, O1)
    c.rect(x - 2, y - 8, 2, 4, O0)
    c.rect(x - 6, y - 6, 2, 3, O0)
    c.rect(x - 8, y + 1, 3, 1, O0)
    c.rect(x + 9, y + 1, 2, 1, PINK)
    if mood == "bite":
        c.poly([(x + 4, y + 3), (x + 10, y + 3), (x + 9, y + 6), (x + 5, y + 6)], RED)
        c.px(x + 9, y + 3, WHITE)
        c.px(x + 6, y + 3, WHITE)
    else:
        c.rect(x + 7, y + 4, 3, 1, O0)
    if mood == "dizzy":
        c.px(x + 3, y - 1, INK)
        c.px(x + 4, y, INK)
    elif mood == "shut":
        c.rect(x + 3, y, 2, 1, INK)
    else:
        c.rect(x + 2, y - 1, 3, 3, EYE)
        c.rect(x + 3, y - 1, 1, 3, INK)
        if mood in ("angry", "bite"):
            c.rect(x + 2, y - 2, 3, 1, O0)


def tail(c, points):
    """Rabo listrado ao longo dos pontos."""
    steps = []
    for (x0, y0), (x1, y1) in zip(points, points[1:]):
        n = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(n + 1):
            steps.append((x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n))
    for i, (x, y) in enumerate(steps):
        c.ellipse(x, y, 1.6, 1.6, O0 if (i // 3) % 2 else O1)
    x, y = steps[-1]
    c.ellipse(x, y, 1.6, 1.6, C2)


def paw(c, x, y, color=C2):
    c.rect(x - 2, y - 3, 4, 3, O2)
    c.rect(x - 2, y - 1, 4, 2, color)


def finish(c):
    c.outline(INK)
    return c


def front(step=0, mood="calm", crouch=0, bob=0, ears_low=False, sway=0):
    """De frente. step 0, 1 ou 2 escolhe a pata erguida. crouch abaixa o corpo."""
    c = Canvas(W, H)
    tail(c, [(CX + 6, GROUND - 6), (CX + 12, GROUND - 8), (CX + 14 + sway, GROUND - 14), (CX + 12 + sway, GROUND - 18)])
    c.ellipse(CX, GROUND - 8 + crouch / 2, 8 + crouch / 2, 7 - crouch / 2, O1)
    c.ellipse(CX, GROUND - 9 + crouch / 2, 7 + crouch / 2, 6 - crouch / 2, O2)
    c.ellipse(CX, GROUND - 6, 4, 5 - crouch / 2, C2)
    # Patas de trás, dos lados.
    c.rect(CX - 9, GROUND - 3, 3, 3, O1)
    c.rect(CX + 6, GROUND - 3, 3, 3, O1)
    paw(c, CX - 4, GROUND - (2 if step == 1 else 0))
    paw(c, CX + 4, GROUND - (2 if step == 2 else 0))
    head_front(c, CX, GROUND - 21 + crouch + bob, mood, ears_low)
    return finish(c)


def back(step=0, bob=0, sway=0, ears_low=False, crouch=0):
    c = Canvas(W, H)
    c.ellipse(CX, GROUND - 8, 8, 7, O1)
    c.ellipse(CX, GROUND - 9, 7, 6, O2)
    for dy in (-12, -9, -6):
        c.rect(CX - 4, GROUND + dy, 8, 1, O0)
    c.rect(CX - 8, GROUND - 3 - (2 if step == 1 else 0), 4, 3, O1)
    c.rect(CX + 4, GROUND - 3 - (2 if step == 2 else 0), 4, 3, O1)
    head_back(c, CX, GROUND - 21 + bob + crouch, ears_low)
    tail(c, [(CX, GROUND - 3), (CX + 1 + sway, GROUND - 8), (CX + 3 + sway * 2, GROUND - 12)])
    return finish(c)


def side(step=0, mood="calm", bob=0, stretch=0, ears_low=False, lift=0):
    """De lado, olhando para a direita. stretch estica o corpo no bote."""
    c = Canvas(W, H)
    base = GROUND - lift
    c0 = CX - stretch
    tail(c, [(c0 - 9 - stretch, base - 9), (c0 - 14 - stretch, base - 12), (c0 - 15 - stretch, base - 18 + stretch * 2)])
    c.ellipse(c0 - 2, base - 9, 10 + stretch, 6 - stretch / 3, O1)
    c.ellipse(c0 - 2, base - 10, 9 + stretch, 5 - stretch / 3, O2)
    c.ellipse(c0, base - 6, 5, 2, C2)
    for dx in (-8, -4, 0):
        c.rect(c0 + dx, base - 15 + (1 if dx != -4 else 0) + int(stretch / 3), 2, 4, O0)
    if stretch:
        # No ar: patas da frente esticadas e as de trás para trás.
        c.rect(c0 + 6, base - 6, 7, 3, O2)
        c.rect(c0 + 11, base - 6, 3, 3, C2)
        c.rect(c0 - 16, base - 6, 7, 3, O1)
        c.rect(c0 - 17, base - 6, 3, 3, C2)
    else:
        a, b = (2, 0) if step == 1 else (0, 2) if step == 2 else (0, 0)
        c.rect(c0 - 10 + a, base - 4, 3, 3 - a, O1)
        paw(c, c0 - 6 - b, base)
        c.rect(c0 + 2 - a, base - 4, 3, 3 - a, O1)
        paw(c, c0 + 5 + b, base)
    head_side(c, c0 + 7 + stretch, base - 20 + bob + int(stretch * 1.5), mood, ears_low)
    return finish(c)


def pounce_front():
    """Bote de frente: no ar, patas da frente abertas e boca aberta."""
    c = Canvas(W, H)
    tail(c, [(CX + 5, GROUND - 16), (CX + 11, GROUND - 22), (CX + 12, GROUND - 28)])
    c.ellipse(CX, GROUND - 14, 8, 7, O1)
    c.ellipse(CX, GROUND - 15, 7, 6, O2)
    for s in (-1, 1):
        c.poly([(CX + s * 5, GROUND - 10), (CX + s * 12, GROUND - 5), (CX + s * 9, GROUND - 2), (CX + s * 3, GROUND - 7)], O2)
        c.rect(CX + s * 10 - 2, GROUND - 4, 4, 3, C2)
    head_front(c, CX, GROUND - 16, "bite", True)
    return finish(c)


def pounce_back():
    c = Canvas(W, H)
    c.ellipse(CX, GROUND - 9, 8, 8, O1)
    c.ellipse(CX, GROUND - 10, 7, 7, O2)
    for dy in (-13, -10, -7):
        c.rect(CX - 4, GROUND + dy, 8, 1, O0)
    for s in (-1, 1):
        c.rect(CX + s * 7 - 2, GROUND - 4, 4, 4, O1)
        c.rect(CX + s * 7 - 2, GROUND - 1, 4, 1, C2)
    head_back(c, CX, GROUND - 24, True)
    tail(c, [(CX, GROUND - 4), (CX, GROUND - 1)])
    return finish(c)


def flash(c):
    for old, new in [(C2, WHITE), (O2, C2), (O1, O2), (O0, O1), (C1, C2)]:
        c.replace(old, new)
    return c


def main():
    note = "\nGerado por tools/art/minion.py."
    frames = {
        "minion_walk_1": (front(1), "Minion: gatinho laranja, de frente, passo 1 e parado."),
        "minion_walk_2": (front(2, bob=1, sway=1), "Minion: de frente, passo 2."),
        "minion_back": (back(1), "Minion: de costas, passo 1."),
        "minion_back_step": (back(2, bob=1, sway=1), "Minion: de costas, passo 2."),
        "minion_side": (side(1), "Minion: de lado, olhando para a direita, passo 1."),
        "minion_side_step": (side(2, bob=1), "Minion: de lado, passo 2."),
        "minion_windup": (
            front(0, "angry", crouch=4, ears_low=True),
            "Minion: agachado, orelhas baixas, preparando o bote.",
        ),
        "minion_lunge": (pounce_front(), "Minion: bote de frente, no ar."),
        "minion_lunge_up": (pounce_back(), "Minion: bote de costas."),
        "minion_lunge_side": (
            side(mood="bite", stretch=3, ears_low=True, lift=4),
            "Minion: bote de lado, esticado no ar.",
        ),
        "minion_recover": (front(0, "dizzy", crouch=2, bob=1), "Minion: parado, se recuperando."),
        "minion_hit": (flash(front(0, "shut", crouch=1, ears_low=True)), "Minion: levando dano."),
    }
    for name, (canvas, text) in frames.items():
        canvas.save(name, text + note)


if __name__ == "__main__":
    main()
