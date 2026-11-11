// A soft flame from cosmic_warrior.html: distance to a tapering capsule, on a quad that turns about its axis.
shader_type spatial;
render_mode blend_add, unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;

uniform float power = 0.0;
uniform float len = 1.0;
uniform float rad = 1.0;
uniform float world_scale = 0.36;
uniform vec3 color : source_color = vec3(1.0, 0.78, 0.42);

varying vec2 v_p;

void vertex() {
	mat4 to_view = VIEW_MATRIX * MODEL_MATRIX;
	vec3 c = (to_view * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 axis = normalize((to_view * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	vec3 view = normalize(-c);
	vec3 side = normalize(cross(axis, view));
	v_p = VERTEX.xy;
	POSITION = PROJECTION_MATRIX * vec4(c + (side * VERTEX.x + axis * VERTEX.y + view * 0.25) * world_scale, 1.0);
}

void fragment() {
	float up = clamp(v_p.y / max(len, 0.001), 0.0, 1.0);
	float wob = sin(v_p.y * 6.0 - TIME * 13.0) * 0.05 + sin(v_p.y * 13.0 - TIME * 21.0 + 1.0) * 0.03;
	float d = length(vec2(v_p.x + wob * up * rad * 1.6, v_p.y - clamp(v_p.y, 0.0, len * (0.88 + 0.12 * sin(TIME * 19.0)))));
	float g = clamp(1.0 - d / (rad * mix(1.0, 0.28, up)), 0.0, 1.0);
	ALBEDO = mix(color, vec3(1.0), smoothstep(0.55, 1.0, g)) * g * g * power;
}
