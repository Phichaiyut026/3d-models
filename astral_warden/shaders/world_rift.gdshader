// INFINITY EDGE: the bright seam left by a cut that splits the world. U runs across it, V along it.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;

uniform float fade = 0.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float x = p.x + sin(p.y * 34.0) * 0.05 + sin(p.y * 90.0 + TIME * 7.0) * 0.025;
	float core = smoothstep(0.1, 0.0, abs(x));
	float halo = pow(max(1.0 - abs(x), 0.0), 3.0) * 0.55;
	ALBEDO = (vec3(1.0, 0.96, 0.84) * core * 2.4 + vec3(1.0, 0.6, 0.2) * halo) * smoothstep(1.0, 0.7, abs(p.y)) * fade;
}
