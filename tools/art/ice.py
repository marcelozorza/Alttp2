"""Inimigos de gelo: o cubo e a estalactite, 16 e 15 quadros na grade fina.

Segunda versão, de 2026-11-11. Marcelo jogou a primeira e achou os dois
"muito feios", pedindo o traço "mais fofo e menos primitivo". O que mudou:
nada de caixa reta nem de cone de régua. O cubo é uma gelatina de gelo de
cantos bem redondos, com bracinhos, e a estalactite é uma gota de gelo
gordinha, de ponta curvada como um gorro. Os dois têm olhos grandes e baixos
no rosto, com dois brilhos, bochecha rosada e boca pequena.

Em cada família, todos os quadros têm o mesmo tamanho e os pés na mesma
linha, para o corpo não pular quando o desenho troca.

Uso: python3 tools/art/ice.py && python3 tools/pixel_svg.py
"""

import math

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


EYE = [".kk.", "wkkk", "wkkk", "kkkk", "kkwk", ".kk."]
EYE_COLORS = {"k": INK, "w": WHITE}


def eye(c, x, y, mood, side=1):
    """Olho alto de 4 por 6, com um brilho grande em cima e um pequeno
    embaixo. side é o lado de fora do rosto, para a sobrancelha brava."""
    if mood == "shut":
        # Olho fechado sorrindo, em arco.
        c.px(x, y + 3, INK)
        c.rect(x + 1, y + 2, 2, 1, INK)
        c.px(x + 3, y + 3, INK)
    elif mood == "dizzy":
        for d in range(4):
            c.px(x + d, y + 1 + d, INK)
            c.px(x + 3 - d, y + 1 + d, INK)
    else:
        c.rows(x, y, EYE, EYE_COLORS)
        if mood in ("angry", "bite"):
            # Sobrancelha inclinada, mais baixa do lado de dentro.
            inner = x if side > 0 else x + 3
            outer = x + 3 if side > 0 else x
            c.line(outer + side, y - 3, inner - side, y - 1, B1)


def face(c, x, y, mood, gap=5):
    """Cara de frente centrada em x: olhos, bochechas e boca."""
    eye(c, x - gap - 3, y, mood, -1)
    eye(c, x + gap - 1, y, mood, 1)
    c.rect(x - gap - 5, y + 6, 3, 2, PINK)
    c.rect(x + gap + 2, y + 6, 3, 2, PINK)
    if mood == "bite":
        c.ellipse(x, y + 7.5, 3, 2.5, INK)
        c.rect(x - 1, y + 8, 2, 2, RED)
        c.px(x - 2, y + 6, WHITE)
        c.px(x + 1, y + 6, WHITE)
    elif mood == "angry":
        # Boca em arco para baixo, com um dentinho.
        c.rect(x - 2, y + 6, 4, 1, INK)
        c.px(x - 3, y + 7, INK)
        c.px(x + 2, y + 7, INK)
        c.px(x - 1, y + 7, WHITE)
    elif mood == "dizzy":
        c.rect(x - 1, y + 7, 2, 2, INK)
    else:
        # Boquinha de gato.
        c.px(x - 2, y + 6, INK)
        c.px(x - 1, y + 7, INK)
        c.px(x, y + 6, INK)
        c.px(x + 1, y + 7, INK)
        c.px(x + 2, y + 6, INK)


def face_side(c, x, y, mood):
    """Cara de lado, olhando para a direita: um olho e a boca na beira."""
    eye(c, x, y, mood, -1)
    c.rect(x - 4, y + 6, 3, 2, PINK)
    if mood == "bite":
        c.ellipse(x + 6, y + 7.5, 2.5, 2.5, INK)
        c.rect(x + 6, y + 8, 2, 2, RED)
        c.px(x + 5, y + 6, WHITE)
    elif mood == "angry":
        c.rect(x + 5, y + 6, 3, 1, INK)
        c.px(x + 4, y + 7, INK)
        c.px(x + 6, y + 7, WHITE)
    else:
        c.px(x + 5, y + 6, INK)
        c.px(x + 6, y + 7, INK)
        c.px(x + 7, y + 6, INK)


