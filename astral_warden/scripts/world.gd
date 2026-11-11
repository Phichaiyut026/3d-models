extends Node3D
## Builds the valley: terrain, vegetation, ruins, actors and UI.

const SKY := preload("res://shaders/sky.gdshader")
const TERRAIN := preload("res://shaders/terrain.gdshader")
const GRASS := preload("res://shaders/grass.gdshader")
const FOLIAGE := preload("res://shaders/foliage.gdshader")
const STONE := preload("res://shaders/stone.gdshader")
const FALLEN_STAR := preload("res://shaders/fallen_star.gdshader")
const GLOW := preload("res://shaders/glow.gdshader")

const SHRINE_START := Vector3(0, 0, 76)
const SHRINE_MID := Vector3(10, 0, -60)
const ARENA := Vector3(22, 0, -116)
const TOWER := Vector3(22, 0, -168)
const CAMP := Vector3(-48, 0, 6)
const GRASS_CHUNK := 32.0
const PROP_CELL := 64.0
const TREE_NEAR_RANGE := 64.0

var _terrain: AstralTerrain
var _stone: ShaderMaterial
var _bodies: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _leaf_texture: ImageTexture
var _grass_chunks: Array = [] ## Each is [MultiMesh, centre, instance count].
var _grass_clock := 0.0
var _grass_near := 1.0
var _grass_far := 0.16
var _sun: DirectionalLight3D
var _env: Environment
var _corruption := -1.0
var _fallout: Array[CPUParticles3D] = [] ## Ash and embers, kept around the camera.

const CORRUPT_CENTER := Vector3(22, 0, -136) ## Matches the corrupt_center shader global.
const SUN_CLEAR := Color(1.0, 0.93, 0.76)
const SUN_TAKEN := Color(1.0, 0.36, 0.32)
const FOG_CLEAR := Color(0.82, 0.77, 0.56)
const FOG_TAKEN := Color(0.32, 0.04, 0.07)


func _ready() -> void:
	Game.world = self
	_rng.seed = 2031
	_stone = ShaderMaterial.new()
	_stone.shader = STONE
	_bodies = StaticBody3D.new()
	_bodies.collision_layer = 1
	_bodies.collision_mask = 0
	add_child(_bodies)
	_leaf_texture = _make_leaf_texture()
	# Set from code too: if the project-settings default is not picked up, the centre falls to the
	# world origin, which is right beside the landing spot.
	RenderingServer.global_shader_parameter_set("corrupt_center", CORRUPT_CENTER)
	RenderingServer.global_shader_parameter_set("corruption", 0.0)

	_build_environment()
	_build_terrain()
	_build_grass()
	_build_trees()
	_build_bushes()
	_build_rocks()
	_build_ruins()
	_build_stakes()
	_build_fallen_star()
	_build_shrines()
	_build_corruption()
	_spawn_actors()
	var haven := SafeHaven.new()
	add_child(haven)
	Game.haven = haven
	_build_ui()

	Game.apply_settings()
	Game.warmup()
	if Game.autotest:
		var driver: Node = load("res://scripts/autotest.gd").new()
		add_child(driver)


## The whole valley belongs to OBLIVION: red space overhead from the landing on, deepest at its tower.
## Stepped, so the sky's lighting is only redrawn when the change can be seen.
func _update_corruption() -> void:
	var at := Game.camera.global_position
	var near := Vector2(at.x - CORRUPT_CENTER.x, at.z - CORRUPT_CENTER.z).length()
	var amount := lerpf(1.0, 0.85, smoothstep(70.0, 200.0, near))
	var in_haven := at.y > SafeHaven.CENTER.y - 60.0
	if in_haven:
		amount = 0.0
	for p: CPUParticles3D in _fallout:
		p.visible = not in_haven
		if not in_haven:
			p.global_position = Vector3(at.x, _ground(Vector3(at.x, 0, at.z)).y + p.get_meta("lift"), at.z)
	amount = snappedf(amount, 0.05)
	if is_equal_approx(amount, _corruption):
		return
	_corruption = amount
	RenderingServer.global_shader_parameter_set("corruption", amount)
	_sun.light_color = SUN_CLEAR.lerp(SUN_TAKEN, amount)
	_sun.light_energy = lerpf(1.55, 0.95, amount)
	_env.fog_light_color = FOG_CLEAR.lerp(FOG_TAKEN, amount)
	_env.fog_density = lerpf(0.003, 0.006, amount)
	_env.ambient_light_energy = lerpf(0.75, 0.5, amount)
	_env.adjustment_saturation = lerpf(1.08, 1.2, amount)


