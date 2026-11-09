// Three-step cel shading, matching the gradient ramp of the web viewer.
shader_type spatial;
render_mode specular_disabled;

uniform vec3 albedo : source_color = vec3(0.3, 0.2, 0.7);
uniform vec3 emissive : source_color = vec3(0.7, 0.6, 1.0);
uniform float emissive_energy = 0.0;
uniform float flash = 0.0;
uniform float reveal_z = 1000.0; // Blade parts past this local Z are still in the rift.
varying float local_z;

void vertex() {
	local_z = VERTEX.z;
}

void fragment() {
	if (local_z > reveal_z) {
		discard;
	}
	ALBEDO = albedo;
	ROUGHNESS = 1.0;
	EMISSION = albedo * 0.3 + emissive * emissive_energy + vec3(flash);
}

void light() {
	float d = dot(NORMAL, LIGHT) * 0.5 + 0.5;
	float ramp = d < 0.3334 ? 0.47 : (d < 0.6667 ? 0.725 : 1.0);
	DIFFUSE_LIGHT += ramp * mix(0.6, 1.0, ATTENUATION) * LIGHT_COLOR / PI;
}
