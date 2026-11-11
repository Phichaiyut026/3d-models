// Zero Day's cape, worked out as in zero_day.html: its edges come apart into pixels and it never holds still.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D tex : source_color, filter_nearest;

void vertex() {
	float u = UV.x;
	float v = UV.y;
	VERTEX.x += sin(TIME * 1.3 + v * 5.0) * 0.3 * v;
	VERTEX.z += v * (sin(u * 19.0 + TIME * 1.8) * 0.55 + sin(u * 8.0 - TIME * 1.2 + v * 4.0) * 0.65);
}

void fragment() {
	vec4 c = texture(tex, UV);
	ALBEDO = c.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.8;
}
