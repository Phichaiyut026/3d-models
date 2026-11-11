// OBLIVION's war-cape, moving with a slow wind off the black hole. UV.y runs from collar to hem.
shader_type spatial;
render_mode cull_disabled;

void vertex() {
	float v = UV.y;
	VERTEX.z += sin(TIME * 1.3 + VERTEX.x * 1.4 + v * 5.0) * 0.22 * v - 0.06 * v * sin(TIME * 2.7 + VERTEX.x);
}

void fragment() {
	ALBEDO = vec3(0.07, 0.004, 0.012);
	ROUGHNESS = 0.8;
}
