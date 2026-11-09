// Camera-facing four-point star, for blade sparks and impact flashes.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 tint : source_color = vec3(1.0);
uniform float fade = 1.0;
uniform float spin = 0.0;
uniform float boost = 3.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec2 d = UV - vec2(0.5);
	float c = cos(spin);
	float s = sin(spin);
	d = mat2(vec2(c, -s), vec2(s, c)) * d * 2.0;
	float shape = sqrt(abs(d.x)) + sqrt(abs(d.y));
	float star = smoothstep(1.0, 0.25, shape);
	float halo = pow(max(1.0 - length(d), 0.0), 3.0) * 0.35;
	ALBEDO = (tint * COLOR.rgb * halo + mix(tint, vec3(1.0), star) * COLOR.rgb * star) * boost * fade * COLOR.a;
}
