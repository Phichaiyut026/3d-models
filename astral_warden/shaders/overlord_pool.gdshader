// Corrupted ground under the Overlord: a black pool cut with glowing red fractures.
shader_type spatial;
render_mode blend_mix, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

float h(vec2 v) {
	return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

float vn(vec2 v) {
	vec2 i = floor(v);
	vec2 f = fract(v);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 v) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 5; i++) {
		s += a * vn(v);
		v = v * 2.03 + 17.0;
		a *= 0.5;
	}
	return s;
}

float crack(vec2 p) {
	vec2 g = floor(p);
	vec2 f = fract(p);
	float a = 8.0;
	float b = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 o = vec2(float(x), float(y));
			vec2 r = o + vec2(h(g + o), h(g + o + 3.0)) - f;
			float d = dot(r, r);
			if (d < a) {
				b = a;
				a = d;
			} else if (d < b) {
				b = d;
			}
		}
	}
	return sqrt(b) - sqrt(a);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float n = fbm(p * 3.5 + TIME * 0.08);
	float pool = 1.0 - smoothstep(0.52 + (n - 0.5) * 0.4, 0.96 + (n - 0.5) * 0.3, d);
	float c = 1.0 - smoothstep(0.0, 0.05, crack(p * 6.0 + (n - 0.5) * 1.1));
	float fade = 1.0 - smoothstep(0.2, 0.78, d);
	ALBEDO = vec3(0.015, 0.008, 0.02) + vec3(2.4, 0.14, 0.3) * c * fade * (0.55 + 0.45 * sin(TIME * 2.3 + d * 9.0));
	ALPHA = pool * 0.96;
}
