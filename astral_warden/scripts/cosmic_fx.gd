class_name CosmicFx
extends RefCounted
## World-scale effects of the supreme form. Every node frees itself.

const GOLD := Color(1.0, 0.78, 0.4)
const PALE := Color(1.0, 0.95, 0.82)
const HUES := [Color("ff6ad5"), Color("6ae0ff"), Color("ffd86a"), Color("8dff9a"), Color("b08cff"), Color("ff9a5a")]
const GALAXY := preload("res://shaders/galaxy_disc.gdshader")
const RIFT := preload("res://shaders/world_rift.gdshader")
const NOVA := preload("res://shaders/nova_shell.gdshader")
const PILLAR := preload("res://shaders/light_pillar.gdshader")
const STAR := preload("res://shaders/star_spark.gdshader")
const SHOCK := preload("res://shaders/shock_ring.gdshader")
const FLAME := preload("res://shaders/soft_flame.gdshader")
const WAVE := preload("res://shaders/crescent_wave.gdshader")
const WEB := 0.36 ## Metres per unit of cosmic_warrior.html.

static var _dot: StandardMaterial3D
static var _wave_cache: ArrayMesh


static func _instance(mesh: Mesh, shader: Shader) -> Array:
	var material := ShaderMaterial.new()
	material.shader = shader
	mesh.surface_set_material(0, material)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.extra_cull_margin = 40.0
	Game.world.add_child(node)
	return [node, material]


static func _fade(material: ShaderMaterial, from: float, to: float, seconds: float) -> Callable:
	return func(v: float) -> void: material.set_shader_parameter("fade", lerpf(from, to, v))


static func _ground(pos: Vector3) -> Vector3:
	return Vector3(pos.x, Game.terrain.get_height(pos.x, pos.z), pos.z)


