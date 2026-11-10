// Light of creation: a camera-facing disc of rays that always stays behind the body.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled, skip_vertex_transform;

uniform float half_size = 5.0;
uniform float depth = 1.4;
uniform float power = 0.6;

varying vec2 v_p;

void vertex() {
	v_p = VERTEX.xy;
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	c.xyz += vec3(VERTEX.xy * half_size, -depth);
	VERTEX = c.xyz;
}

void fragment() {
	float r = length(v_p);
	float an = atan(v_p.y, v_p.x);
	float t = TIME;
	float rays = pow(0.5 + 0.5 * sin(an * 14.0 + t * 0.3 + sin(an * 5.0 - t * 0.5) * 2.0), 3.0) * 0.7 + pow(0.5 + 0.5 * sin(an * 37.0 - t * 0.6), 6.0) * 0.5;
	float fall = pow(max(1.0 - r, 0.0), 1.7);
	float ripple = 0.5 + 0.5 * sin(r * 46.0 - t * 3.0);
	vec3 pal = 0.55 + 0.45 * cos(6.2832 * (an / 6.2832 + r * 1.4 - t * 0.06 + vec3(0.0, 0.33, 0.67)));
	vec3 col = mix(vec3(1.0, 0.9, 0.66), pal, 0.55) * (rays * fall * 1.1 + ripple * fall * 0.1) + vec3(1.0, 0.93, 0.75) * exp(-r * r * 9.0) * 0.9;
	ALBEDO = col * power;
}
