// GENESIS: a whole spiral galaxy unfolding around the fighter.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float fade = 0.0;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float an = atan(p.y, p.x);
	float t = TIME;
	float swirl = an * 2.0 - log(r + 0.02) * 7.0 + t * 0.55;
	float arms = pow(0.5 + 0.5 * sin(swirl), 2.6);
	vec2 cell = floor(vec2(swirl * 22.0, log(r + 0.02) * 40.0));
	float dot_star = step(0.86, h(cell)) * (0.6 + 0.4 * sin(t * 4.0 + h(cell + 3.0) * 30.0));
	float fall = smoothstep(1.0, 0.12, r);
	vec3 pal = mix(vec3(0.25, 0.45, 1.0), vec3(1.0, 0.42, 0.78), smoothstep(0.15, 0.85, r));
	vec3 col = pal * arms * fall * 1.05 + vec3(1.0, 0.95, 0.85) * dot_star * arms * fall * 1.7 + vec3(1.0, 0.88, 0.6) * exp(-r * r * 42.0) * 2.4;
	ALBEDO = col * fade * 1.5;
}
