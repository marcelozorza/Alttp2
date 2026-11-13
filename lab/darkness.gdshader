shader_type canvas_item;
// Escuridão das salas escuras do laboratório: cobre a tela e abre um círculo
// de luz em volta do personagem e de cada tocha acesa.
uniform vec2 screen_size = vec2(640.0, 360.0);
uniform vec2 lights[6];
uniform float radii[6];
uniform int count = 0;
uniform float strength = 0.96;

void fragment() {
	vec2 point = UV * screen_size;
	float alpha = strength;
	for (int i = 0; i < count; i++) {
		float edge = smoothstep(radii[i] * 0.55, radii[i], distance(point, lights[i]));
		alpha = min(alpha, edge * strength);
	}
	COLOR = vec4(0.02, 0.02, 0.05, alpha);
}
