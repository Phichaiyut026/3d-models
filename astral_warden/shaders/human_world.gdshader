// The human world, seen from Safe Mode: a blue planet with its cities lit, through a screen of scanlines.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float fade = 0.0;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float n(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y);
}

float fbm(vec2 p) {
	return n(p) * 0.55 + n(p * 2.1 + 3.0) * 0.28 + n(p * 4.3 + 7.0) * 0.17;
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * vec2(2.0, -2.0);
	float r = length(p) / 0.82;
	vec3 col = vec3(0.0);
	if (r < 1.0) {
		vec3 s = vec3(p / 0.82, sqrt(1.0 - r * r));
		float lon = atan(s.x, s.z) + TIME * 0.05;
		float lat = asin(s.y);
		vec2 map = vec2(lon * 2.4, lat * 3.2);
		float land = smoothstep(0.5, 0.55, fbm(map));
		float clouds = smoothstep(0.55, 0.8, fbm(map * 1.8 + vec2(TIME * 0.03, 2.0)));
		float day = smoothstep(-0.25, 0.45, dot(s, normalize(vec3(-0.75, 0.3, 0.55))));
		vec3 surface = mix(vec3(0.02, 0.1, 0.4), vec3(0.08, 0.3, 0.1), land);
		vec2 cell = floor(map * 34.0);
		float city = step(0.86, h(cell)) * land * step(0.45, fbm(map * 3.0));
		col = surface * day * 1.5 + vec3(0.9) * clouds * day * 0.7 + vec3(1.0, 0.72, 0.32) * city * (1.0 - day) * 2.4;
		col *= 0.35 + 0.65 * s.z;
	}
	float x = (r - 1.0) / 0.035;
	col += vec3(0.25, 0.55, 1.0) * exp(-x * x) * 1.3;
	col += vec3(0.1, 0.3, 0.8) * exp(-max(r - 1.0, 0.0) * 7.0) * step(1.0, r) * 0.5;
	float scan = 0.88 + 0.12 * sin(UV.y * 500.0 - TIME * 6.0);
	float edge = smoothstep(1.0, 0.92, max(abs(p.x), abs(p.y)));
	ALBEDO = col * scan * edge * fade;
}
