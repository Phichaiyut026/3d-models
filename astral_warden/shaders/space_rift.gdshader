// A tear in the air showing open space behind it. Opaque inside, so it reads as a hole.
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D nebula : source_color, filter_linear_mipmap, repeat_enable;
uniform float open = 0.0;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float wobble = sin(atan(p.y, p.x) * 9.0 + TIME * 7.0) * 0.02;
	float shape = sqrt(abs(p.x) * 1.9) + sqrt(abs(p.y)) + wobble;
	float limit = open * 0.96;
	float inside = smoothstep(limit, limit - 0.05, shape);
	float rim = smoothstep(limit + 0.16, limit, shape) * (1.0 - inside);

	float radius = length(p);
	float angle = atan(p.y, p.x) + TIME * 0.9 + 0.8 / (radius + 0.25);
	vec2 swirl = vec2(cos(angle), sin(angle)) * pow(radius, 0.6) * 0.42 + vec2(0.5);
	vec3 space = texture(nebula, swirl).rgb * 1.5 * smoothstep(0.0, 0.5, radius + 0.15);

	vec2 grid = swirl * 24.0;
	float seed = h(floor(grid));
	float star = step(0.82, seed) * smoothstep(0.32, 0.0, length(fract(grid) - 0.5));
	star *= 0.5 + 0.5 * sin(TIME * (3.0 + seed * 6.0) + seed * 40.0);

	vec3 hole = space * 0.75 + vec3(0.02, 0.01, 0.07) + vec3(1.0) * star * 2.5;
	vec3 edge = mix(vec3(0.5, 0.35, 1.0), vec3(1.0, 0.95, 1.0), smoothstep(limit + 0.1, limit, shape)) * 3.2;
	ALBEDO = hole * inside + edge * rim;
	ALPHA = clamp(inside + rim, 0.0, 1.0) * smoothstep(0.0, 0.08, open);
}
