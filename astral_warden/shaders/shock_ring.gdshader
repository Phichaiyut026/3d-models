// A soft expanding ring of light: the shockwave of every power in cosmic_warrior.html.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled;

uniform float r = 0.0;
uniform float a = 0.0;
uniform vec3 color : source_color = vec3(1.0, 0.78, 0.42);
uniform bool billboard = false;

void vertex() {
	if (billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float x = (d - r) / 0.08;
	float w = exp(-x * x);
	float g = (w + 0.16 * (1.0 - smoothstep(0.0, r + 0.001, d))) * (1.0 - smoothstep(0.86, 1.0, d));
	ALBEDO = mix(color, vec3(1.0), w * 0.6) * g * a;
}
