// Worms' faceted black armour, as in worms.html: three hard steps of light, a red rim and a few red cracks.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform vec3 base : source_color = vec3(0.05, 0.05, 0.07);
uniform float veins = 0.6;
uniform float rim_amt = 1.0;
uniform float flash = 0.0;
uniform float power = 0.0; ///< Lights the cracks during its powers.

varying vec3 v_world;

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
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 n = normalize(NORMAL);
	if (!FRONT_FACING) {
		n = -n;
	}
	vec3 l = normalize((VIEW_MATRIX * vec4(-0.45, 0.75, 0.55, 0.0)).xyz);
	float d = dot(n, l);
	float lit = d > 0.5 ? 1.25 : (d > 0.0 ? 0.6 : 0.16);
	vec3 col = base * lit;
	float rim = pow(1.0 - max(dot(n, normalize(VIEW)), 0.0), 3.0);
	col += vec3(1.0, 0.04, 0.12) * rim * rim_amt * (0.09 + power * 0.25);
	vec3 w = v_world * 2.4; // The web model is about 2.4 times larger than the game's.
	float a = n3(w * 0.8 + 7.0) + 0.5 * n3(w * 2.1);
	float vein = pow(1.0 - abs(a / 1.5 * 2.0 - 1.0), 110.0) * veins * step(0.5, n3(w * 0.3 + 2.0));
	col += vec3(1.6, 0.05, 0.16) * vein * (1.0 + power * 2.0);
	ALBEDO = col + vec3(1.0, 0.1, 0.16) * flash;
}
