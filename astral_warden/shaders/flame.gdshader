// Camera-facing quad, so the fire always rises up the screen whatever the arm is doing.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled, skip_vertex_transform;

uniform float size = 1.15;
uniform float power = 0.0;
uniform float flame_seed = 3.7;

varying vec2 v_p;

void vertex() {
	v_p = VERTEX.xy;
	vec4 mv = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	mv.z += 0.3;
	mv.xy += VERTEX.xy * size;
	VERTEX = mv.xyz;
}

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
	for (int i = 0; i < 4; i++) {
		s += a * vn(v);
		v = v * 2.03 + 17.0;
		a *= 0.5;
	}
	return s;
}

void fragment() {
	float t = TIME + flame_seed;
	vec2 q = v_p + vec2(0.0, 0.28);
	float up = clamp(q.y + 0.55, 0.0, 1.6);
	q.x += (fbm(vec2(q.x * 1.6 + flame_seed, q.y * 1.4 - t * 1.3)) - 0.5) * (0.25 + 0.7 * up);
	float n = fbm(vec2(q.x * 3.4, q.y * 2.1 - t * 2.6));
	float r = length(q * vec2(1.25, q.y > 0.0 ? 0.62 : 1.25));
	float body = smoothstep(0.72, 0.08, r + (n - 0.5) * 0.85);
	float core = smoothstep(0.34, 0.02, r + (n - 0.5) * 0.3);
	float ridge = 1.0 - abs(fbm(vec2(q.x * 4.5 + 3.0, q.y * 3.0 - t * 3.2)) * 2.0 - 1.0);
	float wisp = pow(ridge, 10.0) * smoothstep(0.95, 0.25, r);
	vec2 c = v_p + vec2(0.0, 0.2);
	float halo = exp(-dot(c, c) * 3.2) * 0.38;
	float flicker = 0.93 + 0.07 * sin(t * 13.0);
	vec3 col = vec3(0.36, 0.22, 1.0) * halo + vec3(0.34, 0.26, 0.8) * body * flicker
			+ vec3(0.85, 0.9, 1.0) * wisp * 1.1 + vec3(0.8, 0.75, 1.0) * core * 0.3;
	ALBEDO = col * smoothstep(1.0, 0.72, length(v_p)) * power * 1.1;
}
