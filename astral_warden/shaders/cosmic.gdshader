// Still nebula image with star layers that orbit and twinkle on top of it.
shader_type spatial;
render_mode unshaded;

uniform sampler2D nebula : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float u_scale = 4.0;
uniform vec2 u_center = vec2(0.0);
uniform float reveal_z = 1000.0; // Blade parts past this local Z are still in the rift.
varying float local_z;

void vertex() {
	local_z = VERTEX.z;
}

float star_hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec3 star_layer(vec2 uv, float density, float speed, float radius, float prob, float glint) {
	float a = TIME * speed;
	float c = cos(a);
	float s = sin(a);
	vec2 p = mat2(vec2(c, -s), vec2(s, c)) * uv * density + prob * 37.0;
	vec2 id = floor(p);
	vec2 f = fract(p);
	float h = star_hash(id);
	if (h > prob) {
		return vec3(0.0);
	}
	vec2 d = f - (0.3 + 0.4 * vec2(fract(h * 91.7), fract(h * 47.3)));
	float v = fract(h * 13.1);
	float tw = 0.3 + 0.7 * pow(0.5 + 0.5 * sin(TIME * (1.2 + v * 4.0) + h * 80.0), 2.0);
	float core = smoothstep(radius * (0.6 + 0.8 * v), 0.0, length(d));
	float arms = glint * (smoothstep(0.3, 0.0, abs(d.x)) * smoothstep(0.022, 0.0, abs(d.y)) + smoothstep(0.3, 0.0, abs(d.y)) * smoothstep(0.022, 0.0, abs(d.x)));
	vec3 tint = v > 0.66 ? vec3(1.0) : (v > 0.33 ? vec3(0.7, 0.8, 1.0) : vec3(0.78, 0.6, 1.0));
	return tint * (core + arms) * tw * 1.6;
}

void fragment() {
	if (local_z > reveal_z) {
		discard;
	}
	vec2 star_uv = UV * u_scale - u_center;
	vec3 stars = star_layer(star_uv, 9.0, 0.028, 0.1, 0.62, 0.0)
			+ star_layer(star_uv, 5.5, 0.05, 0.12, 0.55, 0.0)
			+ star_layer(star_uv, 3.0, 0.085, 0.11, 0.4, 1.0);
	float cut_edge = smoothstep(reveal_z - 0.3, reveal_z, local_z);
	ALBEDO = texture(nebula, UV).rgb + stars + vec3(0.85, 0.75, 1.0) * cut_edge * 4.0;
}
