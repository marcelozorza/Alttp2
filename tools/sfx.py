#!/usr/bin/env python3
"""Gera os efeitos sonoros do jogo em audio/sfx/, todos originais.

Cada som é uma receita curta, montada de ruído, osciladores e filtros, como
os efeitos dos jogos do fim da vida do Super Nintendo. Tudo sai a 32 kHz, a
taxa do chip de som do console, com o leve abafado da interpolação dele.

As receitas usam sementes fixas, então rodar de novo gera arquivos iguais.
Para mudar um som, edite a receita e rode:

    python3 tools/sfx.py              gera todos os sons
    python3 tools/sfx.py jump land    gera só os nomes dados
    python3 tools/sfx.py --reel x.wav junta todos num arquivo para ouvir

O volume e a variação de tom de cada som no jogo ficam em audio/sfx.gd.
"""

import sys
import wave
import zlib
from pathlib import Path

import numpy as np

SR = 32000
OUT = Path(__file__).resolve().parent.parent / "audio" / "sfx"
RECIPES = {}

# Semente do ruído da receita em andamento.
_rng = np.random.default_rng(0)


def recipe(function):
    RECIPES[function.__name__] = function
    return function


# Blocos básicos ------------------------------------------------------------


def samples(seconds):
    return int(round(seconds * SR))


def times(seconds):
    return np.arange(samples(seconds)) / SR


def noise(seconds):
    return _rng.uniform(-1.0, 1.0, samples(seconds))


def ramp(start, end, seconds, curve="exp"):
    """Valor que vai de start a end, em linha reta ou exponencial."""
    n = samples(seconds)
    if curve == "exp" and start > 0 and end > 0:
        return start * (end / start) ** np.linspace(0.0, 1.0, n)
    return np.linspace(start, end, n)


def tail(n):
    """Fecha o fim de um envelope em zero, para o corte não estalar."""
    out = np.ones(n)
    fade = max(1, min(n // 5, samples(0.008)))
    out[-fade:] = np.cos(np.linspace(0.0, np.pi / 2.0, fade))
    return out


def decay(seconds, half_life):
    """Envelope que cai pela metade a cada half_life segundos."""
    return 0.5 ** (times(seconds) / half_life) * tail(samples(seconds))


def attack_decay(seconds, attack, half_life):
    t = times(seconds)
    rise = np.clip(t / max(attack, 1e-6), 0.0, 1.0)
    fall = 0.5 ** (np.maximum(t - attack, 0.0) / half_life)
    return rise * fall * tail(len(t))


def hump(seconds, peak=0.3):
    """Sobe até peak, como fração da duração, e desce até zero no fim."""
    x = np.linspace(0.0, 1.0, samples(seconds))
    up = np.sin(np.clip(x / peak, 0.0, 1.0) * np.pi / 2.0)
    down = np.cos(np.clip((x - peak) / (1.0 - peak), 0.0, 1.0) * np.pi / 2.0)
    return np.where(x < peak, up, down)


def tone(frequency, seconds, shape="sine"):
    """Oscilador com frequência fixa ou variando, em Hz."""
    n = samples(seconds)
    frequency = np.broadcast_to(np.asarray(frequency, dtype=float), (n,))
    phase = 2.0 * np.pi * np.cumsum(frequency) / SR
    if shape == "sine":
        return np.sin(phase)
    if shape == "square":
        return np.tanh(4.0 * np.sin(phase))
    if shape == "saw":
        return 2.0 * ((phase / (2.0 * np.pi)) % 1.0) - 1.0
    if shape == "triangle":
        return 2.0 / np.pi * np.arcsin(np.sin(phase))
    raise ValueError(shape)


def bell(frequency, seconds, half_life, partials=((1.0, 1.0), (2.76, 0.4), (5.4, 0.2))):
    """Sino ou marimba: parciais inarmônicas, as altas morrem antes."""
    out = np.zeros(samples(seconds))
    for ratio, level in partials:
        out += level * tone(frequency * ratio, seconds) * decay(seconds, half_life / ratio**0.7)
    return out


def svf(x, cutoff, q=0.707, mode="low"):
    """Filtro de variável de estado. cutoff pode mudar a cada amostra."""
    n = len(x)
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), (n,))
    g = np.tan(np.pi * np.clip(cutoff, 10.0, SR * 0.45) / SR)
    k = 1.0 / q
    a1 = 1.0 / (1.0 + g * (g + k))
    a2 = g * a1
    a3 = g * a2
    out = np.empty(n)
    ic1 = 0.0
    ic2 = 0.0
    for i in range(n):
        v3 = x[i] - ic2
        v1 = a1[i] * ic1 + a2[i] * v3
        v2 = ic2 + a2[i] * ic1 + a3[i] * v3
        ic1 = 2.0 * v1 - ic1
        ic2 = 2.0 * v2 - ic2
        if mode == "low":
            out[i] = v2
        elif mode == "band":
            out[i] = v1 * k
        else:
            out[i] = x[i] - k * v1 - v2
    return out


