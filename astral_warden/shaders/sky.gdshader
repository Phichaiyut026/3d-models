// Hazy amber overcast. Static on purpose, so the radiance map is only rendered once.
shader_type sky;

uniform vec3 horizon : source_color = vec3(0.92, 0.84, 0.55);
uniform vec3 mid : source_color = vec3(0.62, 0.64, 0.38);
uniform vec3 zenith : source_color = vec3(0.27, 0.34, 0.3);
uniform vec3 cloud_light : source_color = vec3(1.0, 0.91, 0.62);
uniform vec3 cloud_dark : source_color = vec3(0.34, 0.36, 0.24);
global uniform float corruption; // 0 in the valley, 1 at OBLIVION's tower: the sky turns to red space.

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
	if (corruption > 0.001) {
		// Red space: a black-red void, torn nebula, cold stars and a sun gone the colour of blood.
		vec2 p = vec2(atan(d.x, d.z) * 1.6, d.y * 3.2);
		float neb = fbm(p * 1.4 + fbm(p * 0.9) * 1.8);
		float rift = pow(1.0 - abs(fbm(p * 0.7 + 4.0) * 2.0 - 1.0), 8.0);
		vec3 space = mix(vec3(0.02, 0.0, 0.01), vec3(0.16, 0.0, 0.03), smoothstep(0.35, 0.75, neb));
		space += vec3(0.9, 0.05, 0.08) * rift * 0.55 + vec3(0.35, 0.02, 0.06) * smoothstep(0.55, 0.85, neb);
		vec3 cell = floor(d * 160.0);
		float star = step(0.985, h(cell.xy + cell.z * 7.1)) * smoothstep(0.0, 0.2, d.y + 0.1);
		space += vec3(1.0, 0.85, 0.85) * star * 1.5;
		space += vec3(1.0, 0.1, 0.12) * (pow(s, 40.0) * 0.6 + pow(s, 600.0) * 4.0);
		space = mix(space, vec3(0.12, 0.01, 0.02), smoothstep(0.0, -0.15, d.y));
		color = mix(color, space, corruption);
	}
	COLOR = color;
}
