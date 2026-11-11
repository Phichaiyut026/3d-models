shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform sampler2D leaf_tex : filter_linear_mipmap, repeat_disable;
uniform vec3 color_a : source_color = vec3(0.86, 0.58, 0.1);
uniform vec3 color_b : source_color = vec3(0.93, 0.72, 0.17);
uniform vec3 color_c : source_color = vec3(0.62, 0.34, 0.08);

varying vec3 tint;
varying float taken;
global uniform vec3 corrupt_center;

void vertex() {
	vec3 root = MODEL_MATRIX[3].xyz;
	taken = 1.0 - smoothstep(520.0, 600.0, distance(root.xz, corrupt_center.xz));
	float sway = sin(TIME * 1.1 + root.x * 0.3 + VERTEX.y * 0.25);
	float flutter = sin(TIME * 4.0 + VERTEX.x * 3.0 + VERTEX.z * 2.0);
	VERTEX += vec3(0.05, 0.015, 0.04) * (sway + flutter * 0.4) * COLOR.g * VERTEX.y * 0.12;
	float t = INSTANCE_CUSTOM.r;
	vec3 base = t < 0.5 ? mix(color_a, color_b, t * 2.0) : mix(color_b, color_c, (t - 0.5) * 2.0);
	tint = base * COLOR.r;
	// Leaves near the tower have rotted to black, with a dull red glow along their edges.
	tint = mix(tint, vec3(0.05, 0.025, 0.035) * COLOR.r, taken);
}

void fragment() {
	vec4 leaf = texture(leaf_tex, UV);
	ALBEDO = tint * (0.8 + leaf.r * 0.35);
	EMISSION = vec3(0.8, 0.03, 0.07) * taken * smoothstep(0.6, 0.15, leaf.a) * 0.7;
	ALPHA = leaf.a;
	// Rotting leaves have holes in them.
	ALPHA_SCISSOR_THRESHOLD = mix(0.45, 0.62, taken);
	ROUGHNESS = 0.85;
	BACKLIGHT = vec3(0.5, 0.4, 0.2) * (1.0 - taken);
}