## Ash coming down and embers going up, everywhere the darkness has taken. They follow the camera.
func _build_corruption() -> void:
	var at := _ground(CORRUPT_CENTER)
	for spec: Array in [[Color(0.32, 0.28, 0.3), 220, Vector3.DOWN, 0.2, 9.0, 30.0], [Color(1.0, 0.18, 0.12), 130, Vector3.UP, 0.08, 6.0, 2.0]]:
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * spec[3]
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		material.albedo_color = spec[0]
		if spec[2] == Vector3.UP:
			material.emission_enabled = true
			material.emission = spec[0]
			material.emission_energy_multiplier = 3.0
		quad.material = material
		var p := CPUParticles3D.new()
		p.mesh = quad
		p.amount = spec[1]
		p.lifetime = spec[4]
		p.preprocess = spec[4]
		p.local_coords = false
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(48, 2, 48)
		p.direction = spec[2]
		p.spread = 20.0
		p.gravity = Vector3.ZERO
		p.initial_velocity_min = 0.8
		p.initial_velocity_max = 2.2
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		p.visibility_aabb = AABB(Vector3(-80, -40, -80), Vector3(160, 80, 160))
		add_child(p)
		p.global_position = at + Vector3(0, spec[5], 0)
		p.set_meta("lift", spec[5])
		_fallout.append(p)


## Thins grass with distance. The order inside a chunk is random, so any prefix is an even sample.
func _process(delta: float) -> void:
	if Game.camera != null:
		_update_corruption()
	_grass_clock -= delta
	if _grass_clock > 0.0 or Game.camera == null:
		return
	_grass_clock = 0.2
	var from := Vector2(Game.camera.global_position.x, Game.camera.global_position.z)
	for chunk: Array in _grass_chunks:
		var density := lerpf(_grass_near, _grass_far, smoothstep(26.0, 80.0, from.distance_to(chunk[1])))
		var wanted := int(chunk[2] * snappedf(density, 0.05))
		if (chunk[0] as MultiMesh).visible_instance_count != wanted:
			(chunk[0] as MultiMesh).visible_instance_count = wanted


## 0 low, 1 medium, 2 high. Sets how far shadows reach and how thick the grass is.
func apply_quality(level: int) -> void:
	_sun.directional_shadow_max_distance = [40.0, 70.0, 110.0][level]
	_grass_near = [0.6, 1.0, 1.0][level]
	_grass_far = [0.08, 0.16, 0.32][level]
	_grass_clock = 0.0


func _build_environment() -> void:
	var material := ShaderMaterial.new()
	material.shader = SKY
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_128

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 3.2
	env.tonemap_exposure = 1.0
	env.ssao_enabled = false
	env.ssao_radius = 1.4
	env.ssao_intensity = 1.6
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.02
	env.glow_hdr_threshold = 1.15
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.fog_enabled = true
	env.fog_light_color = Color(0.82, 0.77, 0.56)
	env.fog_sun_scatter = 0.25
	env.fog_density = 0.003
	env.fog_sky_affect = 0.0
	env.fog_aerial_perspective = 0.35
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.05
	var node := WorldEnvironment.new()
	node.environment = env
	add_child(node)
	_env = env

	var sun := DirectionalLight3D.new()
	_sun = sun
	sun.rotation_degrees = Vector3(-38.0, 138.0, 0.0)
	sun.light_color = Color(1.0, 0.93, 0.76)
	sun.light_energy = 1.55
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_split_1 = 0.2
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	add_child(sun)