def low(x, cutoff, q=0.707):
    return svf(x, cutoff, q, "low")


def high(x, cutoff, q=0.707):
    return svf(x, cutoff, q, "high")


def band(x, center, q=1.0):
    return svf(x, center, q, "band")


def fit(x, seconds):
    n = samples(seconds)
    return x[:n] if len(x) >= n else np.pad(x, (0, n - len(x)))


def at(x, seconds):
    """Atrasa o som, para montar sequências."""
    return np.concatenate([np.zeros(samples(seconds)), x])


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for part in parts:
        out[: len(part)] += part
    return out


def grains(seconds, count, make, density_curve=1.0):
    """Espalha count sons curtos pela duração, mais densos no começo."""
    out = np.zeros(samples(seconds))
    for _ in range(count):
        start = seconds * _rng.random() ** density_curve
        grain = make()
        begin = samples(start)
        end = min(begin + len(grain), len(out))
        out[begin:end] += grain[: end - begin]
    return out


def echo(x, delay_seconds, feedback, wet, repeats=4):
    """Eco com o fim mais abafado, como o eco do Super Nintendo."""
    step = samples(delay_seconds)
    out = np.pad(x, (0, step * repeats))
    tap = x
    for i in range(1, repeats + 1):
        tap = low(tap, 5000.0) * feedback
        out[i * step : i * step + len(tap)] += wet * tap
    return out


def crush(x, amount):
    """Saturação leve, que engrossa explosões e pancadas."""
    return np.tanh(x * amount) / np.tanh(amount)


def finish(x, peak=0.89):
    """O abafado do chip do Super Nintendo, sem graves inaudíveis, sem estalo
    no fim, e o volume."""
    x = high(low(low(x, 11000.0), 13000.0), 30.0)
    fade = min(len(x), samples(0.004))
    if fade:
        x[-fade:] *= np.linspace(1.0, 0.0, fade)
    top = np.max(np.abs(x))
    return x * (peak / top) if top > 0 else x


# Peças que vários sons usam ------------------------------------------------


def thud(frequency_from, frequency_to, seconds, half_life):
    body = tone(ramp(frequency_from, frequency_to, seconds), seconds)
    return body * decay(seconds, half_life)


def click(seconds=0.004, cutoff=6000.0):
    return high(noise(seconds), cutoff) * decay(seconds, seconds / 4.0)


def burst(seconds, cutoff, half_life):
    return low(noise(seconds), cutoff) * decay(seconds, half_life)


def whoosh(seconds, center_from, center_to, q=1.4, peak=0.3):
    center = ramp(center_from, center_to, seconds)
    return band(noise(seconds), center, q) * hump(seconds, peak)


def ping(frequency, seconds, half_life):
    return bell(frequency, seconds, half_life, ((1.0, 1.0), (2.32, 0.5), (4.25, 0.25)))