# ---------------------------------------------------------------- cubo

CW, CH = 40, 40
CCX, CGROUND = 20, 38


def cube_body(c, w, h, lift=0, top=7, arms=0):
    """Gelatina de gelo de cantos bem redondos, com o topo mais claro,
    bracinhos e dois pezinhos. arms sobe os bracinhos. Devolve o canto de
    cima à esquerda da frente do bloco."""
    x0 = CCX - w // 2
    y0 = CGROUND - 2 - lift - h
    radius = 5.0
    # Pezinhos e bracinhos, atrás do corpo.
    c.ellipse(CCX - w / 4, CGROUND - 1.5 - min(lift, 1), 3.5, 2, B2)
    c.ellipse(CCX + w / 4, CGROUND - 1.5 - min(lift, 1), 3.5, 2, B2)
    arm_y = y0 + h * 0.62 - arms
    c.ellipse(x0 - 0.5, arm_y, 2.5, 2.5, B4)
    c.ellipse(x0 + w + 0.5, arm_y, 2.5, 2.5, B3)
    for yy in range(h):
        for xx in range(w):
            # Distância ao canto redondo mais próximo.
            cx = min(max(xx + 0.5, radius), w - radius)
            cy = min(max(yy + 0.5, radius), h - radius)
            if math.hypot(xx + 0.5 - cx, yy + 0.5 - cy) > radius:
                continue
            # A beira do topo desce no meio, como a face de cima vista de
            # frente.
            edge = top + 1.5 * math.sin(math.pi * (xx + 0.5) / w)
            color = B4
            if yy < edge:
                color = B5
            elif xx >= w - 3 or yy >= h - 2:
                color = B3
            c.px(x0 + xx, y0 + yy, color)
    # Brilho do topo, reflexo em diagonal e uma bolha.
    c.rect(x0 + 4, y0 + 2, w // 3, 2, WHITE)
    c.px(x0 + 3, y0 + 3, WHITE)
    c.rect(x0 + w - 8, y0 + 3, 2, 1, WHITE)
    c.line(x0 + 2, y0 + top + 6, x0 + 4, y0 + top + 4, B5)
    c.px(x0 + w - 6, y0 + h - 5, B5)
    return x0, y0 + top


def cube_front(mood="calm", w=24, h=24, lift=0):
    c = Canvas(CW, CH)
    x0, fy = cube_body(c, w, h, lift, arms=4 if mood == "bite" else 0)
    face(c, CCX, fy + max(2, (h - 7) // 2 - 5), mood)
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
    x0, fy = cube_body(c, w, h, lift, arms=4 if mood == "bite" else 0)
    face_side(c, x0 + w - 13, fy + max(2, (h - 7) // 2 - 5), mood)
    return finish(c)


def cube_recover():
    c = Canvas(CW, CH)
    c.ellipse(CCX, CGROUND - 2, 16, 2.5, B5)
    x0, fy = cube_body(c, 26, 21)
    face(c, CCX, fy + 2, "dizzy")
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


def shard(c, x, y, s, size=7):
    """Bracinho de gelo: um cristal pequeno e redondo ao lado do bulbo,
    apontando para o lado s."""
    c.ellipse(x + s * 1.5, y - size / 2.0, 3.0, size / 2.0, B4 if s < 0 else B3)
    c.px(int(x + s * 2), int(y - size + 1), WHITE)


def profile(t):
    """Meia largura da gota, de 0 na ponta a 1 na base: um espigão fino em
    cima e um bulbo gordinho embaixo, como uma cebola de gelo."""
    if t < 0.42:
        return 0.07 + 0.27 * (t / 0.42) ** 1.3
    return 0.34 + 0.66 * math.sin((t - 0.42) / 0.58 * math.pi / 2.0) ** 0.75


def crystal(c, tip, height, half, lift=0):
    """Gota de gelo gordinha, de ponta curvada para o lado de tip, com a
    face esquerda clara e a direita escura. Devolve o y da base."""
    base = SGROUND - 7 - lift
    top = base - height
    belly = 5
    for i in range(height + belly):
        y = top + i
        if i < height:
            t = (i + 0.5) / height
            hw = half * profile(t)
            cx = SCX + tip * (1.0 - t) ** 2
        else:
            # Fundo redondo, abaixo da linha da base.
            k = (i - height + 0.5) / belly
            hw = half * math.sqrt(max(0.0, 1.0 - k * k))
            cx = SCX
        for x in range(int(math.floor(cx - hw)), int(math.ceil(cx + hw))):
            u = (x + 0.5 - cx) / max(hw, 0.5)
            if abs(u) > 1.0:
                continue
            color = B4
            if u < -0.45:
                color = B5
            elif u > 0.4 or i >= height + belly - 2:
                color = B3
            c.px(x, y, color)
    # Brilho comprido na face clara e a ponta branca.
    for i in range(int(height * 0.3), int(height * 0.7)):
        t = (i + 0.5) / height
        c.px(int(SCX + tip * (1.0 - t) ** 2 - half * profile(t) * 0.62), top + i, WHITE)
    tx = int(SCX + tip)
    c.px(tx, top, WHITE)
    c.px(tx, top + 1, WHITE)
    c.px(SCX + half // 2, base - 2, B5)
    return base


def feet(c, lift=0):
    y = SGROUND - 2 - min(lift, 1)
    c.ellipse(SCX - 6, y, 4, 2.5, B2)
    c.ellipse(SCX + 6, y, 4, 2.5, B2)


def tusks(c, x, y):
    """Presas de gelo, que caem dos lados da boca."""
    for dx in (-5, 3):
        c.rect(x + dx, y, 2, 2, WHITE)
        c.px(x + dx + (0 if dx < 0 else 1), y + 2, WHITE)


def spike_front(mood="calm", height=34, half=13, lift=0, tip=0):
    c = Canvas(SW, SH)
    feet(c, lift)
    shard(c, SCX - 12, SGROUND - 6 - lift, -1)
    shard(c, SCX + 12, SGROUND - 6 - lift, 1)
    base = crystal(c, tip, height, half, lift)
    face(c, SCX, base - 11, mood, 4)
    tusks(c, SCX, base - 1)
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
    face_side(c, SCX + 1, base - 11, mood)
    c.rect(SCX + 7, base - 1, 2, 2, WHITE)
    c.px(SCX + 8, base + 1, WHITE)
    return finish(c)


def spear_side(step=0):
    """Bote de lado: a gota deita e voa de ponta para a direita."""
    c = Canvas(SW, SH)
    cy = SGROUND - 16 - step
    x0 = SCX - 15 + step * 2
    length, half, belly = 34, 11, 5
    for i in range(length + belly):
        x = x0 + length - 1 - i
        if i < length:
            t = (i + 0.5) / length
            hw = half * profile(t)
            mid = cy - 3.0 * (1.0 - t) ** 2
        else:
            k = (i - length + 0.5) / belly
            hw = half * math.sqrt(max(0.0, 1.0 - k * k))
            mid = cy
        for y in range(int(math.floor(mid - hw)), int(math.ceil(mid + hw))):
            v = (y + 0.5 - mid) / max(hw, 0.5)
            if abs(v) > 1.0:
                continue
            color = B4
            if v < -0.45:
                color = B5
            elif v > 0.4 or i >= length + belly - 2:
                color = B3
            c.px(x, y, color)
    for i in range(int(length * 0.3), int(length * 0.7)):
        t = (i + 0.5) / length
        c.px(x0 + length - 1 - i, int(cy - 3.0 * (1.0 - t) ** 2 - half * profile(t) * 0.62), WHITE)
    c.px(x0 + length - 1, cy - 3, WHITE)
    face_side(c, x0 + 6, cy - 6, "bite")
    for dy in (-8, 0, 8):
        c.rect(x0 - 12 - step * 2, cy + dy, 5, 1, B5)
    return finish(c)


def spike_recover():
    c = Canvas(SW, SH)
    feet(c)
    shard(c, SCX - 12, SGROUND - 6, -1, 6)
    shard(c, SCX + 12, SGROUND - 6, 1, 6)
    base = crystal(c, 5, 29, 14)
    face(c, SCX, base - 11, "dizzy", 4)
    tusks(c, SCX, base - 1)
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
