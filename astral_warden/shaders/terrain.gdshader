shader_type spatial;
render_mode specular_disabled;

varying vec3 world_pos;
global uniform vec3 corrupt_center;

float h(vec2 v) {
	return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

float vn(vec2 v) {
	vec2 i = floor(v);
	vec2 f = fract(v);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 v) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vn(v);
		v = v * 2.1 + 13.0;
		a *= 0.5;
	}
	return s;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float fine = fbm(world_pos.xz * 1.7);
	float broad = fbm(world_pos.xz * 0.13);
	vec3 grass = mix(vec3(0.1, 0.17, 0.05), vec3(0.25, 0.3, 0.08), smoothstep(0.32, 0.68, COLOR.b + (broad - 0.5) * 0.7));
	grass *= 0.75 + fine * 0.5;
	vec3 dirt = mix(vec3(0.22, 0.16, 0.09), vec3(0.42, 0.33, 0.2), fine);
	vec3 rock = mix(vec3(0.2, 0.19, 0.17), vec3(0.45, 0.42, 0.37), fbm(world_pos.xz * 0.6 + world_pos.y * 0.8));
	float dirt_mask = smoothstep(0.35, 0.7, COLOR.r + (fine - 0.5) * 0.7);
	vec3 color = mix(grass, dirt, dirt_mask);
	color = mix(color, rock, smoothstep(0.3, 0.7, COLOR.g + (fine - 0.5) * 0.4));
	// The ground around the tower, taken by OBLIVION's darkness: charred black, split by red veins.
	float reach = distance(world_pos.xz, corrupt_center.xz) + (broad - 0.5) * 30.0;
	float taken = 1.0 - smoothstep(520.0, 600.0, reach); // The whole valley, landing included.
	float cracks = fbm(world_pos.xz * 0.45);
	float vein = pow(1.0 - abs(cracks * 2.0 - 1.0), 22.0) * smoothstep(0.35, 0.9, taken);
	vec3 charred = mix(vec3(0.03, 0.02, 0.025), vec3(0.11, 0.05, 0.06), fine);
	charred = mix(charred, rock * vec3(0.35, 0.2, 0.22), smoothstep(0.3, 0.7, COLOR.g) * 0.6);
	ALBEDO = mix(color, charred, taken);
	EMISSION = vec3(1.0, 0.05, 0.1) * vein * 2.4 * (0.75 + 0.25 * sin(TIME * 2.0 + cracks * 12.0));
	ROUGHNESS = 0.95;
}
