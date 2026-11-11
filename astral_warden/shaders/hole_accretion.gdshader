// OBLIVION's black hole: the burning disc of everything it is still eating.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

varying vec2 v_p;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float n(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	v_p = VERTEX.xy;
}

void fragment() {
	float r = length(v_p);
	float a = atan(v_p.y, v_p.x);
	float u = (r - 7.56) / 7.84;
	float lanes = n(vec2(a * 5.0 + r * 0.9 - TIME * 0.35, r * 3.1)) * 0.75 + n(vec2(a * 16.0 + r * 1.7 - TIME * 0.9, r * 8.0)) * 0.4;
	float fall = smoothstep(0.0, 0.06, u) * pow(max(1.0 - u, 0.0), 1.5);
	vec3 col = mix(vec3(1.0, 0.78, 0.55), mix(vec3(1.0, 0.08, 0.08), vec3(0.28, 0.01, 0.05), smoothstep(0.1, 0.85, u)), smoothstep(0.0, 0.2, u));
	ALBEDO = col * lanes * lanes * fall * 2.3;
}
