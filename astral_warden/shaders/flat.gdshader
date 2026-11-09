// Solid glowing colour; boost above 1 feeds the bloom.
shader_type spatial;
render_mode unshaded;

uniform vec3 color : source_color = vec3(1.0);
uniform float boost = 1.0;
uniform float reveal_z = 1000.0; // Blade parts past this local Z are still in the rift.
varying float local_z;

void vertex() {
	local_z = VERTEX.z;
}

void fragment() {
	if (local_z > reveal_z) {
		discard;
	}
	ALBEDO = color * boost;
}
