// A repair cradle's vitals screen: a weak heartbeat trace and how far the repair has got.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, shadows_disabled;

uniform vec3 color : source_color = vec3(0.35, 1.0, 0.75);
uniform vec3 accent : source_color = vec3(1.0);
uniform float progress = 0.3;
uniform float beat_rate = 0.35;

float pulse(float t, float at, float width) {
	float d = (t - at) / width;
	return exp(-d * d);
}

void fragment() {
	vec2 uv = UV;
	vec2 edge = min(uv, 1.0 - uv);
	float border = 1.0 - smoothstep(0.012, 0.022, min(edge.x, edge.y * 1.6));

	// Heartbeat: a small blip, a spike, a dip, then a long flat wait.
	float t = fract(uv.x * 1.4 - TIME * beat_rate);
	float wave = pulse(t, 0.38, 0.025) * 0.15 + pulse(t, 0.5, 0.012) * 0.9 - pulse(t, 0.54, 0.012) * 0.4 + pulse(t, 0.66, 0.03) * 0.2;
	float line_y = 0.4 - wave * 0.26;
	float trace = 1.0 - smoothstep(0.008, 0.02, abs(uv.y - line_y));
	float head = fract(TIME * beat_rate * 1.0 / 1.4);
	float lit = mix(0.25, 1.0, smoothstep(0.6, 0.0, fract(head - uv.x / 1.0 + 1.0)));

	// Repair bar along the bottom.
	float in_bar = step(0.08, uv.x) * step(uv.x, 0.92) * step(0.74, uv.y) * step(uv.y, 0.86);
	float filled = step((uv.x - 0.08) / 0.84, progress);
	float stripes = 0.75 + 0.25 * step(0.5, fract((uv.x - uv.y) * 22.0 - TIME * 0.8));
	vec3 bar = mix(color * 0.08, accent * 1.4 * stripes, filled) * in_bar;

	float grid = step(0.96, fract(uv.x * 12.0)) + step(0.94, fract(uv.y * 6.0));
	vec3 bg = vec3(0.008, 0.035, 0.03) + color * grid * 0.025;
	ALBEDO = bg + color * (border * 1.3 + trace * 1.6 * lit) + bar;
	ALPHA = 0.9;
}
