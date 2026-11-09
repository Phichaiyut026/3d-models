#include "astral_terrain.h"

#include <godot_cpp/classes/mesh.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_vector3_array.hpp>

#include <algorithm>
#include <cmath>
#include <cstdint>

using namespace godot;

namespace {

const float TAU_F = 6.2831853f;

inline float saturate(float v) { return v < 0.0f ? 0.0f : (v > 1.0f ? 1.0f : v); }
inline float smooth(float a, float b, float v) {
	float t = saturate((v - a) / (b - a));
	return t * t * (3.0f - 2.0f * t);
}
inline float mixf(float a, float b, float t) { return a + (b - a) * t; }

// Park-Miller, the same generator the web viewer uses.
struct Rng {
	int64_t state;
	explicit Rng(int s) : state(s <= 0 ? 1 : s) {}
	float next() {
		state = (state * 16807) % 2147483647;
		return float(state) / 2147483647.0f;
	}
	float range(float a, float b) { return a + (b - a) * next(); }
};

inline float hash2(int x, int y, int s) {
	uint32_t h = uint32_t(x) * 374761393u + uint32_t(y) * 668265263u + uint32_t(s) * 2147483647u;
	h = (h ^ (h >> 13)) * 1274126177u;
	h ^= h >> 16;
	return float(h & 0xffffffu) / 16777215.0f;
}

float value_noise(float x, float y, int s) {
	int ix = int(std::floor(x)), iy = int(std::floor(y));
	float fx = x - ix, fy = y - iy;
	fx = fx * fx * (3.0f - 2.0f * fx);
	fy = fy * fy * (3.0f - 2.0f * fy);
	float a = hash2(ix, iy, s), b = hash2(ix + 1, iy, s);
	float c = hash2(ix, iy + 1, s), d = hash2(ix + 1, iy + 1, s);
	return mixf(mixf(a, b, fx), mixf(c, d, fx), fy);
}

float fbm(float x, float y, int octaves, int s) {
	float amplitude = 0.5f, total = 0.0f;
	for (int i = 0; i < octaves; i++) {
		total += amplitude * value_noise(x, y, s + i);
		x = x * 2.03f + 17.0f;
		y = y * 2.03f - 9.0f;
		amplitude *= 0.5f;
	}
	return total;
}

// Additive radial blob written straight into a float buffer.
void add_blob(std::vector<float> &buffer, int size, float px, float py, float radius, const float color[3], float alpha, bool wrap) {
	int x0 = int(std::floor(px - radius)), x1 = int(std::ceil(px + radius));
	int y0 = int(std::floor(py - radius)), y1 = int(std::ceil(py + radius));
	for (int y = y0; y <= y1; y++) {
		int wy = wrap ? ((y % size) + size) % size : y;
		if (wy < 0 || wy >= size) {
			continue;
		}
		for (int x = x0; x <= x1; x++) {
			int wx = wrap ? ((x % size) + size) % size : x;
			if (wx < 0 || wx >= size) {
				continue;
			}
			float dx = x - px, dy = y - py;
			float d = std::sqrt(dx * dx + dy * dy) / radius;
			if (d >= 1.0f) {
				continue;
			}
			float a = alpha * (1.0f - d);
			int i = (wy * size + wx) * 3;
			buffer[i] += color[0] * a;
			buffer[i + 1] += color[1] * a;
			buffer[i + 2] += color[2] * a;
		}
	}
}

Ref<Image> buffer_to_image(const std::vector<float> &buffer, int size) {
	PackedByteArray bytes;
	bytes.resize(size * size * 3);
	uint8_t *out = bytes.ptrw();
	for (size_t i = 0; i < buffer.size(); i++) {
		out[i] = uint8_t(std::min(255.0f, buffer[i]));
	}
	Ref<Image> image = Image::create_from_data(size, size, false, Image::FORMAT_RGB8, bytes);
	image->generate_mipmaps();
	return image;
}

const float NEBULA[3][3] = { { 122, 53, 224 }, { 52, 86, 255 }, { 192, 80, 224 } };

} // namespace

