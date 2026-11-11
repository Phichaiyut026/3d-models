shader_type spatial;
render_mode cull_disabled, specular_disabled;

varying float blade_h;
varying vec3 tint;
varying float taken;
global uniform vec3 corrupt_center;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 base = MODEL_MATRIX[3].xyz;
	float dist = distance(base, CAMERA_POSITION_WORLD);
	float fade = 1.0 - smoothstep(72.0, 108.0, dist);
	blade_h = UV.y;
	float gust = sin(TIME * 1.2 + world.x * 0.18 + world.z * 0.13) * 0.5 + 0.5;
	float flutter = sin(TIME * 3.1 + INSTANCE_CUSTOM.b * 40.0 + world.x);
	VERTEX *= vec3(1.0, fade, 1.0);
	VERTEX.xz += (vec2(0.16, 0.08) * gust + vec2(0.05) * flutter) * blade_h * blade_h;
	NORMAL = vec3(0.0, 1.0, 0.0);

	vec3 olive = mix(vec3(0.15, 0.26, 0.07), vec3(0.33, 0.39, 0.1), smoothstep(0.32, 0.68, INSTANCE_CUSTOM.g));
	vec3 straw = vec3(0.5, 0.46, 0.2);
	tint = mix(olive, straw, smoothstep(0.78, 1.0, INSTANCE_CUSTOM.r) * 0.7);
	// Near the tower the grass is dead and black, and it does not move with the wind any more.
	taken = 1.0 - smoothstep(520.0, 600.0, distance(base.xz, corrupt_center.xz) + (INSTANCE_CUSTOM.g - 0.5) * 24.0);
	tint = mix(tint, vec3(0.045, 0.03, 0.04), taken);
}

void fragment() {
	ALBEDO = tint * mix(0.42, 1.2, blade_h);
	EMISSION = vec3(0.9, 0.04, 0.08) * taken * smoothstep(0.75, 1.0, blade_h) * 0.9;
	ROUGHNESS = 0.9;
	BACKLIGHT = vec3(0.25) * (1.0 - taken);
}
