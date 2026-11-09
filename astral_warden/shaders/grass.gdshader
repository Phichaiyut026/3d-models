shader_type spatial;
render_mode cull_disabled, specular_disabled;

varying float blade_h;
varying vec3 tint;

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
}

void fragment() {
	ALBEDO = tint * mix(0.42, 1.2, blade_h);
	ROUGHNESS = 0.9;
	BACKLIGHT = vec3(0.25);
}
