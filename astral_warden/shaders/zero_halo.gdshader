// The broken clock behind Zero Day's head: arcs of green that drift against each other.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

float band(float r, float at, float width) {
	return smoothstep(width, width * 0.4, abs(r - at));
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float outer = band(r, 0.86, 0.035) * step(0.0, sin(a * 2.0 + TIME * 0.5) + 0.35);
	float inner = band(r, 0.75, 0.01) * step(0.0, sin(a * 3.0 - TIME * 0.8) + 0.1);
	float ticks = band(r, 0.97, 0.006) * step(0.75, fract(a * 19.1 + TIME * 0.2));
	ALBEDO = vec3(0.72, 1.0, 0.18) * (outer * 1.8 + inner * 1.2 + ticks * 1.0);
}
