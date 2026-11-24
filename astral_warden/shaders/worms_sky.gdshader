// The sky inside WORMS' system: black, a red haze on the horizon and smoke drifting over it.
shader_type spatial;
render_mode unshaded, fog_disabled, cull_front, depth_draw_never, shadows_disabled;

varying vec3 v_d;

float h3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float n3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	v_d = VERTEX;
}

void fragment() {
	vec3 d = normalize(v_d);
	float smoke = n3(d * 3.0 + vec3(TIME * 0.03, 0.0, 0.0)) * 0.6 + n3(d * 7.0 - vec3(0.0, TIME * 0.05, 0.0)) * 0.4;
	float haze = exp(-max(d.y, 0.0) * 6.0);
	vec3 col = vec3(0.09, 0.004, 0.012) * haze * (0.3 + smoke) + vec3(0.012, 0.0, 0.003) * smoke * smoothstep(0.75, 0.0, d.y);
	if (d.y < 0.0) {
		col = mix(col, vec3(0.02, 0.0, 0.006), smoothstep(0.0, -0.04, d.y));
	}
	ALBEDO = col;
}
