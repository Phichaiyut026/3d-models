// The corpses of worlds OBLIVION has already finished with.
shader_type spatial;
render_mode unshaded, fog_disabled;

varying vec3 v_p;

float h(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float n(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h(i), h(i + vec3(1, 0, 0)), f.x), mix(h(i + vec3(0, 1, 0)), h(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h(i + vec3(0, 0, 1)), h(i + vec3(1, 0, 1)), f.x), mix(h(i + vec3(0, 1, 1)), h(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	v_p = normalize(VERTEX);
}

void fragment() {
	float c = n(v_p * 5.0) + 0.5 * n(v_p * 12.0);
	float crack = pow(1.0 - abs(c / 1.5 * 2.0 - 1.0), 18.0);
	ALBEDO = vec3(0.035, 0.03, 0.032) * (0.4 + c * 0.5) + vec3(1.0, 0.12, 0.04) * crack * 1.4;
}
