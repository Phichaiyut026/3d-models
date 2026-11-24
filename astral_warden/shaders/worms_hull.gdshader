// The glowing red line round every silhouette of Worms: a slightly larger copy of the shape, drawn inside-out.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled, fog_disabled;

uniform float thickness = 0.028;
uniform float boost = 1.0;

void vertex() {
	VERTEX += normalize(NORMAL) * thickness;
}

void fragment() {
	ALBEDO = vec3(0.95, 0.03, 0.1) * boost;
}
