// Solid glowing colour seen from both sides. A texture adds decals with cut-out alpha.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 color : source_color = vec3(1.0);
uniform float boost = 1.0;
uniform bool textured = false;
uniform sampler2D decal : source_color, filter_linear_mipmap;

void fragment() {
	vec4 t = textured ? texture(decal, UV) : vec4(1.0);
	ALBEDO = color * t.rgb * boost;
	if (textured) {
		ALPHA = t.a;
		ALPHA_SCISSOR_THRESHOLD = 0.35;
	}
}
