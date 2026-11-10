"""Morcego no traço de 2026-11-10: 16 quadros na grade fina, no lugar dos
quadros de 18 por 7 ampliados. Corpo roxo redondo, orelhas grandes, olhos
amarelos e asas de membrana clara com três pontas.

Todos os quadros têm o mesmo tamanho e a barriga na mesma linha, para o corpo
não pular quando o desenho troca.

Uso: python3 tools/art/bat.py && python3 tools/pixel_svg.py
"""

from canvas import Canvas

INK = "#1e181e"
P0, P1, P2, P3 = "#2e1a4f", "#55308f", "#8a59d0", "#c3a0f0"
EYE, WHITE, PINK = "#f7c53a", "#ffffff", "#e49aa4"
W, H = 46, 28
CX, CY = 23, 16

# Asa esquerda em cada pose: contorno a partir do ombro, com três pontas na
# borda de baixo. A direita é o espelho.
WINGS = {
    "up": [(18, 14), (12, 7), (5, 3), (1, 5), (2, 10), (5, 9), (7, 13), (10, 11), (13, 16), (15, 14), (18, 18)],
    "down": [(18, 13), (12, 12), (5, 14), (1, 19), (2, 24), (5, 21), (7, 25), (10, 21), (13, 24), (15, 20), (18, 19)],
    "high": [(18, 15), (14, 6), (9, 1), (6, 1), (5, 6), (8, 6), (9, 10), (11, 8), (13, 13), (15, 11), (18, 18)],
    "droop": [(18, 14), (13, 14), (7, 17), (4, 22), (5, 26), (7, 23), (9, 26), (11, 22), (13, 25), (15, 21), (18, 20)],
    "swept": [(18, 14), (15, 6), (12, 1), (9, 0), (9, 5), (11, 5), (11, 9), (13, 8), (14, 12), (16, 11), (18, 17)],
}


def wings(c, pose):
    half = Canvas(W, H)
    points = WINGS[pose]
    half.poly(points, P2)
    # Ossos da asa: do ombro a cada ponta de cima.
    for x, y in points[2:5:2]:
        half.line(points[0][0], points[0][1], x, y, P1)
    half.line(points[0][0], points[0][1], points[1][0], points[1][1], P1)
    # Borda de cima mais clara.
    half.line(points[1][0], points[1][1] + 1, points[2][0], points[2][1] + 1, P3)
    c.blit(half, 0, 0)
    c.blit(half.flip_h(), 0, 0)


def ears(c, back):
    for side in (-1, 1):
        x = CX + side * 5
        c.poly([(x - 2, CY - 5), (x + side * 2, CY - 13), (x + 3 * side, CY - 5)], P1)
        if not back:
            c.line(x + side, CY - 10, x + side, CY - 6, PINK)


def body(c, squash=0):
    c.ellipse(CX, CY + squash / 2.0, 7.5, 7 - squash / 2.0, P1)
    c.ellipse(CX, CY + 3, 5, 3, P0)
    c.ellipse(CX - 2, CY - 3, 3, 2, P2)
    # Pezinhos.
    c.rect(CX - 3, CY + 7, 2, 2, P0)
    c.rect(CX + 2, CY + 7, 2, 2, P0)


def face(c, mood):
    for side in (-1, 1):
        x = CX + side * 3 - (1 if side < 0 else 0)
        if mood == "open":
            c.rect(x, CY - 2, 2, 3, EYE)
            c.px(x + (1 if side < 0 else 0), CY - 1, INK)
        elif mood == "angry":
            c.rect(x, CY - 1, 2, 2, EYE)
            c.px(x + (0 if side < 0 else 1), CY - 2, EYE)
            c.px(x + (1 if side < 0 else 0), CY - 1, INK)
        elif mood == "shut":
            c.rect(x, CY - 1, 2, 1, INK)
        elif mood == "dizzy":
            c.px(x, CY - 2, WHITE)
            c.px(x + 1, CY - 1, WHITE)
            c.px(x + 1, CY - 2, P0)
            c.px(x, CY - 1, P0)
    if mood in ("open", "angry"):
        c.rect(CX - 2, CY + 2, 4, 1, INK)
        c.px(CX - 2, CY + 3, WHITE)
        c.px(CX + 1, CY + 3, WHITE)
    elif mood == "dizzy":
        c.rect(CX - 1, CY + 2, 2, 2, INK)


def front(pose, mood, squash=0):
    c = Canvas(W, H)
    wings(c, pose)
    ears(c, False)
    body(c, squash)
    face(c, mood)
    c.outline(INK)
    return c


