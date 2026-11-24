// The code of the antivirus running down ARGON's mantle. Uses the mantle's own x and y, as on the web page.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

varying vec2 v_p;

float h1(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void vertex() {
	v_p = VERTEX.xy;
}

void fragment() {
	float col = floor(v_p.x * 16.0);
	float y = v_p.y * 12.0 + TIME * (2.0 + h1(vec2(col, 1.0)) * 4.0);
	float row = floor(y);
	float glyph = step(0.45, h1(vec2(col, row))) * step(abs(fract(v_p.x * 16.0) - 0.5), 0.3) * step(abs(fract(y) - 0.5), 0.35);
	float trail = pow(fract(-y / 14.0 + h1(vec2(col, 5.0))), 4.0);
	ALBEDO = vec3(0.3, 1.0, 0.82) * glyph * trail * smoothstep(0.1, 1.4, v_p.y) * 0.9;
}
