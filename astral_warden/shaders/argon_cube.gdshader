// QUARANTINE: the glowing cube that seals a threat.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float a = 0.0;

void fragment() {
	vec2 e = min(UV, 1.0 - UV);
	float edge = smoothstep(0.06, 0.0, min(e.x, e.y));
	vec2 g = abs(fract(UV * 6.0) - 0.5);
	float grid = smoothstep(0.06, 0.0, 0.5 - max(g.x, g.y)) * 0.35;
	float scan = smoothstep(0.04, 0.0, abs(fract(UV.y - TIME * 0.8) - 0.5)) * 0.5;
	ALBEDO = (vec3(0.25, 0.95, 1.0) * (edge * 1.8 + grid + scan) + vec3(0.6, 1.0, 0.9) * 0.06) * a;
}
