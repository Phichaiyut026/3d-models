// The glass of a Safe Mode repair cradle: almost clear face-on, glowing at the edges,
// with fine scan lines and a slow bright band climbing through it.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;

uniform vec3 color : source_color = vec3(0.35, 1.0, 0.75);
uniform float height = 4.0;
uniform float strength = 1.0;
varying float v_y;

void vertex() {
	v_y = VERTEX.y / height + 0.5;
}

void fragment() {
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 3.0);
	float lines = smoothstep(0.82, 1.0, sin(v_y * height * 14.0 - TIME * 2.5) * 0.5 + 0.5);
	float band = smoothstep(0.07, 0.0, abs(fract(TIME * 0.16) - v_y));
	float ends = smoothstep(0.1, 0.0, v_y) + smoothstep(0.9, 1.0, v_y);
	ALBEDO = color * strength * (0.025 + rim * 0.75 + lines * 0.06 + band * 0.35 + ends * 0.4);
}