void AstralTerrain::configure(float p_size, int p_resolution, int p_seed) {
	size = p_size;
	resolution = std::max(8, p_resolution);
	seed = p_seed;
	zones.clear();
	path.clear();
}

void AstralTerrain::add_flat_zone(Vector2 p_center, float p_radius, float p_falloff, float p_height) {
	zones.push_back({ p_center, p_radius, p_falloff, p_height });
}

void AstralTerrain::add_path_point(Vector2 p_point) {
	path.push_back(p_point);
}

void AstralTerrain::set_path_width(float p_width) {
	path_width = p_width;
}

float AstralTerrain::flat_zone_mask(float p_x, float p_z) const {
	float mask = 0.0f;
	for (const FlatZone &zone : zones) {
		float d = Vector2(p_x, p_z).distance_to(zone.center);
		mask = std::max(mask, 1.0f - smooth(zone.radius, zone.radius + zone.falloff, d));
	}
	return mask;
}

float AstralTerrain::path_distance(float p_x, float p_z) const {
	float best = 1e9f;
	Vector2 p(p_x, p_z);
	for (size_t i = 0; i + 1 < path.size(); i++) {
		Vector2 a = path[i], ab = path[i + 1] - a;
		float t = saturate((p - a).dot(ab) / std::max(0.001f, ab.length_squared()));
		best = std::min(best, p.distance_to(a + ab * t));
	}
	return best;
}

float AstralTerrain::raw_height(float p_x, float p_z) const {
	// Rolling meadow, with a ring of ridges that closes the map in.
	float rolling = (fbm(p_x * 0.012f, p_z * 0.012f, 5, seed) - 0.5f) * 16.0f;
	float detail = (fbm(p_x * 0.09f, p_z * 0.09f, 3, seed + 40) - 0.5f) * 0.9f;
	float distance = std::sqrt(p_x * p_x + p_z * p_z);
	float edge = smooth(size * 0.33f, size * 0.5f, distance);
	float ridge = 1.0f - std::fabs(fbm(p_x * 0.018f, p_z * 0.018f, 5, seed + 90) * 2.0f - 1.0f);
	float mountains = edge * edge * (34.0f + ridge * ridge * 62.0f);
	float height = rolling + detail + mountains;

	// Roads are sunk slightly and smoothed so they read as worn ground.
	float road = 1.0f - smooth(path_width, path_width + 7.0f, path_distance(p_x, p_z));
	height -= road * 0.25f;
	height = mixf(height, rolling * 0.75f - 0.2f, road * 0.55f);

	for (const FlatZone &zone : zones) {
		float d = Vector2(p_x, p_z).distance_to(zone.center);
		float mask = 1.0f - smooth(zone.radius, zone.radius + zone.falloff, d);
		height = mixf(height, zone.height, mask);
	}
	return height;
}

void AstralTerrain::generate() {
	int row = resolution + 1;
	heights.assign(row * row, 0.0f);
	float step = size / resolution;
	for (int z = 0; z < row; z++) {
		for (int x = 0; x < row; x++) {
			heights[z * row + x] = raw_height(-size * 0.5f + x * step, -size * 0.5f + z * step);
		}
	}
}

float AstralTerrain::get_height(float p_x, float p_z) const {
	if (heights.empty()) {
		return 0.0f;
	}
	float step = size / resolution;
	float gx = std::clamp((p_x + size * 0.5f) / step, 0.0f, float(resolution) - 0.001f);
	float gz = std::clamp((p_z + size * 0.5f) / step, 0.0f, float(resolution) - 0.001f);
	int ix = int(gx), iz = int(gz);
	float fx = gx - ix, fz = gz - iz;
	return mixf(mixf(grid_height(ix, iz), grid_height(ix + 1, iz), fx),
			mixf(grid_height(ix, iz + 1), grid_height(ix + 1, iz + 1), fx), fz);
}