func _build_terrain() -> void:
	_terrain = AstralTerrain.new()
	Game.terrain = _terrain
	_terrain.configure(512.0, 512, 7)
	_terrain.set_path_width(3.2)
	for p: Vector2 in [Vector2(0, 86), Vector2(-5, 52), Vector2(7, 20), Vector2(-3, -20), Vector2(9, -48), Vector2(14, -74), Vector2(22, -92)]:
		_terrain.add_path_point(p)
	_terrain.add_flat_zone(Vector2(SHRINE_START.x, SHRINE_START.z), 8.0, 16.0, 0.0)
	_terrain.add_flat_zone(Vector2(SHRINE_MID.x, SHRINE_MID.z), 6.0, 14.0, 0.0)
	_terrain.add_flat_zone(Vector2(ARENA.x, ARENA.z), 36.0, 22.0, 0.0)
	_terrain.add_flat_zone(Vector2(TOWER.x, TOWER.z), 16.0, 14.0, 0.0)
	_terrain.add_flat_zone(Vector2(CAMP.x, CAMP.z), 12.0, 14.0, 0.0)
	_terrain.generate()

	var material := ShaderMaterial.new()
	material.shader = TERRAIN
	var instance := MeshInstance3D.new()
	var mesh := _terrain.build_mesh(2)
	mesh.surface_set_material(0, material)
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)

	var heights := HeightMapShape3D.new()
	heights.map_width = _terrain.get_resolution() + 1
	heights.map_depth = _terrain.get_resolution() + 1
	heights.map_data = _terrain.get_collision_heights()
	var shape := CollisionShape3D.new()
	shape.shape = heights
	_bodies.add_child(shape)


func _ground(p: Vector3, sink := 0.0) -> Vector3:
	return Vector3(p.x, _terrain.get_height(p.x, p.z) - sink, p.z)


func _make_grass_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for blade in 7:
		var base := Vector3(_rng.randf_range(-0.4, 0.4), 0, _rng.randf_range(-0.4, 0.4))
		var angle := _rng.randf() * TAU
		var side := Vector3(cos(angle), 0, sin(angle)) * _rng.randf_range(0.045, 0.075)
		var lean := Vector3(-sin(angle), 0, cos(angle)) * _rng.randf_range(0.12, 0.42)
		var height := _rng.randf_range(0.5, 0.98)
		var mid := base + Vector3(0, height * 0.55, 0) + lean * 0.35
		var tip := base + Vector3(0, height, 0) + lean
		var quad := [base - side, base + side, mid + side * 0.7, base - side, mid + side * 0.7, mid - side * 0.7, mid - side * 0.7, mid + side * 0.7, tip]
		var levels := [0.0, 0.0, 0.55, 0.0, 0.55, 0.55, 0.55, 0.55, 1.0]
		for i in quad.size():
			vertices.append(quad[i])
			normals.append(Vector3.UP)
			uvs.append(Vector2(0.5, levels[i]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := ShaderMaterial.new()
	material.shader = GRASS
	mesh.surface_set_material(0, material)
	return mesh


func _build_grass() -> void:
	var mesh := _make_grass_mesh()
	var extent := int(ceil(230.0 / GRASS_CHUNK))
	var seed_value := 1000
	for cz in range(-extent, extent):
		for cx in range(-extent, extent):
			seed_value += 17
			var origin := Vector2(cx * GRASS_CHUNK, cz * GRASS_CHUNK)
			var center := origin + Vector2.ONE * GRASS_CHUNK * 0.5
			if center.length() > 232.0:
				continue
			var buffer := _terrain.scatter_grass(origin, GRASS_CHUNK, 3400, seed_value)
			if buffer.is_empty():
				continue
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.use_custom_data = true
			multimesh.mesh = mesh
			multimesh.instance_count = buffer.size() / 16
			multimesh.buffer = buffer
			var instance := MultiMeshInstance3D.new()
			instance.multimesh = multimesh
			instance.position = Vector3(origin.x, 0, origin.y)
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			instance.visibility_range_end = 118.0
			add_child(instance)
			_grass_chunks.append([multimesh, center, multimesh.instance_count])


func _make_leaf_texture() -> ImageTexture:
	var size := 128
	var image := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	image.fill(Color(0.7, 0.7, 0.7, 0.0))
	for i in 46:
		var center := Vector2(_rng.randf_range(10, size - 10), _rng.randf_range(10, size - 10))
		if center.distance_to(Vector2(size, size) * 0.5) > size * 0.46:
			continue
		var angle := _rng.randf() * TAU
		var length := _rng.randf_range(7.0, 11.0)
		var width := _rng.randf_range(3.2, 5.0)
		var shade := _rng.randf_range(0.45, 1.0)
		var reach := int(length) + 1
		for y in range(int(center.y) - reach, int(center.y) + reach + 1):
			for x in range(int(center.x) - reach, int(center.x) + reach + 1):
				if x < 0 or y < 0 or x >= size or y >= size:
					continue
				var d := (Vector2(x, y) - center).rotated(-angle)
				if (d.x / length) ** 2 + (d.y / width) ** 2 <= 1.0:
					image.set_pixel(x, y, Color(shade, shade, shade, 1.0))
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


func _foliage_surface(blobs: Array, cards_per_blob: int, card_min: float, card_max: float) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var mid := Vector3.ZERO
	for blob: Array in blobs:
		mid += blob[0]
	mid /= blobs.size()

	for blob: Array in blobs:
		var center: Vector3 = blob[0]
		var radius: float = blob[1]
		for card in cards_per_blob:
			var out := Vector3(_rng.randfn(0.0, 1.0), _rng.randfn(0.0, 1.0), _rng.randfn(0.0, 1.0)).normalized()
			var p := center + out * radius * pow(_rng.randf(), 0.4)
			var soft := ((p - mid).normalized() + Vector3(0, 0.55, 0) + out * 0.5).normalized()
			var facing := (out + Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.6, 0.6))).normalized()
			var x := facing.cross(Vector3(0.31, 0.87, 0.38)).normalized()
			var y := facing.cross(x)
			var half := _rng.randf_range(card_min, card_max) * 0.5
			var low := clampf((p.y - mid.y) / (radius * 2.2) + 0.5, 0.0, 1.0)
			var depth := clampf((p - center).length() / radius, 0.0, 1.0)
			var shade := lerpf(0.5, 1.12, low * 0.65 + depth * 0.35)
			var base := vertices.size()
			for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				vertices.append(p + (x * corner.x + y * corner.y) * half)
				normals.append(soft)
				uvs.append(corner * 0.5 + Vector2(0.5, 0.5))
				colors.append(Color(shade, 1.0, 0.0, 1.0))
			indices.append_array([base, base + 2, base + 1, base, base + 3, base + 2])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


