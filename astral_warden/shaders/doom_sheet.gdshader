// FLICK OF DOOM: reality drains towards the middle of the screen until there is nothing.
shader_type canvas_item;

uniform float p = 0.0;
uniform float aspect = 1.78;

float h(vec2 v) {
	return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 q = (UV * 2.0 - 1.0) * vec2(aspect, -1.0);
	float r = length(q);
	float a = atan(q.y, q.x);
	float edge = (1.0 - p) * 2.2;
	float swirl = a + 3.0 / (r + 0.3) - TIME * 2.4;
	float streak = pow(0.5 + 0.5 * sin(swirl * 22.0 + h(vec2(floor(swirl * 3.0), 1.0)) * 9.0), 8.0);
	float x = (r - edge) / 0.05;
	float front = exp(-x * x);
	float gone = smoothstep(edge - 0.01, edge + 0.01, r);
	vec3 col = vec3(1.0, 0.05, 0.08) * front * 2.0 + vec3(0.5, 0.01, 0.03) * streak * smoothstep(edge, edge + 0.5, r) * 0.55;
	COLOR = vec4(col, max(gone, front));
}
