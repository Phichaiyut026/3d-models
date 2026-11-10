// Warning on the ground: fills from the middle until the blow lands.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;

uniform float fill = 0.0;
uniform vec3 tint : source_color = vec3(1.0, 0.1, 0.16);

void fragment() {
	float d = length(UV * 2.0 - 1.0);
	float rim = smoothstep(0.93, 0.97, d) * (1.0 - smoothstep(0.98, 1.0, d));
	float front = smoothstep(fill - 0.05, fill, d) * (1.0 - smoothstep(fill, fill + 0.02, d));
	float inside = (1.0 - smoothstep(fill - 0.01, fill, d)) * 0.28;
	float a = (rim * 1.6 + front * 2.0 + inside) * step(d, 1.0);
	ALBEDO = tint * a * 1.6;
}
