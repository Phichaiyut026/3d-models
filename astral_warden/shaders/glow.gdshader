shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 color : source_color = vec3(1.0);
uniform float strength = 1.0;
uniform float pulse_amount = 0.16;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float a = d < 0.4 ? mix(0.85, 0.25, d / 0.4) : mix(0.25, 0.0, (d - 0.4) / 0.6);
	a = max(a, 0.0);
	float pulse = 1.0 - pulse_amount + sin(TIME * 2.4) * pulse_amount;
	ALBEDO = color * a * strength * pulse;
}
