// MULTIVERSE: one small spiral universe hanging in the sky. Always faces the camera.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 hue : source_color = vec3(1.0);

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 p = UV - vec2(0.5);
	float d = length(p) * 2.0;
	vec3 col = mix(vec3(0.95), hue * 0.55, smoothstep(0.0, 0.28, d));
	col = mix(col, hue * 0.34, smoothstep(0.28, 0.76, d));
	col = mix(col, vec3(0.75), smoothstep(0.76, 0.86, d));
	col = mix(col, hue * 0.25, smoothstep(0.86, 0.92, d));
	col *= 1.0 - smoothstep(0.92, 1.0, d);
	float arm = pow(0.5 + 0.5 * cos(2.0 * (atan(p.y, p.x) - length(p) * 30.6)), 40.0) * step(length(p), 0.36);
	ALBEDO = (col + vec3(arm)) * 1.6;
}
