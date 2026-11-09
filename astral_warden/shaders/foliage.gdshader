shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform sampler2D leaf_tex : filter_linear_mipmap, repeat_disable;
uniform vec3 color_a : source_color = vec3(0.86, 0.58, 0.1);
uniform vec3 color_b : source_color = vec3(0.93, 0.72, 0.17);
uniform vec3 color_c : source_color = vec3(0.62, 0.34, 0.08);

varying vec3 tint;

void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;
	float sway = sin(TIME * 1.1 + root.x * 0.3 + VERTEX.y * 0.25);
	float flutter = sin(TIME * 4.0 + VERTEX.x * 3.0 + VERTEX.z * 2.0);
	VERTEX += vec3(0.05, 0.015, 0.04) * (sway + flutter * 0.4) * COLOR.g * VERTEX.y * 0.12;
	float t = INSTANCE_CUSTOM.r;
	vec3 base = t < 0.5 ? mix(color_a, color_b, t * 2.0) : mix(color_b, color_c, (t - 0.5) * 2.0);
	tint = base * COLOR.r;
}

void fragment() {
	vec4 leaf = texture(leaf_tex, UV);
	ALBEDO = tint * (0.8 + leaf.r * 0.35);
	ALPHA = leaf.a;
	ALPHA_SCISSOR_THRESHOLD = 0.45;
	ROUGHNESS = 0.85;
	BACKLIGHT = vec3(0.5, 0.4, 0.2);
}