func _foliage_material(a: Color, b: Color, c: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FOLIAGE
	material.set_shader_parameter("leaf_tex", _leaf_texture)
	material.set_shader_parameter("color_a", a)
	material.set_shader_parameter("color_b", b)
	material.set_shader_parameter("color_c", c)
	return material


func _make_tree_mesh(trunk_height: float, spread: float, material: ShaderMaterial, cards: int, card_scale: float) -> ArrayMesh:
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.2, 0.15, 0.1)
	bark.roughness = 1.0
	var forge := MeshForge.new({"bark": bark})
	var holder := Node3D.new()
	var I := Transform3D.IDENTITY
	forge.limb(holder, I, Vector3(0, -0.5, 0), Vector3(0.25, trunk_height, 0.1), [[0.0, 0.48], [0.25, 0.34], [1.0, 0.17]], "bark", 1.0, 8)

	var blobs: Array = []
	for i in 10:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(0.2, 1.0) * spread
		var center := Vector3(cos(a) * r, trunk_height + _rng.randf_range(-0.6, 3.6) * (1.2 - r / spread * 0.5), sin(a) * r)
		blobs.append([center, _rng.randf_range(1.9, 2.9)])
		if i < 6:
			forge.limb(holder, I, Vector3(0.1, trunk_height * _rng.randf_range(0.65, 0.95), 0.05), center, [[0.0, 0.12], [1.0, 0.03]], "bark", 1.0, 5)
	var mesh := forge.bake(holder)
	holder.free()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _foliage_surface(blobs, cards, 1.6 * card_scale, 2.7 * card_scale))
	mesh.surface_set_material(mesh.get_surface_count() - 1, material)
	return mesh


func _populate(mesh: Mesh, data: PackedFloat32Array, base_scale: float) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = mesh
	multimesh.instance_count = data.size() / 6
	for i in multimesh.instance_count:
		var at := i * 6
		var s := data[at + 3] * base_scale
		var xf := Transform3D(Basis(Vector3.UP, data[at + 4]).scaled(Vector3.ONE * s), Vector3(data[at], data[at + 1], data[at + 2]))
		multimesh.set_instance_transform(i, xf)
		multimesh.set_instance_custom_data(i, Color(data[at + 5], 0, 0, 0))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	add_child(instance)
	return instance


