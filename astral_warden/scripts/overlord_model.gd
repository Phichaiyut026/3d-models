class_name OverlordModel
extends PoseRig
## The tower's boss: System Overlord, first form. The mesh is baked from system_overlord.html.

const SCENE_PATH := "res://models/system_overlord_0.scn"
const TOON := preload("res://shaders/toon.gdshader")
const TOON_DOUBLE := preload("res://shaders/toon_double.gdshader")
const FLAT := preload("res://shaders/flat.gdshader")
const FLAT_DOUBLE := preload("res://shaders/flat_double.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")
const STAR := preload("res://shaders/star_spark.gdshader")
const FLAME := preload("res://shaders/flame.gdshader")
const POOL := preload("res://shaders/overlord_pool.gdshader")
const AURA_FLAME := preload("res://shaders/aura_flame.gdshader")
const AURA_SMOKE := preload("res://shaders/aura_smoke.gdshader")
## The body as capsules [from, to, radius]; flames leave the armour's own surface.
const SURFACE := [
	[Vector3(0, 4.7, 0), Vector3(0, 6.8, 0), 0.92], [Vector3(0, 7, 0), Vector3(0, 7.7, 0), 0.55],
	[Vector3(1.5, 6.1, 0), Vector3(1.5, 6.95, 0), 0.9], [Vector3(1.25, 6.5, 0), Vector3(1.78, 4.95, 0.05), 0.45],
	[Vector3(1.78, 4.95, 0.05), Vector3(2.05, 4.05, 0.12), 0.6], [Vector3(2.05, 4.05, 0.12), Vector3(2.05, 3.2, 0.2), 0.42],
	[Vector3(0.58, 4.2, 0), Vector3(1.02, 2.65, 0.06), 0.62], [Vector3(1.02, 2.65, 0.06), Vector3(1.18, 0.95, -0.02), 0.58],
	[Vector3(1.18, 0.5, 0.1), Vector3(1.3, 0.2, 0.9), 0.5], [Vector3(0.42, 7.52, 0), Vector3(0.8, 8.3, -0.06), 0.22],
]

const JOINT_NODES := {
	"upper": "Pelvis/Spine", "armR": "Pelvis/Spine/ArmR", "foreR": "Pelvis/Spine/ArmR/ForearmR", "hand_R": "Pelvis/Spine/ArmR/ForearmR/HandR",
	"armL": "Pelvis/Spine/ArmL", "foreL": "Pelvis/Spine/ArmL/ForearmL",
	"legR": "ThighR", "shinR": "ThighR/ShinR", "footR": "ThighR/ShinR/FootR",
	"legL": "ThighL", "shinL": "ThighL/ShinL", "footL": "ThighL/ShinL/FootL",
}
const GRIP := Vector3(0.02, -0.42, 0.08)
const GUARD_AHEAD_OF_GRIP := 0.62
const SWORD_SCALE := 1.3

var blade_tip: Node3D
var _toon_materials: Array[ShaderMaterial] = []
var _wings: Array = [] ## [node, side, resting basis]
var _flash := 0.0
var _clock_fx := 0.0
var _pool: MeshInstance3D
var _light: OmniLight3D


func _init() -> void:
	unit = 4.2
	pivot = Vector3(0, 4.2, 0)
	thigh = 1.61
	shin_length = 1.71
	leg_metres = thigh + shin_length
	run_speed = 5.0
	stance = {
		"armL": Vector3(-0.5, 0.0, -0.1),
		"foreL": Vector3(-0.9, 0.0, 0.0),
		"armR": Vector3(-0.25, 0.0, -0.12),
		"foreR": Vector3(-0.9, 0.0, 0.0),
	}
	var model: Node3D = load(SCENE_PATH).instantiate()
	model.rotation_order = EULER_ORDER_XYZ
	root_joint = model
	add_child(model)
	var textures: Dictionary = model.get_meta("textures")
	var shared := {}
	_dress(model, textures, shared)
	# Found first: registering renames each node, which would break the later paths.
	var hand_left: Node3D = model.get_node("Pelvis/Spine/ArmL/ForearmL/HandL")
	var found := {}
	for joint_name: String in JOINT_NODES:
		found[joint_name] = model.get_node(JOINT_NODES[joint_name])
	for joint_name: String in found:
		register(joint_name, found[joint_name])
	var spine: Node3D = joints["upper"]
	for pair: Array in [["WingR", -1.0], ["WingL", 1.0]]:
		var wing: Node3D = spine.get_node(pair[0])
		_wings.append([wing, pair[1], wing.basis])
	_mount_sword(model)
	_add_lights(spine)
	_add_aura(model, hand_left)


