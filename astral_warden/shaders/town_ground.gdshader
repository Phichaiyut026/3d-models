// The ground of the town: grass, two stone roads crossing at the square, a ring road, a cobbled square,
// dirt lanes out to the farms, all fading into meadow at the edge.
shader_type spatial;
render_mode cull_back;

uniform float radius = 130.0;

float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}

varying vec2 v_p;

void vertex() {
	v_p = VERTEX.xz;
}

void fragment() {
	vec2 p = v_p;
	float d = length(p);
	// meadow
	float g = n2(p * 0.15) * 0.6 + n2(p * 0.9) * 0.4;
	vec3 col = mix(vec3(0.16, 0.42, 0.09), vec3(0.3, 0.56, 0.13), g);
	col = mix(col, vec3(0.45, 0.6, 0.15), smoothstep(0.7, 0.9, n2(p * 0.05 + 3.0)) * 0.3);
	// roads: the two main streets, the ring, and dirt lanes
	float main_road = (1.0 - smoothstep(3.3, 3.8, abs(p.x))) + (1.0 - smoothstep(3.3, 3.8, abs(p.y)));
	main_road = clamp(main_road, 0.0, 1.0) * (1.0 - smoothstep(radius * 0.92, radius, d));
	float ring = 1.0 - smoothstep(2.6, 3.1, abs(d - 60.0));
	float square = 1.0 - smoothstep(19.0, 19.6, d);
	float stone = max(max(main_road, ring), square);
	// cobbles: a grid of rounded stones, with dark mortar
	vec2 c = p * vec2(1.4, 1.8);
	c.x += floor(c.y) * 0.5;
	vec2 f = fract(c) - 0.5;
	float cob = smoothstep(0.5, 0.36, max(abs(f.x), abs(f.y)));
	vec3 stone_col = mix(vec3(0.62, 0.6, 0.58), vec3(0.92, 0.88, 0.8), cob * (0.7 + 0.3 * h2(floor(c))));
	// the square: a star of pale stone set into it
	float an = atan(p.y, p.x);
	float star = (1.0 - smoothstep(0.0, 0.6, abs(d - (7.0 + 3.0 * abs(cos(an * 2.5)))))) * square;
	stone_col = mix(stone_col, vec3(1.0, 0.84, 0.4), star);
	col = mix(col, stone_col, stone);
	// worn dirt lanes out to the fields and cottages
	float lane = 0.0;
	for (int i = 0; i < 6; i++) {
		float a = float(i) * 1.047 + 0.52;
		vec2 dir = vec2(cos(a), sin(a));
		float along = dot(p, dir);
		float across = abs(dot(p, vec2(-dir.y, dir.x)));
		lane = max(lane, (1.0 - smoothstep(1.6, 2.2, across)) * step(62.0, along) * step(along, 118.0));
	}
	col = mix(col, mix(vec3(0.72, 0.6, 0.4), vec3(0.82, 0.7, 0.48), n2(p * 1.3)), lane * (1.0 - stone));
	ALBEDO = col;
	ROUGHNESS = mix(0.95, 0.8, stone);
}