## Splits scatter rows into square cells, so off-screen and distant props cost nothing.
func _into_cells(points: PackedFloat32Array) -> Dictionary:
	var cells := {}
	for i in points.size() / 6:
		var row := points.slice(i * 6, i * 6 + 6)
		var key := Vector2i((Vector2(row[0], row[2]) / PROP_CELL).floor())
		if not cells.has(key):
			cells[key] = PackedFloat32Array()
		cells[key].append_array(row)
	return cells


func _build_trees() -> void:
	var material := _foliage_material(Color(0.86, 0.57, 0.1), Color(0.95, 0.72, 0.16), Color(0.66, 0.34, 0.07))
	var meshes := []
	var far_meshes := []
	for shape: Array in [[6.0, 3.6], [7.5, 4.2], [5.0, 3.2]]:
		# The same random state makes the distant version the same tree with fewer, larger cards.
		var state := _rng.state
		meshes.append(_make_tree_mesh(shape[0], shape[1], material, 30, 1.2))
		_rng.state = state
		far_meshes.append(_make_tree_mesh(shape[0], shape[1], material, 13, 1.85))

	var all_points := _terrain.scatter_props(560, 16.0, 238.0, 0.86, 5.0, 6.5, 55)
	var trunk := CylinderShape3D.new()
	trunk.radius = 0.5
	trunk.height = 9.0
	var groups := [PackedFloat32Array(), PackedFloat32Array(), PackedFloat32Array()]
	for i in all_points.size() / 6:
		var row := all_points.slice(i * 6, i * 6 + 6)
		groups[i % 3].append_array(row)
		var collider := CollisionShape3D.new()
		collider.shape = trunk
		collider.position = Vector3(row[0], row[1] + 3.5, row[2])
		_bodies.add_child(collider)

	for i in 3:
		var cells := _into_cells(groups[i])
		for key: Vector2i in cells:
			var near := _populate(meshes[i], cells[key], 1.0)
			near.visibility_range_end = TREE_NEAR_RANGE
			var far := _populate(far_meshes[i], cells[key], 1.0)
			far.visibility_range_begin = TREE_NEAR_RANGE
			far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_bushes() -> void:
	var material := _foliage_material(Color(0.42, 0.42, 0.12), Color(0.66, 0.56, 0.14), Color(0.32, 0.34, 0.1))
	var blobs := [[Vector3(0, 0.6, 0), 1.0], [Vector3(0.8, 0.5, 0.2), 0.8], [Vector3(-0.6, 0.45, -0.5), 0.75]]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _foliage_surface(blobs, 40, 0.65, 1.1))
	mesh.surface_set_material(0, material)
	var cells := _into_cells(_terrain.scatter_props(420, 6.0, 225.0, 0.88, 2.0, 3.5, 77))
	for key: Vector2i in cells:
		var instance := _populate(mesh, cells[key], 1.05)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_end = 130.0


func _make_rock(flatten: float, seed_value: int) -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 1.2
	noise.fractal_octaves = 4
	var geo := MeshForge.sphere_geo(1.0, 34, 22)
	for i in geo.points.size():
		var p := geo.points[i]
		var d := 1.0 + noise.get_noise_3dv(p) * 0.42
		p *= d
		p.y *= flatten
		if p.y > 0.0:
			p.y = lerpf(p.y, minf(p.y, flatten * 0.5), 0.6)
		geo.points[i] = p
	var forge := MeshForge.new({"stone": _stone})
	var holder := Node3D.new()
	var soup := forge.prepare(geo, true)
	soup.nor = soup.smo
	forge.add_soup(holder, Transform3D.IDENTITY, soup, "stone")
	var mesh := forge.bake(holder)
	holder.free()
	return mesh


func _place_rock(mesh: ArrayMesh, hull: PackedVector3Array, p: Vector3, size: Vector3, yaw: float) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	var basis_value := Basis(Vector3.UP, yaw).scaled(size)
	instance.transform = Transform3D(basis_value, _ground(p, size.y * 0.16))
	add_child(instance)

	var scaled := PackedVector3Array()
	for point in hull:
		scaled.append(point * size)
	var shape := ConvexPolygonShape3D.new()
	shape.points = scaled
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.transform = Transform3D(Basis(Vector3.UP, yaw), instance.position)
	_bodies.add_child(collider)


