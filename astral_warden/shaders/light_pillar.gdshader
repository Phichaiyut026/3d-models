// The column of light that carries the transformation. V runs up the cylinder.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float fade = 1.0;
uniform vec3 tint : source_color = vec3(1.0, 0.82, 0.45);

void fragment() {
	float edge = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	float streak = 0.75 + 0.25 * sin(UV.x * 70.0 + TIME * 5.0);
	ALBEDO = mix(tint, vec3(1.0), 0.45) * (0.35 + edge) * streak * smoothstep(0.0, 0.8, UV.y) * fade * 1.6;
}