def crackle(seconds, count, low_hz=600.0, high_hz=3000.0, curve=1.6):
    def make():
        length = _rng.uniform(0.004, 0.02)
        center = _rng.uniform(low_hz, high_hz)
        return band(noise(length), center, 2.0) * decay(length, length / 3.0) * _rng.uniform(0.3, 1.0)

    return grains(seconds, count, make, curve)


def yelp(pitch_from, pitch_to, seconds):
    """Ganido de cachorro: voz em dente de serra com dois formantes."""
    voice = tone(ramp(pitch_from, pitch_to, seconds), seconds, "saw")
    formed = band(voice, 1000.0, 3.0) + 0.6 * band(voice, 2600.0, 4.0)
    breath = 0.15 * band(noise(seconds), 3000.0, 1.0)
    return (formed + breath) * attack_decay(seconds, 0.008, seconds / 3.0)


# Espada e combate ------------------------------------------------------------


@recipe
def sword_swing():
    return finish(whoosh(0.16, 900.0, 3400.0, 1.3, 0.35) + 0.3 * whoosh(0.16, 3000.0, 6000.0, 2.0, 0.3))


@recipe
def sword_hit():
    return finish(
        mix(thud(190.0, 70.0, 0.14, 0.035), 0.7 * burst(0.08, 2500.0, 0.015), 0.4 * click())
    )


@recipe
def sword_denied():
    buzz = low(tone(110.0, 0.14, "square"), 900.0) * attack_decay(0.14, 0.005, 0.05)
    return finish(mix(buzz, 0.3 * thud(150.0, 90.0, 0.08, 0.02)))


@recipe
def sword_lock():
    goo = low(noise(0.12), ramp(2500.0, 300.0, 0.12)) * decay(0.12, 0.03)
    sag = low(tone(ramp(330.0, 110.0, 0.4), 0.4, "square"), 1200.0)
    sag *= attack_decay(0.4, 0.01, 0.12) * (1.0 + 0.3 * tone(14.0, 0.4))
    return finish(mix(goo, at(0.6 * sag, 0.04)))


@recipe
def immune():
    metal = bell(1840.0, 0.35, 0.09, ((1.0, 1.0), (1.48, 0.6), (2.26, 0.45), (3.04, 0.25)))
    return finish(mix(metal, 0.5 * click(0.003, 4000.0)))


@recipe
def deny():
    knock = mix(thud(130.0, 80.0, 0.08, 0.02), 0.6 * burst(0.05, 900.0, 0.01))
    return finish(mix(knock, at(0.45 * knock, 0.05), at(0.2 * knock, 0.1)))


@recipe
def bump():
    return finish(mix(thud(150.0, 70.0, 0.1, 0.025), 0.5 * burst(0.05, 1200.0, 0.01)))


# Giorgino -------------------------------------------------------------------


@recipe
def step():
    """Passo da corrida: a almofada da pata bate no chão, com um toque de
    unha. Mais encorpado desde 2026-11-08, quando Marcelo não ouvia o passo."""
    pad = thud(190.0, 95.0, 0.07, 0.018)
    scuff = 0.6 * burst(0.05, 1400.0, 0.01)
    claw = 0.45 * click(0.003, 5500.0)
    return finish(mix(pad, scuff, at(claw, 0.005)))


@recipe
def dash():
    claws = mix(*(at(0.5 * click(0.003, 5000.0), d) for d in (0.0, 0.025, 0.05)))
    return finish(mix(claws, 0.8 * whoosh(0.2, 500.0, 1600.0, 1.2, 0.25)))


@recipe
def hurt():
    return finish(yelp(1150.0, 620.0, 0.2))


@recipe
def low_health():
    """Aviso de vida baixa: dois toques curtos e secos, como um monitor."""
    beep = tone(1760.0, 0.05) * attack_decay(0.05, 0.003, 0.02)
    return finish(mix(beep, at(beep, 0.11)))