func _build_rocks() -> void:
	var meshes: Array[ArrayMesh] = [_make_rock(0.42, 3), _make_rock(0.5, 8), _make_rock(0.7, 13)]
	var hulls: Array[PackedVector3Array] = []
	for mesh in meshes:
		hulls.append(mesh.create_convex_shape(true, true).points)

	# Hand-placed slabs framing the road out of the first shrine.
	var slabs := [
		[Vector3(-13, 0, 57), Vector3(9.0, 2.7, 4.2), 0.3], [Vector3(15, 0, 50), Vector3(7.0, 3.0, 4.6), -0.5],
		[Vector3(21, 0, 44), Vector3(5.0, 2.4, 3.2), 0.9], [Vector3(-20, 0, 42), Vector3(4.5, 1.8, 3.4), 1.2],
		[Vector3(-9, 0, 37), Vector3(3.5, 1.4, 2.4), 2.2], [Vector3(12, 0, 34), Vector3(4.0, 1.7, 3.0), 0.2],
	]
	for slab: Array in slabs:
		_place_rock(meshes[0], hulls[0], slab[0], slab[1], slab[2])

	var points := _terrain.scatter_props(90, 18.0, 225.0, 0.88, 4.0, 9.0, 91)
	for i in points.size() / 6:
		var at := i * 6
		var variant := i % 3
		var s := points[at + 3] * (1.5 + points[at + 5] * 2.6)
		var size := Vector3(s * _rng.randf_range(1.0, 1.7), s * _rng.randf_range(0.65, 1.0), s)
		_place_rock(meshes[variant], hulls[variant], Vector3(points[at], 0, points[at + 2]), size, points[at + 4])


func _block(pos: Vector3, size: Vector3, yaw := 0.0) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _stone
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.transform = Transform3D(Basis(Vector3.UP, yaw), pos)
	add_child(instance)
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.transform = instance.transform
	_bodies.add_child(collider)


func _drum(pos: Vector3, top: float, bottom: float, height: float, sides := 20) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 1
	mesh.material = _stone
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	add_child(instance)
	var shape := CylinderShape3D.new()
	shape.radius = maxf(top, bottom)
	shape.height = height
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = pos
	_bodies.add_child(collider)


func _window(base: Vector3, angle: float, radius: float, y: float, size: Vector3, material: StandardMaterial3D) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.transform = Transform3D(Basis(Vector3.UP, angle), base + Vector3(sin(angle) * radius, y, cos(angle) * radius))
	add_child(instance)


func _build_tower(base: Vector3, scale_factor: float, shadow: StandardMaterial3D) -> void:
	var k := scale_factor
	_drum(base + Vector3(0, 9 * k, 0), 10.0 * k, 12.5 * k, 18.0 * k, 16)
	_drum(base + Vector3(0, 34 * k, 0), 8.2 * k, 9.6 * k, 32.0 * k, 16)
	_drum(base + Vector3(0, 53 * k, 0), 10.4 * k, 8.6 * k, 6.0 * k, 16)
	_drum(base + Vector3(0, 62 * k, 0), 7.2 * k, 7.8 * k, 12.0 * k, 12)
	for i in 12:
		var a := i * TAU / 12.0
		var height := (2.0 + 3.5 * absf(sin(i * 2.3))) * k
		_block(base + Vector3(sin(a) * 9.6 * k, (56 * k + height * 0.5), cos(a) * 9.6 * k), Vector3(2.4 * k, height, 1.6 * k), a)
		if i % 2 == 0:
			_block(base + Vector3(sin(a) * 11.4 * k, 9.0 * k, cos(a) * 11.4 * k), Vector3(3.2 * k, 18.0 * k, 4.2 * k), a)
		_window(base, a + 0.26, 9.1 * k, 28.0 * k, Vector3(1.3, 6.0, 0.9) * k, shadow)
		if i % 3 == 0:
			_window(base, a, 8.8 * k, 43.0 * k, Vector3(1.2, 5.0, 0.9) * k, shadow)
		_window(base, a, 7.5 * k, 63.0 * k, Vector3(1.0, 4.0, 0.9) * k, shadow)


