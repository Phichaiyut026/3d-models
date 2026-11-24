// A floating system screen round อั้ม: a bright frame, rows of code scrolling up, a title bar and a scan line.
shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 tint : source_color = vec3(0.27, 0.94, 0.85);
uniform float alpha = 1.0;
uniform float seed = 0.0;
uniform float done = 0.0; // 1 once this screen has been put back in order: it settles to a calm green tick

float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void fragment() {
	vec2 uv = UV;
	float frame = step(uv.x, 0.025) + step(0.975, uv.x) + step(uv.y, 0.035) + step(0.965, uv.y);
	float bar = step(uv.y, 0.14) * 0.35;
	// rows of "code": broken bars of different lengths, scrolling upward
	float rows = 14.0;
	float y = uv.y * rows - TIME * 1.4 - seed * 7.0;
	float row = floor(y);
	float inrow = fract(y);
	float len = 0.25 + 0.65 * h2(vec2(row, seed));
	float word = step(0.25, h2(vec2(floor(uv.x * 18.0), row + seed * 3.0)));
	float code = step(0.3, inrow) * step(inrow, 0.7) * step(0.08, uv.x) * step(uv.x, len) * word * step(0.18, uv.y);
	float scan = smoothstep(0.03, 0.0, abs(fract(uv.y - TIME * 0.35 + seed) - 0.5) - 0.47);
	vec3 col = tint * (frame * 1.6 + bar + code * 0.9 + scan * 0.5 + 0.06);
	// the tick of a screen that is in order
	vec2 c = (uv - vec2(0.5, 0.55)) * vec2(1.6, 1.0);
	float tick = smoothstep(0.05, 0.0, abs(c.y + c.x * 0.9 + 0.08) - 0.0) * step(-0.25, c.x) * step(c.x, -0.05)
		+ smoothstep(0.05, 0.0, abs(c.y - c.x * 1.1 + 0.02)) * step(-0.05, c.x) * step(c.x, 0.32);
	col = mix(col, vec3(0.5, 1.0, 0.6) * (frame * 1.6 + 0.08 + tick * 1.8), done);
	ALBEDO = col * alpha;
}
