// The colossal star that hangs over the valley. Fog-free so it stays legible at any distance.
shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D nebula : source_color, filter_linear_mipmap, repeat_enable;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 cell = floor(UV * 26.0);
	vec2 f = fract(UV * 26.0) - 0.5;
	float seed = h(cell);
	float twinkle = 0.45 + 0.55 * sin(TIME * (0.6 + seed * 2.0) + seed * 40.0);
	float star = smoothstep(0.14, 0.0, length(f)) * step(0.72, seed) * twinkle * 3.0;
	float edge = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	ALBEDO = texture(nebula, UV).rgb * 1.5 + vec3(star) + vec3(0.55, 0.4, 1.0) * edge * 1.4;
}
