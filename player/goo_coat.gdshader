shader_type canvas_item;
// Gosma rosa grudada no Giorgino enquanto a espada está travada (pedido de
// Marcelo em 2026-11-08). Pinta o desenho art/goo_coat.svg só onde a sprite
// tem pixel, contado a partir do alto dela, então cobre a cabeça e escorre
// pelo corpo em qualquer pose. Desenho em tools/goo_art.py.

uniform sampler2D goo : repeat_enable, filter_nearest;
// 0 sem gosma, 1 com gosma.
uniform float amount = 0.0;

// No fragment do Godot 4, COLOR já chega multiplicado pela textura, então a
// sprite não é lida de novo, só a transparência dela para saber onde pintar.
void fragment() {
	float sprite_alpha = texture(TEXTURE, UV).a;
	vec2 pixel = floor(UV / TEXTURE_PIXEL_SIZE);
	vec2 goo_size = vec2(textureSize(goo, 0));
	vec4 coat = vec4(0.0);
	if (pixel.y < goo_size.y) {
		coat = texture(goo, (pixel + 0.5) / goo_size);
	}
	float cover = coat.a * amount * step(0.5, sprite_alpha);
	COLOR.rgb = mix(COLOR.rgb, coat.rgb, cover);
}
