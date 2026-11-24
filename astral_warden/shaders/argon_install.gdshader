// CLEAN INSTALL: the installer's sigil across the sky. `prog` fills the progress arc.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float a = 0.0;
uniform float prog = 0.0;

float hex_dist(vec2 q) {
	q = abs(q);
	return max(dot(q, vec2(0.5, 0.8660254)), q.x);
}

vec4 hex_coords(vec2 uv) {
	vec2 hr = vec2(1.0, 1.7320508);
	vec2 hh = hr * 0.5;
	vec2 ha = mod(uv, hr) - hh;
	vec2 hb = mod(uv - hh, hr) - hh;
	vec2 gv = dot(ha, ha) < dot(hb, hb) ? ha : hb;
	return vec4(gv, uv - gv);
}

float ln(float v, float w) {
	return smoothstep(w, 0.0, abs(v));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	p.y = -p.y;
	float r = length(p);
	float an = atan(p.y, p.x);
	float t = TIME;
	float hx = hex_dist(p) * 2.0;
	float rings = ln(hx - 0.95, 0.012) + ln(hx - 0.82, 0.008) + ln(hx - 0.55, 0.01) + ln(r - 0.7, 0.006) + ln(hx - 0.3, 0.012);
	float spokes = ln(0.5 - abs(fract((an + t * 0.15) / 6.2832 * 6.0) - 0.5), 0.02) * step(0.3, hx) * step(hx, 0.82);
	float ticks = ln(fract((an - t * 0.2) / 6.2832 * 48.0) - 0.5, 0.08) * step(0.84, hx) * step(hx, 0.93);
	float arc = step(fract(0.25 - an / 6.2832), prog) * ln(r - 0.7, 0.028);
	vec4 hc = hex_coords(p * 16.0);
	float cells = smoothstep(0.06, 0.0, 0.5 - hex_dist(hc.xy)) * step(hx, 0.3);
	vec3 col = vec3(0.3, 0.95, 1.0) * (rings + spokes * 0.6 + ticks * 0.7 + cells * 0.5) + vec3(0.75, 1.0, 0.85) * arc * 2.2 + vec3(0.7, 0.5, 1.0) * pow(max(1.0 - r, 0.0), 2.0) * 0.25;
	ALBEDO = col * step(hx, 1.0) * a;
}
