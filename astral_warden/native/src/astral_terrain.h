#pragma once

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector3.hpp>

#include <vector>

namespace godot {

// Native side of the world: heightfield, vertex painting, scatter buffers and
// the nebula images. Everything here is per-vertex or per-pixel work that would
// take many seconds in GDScript.
class AstralTerrain : public RefCounted {
	GDCLASS(AstralTerrain, RefCounted)

public:
	void configure(float p_size, int p_resolution, int p_seed);
	void add_flat_zone(Vector2 p_center, float p_radius, float p_falloff, float p_height);
	void add_path_point(Vector2 p_point);
	void set_path_width(float p_width);
	void generate();

	float get_height(float p_x, float p_z) const;
	Vector3 get_normal(float p_x, float p_z) const;
	float get_size() const { return size; }
	int get_resolution() const { return resolution; }

	// Distance in metres to the nearest path centre line.
	float path_distance(float p_x, float p_z) const;
	// True when something tall may stand here: not on a path, a flat zone or a steep slope.
	bool is_open_ground(float p_x, float p_z, float p_margin) const;

	Ref<ArrayMesh> build_mesh(int p_step) const;
	PackedFloat32Array get_collision_heights() const;

	// MultiMesh buffer (12 floats per transform + 4 custom floats per instance) for one square chunk.
	PackedFloat32Array scatter_grass(Vector2 p_origin, float p_chunk_size, int p_count, int p_seed) const;
	// Positions for large props, as xyz + uniform scale + yaw + random tint.
	PackedFloat32Array scatter_props(int p_count, float p_radius_min, float p_radius_max, float p_max_slope, float p_margin, float p_spacing, int p_seed) const;

	static Ref<Image> make_nebula_tile(int p_size, int p_seed);
	static Ref<Image> make_wing_image(int p_size, int p_seed);

protected:
	static void _bind_methods();

private:
	struct FlatZone {
		Vector2 center;
		float radius;
		float falloff;
		float height;
	};

	float raw_height(float p_x, float p_z) const;
	float grid_height(int p_x, int p_z) const { return heights[p_z * (resolution + 1) + p_x]; }
	float flat_zone_mask(float p_x, float p_z) const;

	float size = 500.0f;
	int resolution = 500;
	int seed = 1;
	float path_width = 3.5f;
	std::vector<float> heights;
	std::vector<FlatZone> zones;
	std::vector<Vector2> path;
};

} // namespace godot
