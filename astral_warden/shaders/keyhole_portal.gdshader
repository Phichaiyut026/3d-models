// BACKDOOR: Zero Day's door, a keyhole you can walk through.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float power = 1.0;
uniform vec3 color : source_color = vec3(0.72, 1.0, 0.18);

float keyhole(vec2 p) {
	float circle = length(p - vec2(0.0, 0.3)) - 0.28;
	float width = mix(0.32, 0.12, clamp((p.y + 0.75) / 0.95, 0.0, 1.0));
	float body = max(abs(p.x) - width, max(-p.y - 0.75, p.y - 0.2));
	return min(circle, body);
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(2.0, -2.0);
	float d = keyhole(p);
	float core = smoothstep(0.02, -0.02, d);
	float halo = exp(-max(d, 0.0) * 9.0);
	float scan = 0.85 + 0.15 * sin(p.y * 60.0 - TIME * 14.0);
	float rim = exp(-pow(d / 0.018, 2.0));
	ALBEDO = (mix(color, vec3(0.92, 1.0, 0.87), core * 0.7) * (core * 1.2 * scan + halo * 0.8) + vec3(0.92, 1.0, 0.87) * rim * 1.6) * power;
}
