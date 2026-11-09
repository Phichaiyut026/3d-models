shader_type spatial;

uniform vec3 light_tone : source_color = vec3(0.6, 0.59, 0.56);
uniform vec3 dark_tone : source_color = vec3(0.38, 0.37, 0.35);
uniform vec3 moss : source_color = vec3(0.27, 0.32, 0.13);
uniform float moss_amount = 0.7;
uniform float noise_scale = 1.2;

varying vec3 world_pos;
varying vec3 world_normal;

float h(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float vn(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h(i), h(i + vec3(1, 0, 0)), f.x), mix(h(i + vec3(0, 1, 0)), h(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(h(i + vec3(0, 0, 1)), h(i + vec3(1, 0, 1)), f.x), mix(h(i + vec3(0, 1, 1)), h(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float a = 0.5;
	float s = 0.0;
	for (int i = 0; i < 4; i++) {
		s += a * vn(p);
		p = p * 2.1 + 11.0;
		a *= 0.5;
	}
	return s;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float broad = fbm(world_pos * noise_scale * 0.22);
	float grain = fbm(world_pos * noise_scale * 4.0);
	float cracks = smoothstep(0.012, 0.0, abs(fbm(world_pos * noise_scale * 1.1) - 0.5));
	vec3 color = mix(dark_tone, light_tone, clamp(broad * 0.9 + grain * 0.75 - 0.32, 0.0, 1.0));
	color *= 1.0 - cracks * 0.4;
	float moss_mask = smoothstep(0.45, 0.85, world_normal.y) * smoothstep(0.42, 0.62, fbm(world_pos * 0.55)) * moss_amount;
	ALBEDO = mix(color, moss, moss_mask);
	ROUGHNESS = 0.92;
	SPECULAR = 0.2;
}
