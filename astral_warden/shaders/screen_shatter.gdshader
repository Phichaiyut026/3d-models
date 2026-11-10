// ERASURE: reality breaks like glass over the whole screen.
shader_type canvas_item;

uniform float p = 0.0;
uniform float aspect = 1.78;

float h(vec2 v) {
	return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 h2(vec2 v) {
	return vec2(h(v), h(v + 19.3));
}

void fragment() {
	vec2 v_p = UV * 2.0 - 1.0;
	vec2 cuv = v_p * vec2(aspect, 1.0) * 3.6;
	vec2 g = floor(cuv);
	vec2 f = fract(cuv);
	vec2 id = g;
	float f1 = 8.0;
	float f2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 o = vec2(float(x), float(y));
			vec2 c = g + o;
			vec2 r = o + h2(c) - f;
			float d = dot(r, r);
			if (d < f1) {
				f2 = f1;
				f1 = d;
				id = c;
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	f1 = sqrt(f1);
	f2 = sqrt(f2);
	float dist = length(v_p * vec2(aspect, 1.0));
	float reach = smoothstep(dist - 0.25, dist, p * 3.0);
	float crack = smoothstep(0.05, 0.0, f2 - f1) * reach;
	float gone = step(h(id) * 0.92 + 0.06, (p - 0.42) / 0.58);
	vec2 s = fract(cuv * 9.0) - 0.5;
	float dot_star = step(0.9, h(floor(cuv * 9.0))) * smoothstep(0.34, 0.0, length(s));
	vec3 void_col = vec3(0.01, 0.005, 0.03) + vec3(0.9, 0.85, 1.0) * dot_star + vec3(0.18, 0.06, 0.32) * h(id);
	COLOR = vec4(mix(vec3(1.0, 0.86, 0.5) * 1.4, void_col, gone), max(crack, gone));
}
