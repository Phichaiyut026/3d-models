// ARGON's radar sigil under the feet, its sweep always turning.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float power = 1.0;

float hex_dist(vec2 p) {
	p = abs(p);
	return max(dot(p, vec2(0.5, 0.8660254)), p.x);
}

vec4 hex_coords(vec2 uv) {
	vec2 hr = vec2(1.0, 1.7320508);
	vec2 hh = hr * 0.5;
	vec2 a = mod(uv, hr) - hh;
	vec2 b = mod(uv - hh, hr) - hh;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	return vec4(gv, uv - gv);
}

float ln(float v, float w) {
	return smoothstep(w, 0.0, abs(v));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float an = atan(p.y, p.x);
	float t = TIME;
	float hx = hex_dist(p) * 2.0;
	float rings = ln(d - 0.93, 0.012) + ln(d - 0.78, 0.008) + ln(hx - 0.55, 0.01) + ln(hx - 0.3, 0.012);
	float ticks = ln(fract((an - t * 0.2) / 6.2832 * 36.0) - 0.5, 0.06) * step(0.8, d) * step(d, 0.92);
	float sweep = pow(fract((an - t * 1.2) / 6.2832), 7.0) * step(d, 0.78);
	vec4 hc = hex_coords(p * 9.0);
	float cells = smoothstep(0.06, 0.0, 0.5 - hex_dist(hc.xy)) * step(d, 0.78) * 0.35;
	vec3 col = vec3(0.3, 0.95, 1.0) * (rings * 0.9 + ticks * 0.8 + cells) + vec3(0.6, 1.0, 0.85) * sweep * 0.9 + vec3(0.6, 0.45, 1.0) * pow(max(1.0 - d, 0.0), 2.0) * 0.18;
	ALBEDO = col * step(d, 1.0) * power * 1.6;
}
