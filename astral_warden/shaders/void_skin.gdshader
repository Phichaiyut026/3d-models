// OBLIVION's body: not a surface so much as a hole in the shape of a body, veined with red.
shader_type spatial;
render_mode unshaded, fog_disabled;

uniform float flash = 0.0;

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
	v_p = VERTEX;
}

void fragment() {
	float a = n(v_p * 3.1 + TIME * 0.1) + 0.5 * n(v_p * 7.3 - TIME * 0.16);
	float vein = pow(1.0 - abs(a / 1.5 * 2.0 - 1.0), 26.0);
	ALBEDO = vec3(0.004, 0.002, 0.006) + vec3(1.0, 0.03, 0.08) * vein * (0.7 + 0.3 * sin(TIME * 2.6)) * 2.0 + vec3(flash);
}
