"""Paleta mestra do Giorgino: todas as cores que um desenho de art/source pode
usar. A cor do contorno é a do Giorgino, e as rampas têm de 3 a 6 tons, do
escuro ao claro. tools/check_art.py recusa cor fora desta lista.

Direção de 2026-11-10: 8-bit revisitado. Poucas cores por desenho, tons
chapados, contorno firme e formas grandes.
"""

RAMPS = {
    # Tinta do contorno e os pretos do Giorgino.
    "ink": ["#0e0b0d", "#1e181e", "#2a2329"],
    # Pedra fria, do quase preto ao quase branco.
    "stone": ["#1b1926", "#262335", "#3a3750", "#55526f", "#7c7b99", "#a9aac2", "#d6d8e6"],
    # Brancos e cinzas do pelo do Giorgino.
    "fur": ["#8d8798", "#c7c1cf", "#f4f1ea", "#ffffff"],
    "earth": ["#3b2530", "#5c4232", "#8a5a3c", "#b9824e", "#ddb277", "#f3dfa6"],
    "red": ["#5e1830", "#9c2338", "#d83a3f", "#f0705c"],
    "pink": ["#d9578a", "#e49aa4", "#f9cfd0"],
    # Gosma do lobo.
    "magenta": ["#7a1a78", "#c038b8", "#ee7fe0"],
    "orange": ["#c85a1e", "#f08c2e"],
    "yellow": ["#d99a1c", "#f7c53a", "#fff1a8"],
    "green": ["#12332f", "#1f5a3a", "#2f8a45", "#59b84c", "#a4dc5a", "#dff29a"],
    "teal": ["#1b5e63", "#2aa198", "#7fe0c8"],
    "blue": ["#141a3c", "#1a2452", "#27409a", "#3b7bdc", "#6cc3f2", "#c6efff"],
    "purple": ["#1f1238", "#2e1a4f", "#55308f", "#8a59d0", "#c3a0f0"],
}

COLORS = [color for ramp in RAMPS.values() for color in ramp]


def rgb(color):
    value = color.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def _lab(color):
    r, g, b = (c / 255.0 for c in rgb(color))

    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = lin(r), lin(g), lin(b)
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883

    def f(t):
        return t ** (1 / 3) if t > 0.008856 else 7.787 * t + 16 / 116

    return (116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z)))


_LAB = {color: _lab(color) for color in COLORS}


def nearest(color):
    """Cor da paleta mestra mais próxima de uma cor qualquer, a olho humano."""
    color = color.lower()
    if color in _LAB:
        return color
    lab = _lab(color)
    return min(COLORS, key=lambda c: sum((a - b) ** 2 for a, b in zip(lab, _LAB[c])))
