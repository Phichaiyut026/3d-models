// PURGE: the line through the world where everything was deleted. U runs across it, V along it.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;

uniform float fade = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float x = p.x + step(0.5, fract(p.y * 40.0 - TIME * 3.0)) * 0.03;
	float core = smoothstep(0.1, 0.0, abs(x));
	float glow = pow(max(1.0 - abs(x), 0.0), 3.0) * 0.55;
	float bits = step(0.6, fract(sin(floor(p.y * 160.0) * 91.7) * 4375.5)) * smoothstep(0.4, 0.1, abs(x)) * 0.6;
	ALBEDO = (vec3(0.85, 1.0, 0.97) * core * 2.0 + vec3(0.2, 0.9, 1.0) * (glow + bits)) * smoothstep(1.0, 0.7, abs(p.y)) * fade;
}
