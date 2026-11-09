// Soft light hugging the blade. Drawn on two crossed quads.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.6, 0.48, 1.0);
uniform float power = 0.0;

void fragment() {
	float across = 1.0 - abs(UV.x * 2.0 - 1.0);
	float along = smoothstep(0.0, 0.1, UV.y) * smoothstep(1.0, 0.82, UV.y);
	float wave = 0.8 + 0.2 * sin(UV.y * 22.0 + TIME * 16.0);
	ALBEDO = tint * pow(across, 2.6) * along * wave * power * 1.6;
}
