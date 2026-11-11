// The giant crescent thrown by the blade in GALAXY.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float a = 0.0;

void fragment() {
	float f = pow(max(abs(dot(NORMAL, VIEW)), 0.0), 1.3) * pow(sin(UV.x * PI), 0.7);
	ALBEDO = mix(vec3(1.0, 0.66, 0.24), vec3(1.0, 0.96, 0.86), f) * f * a * 2.4;
}
