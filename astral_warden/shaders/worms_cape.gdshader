// Worms' cape from worms.html: black outside, red-lit inside, its hem cut into stepped pixel teeth.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

uniform float flash = 0.0;

varying vec3 v_world;
varying vec3 v_out;
varying float v_fold;

float h2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float sd(vec2 p, vec2 half_size) {
	return abs(p.x) / half_size.x + abs(p.y) / half_size.y;
}

void vertex() {
	vec3 p = VERTEX;
	float v = 1.0 - UV.y;
	vec3 out_dir = normalize(vec3(p.x, 0.0, p.z - 0.2));
	float sway = sin(v * 4.0 - TIME * 1.4 + UV.x * 6.0) * 0.28 + sin(TIME * 0.9 + UV.x * 11.0) * 0.12;
	p += out_dir * sway * v * v;
	p.x += sin(TIME * 0.7 + v * 2.0) * 0.25 * v * v;
	v_fold = sin((UV.x - 0.5) * 2.0 * mix(1.05, 1.4, v) * 8.0);
	VERTEX = p;
	v_world = (MODEL_MATRIX * vec4(p, 1.0)).xyz;
	v_out = normalize((MODEL_MATRIX * vec4(out_dir, 0.0)).xyz);
}

void fragment() {
	float v = 1.0 - UV.y;
	float u = UV.x;
	const float COLS = 64.0;
	const float ROWS = 56.0;
	float cx = floor(u * COLS);
	float cy = floor(v * ROWS);
	float cu = (cx + 0.5) / COLS;
	float cv = cy / ROWS;
	float t = cu * 7.0 + 0.5;
	float id = floor(t);
	float f = fract(t);
	float depth = 0.1 + 0.2 * h2(vec2(id, 1.0));
	float hem = 1.0 - depth * abs(f - 0.5) * 2.0 - 0.015;
	hem = floor(hem * ROWS) / ROWS;
	vec3 hot = vec3(2.0, 0.09, 0.24);
	vec3 col;
	if (cv >= hem) {
		if (cv > hem + 0.075 || h2(vec2(cx, cy)) < 0.8) {
			discard;
		}
		col = hot;
	} else {
		if (cv > hem - 0.09 && h2(vec2(cx, cy) + 3.0) > 0.86) {
			discard;
		}
		vec3 cam = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
		float outside = dot(v_out, normalize(cam - v_world));
		float fold = 0.62 + 0.38 * v_fold;
		float near = smoothstep(hem - 0.2, hem, cv);
		if (outside > 0.0) {
			col = vec3(0.012, 0.008, 0.016) * fold + vec3(0.3, 0.006, 0.03) * near * near;
			float lane = floor(u * 26.0);
			float jog = floor(v * 9.0);
			float xp = (lane + 0.5 + (h2(vec2(lane, jog)) - 0.5) * 0.6) / 26.0;
			float tr = (1.0 - smoothstep(0.0012, 0.003, abs(u - xp))) * step(h2(vec2(lane, 3.0)), 0.42) * smoothstep(0.1, 0.4, v) * step(v, hem - 0.06);
			col += vec3(0.5, 0.012, 0.06) * tr;
			col += hot * 0.5 * step(0.994, h2(floor(vec2(u * 34.0, v * 46.0)) + floor(TIME * 2.5))) * step(0.22, v);
			vec2 q = vec2((u - 0.5) * 6.2, v * 14.0);
			float dia = sd(q - vec2(0.0, 3.3), vec2(0.62, 1.05));
			float sig = step(abs(dia - 1.0), 0.16) + step(dia, 0.42);
			float bl = sd(q - vec2(0.0, 6.6), vec2(0.34, 2.3));
			sig += step(bl, 1.0) * step(5.0, q.y) + step(abs(q.x), 0.34 * (1.0 - (5.0 - q.y) / 0.7)) * step(4.6, q.y) * step(q.y, 5.0);
			float pr = sd(vec2(abs(q.x) - 0.72, q.y - 6.0), vec2(0.15, 1.3));
			sig += step(pr, 1.0);
			col += hot * clamp(sig, 0.0, 1.0) * (0.8 + 0.2 * sin(TIME * 2.0));
			col += vec3(0.35, 0.0, 0.04) * exp(-length(vec2(q.x, (q.y - 5.2) * 0.5)) * 1.1) * 0.6;
		} else {
			col = mix(vec3(0.006, 0.001, 0.003), vec3(0.075, 0.002, 0.01), smoothstep(0.2, 1.0, v)) * fold;
			col += vec3(0.3, 0.006, 0.03) * near * near;
		}
		float edge = step(hem - 2.0 / ROWS, cv) + step(u, 0.014) + step(0.986, u);
		col = mix(col, hot, clamp(edge, 0.0, 1.0));
	}
	ALBEDO = col + vec3(1.0, 0.1, 0.16) * flash * 0.4;
}
