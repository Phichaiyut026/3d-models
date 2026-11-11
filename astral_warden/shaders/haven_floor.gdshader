// Safe Mode's floor: a quiet circuit grid with slow pulses travelling out from the middle.
shader_type spatial;
render_mode unshaded, fog_disabled;

varying vec2 v_p;

void vertex() {
	v_p = VERTEX.xz;
}

float line_at(float x, float width) {
	float d = abs(fract(x) - 0.5);
	return smoothstep(width, width * 0.4, 0.5 - d);
}

void fragment() {
	float r = length(v_p);
	float grid = max(line_at(v_p.x / 4.0, 0.02), line_at(v_p.y / 4.0, 0.02));
	float fine = max(line_at(v_p.x, 0.012), line_at(v_p.y, 0.012)) * 0.25;
	float pulse = pow(0.5 + 0.5 * sin(r * 0.5 - TIME * 1.2), 10.0);
	float ring = smoothstep(0.4, 0.0, abs(r - 13.0)) + smoothstep(0.3, 0.0, abs(r - 34.0));
	vec3 base = vec3(0.012, 0.025, 0.03);
	vec3 teal = vec3(0.1, 0.75, 0.55);
	ALBEDO = base + teal * (grid * (0.25 + pulse * 1.6) + fine * 0.5) + vec3(0.72, 1.0, 0.18) * ring * 0.9;
}
