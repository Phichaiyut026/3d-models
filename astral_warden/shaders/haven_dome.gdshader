// The inside of Safe Mode: columns of data falling through a dark green sky.
shader_type spatial;
render_mode unshaded, fog_disabled, cull_front, shadows_disabled;

varying vec3 v_d;

float h(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	v_d = normalize(VERTEX);
}

void fragment() {
	vec3 d = normalize(v_d);
	float column = floor((atan(d.z, d.x) / TAU + 0.5) * 180.0);
	float speed = 0.25 + h(vec2(column, 3.0)) * 0.7;
	float y = d.y * 34.0 + TIME * speed * 6.0;
	float cell = floor(y);
	float bit = step(0.55, h(vec2(column, cell)));
	float trail = pow(fract(h(vec2(column, 7.0)) * 9.0 + y / 22.0), 5.0);
	vec3 sky = mix(vec3(0.005, 0.03, 0.03), vec3(0.01, 0.12, 0.09), smoothstep(-0.1, 0.9, d.y));
	ALBEDO = sky + vec3(0.25, 0.95, 0.45) * bit * trail * 0.9;
}
