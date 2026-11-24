// ARGON's aura: honeycomb and rays, a camera-facing disc that always stays behind the body.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled, skip_vertex_transform;

uniform float half_size = 5.0;
uniform float depth = 1.4;
uniform float power = 0.6;

varying vec2 v_p;

float hex_dist(vec2 p) {
	p = abs(p);
	return max(dot(p, vec2(0.5, 0.8660254)), p.x);
}

vec4 hex_coords(vec2 uv) {
	vec2 hr = vec2(1.0, 1.7320508);
	vec2 hh = hr * 0.5;
	vec2 a = mod(uv, hr) - hh;
	vec2 b = mod(uv - hh, hr) - hh;
	vec2 gv = dot(a, a) < dot(b, b) ? a : b;
	return vec4(gv, uv - gv);
}

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
	float rays = pow(0.5 + 0.5 * sin(an * 12.0 + t * 0.3 + sin(an * 5.0 - t * 0.5) * 2.0), 3.0) * 0.65 + pow(0.5 + 0.5 * sin(an * 36.0 - t * 0.6), 6.0) * 0.45;
	float fall = pow(max(1.0 - r, 0.0), 1.7);
	vec4 hc = hex_coords(v_p * 11.0);
	float cells = smoothstep(0.06, 0.0, 0.5 - hex_dist(hc.xy)) * pow(0.5 + 0.5 * sin(t * 1.5 - length(hc.zw) * 0.6), 4.0);
	vec3 pal = mix(vec3(0.25, 0.9, 1.0), vec3(0.62, 0.45, 1.0), 0.5 + 0.5 * sin(an * 3.0 + t * 0.4));
	vec3 col = pal * (rays * fall * 1.1 + cells * fall * 0.6) + vec3(0.8, 1.0, 0.96) * exp(-r * r * 9.0) * 0.9;
	ALBEDO = col * power;
}
