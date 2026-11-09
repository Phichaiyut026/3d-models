// Ribbon left by the blade. UV.x is life (1 = just made), UV.y runs hilt side to tip side,
// UV2.x is distance along the swing in metres. COLOR carries the attack's tint.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

float h(vec2 v) {
	return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

float vn(vec2 v) {
	vec2 i = floor(v);
	vec2 f = fract(v);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float life = UV.x;
	float across = UV.y;
	float fade = smoothstep(0.0, 0.6, life);
	float body_mask = pow(smoothstep(0.0, 1.0, across), 2.2);
	float streak = 0.45 + 0.75 * vn(vec2(UV2.x * 3.5 - TIME * 5.0, across * 9.0));

	// The hot leading edge thins out as the ribbon ages.
	float rim_width = mix(0.995, 0.86, life);
	float rim = smoothstep(rim_width, 0.995, across);

	vec2 grid = vec2(UV2.x * 5.0, across * 7.0);
	vec2 cell = floor(grid);
	vec2 f = fract(grid) - 0.5;
	float seed = h(cell);
	float star = step(0.8, seed) * smoothstep(0.2, 0.0, length(f)) * across;

	vec3 aged = mix(vec3(0.2, 0.3, 1.0), COLOR.rgb, smoothstep(0.1, 0.8, life));
	vec3 glow = aged * body_mask * streak * 1.1 + vec3(1.0, 0.97, 1.0) * rim * 2.2 + vec3(1.0) * star * 1.6;
	ALBEDO = glow * fade * COLOR.a;
}