Vector3 AstralTerrain::get_normal(float p_x, float p_z) const {
	const float e = 1.0f;
	Vector3 n(get_height(p_x - e, p_z) - get_height(p_x + e, p_z), 2.0f * e,
			get_height(p_x, p_z - e) - get_height(p_x, p_z + e));
	return n.normalized();
}

bool AstralTerrain::is_open_ground(float p_x, float p_z, float p_margin) const {
	if (path_distance(p_x, p_z) < path_width + p_margin) {
		return false;
	}
	for (const FlatZone &zone : zones) {
		if (Vector2(p_x, p_z).distance_to(zone.center) < zone.radius + p_margin) {
			return false;
		}
	}
	return true;
}

Ref<ArrayMesh> AstralTerrain::build_mesh(int p_step) const {
	int stride = std::max(1, p_step);
	int cells = resolution / stride;
	int row = cells + 1;
	float step = size / resolution * stride;

	PackedVector3Array vertices, normals;
	PackedColorArray colors;
	PackedInt32Array indices;
	vertices.resize(row * row);
	normals.resize(row * row);
	colors.resize(row * row);
	indices.resize(cells * cells * 6);

	Vector3 *vp = vertices.ptrw();
	Vector3 *np = normals.ptrw();
	Color *cp = colors.ptrw();

	for (int z = 0; z < row; z++) {
		for (int x = 0; x < row; x++) {
			int i = z * row + x;
			int gx = x * stride, gz = z * stride;
			float wx = -size * 0.5f + x * step, wz = -size * 0.5f + z * step;
			vp[i] = Vector3(wx, grid_height(gx, gz), wz);

			float left = grid_height(std::max(0, gx - stride), gz), right = grid_height(std::min(resolution, gx + stride), gz);
			float back = grid_height(gx, std::max(0, gz - stride)), front = grid_height(gx, std::min(resolution, gz + stride));
			Vector3 n = Vector3(left - right, 2.0f * step, back - front).normalized();
			np[i] = n;

			// R = worn dirt, G = bare rock, B = gold/green meadow variation.
			float road = 1.0f - smooth(path_width * 0.45f, path_width + 2.5f, path_distance(wx, wz));
			float patches = smooth(0.52f, 0.68f, fbm(wx * 0.05f, wz * 0.05f, 4, seed + 7));
			float dirt = saturate(road + patches * 0.35f);
			float rock = smooth(0.84f, 0.68f, n.y);
			float meadow = fbm(wx * 0.022f, wz * 0.022f, 3, seed + 21);
			cp[i] = Color(dirt, rock, meadow, 1.0f);
		}
	}

	int *ip = indices.ptrw();
	int k = 0;
	for (int z = 0; z < cells; z++) {
		for (int x = 0; x < cells; x++) {
			int a = z * row + x, b = a + 1, c = a + row, d = c + 1;
			// Godot treats clockwise as the front face.
			ip[k++] = a;
			ip[k++] = b;
			ip[k++] = c;
			ip[k++] = b;
			ip[k++] = d;
			ip[k++] = c;
		}
	}

	Array arrays;
	arrays.resize(Mesh::ARRAY_MAX);
	arrays[Mesh::ARRAY_VERTEX] = vertices;
	arrays[Mesh::ARRAY_NORMAL] = normals;
	arrays[Mesh::ARRAY_COLOR] = colors;
	arrays[Mesh::ARRAY_INDEX] = indices;

	Ref<ArrayMesh> mesh;
	mesh.instantiate();
	mesh->add_surface_from_arrays(Mesh::PRIMITIVE_TRIANGLES, arrays);
	return mesh;
}

PackedFloat32Array AstralTerrain::get_collision_heights() const {
	PackedFloat32Array out;
	out.resize(heights.size());
	std::copy(heights.begin(), heights.end(), out.ptrw());
	return out;
}

