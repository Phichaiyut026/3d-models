// OBLIVION's black hole: the photon ring and red lensing around the sphere. Always faces the camera.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float power = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float d = length(p) * 2.7;
	float a = atan(-p.y, p.x);
	float x = (d - 1.05) / 0.035;
	float photon = exp(-x * x) * 3.2;
	float lens = smoothstep(1.0, 1.06, d) * pow(max(1.0 - (d - 1.0) / 1.75, 0.0), 2.6) * (0.75 + 0.25 * sin(a * 6.0 + TIME * 0.9) * sin(a * 11.0 - TIME * 0.6));
	float y = (d - 1.42 - 0.22 * sin(a)) / 0.12;
	float upper = exp(-y * y) * smoothstep(-0.2, 1.0, sin(a)) * 1.5;
	ALBEDO = (vec3(1.0, 0.03, 0.06) * lens * 1.5 + vec3(1.0, 0.35, 0.22) * photon + vec3(1.0, 0.2, 0.12) * upper) * power;
}
