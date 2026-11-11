// BLACK HOLE: the swirling disc around the black core. Always faces the camera.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float a = 0.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float d = length(p);
	float an = atan(p.y, p.x);
	float arms = sin(an * 3.0 + 9.0 / (d + 0.12) - TIME * 7.0) * 0.5 + 0.5;
	float band = smoothstep(0.3, 0.42, d) * (1.0 - smoothstep(0.55, 1.0, d));
	float x = (d - 0.34) / 0.045;
	float rim = exp(-x * x);
	vec3 col = mix(vec3(0.45, 0.2, 1.0), vec3(1.0, 0.85, 0.95), arms * arms);
	ALBEDO = (col * band * (0.3 + arms) + vec3(0.95, 0.9, 1.0) * rim * 2.0) * a;
}