PackedFloat32Array AstralTerrain::scatter_grass(Vector2 p_origin, float p_chunk_size, int p_count, int p_seed) const {
	Rng rng(p_seed);
	std::vector<float> data;
	data.reserve(p_count * 16);
	for (int i = 0; i < p_count; i++) {
		float lx = rng.next() * p_chunk_size, lz = rng.next() * p_chunk_size;
		float scale = rng.range(0.7f, 1.35f), yaw = rng.next() * TAU_F, tint = rng.next();
		float wx = p_origin.x + lx, wz = p_origin.y + lz;

		float road = path_distance(wx, wz);
		if (road < path_width * 0.55f) {
			continue;
		}
		Vector3 n = get_normal(wx, wz);
		if (n.y < 0.84f) {
			continue;
		}
		// Thin the meadow into clumps, and shorten it towards roads.
		float density = fbm(wx * 0.07f, wz * 0.07f, 3, seed + 3);
		if (density < 0.3f) {
			continue;
		}
		float road_fade = smooth(path_width * 0.55f, path_width + 3.0f, road);
		float height_scale = scale * (0.55f + 0.45f * road_fade) * (0.8f + density * 0.65f);

		float c = std::cos(yaw) * scale, s = std::sin(yaw) * scale;
		float y = get_height(wx, wz) - 0.02f;
		const float row[16] = {
			c, 0.0f, s, lx,
			0.0f, height_scale, 0.0f, y,
			-s, 0.0f, c, lz,
			tint, float(fbm(wx * 0.02f, wz * 0.02f, 3, seed + 21)), rng.next(), 1.0f
		};
		data.insert(data.end(), row, row + 16);
	}
	PackedFloat32Array out;
	out.resize(data.size());
	std::copy(data.begin(), data.end(), out.ptrw());
	return out;
}

PackedFloat32Array AstralTerrain::scatter_props(int p_count, float p_radius_min, float p_radius_max, float p_max_slope, float p_margin, float p_spacing, int p_seed) const {
	Rng rng(p_seed);
	std::vector<float> data;
	std::vector<Vector2> placed;
	int attempts = p_count * 40;
	while (attempts-- > 0 && int(placed.size()) < p_count) {
		float angle = rng.next() * TAU_F;
		float radius = std::sqrt(mixf(p_radius_min * p_radius_min, p_radius_max * p_radius_max, rng.next()));
		Vector2 p(std::cos(angle) * radius, std::sin(angle) * radius);
		if (!is_open_ground(p.x, p.y, p_margin) || get_normal(p.x, p.y).y < p_max_slope) {
			continue;
		}
		bool crowded = false;
		for (const Vector2 &other : placed) {
			if (other.distance_squared_to(p) < p_spacing * p_spacing) {
				crowded = true;
				break;
			}
		}
		if (crowded) {
			continue;
		}
		placed.push_back(p);
		const float row[6] = { p.x, get_height(p.x, p.y), p.y, rng.range(0.75f, 1.35f), rng.next() * TAU_F, rng.next() };
		data.insert(data.end(), row, row + 6);
	}
	PackedFloat32Array out;
	out.resize(data.size());
	std::copy(data.begin(), data.end(), out.ptrw());
	return out;
}

Ref<Image> AstralTerrain::make_nebula_tile(int p_size, int p_seed) {
	Rng rng(p_seed);
	std::vector<float> buffer(p_size * p_size * 3);
	for (int i = 0; i < p_size * p_size; i++) {
		buffer[i * 3] = 0x12;
		buffer[i * 3 + 1] = 0x0c;
		buffer[i * 3 + 2] = 0x48;
	}
	float k = p_size / 512.0f;
	for (int i = 0; i < 34; i++) {
		float px = rng.next() * p_size, py = rng.next() * p_size, r = (50.0f + rng.next() * 90.0f) * k;
		add_blob(buffer, p_size, px, py, r, NEBULA[int(rng.next() * 3.0f) % 3], 0.26f, true);
	}
	return buffer_to_image(buffer, p_size);
}

