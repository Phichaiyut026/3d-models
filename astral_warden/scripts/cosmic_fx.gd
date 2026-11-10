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


## INFINITY EDGE: a blazing seam along the ground and a sheet of light standing on it.
static func world_cut(origin: Vector3, forward: Vector3, length: float, width: float) -> void:
	var face := Basis.looking_at(-forward, Vector3.UP)
	var center := origin + forward * length * 0.5
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(width * 5.2, length) # Wide enough to read when seen from straight behind.
	var low := _instance(floor_mesh, RIFT)
	(low[0] as MeshInstance3D).global_transform = Transform3D(face, _ground(center) + Vector3(0, 0.2, 0))
	var sheet_mesh := PlaneMesh.new()
	sheet_mesh.size = Vector2(90.0, length)
	var sheet := _instance(sheet_mesh, RIFT)
	var upright := face * Basis(Vector3.BACK, PI * 0.5)
	(sheet[0] as MeshInstance3D).global_transform = Transform3D(upright, _ground(center) + Vector3(0, 40.0, 0))
	for made: Array in [low, sheet]:
		var node: MeshInstance3D = made[0]
		var tween := node.create_tween()
		tween.tween_method(_fade(made[1], 0.0, 1.5, 0.08), 0.0, 1.0, 0.08)
		tween.tween_method(_fade(made[1], 1.5, 0.0, 0.8), 0.0, 1.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(node.queue_free)
	for i in 16:
		var at := _ground(origin + forward * length * (i + 0.5) / 16.0)
		Fx.ring(at, 9.0 + (i % 3) * 5.0, PALE if i % 2 == 0 else GOLD, 0.7)
		Fx.burst(at + Vector3(0, 0.3, 0), GOLD, 24, 30.0, 0.14)


## GENESIS: the galaxy that unfolds overhead.
static func galaxy(pos: Vector3, facing: Vector3, radius: float, seconds: float, tilt := 0.85) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(2, 2)
	var made := _instance(mesh, GALAXY)
	var node: MeshInstance3D = made[0]
	# Tipped toward the warrior, so the spiral fills the view instead of lying edge-on.
	var spread := Basis(facing.cross(Vector3.UP).normalized(), tilt)
	node.global_transform = Transform3D(spread, pos)
	node.scale = Vector3.ONE * 0.5
	var tween := node.create_tween().set_parallel(true)
	tween.tween_property(node, "scale", Vector3.ONE * radius, seconds * 0.62).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_fade(made[1], 0.0, 1.0, 0.3), 0.0, 1.0, 0.35)
	tween.chain().tween_method(_fade(made[1], 1.0, 0.0, 0.35), 0.0, 1.0, 0.35)
	tween.tween_callback(node.queue_free)


## BIG BANG: light racing inward before the blast.
static func implode(center: Vector3, seconds: float) -> void:
	for i in 36:
		var a := randf() * TAU
		var e := randf_range(-0.3, 0.6)
		var c := sqrt(1.0 - e * e)
		var from := center + Vector3(cos(a) * c, e, sin(a) * c) * randf_range(22.0, 55.0)
		var star := star_at(from, randf_range(2.0, 5.0), HUES[i % HUES.size()], -1.0)
		var tween := star.create_tween()
		tween.tween_interval(randf() * seconds * 0.55)
		tween.tween_property(star, "global_position", center, seconds * 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(star.queue_free)


## BIG BANG: the shell of light.
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


## Draws each effect once behind the loading screen.
static func warm(at: Vector3) -> void:
	pillar(at, 4.0, 0.2)
	star_at(at, 1.0, GOLD, 0.1)
	world_cut(at, Vector3.FORWARD, 4.0, 1.0)
	galaxy(at, Vector3.FORWARD, 2.0, 0.2)
	nova(at, 2.0, 0.2)