@recipe
def down():
    cry = yelp(950.0, 320.0, 0.6)
    return finish(mix(cry, at(0.7 * thud(90.0, 45.0, 0.2, 0.05), 0.42)))


@recipe
def jump():
    rise = ramp(230.0, 560.0, 0.12)
    held = np.full(samples(0.23), 560.0) * (1.0 + 0.06 * tone(18.0, 0.23) * decay(0.23, 0.08))
    pitch = np.concatenate([rise, held])
    coil = tone(pitch, 0.35) + 0.25 * tone(pitch * 2.0, 0.35)
    coil *= attack_decay(0.35, 0.004, 0.1)
    return finish(mix(coil, 0.4 * click(0.004, 3000.0)))


@recipe
def jump_strong():
    """Pulo da mola forte: a mola é maior, então o som é mais grave e mais longo."""
    rise = ramp(150.0, 440.0, 0.16)
    held = np.full(samples(0.3), 440.0) * (1.0 + 0.07 * tone(14.0, 0.3) * decay(0.3, 0.1))
    pitch = np.concatenate([rise, held])
    coil = tone(pitch, 0.46) + 0.3 * tone(pitch * 2.0, 0.46) + 0.12 * tone(pitch * 0.5, 0.46)
    coil *= attack_decay(0.46, 0.005, 0.13)
    return finish(mix(coil, 0.5 * click(0.005, 2500.0), 0.4 * thud(110.0, 60.0, 0.1, 0.03)))


@recipe
def land():
    return finish(mix(burst(0.08, 600.0, 0.02), 0.8 * thud(120.0, 70.0, 0.08, 0.02)))


@recipe
def ledge_drop():
    return finish(whoosh(0.14, 1400.0, 500.0, 1.2, 0.4))


# Ferramentas ------------------------------------------------------------------


@recipe
def fire_shoot():
    roar = band(noise(0.3), ramp(600.0, 1900.0, 0.3), 0.9) * attack_decay(0.3, 0.015, 0.08)
    body = thud(90.0, 150.0, 0.3, 0.06)
    return finish(mix(roar, 0.5 * body, 0.35 * crackle(0.3, 14, 1500.0, 5000.0)))


@recipe
def fire_hit():
    puff = low(noise(0.25), ramp(3000.0, 400.0, 0.25)) * decay(0.25, 0.05)
    sizzle = high(noise(0.25), 4000.0) * decay(0.25, 0.08)
    return finish(mix(puff, 0.3 * sizzle))


@recipe
def bomb_place():
    drop = mix(thud(170.0, 95.0, 0.1, 0.025), 0.5 * burst(0.03, 1500.0, 0.006))
    fuse = high(noise(0.22), 5000.0) * hump(0.22, 0.15) * (0.6 + 0.4 * np.abs(low(noise(0.22), 60.0)) * 5)
    return finish(mix(drop, at(0.22 * fuse, 0.04)))


@recipe
def explosion():
    boom = crush(thud(75.0, 32.0, 1.0, 0.18), 2.5)
    blast = low(noise(1.0), ramp(6000.0, 250.0, 1.0)) * attack_decay(1.0, 0.004, 0.14)
    debris = crackle(1.0, 40, 400.0, 2500.0, 1.8)
    return finish(echo(mix(boom, 0.9 * blast, 0.35 * debris), 0.09, 0.35, 0.25, 3))


# Baús, chaves e portas --------------------------------------------------------


@recipe
def chest_open():
    seconds = 0.32
    rate = ramp(55.0, 150.0, seconds)
    phase = np.cumsum(rate) / SR
    pulses = (np.diff(np.floor(phase), prepend=0.0) > 0).astype(float)
    creak = band(pulses, ramp(700.0, 1300.0, seconds), 6.0) * hump(seconds, 0.6)
    clack = mix(thud(220.0, 140.0, 0.08, 0.015), 0.6 * burst(0.03, 2500.0, 0.005))
    return finish(mix(creak, at(clack, seconds)))


