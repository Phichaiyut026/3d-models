// Zero Day's aura (zero_day.html): a skin of green fire over every part of the body, with scan lines
// and, in bursts, whole bands of it slipping sideways like a corrupted signal.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_back, depth_draw_never, shadows_disabled;

uniform vec3 tint : source_color = vec3(0.17, 1.0, 0.29);
uniform float strength = 0.55;
uniform float glitch = 0.0;
uniform float puff = 0.35; // How far the skin stands off the body, in the model's own units.

varying vec3 wp;

float hh(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float nn(vec3 p) {
	vec3 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hh(i), hh(i + vec3(1, 0, 0)), f.x), mix(hh(i + vec3(0, 1, 0)), hh(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hh(i + vec3(0, 0, 1)), hh(i + vec3(1, 0, 1)), f.x), mix(hh(i + vec3(0, 1, 1)), hh(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	float n = nn(VERTEX * 0.9 - vec3(0.0, TIME * 2.4, 0.0));
	VERTEX += NORMAL * puff * (0.4 + n);
	float band = floor(VERTEX.y * 1.4);
	float slip = hh(vec3(band, floor(TIME * 18.0), 1.0)) - 0.5;
	VERTEX.x += slip * 1.6 * glitch * step(0.55, hh(vec3(band, floor(TIME * 18.0), 5.0)));
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.2);
	float fl = nn(wp * vec3(3.8, 1.7, 3.8) - vec3(0.0, TIME * 3.4, 0.0));
	float scan = 0.75 + 0.25 * sin(wp.y * 22.0 - TIME * 12.0);
	float lit = rim * (0.3 + 1.7 * smoothstep(0.45, 0.9, fl)) * scan;
	ALBEDO = mix(tint, vec3(0.9, 1.0, 0.9), smoothstep(0.75, 1.0, fl) * rim) * lit * strength * (1.0 + glitch * 0.6);
}