func _dress(node: Node, textures: Dictionary, shared: Dictionary) -> void:
	for child in node.get_children():
		_dress(child, textures, shared)
	if not node is MeshInstance3D:
		return
	var instance: MeshInstance3D = node
	var mesh := instance.mesh
	for i in mesh.get_surface_count():
		var key: String = (mesh as ArrayMesh).surface_get_name(i)
		if not shared.has(key):
			shared[key] = _material(key, textures)
		instance.set_surface_override_material(i, shared[key])


func _material(surface_key: String, textures: Dictionary) -> ShaderMaterial:
	var parts := surface_key.split("|")
	var key := parts[0]
	var outline := parts[1] == "1"
	var pieces := key.split("_")
	var color := Color("#" + pieces[1])
	var double := key.ends_with("_ds")
	var m := ShaderMaterial.new()
	if pieces[0] == "toon":
		m.shader = TOON_DOUBLE if double else TOON
		m.set_shader_parameter("albedo", color)
		_toon_materials.append(m)
	else:
		m.shader = FLAT_DOUBLE if double else FLAT
		m.set_shader_parameter("color", color)
		m.set_shader_parameter("boost", 1.0 if textures.has(key) else 2.4)
		if textures.has(key):
			m.set_shader_parameter("textured", true)
			m.set_shader_parameter("decal", textures[key])
	if outline:
		var hull := ShaderMaterial.new()
		hull.shader = OUTLINE
		hull.set_shader_parameter("color", Color(0.03, 0.035, 0.05))
		hull.set_shader_parameter("thickness", 0.03)
		m.next_pass = hull
	return m


## The greatsword moves from the root into the right hand, pointing forward in the guard stance.
func _mount_sword(model: Node3D) -> void:
	var sword: Node3D = model.get_node("Greatsword")
	var ready_pose := Basis.from_euler(stance["armR"], EULER_ORDER_XYZ) * Basis.from_euler(stance["foreR"], EULER_ORDER_XYZ)
	var tipped := ready_pose.inverse() * Basis.from_euler(Vector3(-0.35, 0, 0), EULER_ORDER_XYZ)
	# The blade was authored along +X with its width along +Y; the rig swings along +Z with width on X.
	var along := tipped * Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0))
	sword.owner = null
	model.remove_child(sword)
	joints["hand_R"].add_child(sword)
	sword.transform = Transform3D(along.scaled_local(Vector3.ONE * SWORD_SCALE), GRIP + along.x * GUARD_AHEAD_OF_GRIP * SWORD_SCALE)
	blade_tip = Node3D.new()
	blade_tip.position = Vector3(4.54, 0, 0)
	sword.add_child(blade_tip)


