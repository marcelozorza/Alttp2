"""Tatu de pedra no traço de 2026-11-10: 12 quadros na grade fina. Casco em
cúpula com cinco faixas de pedra, cara clara de focinho comprido, orelhas
em pé e patas curtas.

Todos os quadros têm o mesmo tamanho e o chão na mesma linha.

Uso: python3 tools/art/armadillo.py && python3 tools/pixel_svg.py
"""

from canvas import Canvas

INK = "#1e181e"
S1, S2, S3, S4 = "#3a3750", "#55526f", "#7c7b99", "#a9aac2"
E1, E2, E3 = "#8a5a3c", "#b9824e", "#ddb277"
PINK, WHITE = "#e49aa4", "#ffffff"
W, H = 44, 32
CX = 22
GROUND = 30


def dome(c, cx, cy, rx, ry, vertical):
    """Casco: cúpula clara em cima, escura embaixo, com faixas."""
    c.ellipse(cx, cy, rx, ry, S2)
    c.ellipse(cx, cy - 1, rx - 1, ry - 1.5, S3)
    c.ellipse(cx - rx * 0.3, cy - ry * 0.45, rx * 0.45, ry * 0.25, S4)
    if vertical:
        for i in range(-2, 3):
            x = int(cx + i * rx * 0.36)
            for y in range(int(cy - ry), int(cy + ry) + 1):
                if c.get(x, y) in (S2, S3, S4):
                    c.px(x, y, S1)
    else:
        for i in range(-1, 3):
            y = int(cy + i * ry * 0.36)
            for x in range(int(cx - rx), int(cx + rx) + 1):
                if c.get(x, y) in (S2, S3, S4):
                    c.px(x, y, S1)


def feet(c, xs, lift):
    for i, x in enumerate(xs):
        up = 1 if (i % 2 == lift) else 0
        c.rect(x, GROUND - 3 - up, 4, 3, E2)
        c.rect(x, GROUND - 1 - up, 4, 1, E1)


def front(lift, mood="calm"):
    c = Canvas(W, H)
    feet(c, [CX - 11, CX + 7], lift)
    dome(c, CX, GROUND - 13, 13, 11, False)
    # Orelhas e cara por baixo da borda do casco.
    for s in (-1, 1):
        c.poly([(CX + s * 5, GROUND - 13), (CX + s * 8, GROUND - 19), (CX + s * 9, GROUND - 12)], E2)
        c.px(CX + s * 7, GROUND - 15, PINK)
    c.ellipse(CX, GROUND - 7, 7, 6, E3)
    c.ellipse(CX, GROUND - 4, 4, 3.5, E2)
    c.rect(CX - 1, GROUND - 4, 2, 2, INK)
    for s in (-1, 1):
        x = CX + s * 4 - (1 if s < 0 else 0)
        if mood == "shut":
            c.rect(x, GROUND - 9, 2, 1, INK)
        else:
            c.rect(x, GROUND - 10, 2, 2, INK)
            c.px(x, GROUND - 10, WHITE)
            if mood == "angry":
                c.px(x + (0 if s < 0 else 1), GROUND - 11, E1)
    c.outline(INK)
    return c


def back(lift):
    c = Canvas(W, H)
    feet(c, [CX - 11, CX + 7], lift)
    for s in (-1, 1):
        c.poly([(CX + s * 5, GROUND - 20), (CX + s * 8, GROUND - 26), (CX + s * 10, GROUND - 19)], E2)
    c.rect(CX - 1, GROUND - 3, 2, 3, E2)
    dome(c, CX, GROUND - 13, 13, 11, False)
    c.outline(INK)
    return c


def side(lift, mood="calm"):
    """De lado, olhando para a direita."""
    c = Canvas(W, H)
    c.poly([(CX - 13, GROUND - 8), (CX - 19, GROUND - 4), (CX - 18, GROUND - 3), (CX - 12, GROUND - 5)], E2)
    feet(c, [CX - 10, CX - 3, CX + 4], lift)
    # Cabeça à frente do casco.
    c.poly([(CX + 9, GROUND - 16), (CX + 12, GROUND - 22), (CX + 14, GROUND - 15)], E2)
    c.px(CX + 12, GROUND - 18, PINK)
    c.ellipse(CX + 13, GROUND - 10, 5, 5, E3)
    c.poly([(CX + 14, GROUND - 11), (CX + 21, GROUND - 8), (CX + 21, GROUND - 6), (CX + 14, GROUND - 5)], E3)
    c.rect(CX + 20, GROUND - 8, 2, 2, INK)
    if mood == "shut":
        c.rect(CX + 14, GROUND - 11, 2, 1, INK)
    else:
        c.rect(CX + 14, GROUND - 12, 2, 2, INK)
        c.px(CX + 14, GROUND - 12, WHITE)
    dome(c, CX - 2, GROUND - 13, 14, 10, True)
    c.outline(INK)
    return c


def ball(vertical):
    c = Canvas(W, H)
    dome(c, CX, GROUND - 12, 12, 12, vertical)
    c.outline(INK)
    return c


def hide():
    """Encolhido: o casco no chão, só os olhos por baixo."""
    c = Canvas(W, H)
    dome(c, CX, GROUND - 10, 14, 10, False)
    c.rect(CX - 8, GROUND - 3, 16, 3, S1)
    c.rect(CX - 5, GROUND - 2, 2, 1, WHITE)
    c.rect(CX + 3, GROUND - 2, 2, 1, WHITE)
    c.outline(INK)
    return c


def fallen():
    """De barriga para cima."""
    c = Canvas(W, H)
    c.ellipse(CX, GROUND - 5, 14, 5, S2)
    c.ellipse(CX, GROUND - 8, 11, 5, E3)
    c.ellipse(CX, GROUND - 9, 7, 3, E2)
    for x in (CX - 11, CX - 5, CX + 2, CX + 8):
        c.rect(x, GROUND - 15, 3, 4, E2)
    c.ellipse(CX + 15, GROUND - 5, 4, 4, E3)
    c.px(CX + 15, GROUND - 6, INK)
    c.px(CX + 16, GROUND - 5, INK)
    c.px(CX + 16, GROUND - 6, E2)
    c.outline(INK)
    return c


def flash(c):
    for old, new in [(S4, WHITE), (S3, WHITE), (S2, S4), (S1, S3), (E3, WHITE), (E2, E3)]:
        c.replace(old, new)
    return c


def main():
    note = "\nGerado por tools/art/armadillo.py."
    frames = {
        "armadillo_down": (front(0), "Tatu: de frente."),
        "armadillo_down_step": (front(1), "Tatu: de frente, segundo passo."),
        "armadillo_up": (back(0), "Tatu: de costas."),
        "armadillo_up_step": (back(1), "Tatu: de costas, segundo passo."),
        "armadillo_side": (side(0), "Tatu: de lado, olhando para a direita."),
        "armadillo_side_step": (side(1), "Tatu: de lado, segundo passo."),
        "armadillo_threat": (front(0, "angry"), "Tatu: de frente, ameaçando."),
        "armadillo_hide": (hide(), "Tatu: encolhido debaixo do casco."),
        "armadillo_ball": (ball(False), "Tatu: enrolado em bola."),
        "armadillo_ball_side": (ball(True), "Tatu: enrolado em bola, rolando de lado."),
        "armadillo_hit": (flash(front(0, "shut")), "Tatu: levando dano."),
        "armadillo_fallen": (fallen(), "Tatu: caído, de barriga para cima."),
    }
    for name, (canvas, text) in frames.items():
        canvas.save(name, text + note)


if __name__ == "__main__":
    main()
