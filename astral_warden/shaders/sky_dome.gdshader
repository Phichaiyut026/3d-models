// The sky turns to deep space during the biggest powers.
shader_type spatial;
render_mode blend_mix, unshaded, fog_disabled, cull_front, depth_draw_never, shadows_disabled;

uniform float a = 0.0;
uniform float red = 0.0;

varying vec3 v_d;

float h(vec3 p) {
	return fract(sin(dot(p, vec3(12.9, 78.2, 37.7))) * 43758.5);
}

void vertex() {
	v_d = normalize(VERTEX);
}

void fragment() {
	vec3 d = normalize(v_d);
	vec3 g = d * 130.0;
	vec3 cell = floor(g);
	vec3 f = fract(g) - 0.5;
	float star = step(0.965, h(cell)) * smoothstep(0.5, 0.08, length(f)) * (0.5 + 0.5 * sin(TIME * 3.0 + h(cell + 1.0) * 40.0));
	float n = sin(d.x * 4.0 + TIME * 0.2) * sin(d.y * 5.0) * sin(d.z * 3.0 + 1.0);
	vec3 neb = mix(vec3(0.02, 0.01, 0.09), vec3(0.3, 0.08, 0.55), smoothstep(-0.1, 0.7, n)) + vec3(0.05, 0.15, 0.5) * smoothstep(0.2, 0.9, -n);
	vec3 blood = vec3(neb.r * 1.3 + neb.b * 0.5, neb.g * 0.1, neb.b * 0.12);
	ALBEDO = mix(neb, blood, red) + vec3(star) * 2.0;
	ALPHA = a;
}