Ref<Image> AstralTerrain::make_wing_image(int p_size, int p_seed) {
	Rng rng(p_seed);
	std::vector<float> buffer(p_size * p_size * 3);
	for (int i = 0; i < p_size * p_size; i++) {
		buffer[i * 3] = 0x17;
		buffer[i * 3 + 1] = 0x10;
		buffer[i * 3 + 2] = 0x5a;
	}
	// Spots are placed in wing-sheet units: x from the spine outward, y from the lowest spike to the top tip.
	auto spot = [&](float wx, float wy, float r, const float *color, float alpha) {
		add_blob(buffer, p_size, wx / 2.9f * p_size, (1.0f - (wy - 2.1f) / 3.1f) * p_size, r * p_size / 2.9f, color, alpha, false);
	};
	const float blue[3] = { 52, 96, 255 }, violet[3] = { 150, 60, 240 }, pink[3] = { 226, 96, 230 }, pale[3] = { 150, 190, 255 };
	spot(1.1f, 4.15f, 0.75f, blue, 0.75f);
	spot(1.55f, 3.45f, 0.85f, violet, 0.8f);
	spot(1.95f, 3.1f, 0.55f, pink, 0.55f);
	spot(1.35f, 3.85f, 0.35f, pale, 0.55f);
	for (int i = 0; i < 22; i++) {
		float x = 0.7f + rng.next() * 1.7f, y = 2.7f + rng.next() * 1.8f, r = 0.1f + rng.next() * 0.25f;
		spot(x, y, r, NEBULA[int(rng.next() * 3.0f) % 3], 0.3f);
	}
	return buffer_to_image(buffer, p_size);
}

void AstralTerrain::_bind_methods() {
	ClassDB::bind_method(D_METHOD("configure", "size", "resolution", "seed"), &AstralTerrain::configure);
	ClassDB::bind_method(D_METHOD("add_flat_zone", "center", "radius", "falloff", "height"), &AstralTerrain::add_flat_zone);
	ClassDB::bind_method(D_METHOD("add_path_point", "point"), &AstralTerrain::add_path_point);
	ClassDB::bind_method(D_METHOD("set_path_width", "width"), &AstralTerrain::set_path_width);
	ClassDB::bind_method(D_METHOD("generate"), &AstralTerrain::generate);
	ClassDB::bind_method(D_METHOD("get_height", "x", "z"), &AstralTerrain::get_height);
	ClassDB::bind_method(D_METHOD("get_normal", "x", "z"), &AstralTerrain::get_normal);
	ClassDB::bind_method(D_METHOD("get_size"), &AstralTerrain::get_size);
	ClassDB::bind_method(D_METHOD("get_resolution"), &AstralTerrain::get_resolution);
	ClassDB::bind_method(D_METHOD("path_distance", "x", "z"), &AstralTerrain::path_distance);
	ClassDB::bind_method(D_METHOD("is_open_ground", "x", "z", "margin"), &AstralTerrain::is_open_ground);
	ClassDB::bind_method(D_METHOD("build_mesh", "step"), &AstralTerrain::build_mesh);
	ClassDB::bind_method(D_METHOD("get_collision_heights"), &AstralTerrain::get_collision_heights);
	ClassDB::bind_method(D_METHOD("scatter_grass", "origin", "chunk_size", "count", "seed"), &AstralTerrain::scatter_grass);
	ClassDB::bind_method(D_METHOD("scatter_props", "count", "radius_min", "radius_max", "max_slope", "margin", "spacing", "seed"), &AstralTerrain::scatter_props);
	ClassDB::bind_static_method("AstralTerrain", D_METHOD("make_nebula_tile", "size", "seed"), &AstralTerrain::make_nebula_tile);
	ClassDB::bind_static_method("AstralTerrain", D_METHOD("make_wing_image", "size", "seed"), &AstralTerrain::make_wing_image);
}