@recipe
def item_tool():
    notes = (523.25, 659.25, 783.99, 1046.5)
    melody = mix(*(at(0.8 * bell(f, 0.5, 0.18), i * 0.075) for i, f in enumerate(notes)))
    chord = mix(*(at(0.35 * bell(f, 0.8, 0.3), 0.3) for f in (1046.5, 1318.5, 1568.0)))
    return finish(echo(mix(melody, chord), 0.11, 0.4, 0.3, 3))


@recipe
def item_heart():
    first = bell(659.25, 0.4, 0.15, ((1.0, 1.0), (2.0, 0.3), (3.0, 0.1)))
    second = bell(880.0, 0.55, 0.22, ((1.0, 1.0), (2.0, 0.3), (3.0, 0.1)))
    return finish(echo(mix(first, at(second, 0.12)), 0.1, 0.35, 0.25, 3))


@recipe
def item_key():
    def make():
        return ping(_rng.uniform(2800.0, 5200.0), 0.12, 0.025)

    return finish(mix(grains(0.25, 6, make, 1.2), 0.3 * click()))


@recipe
def door_locked():
    knock = mix(thud(160.0, 110.0, 0.05, 0.012), 0.5 * burst(0.03, 1800.0, 0.006))
    latch = 0.4 * ping(2100.0, 0.05, 0.01)
    parts = [at(mix(knock, latch) * (1.0 - 0.18 * i), i * 0.055) for i in range(4)]
    return finish(mix(*parts))


@recipe
def door_unlock():
    scrape = high(noise(0.05), 3000.0) * hump(0.05, 0.5)
    clicks = mix(at(click(0.004, 3500.0), 0.07), at(0.8 * click(0.004, 2500.0), 0.13))
    clunk = mix(thud(95.0, 60.0, 0.15, 0.04), 0.6 * burst(0.08, 700.0, 0.02))
    rumble = low(noise(0.35), 280.0) * hump(0.35, 0.3) * 2.0
    return finish(mix(0.3 * scrape, clicks, at(clunk, 0.18), at(0.6 * rumble, 0.24)))


# Bloqueios ----------------------------------------------------------------------


@recipe
def wall_break():
    crack = 0.5 * high(noise(0.03), 1200.0) * decay(0.03, 0.006)
    rubble = crackle(0.8, 55, 250.0, 2200.0, 1.7)
    rumble = low(noise(0.8), 180.0) * attack_decay(0.8, 0.01, 0.2) * 2.0
    return finish(mix(crack, rubble, 0.8 * rumble))


@recipe
def ice_melt():
    rough = 0.4 + np.abs(low(noise(0.6), 90.0)) * 8.0
    sizzle = high(noise(0.6), 3200.0) * rough * attack_decay(0.6, 0.02, 0.18)
    drips = mix(*(at(0.5 * tone(ramp(1200.0, 2600.0, 0.025), 0.025) * hump(0.025), d) for d in (0.32, 0.45)))
    return finish(mix(sizzle, drips))


# Inimigos -----------------------------------------------------------------------


@recipe
def enemy_hit():
    return finish(mix(thud(320.0, 120.0, 0.14, 0.03), 0.6 * burst(0.06, 1800.0, 0.012), 0.3 * click()))


@recipe
def enemy_die():
    pop = thud(520.0, 90.0, 0.08, 0.025)
    poof = low(noise(0.4), ramp(4000.0, 200.0, 0.4)) * attack_decay(0.4, 0.01, 0.08)
    return finish(mix(pop, 0.8 * poof))


@recipe
def enemy_windup():
    rough = 0.5 + np.abs(low(noise(0.25), 35.0)) * 6.0
    growl = band(tone(ramp(85.0, 110.0, 0.25), 0.25, "saw"), 420.0, 1.5) * rough
    return finish(growl * hump(0.25, 0.6))