def back(pose):
    c = Canvas(W, H)
    wings(c, pose)
    ears(c, True)
    body(c)
    c.ellipse(CX, CY + 3, 5, 3, P1)
    c.ellipse(CX, CY + 4, 4, 2, P0)
    c.ellipse(CX, CY - 3, 4, 2, P2)
    c.outline(INK)
    return c


def side(pose, mood):
    """De lado, olhando para a direita: uma asa só, atrás do corpo."""
    c = Canvas(W, H)
    wing = Canvas(W, H)
    wings(wing, pose)
    for y in range(H):
        for x in range(CX - 2, W):
            wing.p[y][x] = None
    c.blit(wing, 5, 0)
    x = CX + 3
    c.poly([(x - 4, CY - 5), (x - 3, CY - 13), (x + 1, CY - 5)], P1)
    c.poly([(x + 1, CY - 5), (x + 4, CY - 12), (x + 5, CY - 4)], P1)
    c.line(x + 4, CY - 9, x + 4, CY - 6, PINK)
    c.ellipse(x, CY, 7, 7, P1)
    c.ellipse(x - 1, CY + 3, 5, 3, P0)
    c.ellipse(x - 2, CY - 3, 3, 2, P2)
    c.rect(x + 5, CY, 3, 3, P1)
    c.rect(x - 2, CY + 7, 2, 2, P0)
    c.rect(x + 2, CY + 7, 2, 2, P0)
    if mood == "open":
        c.rect(x + 3, CY - 2, 2, 3, EYE)
        c.px(x + 4, CY - 1, INK)
    else:
        c.rect(x + 3, CY - 1, 2, 2, EYE)
        c.px(x + 3, CY - 2, EYE)
        c.px(x + 4, CY - 1, INK)
    c.rect(x + 4, CY + 3, 3, 1, INK)
    c.px(x + 6, CY + 4, WHITE)
    c.outline(INK)
    return c


def flash(c):
    """Quadro de dano: o corpo clareia."""
    c.replace(P1, P3)
    c.replace(P2, WHITE)
    c.replace(P0, P2)
    c.replace(EYE, WHITE)
    return c


def fallen():
    c = Canvas(W, H)
    half = Canvas(W, H)
    half.poly([(18, 21), (10, 19), (2, 21), (1, 24), (6, 23), (9, 25), (13, 23), (18, 25)], P2)
    half.line(18, 21, 2, 21, P1)
    c.blit(half, 0, 0)
    c.blit(half.flip_h(), 0, 0)
    for s in (-1, 1):
        x = CX + s * 5
        c.poly([(x - 2, 19), (x + s * 3, 14), (x + 3 * s, 20)], P1)
    c.ellipse(CX, 22, 8, 4.5, P1)
    c.ellipse(CX, 24, 5, 2, P0)
    for s in (-1, 1):
        x = CX + s * 3 - (1 if s < 0 else 0)
        c.px(x, 20, INK)
        c.px(x + 1, 21, INK)
        c.px(x + 1, 20, INK)
        c.px(x, 21, INK)
    c.outline(INK)
    return c


def main():
    note = "\nGerado por tools/art/bat.py."
    frames = {
        "bat_down": (front("up", "open"), "Morcego: de frente, asas no alto."),
        "bat_down_step": (front("down", "open"), "Morcego: de frente, asas embaixo."),
        "bat_up": (back("up"), "Morcego: de costas, asas no alto."),
        "bat_up_step": (back("down"), "Morcego: de costas, asas embaixo."),
        "bat_side": (side("up", "open"), "Morcego: de lado, olhando para a direita, asa no alto."),
        "bat_side_step": (side("down", "open"), "Morcego: de lado, asa embaixo."),
        "bat_windup": (front("high", "angry", 2), "Morcego: parado, preparando o mergulho."),
        "bat_lunge_down": (front("swept", "angry"), "Morcego: mergulhando para a frente."),
        "bat_lunge_down_step": (front("high", "angry"), "Morcego: mergulhando para a frente, segundo quadro."),
        "bat_lunge_up": (back("swept"), "Morcego: mergulhando de costas."),
        "bat_lunge_up_step": (back("high"), "Morcego: mergulhando de costas, segundo quadro."),
        "bat_lunge_side": (side("swept", "angry"), "Morcego: mergulhando de lado."),
        "bat_lunge_side_step": (side("high", "angry"), "Morcego: mergulhando de lado, segundo quadro."),
        "bat_recover": (front("droop", "dizzy"), "Morcego: parado, se recuperando."),
        "bat_hit": (flash(front("droop", "shut")), "Morcego: levando dano."),
        "bat_fallen": (fallen(), "Morcego: caído, sem vida."),
    }
    for name, (canvas, text) in frames.items():
        canvas.save(name, text + note)


if __name__ == "__main__":
    main()
