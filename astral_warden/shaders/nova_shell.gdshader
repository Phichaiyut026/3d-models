// BIG BANG: the expanding shell of light, brightest at its silhouette.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float fade = 1.0;
uniform vec3 inner : source_color = vec3(1.0, 0.66, 0.26);

void fragment() {
	float edge = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.2);
	ALBEDO = mix(inner, vec3(1.0, 0.97, 0.9), edge) * (edge * 1.6 + 0.25) * fade * 1.5;
}