@recipe
def enemy_lunge():
    return finish(whoosh(0.12, 450.0, 1500.0, 1.2, 0.3))


@recipe
def grenade_throw():
    spin = 0.55 + 0.45 * tone(26.0, 0.22)
    return finish(whoosh(0.22, 700.0, 1800.0, 1.5, 0.4) * spin)


@recipe
def grenade_burst():
    splat = low(noise(0.15), ramp(3500.0, 500.0, 0.15)) * decay(0.15, 0.03)
    carrier = ramp(1500.0, 280.0, 0.35)
    zap = tone(carrier + 400.0 * tone(carrier * 1.5, 0.35), 0.35) * attack_decay(0.35, 0.005, 0.08)
    return finish(mix(splat, 0.5 * zap))


# Chefes -------------------------------------------------------------------------


@recipe
def boss_wake():
    rough = 0.4 + np.abs(low(noise(0.8), 25.0)) * 7.0
    grind = low(noise(0.8), 500.0) * rough
    voice = band(tone(ramp(55.0, 75.0, 0.8), 0.8, "saw"), 300.0, 1.2)
    return finish(mix(grind, 1.2 * voice) * hump(0.8, 0.4))


@recipe
def boss_windup():
    rise = band(noise(0.5), ramp(180.0, 650.0, 0.5), 2.0) * ramp(0.2, 1.0, 0.5, "lin")
    return finish(rise * hump(0.5, 0.9))


@recipe
def boss_slam():
    boom = crush(thud(62.0, 28.0, 0.9, 0.16), 3.0)
    dust = low(noise(0.9), ramp(2200.0, 180.0, 0.9)) * attack_decay(0.9, 0.003, 0.1)
    debris = crackle(0.9, 25, 300.0, 1800.0, 2.0)
    return finish(mix(boom, 0.7 * dust, 0.3 * debris))


@recipe
def boss_charge():
    rush = whoosh(0.45, 300.0, 900.0, 1.0, 0.5)
    stomps = mix(*(at(0.6 * thud(80.0, 50.0, 0.06, 0.015), d) for d in (0.0, 0.09, 0.18, 0.27)))
    return finish(mix(rush, stomps))


@recipe
def boss_hit():
    return finish(mix(thud(160.0, 55.0, 0.22, 0.05), 0.7 * burst(0.1, 1500.0, 0.02), 0.3 * click()))


@recipe
def shell_break():
    def shard():
        return ping(_rng.uniform(2200.0, 7000.0), 0.18, 0.03) * _rng.uniform(0.3, 1.0)

    crack = high(noise(0.04), 2000.0) * decay(0.04, 0.008)
    return finish(mix(crack, grains(0.7, 22, shard, 2.5), 0.5 * thud(140.0, 70.0, 0.1, 0.02)))


@recipe
def armor_break():
    crack = high(noise(0.04), 800.0) * decay(0.04, 0.01)
    rubble = crackle(0.7, 45, 180.0, 1500.0, 1.8)
    boom = crush(thud(90.0, 40.0, 0.4, 0.07), 2.0)
    return finish(mix(crack, rubble, 0.8 * boom))


@recipe
def shell_regrow():
    def sparkle():
        frequency = _rng.uniform(2500.0, 6000.0)
        return tone(ramp(frequency, frequency * 1.3, 0.04), 0.04) * hump(0.04) * 0.6

    rising = grains(0.5, 26, sparkle, 0.6)
    frost = high(noise(0.5), 5000.0) * ramp(0.05, 0.4, 0.5, "lin")
    return finish(mix(rising, frost) * hump(0.5, 0.85))


@recipe
def boss_die():
    def blast(pitch):
        boom = crush(thud(pitch, pitch * 0.45, 0.7, 0.12), 2.5)
        return mix(boom, 0.8 * low(noise(0.7), ramp(5000.0, 250.0, 0.7)) * decay(0.7, 0.1))

    parts = mix(blast(85.0), at(0.85 * blast(70.0), 0.32), at(blast(55.0), 0.7))
    tail = low(noise(1.7), 200.0) * attack_decay(1.7, 0.3, 0.35) * 2.0
    return finish(echo(mix(parts, 0.6 * tail), 0.12, 0.3, 0.2, 3))


