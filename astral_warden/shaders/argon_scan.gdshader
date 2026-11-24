// SCAN: a radar sweep across the ground. `p` is how far the front has travelled, 0 to 1.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;

uniform float p = 0.0;
uniform float a = 0.0;

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

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float d = length(q);
	float an = atan(q.y, q.x);
	float front = exp(-pow((d - p) / 0.006, 2.0)) * 2.0 + exp(-pow((d - p) / 0.05, 2.0)) * 0.45;
	float inside = step(d, p);
	float sweep = pow(fract((an - p * 18.0) / 6.2832), 8.0) * inside;
	vec4 hc = hex_coords(q * 48.0);
	float cell = smoothstep(0.06, 0.0, 0.5 - hex_dist(hc.xy)) * inside * (1.0 - d / max(p, 0.001));
	ALBEDO = vec3(0.3, 0.95, 1.0) * (front + cell * 0.4 + sweep * 0.7) * a * step(d, 1.0);
}