## The column of light that carries the change of form.
static func pillar(pos: Vector3, height := 40.0, seconds := 1.0, tint := GOLD, radius := 5.0) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = height
	mesh.cap_top = false
	mesh.cap_bottom = false
	mesh.radial_segments = 32
	mesh.rings = 1
	var made := _instance(mesh, PILLAR)
	var node: MeshInstance3D = made[0]
	var material: ShaderMaterial = made[1]
	material.set_shader_parameter("tint", tint)
	node.global_position = pos + Vector3(0, height * 0.5, 0)
	node.scale = Vector3(0.3, 1.0, 0.3)
	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(node, "scale", Vector3(radius, 1.0, radius), seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(_fade(material, 1.0, 0.0, seconds), 0.0, 1.0, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(node.queue_free)


## A spinning point of light; used for sparks of creation and whole small universes.
static func star_at(pos: Vector3, size: float, tint: Color, seconds: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	var made := _instance(quad, STAR)
	var node: MeshInstance3D = made[0]
	var material: ShaderMaterial = made[1]
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("spin", randf() * PI)
	node.global_position = pos
	node.scale = Vector3(0.05, 0.05, 1.0)
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector3(size, size, 1.0), minf(0.3, seconds * 0.4)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if seconds > 0.0:
		tween.tween_interval(seconds)
		tween.tween_method(func(v: float) -> void: material.set_shader_parameter("fade", v), 1.0, 0.0, 0.2)
		tween.tween_callback(node.queue_free)
	return node


## The shell of light.
static func nova(center: Vector3, radius: float, seconds: float, tint := Color(1.0, 0.66, 0.26)) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 40
	mesh.rings = 24
	var made := _instance(mesh, NOVA)
	var node: MeshInstance3D = made[0]
	(made[1] as ShaderMaterial).set_shader_parameter("inner", tint)
	node.global_position = center
	node.scale = Vector3.ONE * 0.4
	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(node, "scale", Vector3.ONE * radius, seconds).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_method(_fade(made[1], 1.6, 0.0, seconds), 0.0, 1.0, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(node.queue_free)


static func flash(tint: Color, strength: float, seconds: float) -> void:
	var rect := Game.hud.screen_flash
	rect.color = Color(tint, strength)
	rect.visible = true
	var tween := rect.create_tween().set_ignore_time_scale(true)
	tween.tween_property(rect, "color:a", 0.0, seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(rect.hide)


## ERASURE: `seconds` covers the whole break, until reality snaps back.
static func shatter(seconds: float) -> void:
	var rect := Game.hud.screen_shatter
	var material: ShaderMaterial = rect.material
	material.set_shader_parameter("aspect", rect.size.x / maxf(rect.size.y, 1.0))
	material.set_shader_parameter("p", 0.0)
	rect.visible = true
	var set_p := func(v: float) -> void: material.set_shader_parameter("p", v)
	var tween := rect.create_tween().set_ignore_time_scale(true)
	tween.tween_method(set_p, 0.0, 0.66, seconds * 0.55)
	tween.tween_method(set_p, 0.66, 1.0, seconds * 0.3)
	tween.tween_interval(seconds * 0.15)
	tween.tween_callback(rect.hide)


## An expanding soft ring: facing the camera, or lying on the ground when `flat`.
static func shock(pos: Vector3, size: float, strength: float, life: float, tint: Color, flat := false) -> void:
	var made := _instance(QuadMesh.new(), SHOCK)
	var node: MeshInstance3D = made[0]
	var material: ShaderMaterial = made[1]
	material.set_shader_parameter("color", tint)
	material.set_shader_parameter("billboard", not flat)
	var at := _ground(pos) + Vector3(0, 0.15, 0) if flat else pos
	var face := Basis(Vector3.RIGHT, -PI * 0.5) if flat else Basis.IDENTITY
	node.global_transform = Transform3D(face.scaled_local(Vector3(size * 2.0, size * 2.0, 1.0)), at)
	node.extra_cull_margin = size * 2.0 + 10.0
	var grow := func(v: float) -> void:
		material.set_shader_parameter("r", (1.0 - (1.0 - v) * (1.0 - v)) * 0.9)
		material.set_shader_parameter("a", (1.0 - v) * strength)
	var tween := node.create_tween().set_ignore_time_scale(true)
	tween.tween_method(grow, 0.0, 1.0, life)
	tween.tween_callback(node.queue_free)


static func _dot_material() -> StandardMaterial3D:
	if _dot == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.45, Color(1, 1, 1, 0.55))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 32
		texture.height = 32
		_dot = StandardMaterial3D.new()
		_dot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_dot.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_dot.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_dot.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		_dot.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_dot.vertex_color_use_as_albedo = true
		_dot.albedo_texture = texture
		_dot.disable_fog = true
	return _dot


## The web page's glowing sparks. `speed` is in web units; the count is capped to keep the frame rate.
static func sparks(pos: Vector3, count: int, speed: float) -> void:
	var p := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 0.5 * WEB
	quad.material = _dot_material()
	p.mesh = quad
	p.amount = clampi(count / 2, 8, 360)
	p.lifetime = 0.75
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * WEB * 0.4
	p.initial_velocity_max = speed * WEB * 1.2
	p.gravity = Vector3(0, -7.0 * WEB, 0)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.95, 0.85, 1.0))
	ramp.set_color(1, Color(0, 0, 0))
	ramp.add_point(0.5, Color(0.37, 0.29, 0.5))
	p.color_ramp = ramp
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.finished.connect(p.queue_free)
	Game.world.add_child(p)
	p.global_position = pos
	p.emitting = true


## A four-pointed star thrown along `velocity`, which is already in metres.
static func shoot(pos: Vector3, velocity: Vector3, life: float, size: float) -> void:
	var made := _instance(QuadMesh.new(), STAR)
	var node: MeshInstance3D = made[0]
	var material: ShaderMaterial = made[1]
	material.set_shader_parameter("tint", Color("fff0c8"))
	material.set_shader_parameter("spin", randf() * PI)
	node.global_position = pos
	node.scale = Vector3(size, size, 1.0)
	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(node, "global_position", pos + velocity * life, life)
	tween.tween_property(node, "scale", Vector3(size * 0.6, size * 0.6, 1.0), life)
	tween.tween_method(func(v: float) -> void: material.set_shader_parameter("fade", minf(1.0, v * 2.2)), 1.0, 0.0, life)
	tween.chain().tween_callback(node.queue_free)


## Light drawn into a point.
static func inflow(center: Vector3, amount: int, radius: float, life: float) -> void:
	for i in amount:
		var a := randf() * TAU
		var e := randf_range(-1.0, 1.0)
		var c := sqrt(1.0 - e * e)
		var from := center + Vector3(cos(a) * c, e, sin(a) * c) * radius * randf_range(0.6, 1.2)
		shoot(from, (center - from) / life, life, 0.3)


## A soft flame. `length` and `radius` are in web units. Returns [node, material]; the caller places it.
static func flame(length: float, radius: float, tint: Color, parent: Node3D) -> Array:
	var quad := QuadMesh.new()
	quad.size = Vector2(radius * 3.4, length + radius * 3.4)
	quad.center_offset = Vector3(0, length * 0.5, 0)
	var material := ShaderMaterial.new()
	material.shader = FLAME
	material.set_shader_parameter("len", length)
	material.set_shader_parameter("rad", radius)
	material.set_shader_parameter("world_scale", WEB)
	material.set_shader_parameter("color", tint)
	var node := MeshInstance3D.new()
	node.mesh = quad
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.extra_cull_margin = 400.0
	parent.add_child(node)
	return [node, material]


## NOVA: the column of fire thrown from the fist.
static func beam(pos: Vector3, ahead: Vector3) -> void:
	var made := flame(34.0, 3.4, Color("ffc86a"), Game.world)
	var node: MeshInstance3D = made[0]
	var material: ShaderMaterial = made[1]
	node.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, ahead.normalized())), pos)
	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(node, "global_position", pos + ahead * 90.0 * WEB * 0.55, 0.55)
	tween.tween_method(func(v: float) -> void: material.set_shader_parameter("power", v), 2.2, 0.0, 0.55)
	tween.chain().tween_callback(node.queue_free)