@recipe
def relic():
    notes = (783.99, 987.77, 1174.66, 1567.98, 1975.53)
    melody = mix(*(at(bell(f, 0.9, 0.3), i * 0.09) for i, f in enumerate(notes)))

    def sparkle():
        return ping(_rng.uniform(3000.0, 7000.0), 0.08, 0.02) * 0.35

    return finish(echo(mix(melody, grains(1.1, 18, sparkle, 1.0)), 0.13, 0.45, 0.35, 4))


@recipe
def save():
    """Pedra de salvamento: um arpejo curto que sobe, com um brilho por cima."""
    notes = (659.25, 783.99, 987.77, 1318.5)
    melody = mix(*(at(0.8 * bell(f, 0.6, 0.2), i * 0.08) for i, f in enumerate(notes)))
    shimmer = tone(ramp(2000.0, 4000.0, 0.5), 0.5) * hump(0.5, 0.3) * 0.15
    return finish(echo(mix(melody, shimmer), 0.12, 0.4, 0.3, 3))


@recipe
def switch_press():
    """Interruptor afundando: um estalo e uma pancada curta de pedra."""
    return finish(mix(click(0.004, 4000.0), thud(180.0, 90.0, 0.12, 0.03)))


@recipe
def block_drag():
    """Bloco pesado arrastado no chão de pedra: ronco grave de atrito com
    estalos de pedra raspando. Toca em sequência enquanto o bloco anda,
    pedido de Marcelo em 2026-11-08."""
    seconds = 0.22
    rumble = low(noise(seconds), 260.0, 1.2) * hump(seconds, 0.4) * 1.4
    grind = band(noise(seconds), 900.0, 2.0) * hump(seconds, 0.5) * 0.35
    grit = 0.5 * crackle(seconds, 9, 700.0, 2400.0)
    return finish(mix(rumble, grind, grit), 0.7)


@recipe
def switch_release():
    """Interruptor voltando: a pancada ao contrário, mais leve."""
    return finish(mix(0.6 * click(0.003, 3000.0), thud(110.0, 170.0, 0.1, 0.03)))


# Menus --------------------------------------------------------------------------


@recipe
def menu_move():
    return finish(mix(tone(1800.0, 0.05) * decay(0.05, 0.01), 0.3 * click(0.002, 5000.0)))


@recipe
def menu_confirm():
    first = bell(880.0, 0.12, 0.04, ((1.0, 1.0), (2.0, 0.25)))
    second = bell(1318.5, 0.2, 0.06, ((1.0, 1.0), (2.0, 0.25)))
    return finish(mix(first, at(second, 0.06)))


# Saída -------------------------------------------------------------------------


def render(name):
    global _rng
    _rng = np.random.default_rng(zlib.crc32(name.encode()))
    return RECIPES[name]()


def write_wav(path, signal):
    data = (np.clip(signal, -1.0, 1.0) * 32767.0).astype("<i2")
    with wave.open(str(path), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(SR)
        file.writeframes(data.tobytes())


def main(arguments):
    if arguments[:1] == ["--reel"]:
        gap = np.zeros(samples(0.5))
        reel = np.concatenate([np.concatenate([render(name), gap]) for name in RECIPES])
        write_wav(Path(arguments[1]), reel)
        print("\n".join(RECIPES))
        return 0
    names = arguments or list(RECIPES)
    OUT.mkdir(parents=True, exist_ok=True)
    for name in names:
        if name not in RECIPES:
            print(f"som desconhecido: {name}")
            return 1
        write_wav(OUT / f"{name}.wav", render(name))
        print(f"{name}.wav")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
