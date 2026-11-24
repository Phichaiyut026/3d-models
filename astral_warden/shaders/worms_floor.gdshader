// The floor of WORMS' system: near-black, with red circuit traces and a ring of command glyphs at its centre.
shader_type spatial;
render_mode unshaded, fog_disabled;

uniform float radius = 70.0;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ln(float v, float w) {
	return smoothstep(w, 0.0, abs(v));
}

void fragment() {
	vec2 p = (UV * 2.0 - 1.0) * radius * 1.2;
	float d = length(p);
	float an = atan(p.y, p.x);
	vec3 col = vec3(0.014, 0.004, 0.008);
	// circuit traces on a grid, a few lit
	vec2 cell = floor(p / 3.0);
	vec2 f = fract(p / 3.0);
	float lane = step(0.7, h2(cell)) * ln(f.x - 0.5, 0.025) + step(0.75, h2(cell + 7.0)) * ln(f.y - 0.5, 0.025);
	float pulse = 0.5 + 0.5 * sin(TIME * 2.0 + h2(cell) * 40.0 - d * 0.2);
	col += vec3(0.5, 0.01, 0.05) * lane * (0.35 + pulse * 0.6);
	// the command circle
	float rings = ln(d - 24.0, 0.12) + ln(d - 21.5, 0.06) + ln(d - 9.0, 0.08);
	float ticks = ln(fract((an + TIME * 0.05) / 6.2832 * 64.0) - 0.5, 0.08) * step(21.5, d) * step(d, 24.0);
	float spokes = ln(0.5 - abs(fract((an - TIME * 0.08) / 6.2832 * 6.0) - 0.5), 0.01) * step(9.0, d) * step(d, 21.5);
	col += vec3(1.4, 0.05, 0.14) * (rings + ticks * 0.7 + spokes * 0.5);
	col += vec3(0.25, 0.0, 0.03) * exp(-d * d / 300.0);
	// fades into the dark at the edge
	col *= smoothstep(radius * 1.15, radius * 0.8, d);
	ALBEDO = col;
}