static func _wave_mesh() -> ArrayMesh:
	if _wave_cache != null:
		return _wave_cache
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var along := 64
	var around := 14
	for i in along + 1:
		var u := float(i) / along
		var arc := lerpf(-1.2, 1.2, u)
		var out := Vector3(0.0, sin(arc), cos(arc))
		var spine := out * 4.0 - Vector3(0, 0, 4.0)
		for j in around + 1:
			var a := float(j) / around * TAU
			var normal := out * cos(a) + Vector3.RIGHT * sin(a)
			vertices.append(spine + normal * 0.55)
			normals.append(normal)
			uvs.append(Vector2(u, float(j) / around))
	for i in along:
		for j in around:
			var a := i * (around + 1) + j
			var b := a + around + 1
			indices.append_array(PackedInt32Array([a, b, a + 1, a + 1, b, b + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	_wave_cache = ArrayMesh.new()
	_wave_cache.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _wave_cache


## GALAXY: the giant crescent thrown by the blade.
static func wave(pos: Vector3, ahead: Vector3, tilt: float, size: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = WAVE
	var node := MeshInstance3D.new()
	node.mesh = _wave_mesh()
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.extra_cull_margin = 40.0
	Game.world.add_child(node)
	var face := Basis.looking_at(-ahead, Vector3.UP) * Basis(Vector3.BACK, tilt)
	node.global_transform = Transform3D(face, pos)
	node.scale = Vector3.ONE * size * WEB
	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(node, "global_position", pos + ahead * 74.0 * WEB * 0.8, 0.8)
	tween.tween_property(node, "scale", Vector3.ONE * size * WEB * 2.6, 0.8)
	tween.tween_method(func(v: float) -> void: material.set_shader_parameter("a", 1.0 - v * v), 0.0, 1.0, 0.8)
	tween.chain().tween_callback(node.queue_free)


## COMET's crater, and every hero landing.
static func crater(pos: Vector3) -> void:
	var cream := Color("fff2d0")
	shock(pos, 70.0 * WEB, 2.4, 0.95, Color("ffc86a"), true)
	shock(pos, 38.0 * WEB, 1.9, 0.62, cream, true)
	shock(pos, 18.0 * WEB, 1.6, 0.36, Color.WHITE, true)
	var ground := _ground(pos) + Vector3(0, 0.2, 0)
	sparks(ground, 480, 36.0)
	Fx.burst(ground, Color(0.72, 0.62, 0.42), 40, 11.0, 0.12)
	for i in 36:
		var a := i / 36.0 * TAU
		shoot(ground + Vector3(0, 0.4, 0), Vector3(cos(a) * 42.0, randf_range(6.0, 24.0), sin(a) * 42.0) * WEB, 0.8, 3.8 * WEB)


## Draws each effect once behind the loading screen.
static func warm(at: Vector3) -> void:
	shock(at, 2.0, 1.0, 0.2, GOLD)
	sparks(at, 16, 4.0)
	shoot(at, Vector3.UP, 0.2, 0.5)
	wave(at, Vector3.FORWARD, 0.0, 0.2)
	beam(at, Vector3.FORWARD)
	pillar(at, 4.0, 0.2)
	star_at(at, 1.0, GOLD, 0.1)
	nova(at, 2.0, 0.2)
