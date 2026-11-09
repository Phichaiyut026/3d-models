// Inverted hull pushed along the welded normals stored in CUSTOM0.
shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;

uniform vec3 color : source_color = vec3(0.07, 0.04, 0.23);
uniform float thickness = 0.02;
uniform float boost = 1.0;
uniform float reveal_z = 1000.0; // Blade parts past this local Z are still in the rift.
varying float local_z;

void vertex() {
	local_z = VERTEX.z;
	VERTEX += CUSTOM0.xyz * thickness;
}

void fragment() {
	if (local_z > reveal_z) {
		discard;
	}
	ALBEDO = color * boost;
}
