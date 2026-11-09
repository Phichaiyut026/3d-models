// Hazy amber overcast. Static on purpose, so the radiance map is only rendered once.
shader_type sky;

uniform vec3 horizon : source_color = vec3(0.92, 0.84, 0.55);
uniform vec3 mid : source_color = vec3(0.62, 0.64, 0.38);
uniform vec3 zenith : source_color = vec3(0.27, 0.34, 0.3);
uniform vec3 cloud_light : source_color = vec3(1.0, 0.91, 0.62);
uniform vec3 cloud_dark : source_color = vec3(0.34, 0.36, 0.24);

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
	for (int i = 0; i < 6; i++) {
		s += a * vn(v);
		v = v * 2.04 + 19.0;
		a *= 0.5;
	}
	return s;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float up = max(d.y, 0.0);
	vec3 color = mix(horizon, mid, smoothstep(0.0, 0.22, up));
	color = mix(color, zenith, smoothstep(0.18, 0.85, up));

	if (d.y > 0.005) {
		vec2 uv = d.xz / (d.y + 0.16) * 1.15;
		float warp = fbm(uv * 0.8);
		float n = fbm(uv + warp * 1.4);
		float cover = smoothstep(0.36, 0.6, n) * smoothstep(0.0, 0.06, d.y);
		float shade = smoothstep(0.42, 0.78, fbm(uv + warp * 1.4 + vec2(0.06, 0.05)));
		vec3 cloud = mix(cloud_light, cloud_dark, shade * 0.9);
		color = mix(color, cloud, cover * 0.86);
	}

	float s = max(dot(d, LIGHT0_DIRECTION), 0.0);
	color += vec3(1.0, 0.82, 0.46) * (pow(s, 6.0) * 0.28 + pow(s, 90.0) * 0.6 + pow(s, 900.0) * 3.0);
	if (d.y < 0.0) {
		color = mix(color, horizon * 0.55, smoothstep(0.0, -0.1, d.y));
	}
	COLOR = color;
}
