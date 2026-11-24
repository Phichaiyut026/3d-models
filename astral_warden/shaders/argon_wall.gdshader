// FIREWALL: a honeycomb dome that grows up from the ground. Nothing gets through while it stands.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float a = 0.0;
uniform vec3 hit = vec3(0.0, 1.0, 0.0);
uniform float hit_age = 9.0;

varying vec3 v_l;

float hex_dist(vec2 q) {
	q = abs(q);
	return max(dot(q, vec2(0.5, 0.8660254)), q.x);
}

vec4 hex_coords(vec2 uv) {
	vec2 hr = vec2(1.0, 1.7320508);
	vec2 hh = hr * 0.5;
	vec2 ha = mod(uv, hr) - hh;
	vec2 hb = mod(uv - hh, hr) - hh;
	vec2 gv = dot(ha, ha) < dot(hb, hb) ? ha : hb;
	return vec4(gv, uv - gv);
}

void vertex() {
	v_l = VERTEX;
}

void fragment() {
	vec3 d = normalize(v_l);
	if (d.y < -0.02) {
		discard;
	}
	float grow = a * 1.25 - 0.1;
	if (d.y > grow) {
		discard;
	}
	vec4 hc = hex_coords(vec2(atan(d.z, d.x) * 7.6, d.y * 14.0));
	float edge = smoothstep(0.06, 0.0, 0.5 - hex_dist(hc.xy));
	float lit = pow(0.5 + 0.5 * sin(TIME * 2.0 + dot(hc.zw, vec2(3.1, 1.7))), 8.0);
	float fres = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
	float hd = distance(d, normalize(hit));
	float ripple = exp(-pow((hd - hit_age * 1.4) / 0.05, 2.0)) * max(0.0, 1.0 - hit_age * 1.6);
	float front = exp(-pow((d.y - grow) / 0.02, 2.0));
	vec3 col = vec3(0.25, 0.9, 1.0) * (edge * (0.55 + lit) + fres * 0.8 + 0.04) + vec3(0.8, 1.0, 0.95) * (ripple * 2.5 + front * 2.0);
	ALBEDO = col * min(a, 1.0);
}
