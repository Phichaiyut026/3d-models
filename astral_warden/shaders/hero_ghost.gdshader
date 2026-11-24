// UNITED WAVE: a hero's shadow in the sky behind Gemini, all rim light and scan lines (gemini_aegis.html).
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_back, depth_draw_never, shadows_disabled;

uniform vec3 tint : source_color = vec3(1.0);
uniform float a = 0.0;
uniform float stripes = 25.0; // Radians per metre: the page's nine per unit, at 0.36 m a unit.

varying float wy;

void vertex() {
	wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	float rim = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.2);
	float scan = 0.78 + 0.22 * sin(wy * stripes - TIME * 7.0);
	vec3 col = tint * (0.16 + 1.5 * rim) + vec3(1.0) * pow(rim, 4.0) * 0.5;
	ALBEDO = col * scan * a;
}