func _spark(parent: Node3D, pos: Vector3, size: float, tint: Color, boost: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var material := ShaderMaterial.new()
	material.shader = STAR
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("boost", boost)
	quad.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.position = pos
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _add_lights(spine: Node3D) -> void:
	# The broken red core in the chest, and embers coming off the body.
	_spark(spine, Vector3(0, 0.75, 0.75), 2.6, Color(1.0, 0.14, 0.2), 1.2)
	var dot := SphereMesh.new()
	dot.radius = 0.09
	dot.height = 0.18
	dot.radial_segments = 6
	dot.rings = 3
	dot.material = Fx.flat_material(Color(1.0, 0.16, 0.2), 3.0)
	var embers := CPUParticles3D.new()
	embers.mesh = dot
	embers.amount = 44
	embers.lifetime = 1.8
	embers.local_coords = false
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	embers.emission_box_extents = Vector3(2.0, 3.0, 1.0)
	embers.direction = Vector3.UP
	embers.spread = 25.0
	embers.gravity = Vector3.ZERO
	embers.initial_velocity_min = 1.0
	embers.initial_velocity_max = 2.6
	embers.scale_amount_min = 0.4
	embers.scale_amount_max = 1.1
	embers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spine.add_child(embers)


func _hand_fire(hand: Node3D, flame_seed: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	var m := ShaderMaterial.new()
	m.shader = FLAME
	m.set_shader_parameter("flame_seed", flame_seed)
	m.set_shader_parameter("red", 1.0)
	m.set_shader_parameter("power", 0.8)
	m.set_shader_parameter("size", 1.9)
	quad.material = m
	var fire := MeshInstance3D.new()
	fire.mesh = quad
	fire.position = Vector3(0, -0.75, 0.1)
	fire.extra_cull_margin = 100.0
	fire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hand.add_child(fire)


func _particles(shader: Shader, amount: int, lifetime: float, size: float) -> CPUParticles3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var m := ShaderMaterial.new()
	m.shader = shader
	quad.material = m
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.9))
	fade.set_color(1, Color(1, 1, 1, 0))
	var p := CPUParticles3D.new()
	p.mesh = quad
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false
	p.color_ramp = fade
	p.gravity = Vector3.ZERO
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-40, -10, -40), Vector3(80, 60, 80))
	return p


## The villain's aura: red fire off the armour, black smoke, and the corrupted ground.
func _add_aura(model: Node3D, hand_left: Node3D) -> void:
	_hand_fire(joints["hand_R"], 3.7)
	_hand_fire(hand_left, 11.3)
	var points := PackedVector3Array()
	for capsule: Array in SURFACE:
		for side: float in [-1.0, 1.0]:
			if capsule[0].x == 0.0 and side < 0.0:
				continue
			for i in 34:
				var a: Vector3 = capsule[0]
				var b: Vector3 = capsule[1]
				var at := a.lerp(b, randf())
				at.x *= side
				var dir := Vector3(randf_range(-1, 1), randf_range(-0.4, 0.8), randf_range(-1, 1)).normalized()
				points.append(at + dir * float(capsule[2]))
	var flames := _particles(AURA_FLAME, 80, 0.8, 1.5)
	flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	flames.emission_points = points
	flames.direction = Vector3.UP
	flames.spread = 16.0
	flames.initial_velocity_min = 1.6
	flames.initial_velocity_max = 4.6
	flames.scale_amount_min = 0.5
	flames.scale_amount_max = 1.4
	model.add_child(flames)

	var smoke := _particles(AURA_SMOKE, 40, 4.5, 5.0)
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 6.0
	smoke.position = Vector3(0, 1.0, 0)
	smoke.direction = Vector3.UP
	smoke.spread = 22.0
	smoke.initial_velocity_min = 0.5
	smoke.initial_velocity_max = 1.4
	smoke.scale_amount_min = 0.7
	smoke.scale_amount_max = 1.6
	model.add_child(smoke)

	var plane := PlaneMesh.new()
	plane.size = Vector2(19, 19)
	var pool_material := ShaderMaterial.new()
	pool_material.shader = POOL
	plane.material = pool_material
	_pool = MeshInstance3D.new()
	_pool.mesh = plane
	_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pool)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.16, 0.2)
	_light.omni_range = 18.0
	_light.position = Vector3(0, 5.5, 0)
	add_child(_light)


func flash_hit() -> void:
	_flash = 1.0


func _process(delta: float) -> void:
	update_pose(delta)
	_clock_fx += delta
	# The pool stays on the ground when the body leaps.
	_pool.position.y = 0.3 - position.y / maxf(scale.y, 0.01)
	_light.light_energy = 3.4 + sin(_clock_fx * 19.0) * 0.5
	for wing: Array in _wings:
		var node: Node3D = wing[0]
		node.basis = Basis(Vector3.UP, wing[1] * sin(_clock_fx * 0.9) * 0.05) * wing[2]
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 6.0)
		for m in _toon_materials:
			m.set_shader_parameter("flash", _flash * 0.6)
