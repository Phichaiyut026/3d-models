// Crescent of light thrown forward by the finishing blows.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.7, 0.5, 1.0);
uniform float fade = 1.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(2.0, -2.0);
	float outer = length(p + vec2(0.0, 0.32));
	float inner = length(p + vec2(0.0, 0.62));
	float band = smoothstep(0.98, 0.93, outer) * smoothstep(0.86, 1.02, inner);
	float rim = smoothstep(0.86, 0.94, outer) * smoothstep(0.98, 0.94, outer) * smoothstep(0.9, 1.05, inner);
	float tips = smoothstep(1.0, 0.45, abs(p.x));
	ALBEDO = (tint * band * 1.2 + vec3(1.0, 0.97, 1.0) * rim * 2.4) * tips * fade;
}
