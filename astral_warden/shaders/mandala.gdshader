// The mandala of creation under the feet of the supreme form.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float power = 1.0;

float ln(float v, float w) {
	return smoothstep(w, 0.0, abs(v));
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float an = atan(p.y, p.x);
	float t = TIME;
	float rings = ln(d - 0.93, 0.012) + ln(d - 0.78, 0.008) + ln(d - 0.42, 0.008) + ln(d - 0.3, 0.012);
	float sect = abs(fract((an + t * 0.12) / 6.2832 * 12.0) - 0.5) * 2.0;
	float star_line = ln(d - (0.3 + 0.48 * sect), 0.012) * step(d, 0.8);
	float tick = ln(fract((an - t * 0.2) / 6.2832 * 24.0) - 0.5, 0.06) * step(0.8, d) * step(d, 0.92);
	float wash = pow(max(1.0 - d, 0.0), 2.0) * 0.18;
	vec3 col = vec3(1.0, 0.82, 0.42) * (rings * 0.9 + star_line + tick * 0.8) + vec3(0.65, 0.45, 1.0) * wash;
	ALBEDO = col * step(d, 1.0) * power * 1.6;
}