func _build_ruins() -> void:
	var shadow := StandardMaterial3D.new()
	shadow.albedo_color = Color(0.02, 0.02, 0.02)
	shadow.roughness = 1.0

	_build_tower(_ground(TOWER), 1.0, shadow)
	_build_tower(_ground(TOWER + Vector3(-78, 0, -22)), 0.55, shadow)

	# Broken curtain wall around the arena, open on the south side.
	var count := 34
	for i in count:
		var angle := float(i) / count * TAU
		var dir := Vector3(sin(angle), 0, cos(angle))
		if dir.z > 0.9:
			continue
		var height := 3.0 + 6.5 * absf(sin(i * 1.73))
		if i % 7 == 3:
			height = 1.5
		var p := ARENA + dir * 37.0
		_block(_ground(p) + Vector3(0, height * 0.5 - 0.3, 0), Vector3(7.2, height, 2.0), angle + PI * 0.5)
		if i % 3 == 0:
			_block(_ground(p + dir * 1.8) + Vector3(0, height * 0.35, 0), Vector3(2.4, height * 0.7, 2.4), angle)

	# South gate.
	var gate := ARENA + Vector3(0, 0, 37)
	for s: float in [-1.0, 1.0]:
		var at := gate + Vector3(s * 9, 0, 0)
		_block(_ground(at) + Vector3(0, 6.5, 0), Vector3(3.2, 13.0, 3.2))
		_block(_ground(at) + Vector3(0, 13.6, 0), Vector3(4.2, 1.2, 4.2))
		_block(_ground(gate + Vector3(s * 17, 0, 0)) + Vector3(0, 3.4, 0), Vector3(11.0, 6.8, 2.0))
	_block(_ground(gate) + Vector3(-1.5, 14.8, 0), Vector3(15.0, 1.6, 3.0))

	# Fallen columns in the arena.
	for spot: Vector3 in [ARENA + Vector3(-19, 0, 12), ARENA + Vector3(21, 0, -6), ARENA + Vector3(-14, 0, -20), ARENA + Vector3(16, 0, 18)]:
		_drum(_ground(spot) + Vector3(0, 3.0, 0), 1.2, 1.5, 6.0, 10)

	# Standing arches out in the meadow.
	for arch: Array in [[Vector3(-30, 0, 18), 0.4], [Vector3(33, 0, -18), -0.7], [Vector3(-62, 0, -60), 1.1], [Vector3(66, 0, 40), 0.2]]:
		var base: Vector3 = arch[0]
		var yaw: float = arch[1]
		var side := Vector3(cos(yaw), 0, -sin(yaw))
		_block(_ground(base + side * 4.0) + Vector3(0, 4.5, 0), Vector3(1.8, 9.0, 1.8), yaw)
		_block(_ground(base - side * 4.0) + Vector3(0, 3.0, 0), Vector3(1.8, 6.0, 1.8), yaw)
		_block(_ground(base + side * 1.4) + Vector3(0, 9.6, 0), Vector3(7.5, 1.3, 2.0), yaw)


func _build_stakes() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.07, 0.06, 0.05)
	dark.roughness = 0.9
	var forge := MeshForge.new({"dark": dark})
	var holder := Node3D.new()
	var I := Transform3D.IDENTITY
	forge.limb(holder, I, Vector3(0, -0.4, 0), Vector3(0.16, 4.2, 0), [[0.0, 0.11], [1.0, 0.075]], "dark", 1.0, 7)
	forge.limb(holder, I, Vector3(0.16, 4.2, 0), Vector3(-0.08, 7.0, 0), [[0.0, 0.075], [1.0, 0.03]], "dark", 1.0, 7)
	forge.plate(holder, MeshForge.xform(Vector3(-0.08, 7.05, 0)), MeshForge.star4(1.1, 0.14, 0.62), 0.09, "dark")
	forge.limb(holder, I, Vector3(0.1, 3.3, 0), Vector3(1.1, 4.5, 0), [[0.0, 0.05], [1.0, 0.012]], "dark", 1.0, 5)
	var mesh := forge.bake(holder)
	holder.free()

	var spots := [Vector3(-13, 0, 50), Vector3(-8, 0, 48), Vector3(6, 0, 45), Vector3(10, 0, 40), Vector3(-15, 0, 34), Vector3(14, 0, 28), Vector3(-44, 0, 15), Vector3(-55, 0, 1)]
	for spot: Vector3 in spots:
		var instance := MeshInstance3D.new()
		instance.mesh = mesh
		var tilt := Basis.from_euler(Vector3(_rng.randf_range(-0.09, 0.09), _rng.randf() * TAU, _rng.randf_range(-0.09, 0.09)))
		instance.transform = Transform3D(tilt, _ground(spot))
		add_child(instance)


func _build_fallen_star() -> void:
	var material := ShaderMaterial.new()
	material.shader = FALLEN_STAR
	material.set_shader_parameter("nebula", ImageTexture.create_from_image(AstralTerrain.make_wing_image(1024, 41)))
	var forge := MeshForge.new({"star": material})
	var holder := Node3D.new()
	var geo := MeshForge.shape_geo(MeshForge.star4(1.0, 0.17, 1.35), 0.2, 0.05)
	var soup := forge.prepare(geo)
	for i in soup.pos.size():
		soup.uv[i] = Vector2(soup.pos[i].x * 0.5 + 0.5, 0.5 - soup.pos[i].y * 0.37)
	forge.add_soup(holder, Transform3D.IDENTITY, soup, "star")
	var instance := MeshInstance3D.new()
	instance.mesh = forge.bake(holder)
	holder.free()
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var xf := Transform3D(Basis.from_euler(Vector3(0.05, 0.1, 0.16)).scaled(Vector3.ONE * 72.0), Vector3(-70, 222, -720))
	instance.transform = xf
	add_child(instance)

	var halo := QuadMesh.new()
	halo.size = Vector2(430, 430)
	var glow := ShaderMaterial.new()
	glow.shader = GLOW
	glow.set_shader_parameter("color", Color(0.55, 0.42, 1.0))
	glow.set_shader_parameter("strength", 0.42)
	glow.set_shader_parameter("pulse_amount", 0.08)
	halo.material = glow
	var halo_node := MeshInstance3D.new()
	halo_node.mesh = halo
	halo_node.position = xf.origin + Vector3(0, 0, -12)
	halo_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo_node)


func _build_shrines() -> void:
	for p: Vector3 in [SHRINE_START, SHRINE_MID]:
		var shrine := Shrine.new()
		add_child(shrine)
		shrine.global_position = _ground(p)
		Game.shrines.append(shrine)
	Game.checkpoint = Game.shrines[0]


func _spawn_actors() -> void:
	var player := Player.new()
	add_child(player)
	player.global_position = _ground(SHRINE_START + Vector3(0, 0, -9), -0.2)
	Game.player = player
	player.reset_camera()

	var posts := [
		[Vector3(-2, 0, 44), "process"], [Vector3(2, 0, 40), "process"], [Vector3(6, 0, 12), "process"], [Vector3(-9, 0, 2), "process"], [Vector3(-3, 0, -30), "firewall"], [Vector3(13, 0, -40), "daemon"],
		[CAMP + Vector3(3, 0, 3), "process"], [CAMP + Vector3(-4, 0, -2), "firewall"], [CAMP + Vector3(1, 0, -6), "daemon"],
		[ARENA + Vector3(-5, 0, 46), "firewall"], [ARENA + Vector3(6, 0, 46), "daemon"], [ARENA + Vector3(0, 0, 38), "rootkit"],
	]
	for post: Array in posts:
		var enemy := Enemy.new().setup(_ground(post[0], -0.1), false, post[1])
		add_child(enemy)
		Game.enemies.append(enemy)
	var boss := Enemy.new().setup(_ground(ARENA + Vector3(0, 0, -10), -0.1), true)
	add_child(boss)
	Game.enemies.append(boss)
	Game.boss = boss


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var hud := Hud.new()
	layer.add_child(hud)
	Game.hud = hud
	var menu_layer := CanvasLayer.new()
	menu_layer.layer = 2
	menu_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(menu_layer)
	var menu := GameMenu.new()
	menu_layer.add_child(menu)
	Game.menu = menu
	var scene := Cutscene.new()
	add_child(scene)
	Game.cutscene = scene
	var powers := CosmicShow.new()
	add_child(powers)
	Game.powers = powers
