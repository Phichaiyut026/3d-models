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
const VOID_SKIN := preload("res://shaders/void_skin.gdshader")
const WAR_CAPE := preload("res://shaders/war_cape.gdshader")
const HOLE_HALO := preload("res://shaders/hole_halo.gdshader")
const HOLE_ACCRETION := preload("res://shaders/hole_accretion.gdshader")
const DEAD_WORLD := preload("res://shaders/dead_world.gdshader")
const FIRST_SCALE := 0.62
const OBLIVION_SCALE := FIRST_SCALE * 2.7 ## The web model's BODY.
const HOLE_R := 6.2
const HOLE_AT := Vector3(0, 8.6, -14)
const SPINE_PIVOT := Vector3(0, 4.85, 0)
## The first form's colours and what they become, from the two versions of system_overlord.html.
const OBLIVION_COLORS := {
	"12131b": "14151d", "20222e": "21232e", "3a3f50": "3c3f4e", "3a404f": "1f2028", "7f889c": "6a6e7c", "050509": "020204",
	"e0142a": "ff0a24", "ed1f33": "ff0a24", "8e0a1c": "7a0512", "5a22d8": "ff1838", "d8206e": "ff2238",
}
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
const SWORD_SCALE := 1.3

var blade_tip: Node3D
var _toon_materials: Array[ShaderMaterial] = []
var _wings: Array = [] ## [node, side, resting basis]
var _flash := 0.0
var _clock_fx := 0.0
var _pool: MeshInstance3D
var _light: OmniLight3D
var _shared := {}
var _undo: Array = [] ## [material, parameter or "", old value]
var _extras: Node3D
var _hole: Node3D
var _hole_disc: MeshInstance3D
var _halo_material: ShaderMaterial
var _graveyard: Node3D
var _worlds: Array = [] ## [node, angle, radius, speed]
var _ash: CPUParticles3D
var _hole_size := 1.0
var _hole_goal := 1.0
var _awake := false


func _init() -> void:
	unit = 4.2
	pivot = Vector3(0, 4.2, 0)
	thigh = 1.61
	shin_length = 1.71
	leg_metres = thigh + shin_length
	run_speed = 5.0
	stance = OverlordMoves.GUARD.duplicate()
	extra_actions = OverlordMoves.ACTIONS.duplicate()
	# The leap keeps its legs; only the sword arm follows the model page.
	var slam: Array = ACTIONS["slam"].duplicate(true)
	for i in slam.size():
		var arm: Dictionary = OverlordMoves.SWORD_UP if i < 2 else OverlordMoves.SWORD_DOWN
		slam[i][1]["armR"] = arm["armR"]
		slam[i][1]["foreR"] = arm["foreR"]
	extra_actions["slam"] = slam
	var model: Node3D = load(SCENE_PATH).instantiate()
	model.rotation_order = EULER_ORDER_XYZ
	root_joint = model
	add_child(model)
	var textures: Dictionary = model.get_meta("textures")
	_dress(model, textures, _shared)
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


## The greatsword goes into the right hand exactly as on the model page: a grip in the fist, the blade set from it.
func _mount_sword(model: Node3D) -> void:
	var sword: Node3D = model.get_node("Greatsword")
	sword.owner = null
	model.remove_child(sword)
	var grip := Node3D.new()
	grip.position = OverlordMoves.GRIP_IN_HAND
	grip.basis = Basis(Vector3.BACK, -OverlordMoves.SWORD_ANGLE)
	joints["hand_R"].add_child(grip)
	grip.add_child(sword)
	sword.position = OverlordMoves.GUARD_FROM_GRIP
	register("sword", sword)
	sword.rotation_order = EULER_ORDER_ZYX
	sword.rotation = Vector3(0, 0, OverlordMoves.SWORD_ANGLE)
	sword.scale = Vector3(SWORD_SCALE, 1.0, 1.0)
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


## At rest the blade lies flat; a cut's keys turn its edge to lead.
func _base_pose() -> Dictionary:
	var pose := super()
	pose["sword"] = Vector3(0, 0, OverlordMoves.SWORD_ANGLE)
	return pose


## Opens the black hole behind the body, ahead of the change itself.
func open_hole() -> void:
	_build_oblivion()
	_extras.visible = false
	_hole.visible = true
	_hole.scale = Vector3.ONE * 0.01
	_hole_size = 0.01
	_hole_goal = 1.0


func set_hole(size: float) -> void:
	_hole_goal = size


func hole_position() -> Vector3:
	return _hole.global_position if _hole != null else global_position


## Becomes OBLIVION: the same body recoloured and grown, with everything it carries.
func awaken() -> void:
	if _awake:
		return
	_awake = true
	_build_oblivion()
	_extras.visible = true
	_hole.visible = true
	_ash.emitting = true
	_hole_goal = 1.0
	_undo.clear()
	for key: String in _shared:
		var material: ShaderMaterial = _shared[key]
		var pieces := key.split("_")
		if key == "toon_0a0b11":
			_undo.append([material, "", material.shader])
			material.shader = VOID_SKIN
		elif OBLIVION_COLORS.has(pieces[1]):
			var parameter := "albedo" if pieces[0] == "toon" else "color"
			_undo.append([material, parameter, material.get_shader_parameter(parameter)])
			material.set_shader_parameter(parameter, Color("#" + OBLIVION_COLORS[pieces[1]]))
	create_tween().tween_property(self, "scale", Vector3.ONE * OBLIVION_SCALE, 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_light.light_energy = 8.0
	_light.omni_range = 40.0


## Back to the first form, for a new run.
func revert_form() -> void:
	if _extras != null:
		_extras.visible = false
		_hole.visible = false
		_ash.emitting = false
	if not _awake:
		return
	_awake = false
	for entry: Array in _undo:
		if entry[1] == "":
			entry[0].shader = entry[2]
		else:
			entry[0].set_shader_parameter(entry[1], entry[2])
	_undo.clear()
	scale = Vector3.ONE * FIRST_SCALE
	_light.omni_range = 18.0


func _toon(hex: String) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", Color("#" + hex))
	_toon_materials.append(m)
	var hull := ShaderMaterial.new()
	hull.shader = OUTLINE
	hull.set_shader_parameter("color", Color(0.03, 0.035, 0.05))
	hull.set_shader_parameter("thickness", 0.03)
	m.next_pass = hull
	return m


## A flat outline given `depth` along Z, centred on the plane.
func _extrude(points: PackedVector2Array, depth: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := depth * 0.5
	var fan := Geometry2D.triangulate_polygon(points)
	for i in range(0, fan.size(), 3):
		for corner: int in [fan[i], fan[i + 1], fan[i + 2]]:
			st.set_normal(Vector3.BACK)
			st.add_vertex(Vector3(points[corner].x, points[corner].y, half))
		for corner: int in [fan[i + 2], fan[i + 1], fan[i]]:
			st.set_normal(Vector3.FORWARD)
			st.add_vertex(Vector3(points[corner].x, points[corner].y, -half))
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var edge := b - a
		var normal := Vector3(edge.y, -edge.x, 0.0).normalized()
		if Geometry2D.is_polygon_clockwise(points):
			normal = -normal
		var quad := [Vector3(a.x, a.y, half), Vector3(b.x, b.y, half), Vector3(b.x, b.y, -half), Vector3(a.x, a.y, -half)]
		for index: int in [0, 1, 2, 0, 2, 3]:
			st.set_normal(normal)
			st.add_vertex(quad[index])
	return st.commit()


func _part(parent: Node3D, mesh: Mesh, material: Material, at: Vector3, rotation_xyz := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	node.rotation = rotation_xyz
	parent.add_child(node)
	return node


func _build_oblivion() -> void:
	if _extras != null:
		return
	_extras = Node3D.new()
	joints["upper"].add_child(_extras)
	var silver := _toon("6a6e7c")
	var lite := _toon("3c3f4e")
	var gold := _toon("8f6a26")
	var red := Fx.flat_material(Color("ff0a24"), 3.0)
	var guard := BoxMesh.new()
	guard.size = Vector3(0.9, 0.13, 0.15)
	# The blades of every champion it has ever beaten, carried across the back.
	for i in 9:
		var a := (i - 4) * 0.28
		var length := 6.2 - absf(i - 4) * 0.46
		var blade := PackedVector2Array([Vector2(-0.2, 0), Vector2(0.2, 0), Vector2(0.26, 0.5), Vector2(0.2, length - 0.9), Vector2(0, length), Vector2(-0.2, length - 0.9), Vector2(-0.26, 0.5)])
		var edge := PackedVector2Array([Vector2(-0.02, 0.4), Vector2(0.02, 0.4), Vector2(0.02, length - 0.9), Vector2(0, length - 0.3), Vector2(-0.02, length - 0.9)])
		var at := Vector3(sin(a) * 0.3, 6.45 + cos(a) * 0.3, -1.1 - absf(i - 4) * 0.02) - SPINE_PIVOT
		var turn := Vector3(-0.2, 0, -a)
		_part(_extras, _extrude(blade, 0.06), silver if i % 2 == 1 else lite, at, turn).rotation_order = EULER_ORDER_XYZ
		_part(_extras, guard, gold, at, turn).rotation_order = EULER_ORDER_XYZ
		_part(_extras, _extrude(edge, 0.08), red, at, turn).rotation_order = EULER_ORDER_XYZ
	_build_cape()
	var clasp := SphereMesh.new()
	clasp.radius = 0.24
	clasp.height = 0.48
	var stone := SphereMesh.new()
	stone.radius = 0.13
	stone.height = 0.26
	for side: float in [-1.0, 1.0]:
		_part(_extras, clasp, gold, Vector3(side * 0.96, 6.84, -0.72) - SPINE_PIVOT).scale = Vector3(1, 1, 0.5)
		_part(_extras, stone, red, Vector3(side * 0.96, 6.84, -0.8) - SPINE_PIVOT).scale = Vector3(1, 1, 0.6)
	_build_hole()
	_build_ash()


func _build_cape() -> void:
	var columns := 18
	var rows := 16
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := []
	for j in rows + 1:
		for i in columns + 1:
			var u := float(i) / columns * 2.0 - 1.0
			var v := float(j) / rows
			var index := j * (columns + 1) + i
			var hem := float(index * 37 % 10) / 10.0 * 0.9 * (v - 0.9) * 10.0 if v > 0.9 else 0.0
			var half := 1.12 + v * 0.95
			cells.append([Vector3(u * half * 0.5, 6.92 - v * 6.5 + hem, -0.84 - v * 0.5) - SPINE_PIVOT, Vector2(float(i) / columns, v)])
	for j in rows:
		for i in columns:
			var a := j * (columns + 1) + i
			var b := a + columns + 1
			for index: int in [a, b, a + 1, a + 1, b, b + 1]:
				st.set_uv(cells[index][1])
				st.add_vertex(cells[index][0])
	st.generate_normals()
	var material := ShaderMaterial.new()
	material.shader = WAR_CAPE
	var cape := _part(_extras, st.commit(), material, Vector3.ZERO)
	cape.extra_cull_margin = 4.0


func _build_hole() -> void:
	_hole = Node3D.new()
	_hole.position = HOLE_AT
	root_joint.get_parent().add_child(_hole)
	var sphere := SphereMesh.new()
	sphere.radius = HOLE_R
	sphere.height = HOLE_R * 2.0
	sphere.radial_segments = 48
	sphere.rings = 32
	var core := _part(_hole, sphere, Fx.flat_material(Color.BLACK, 1.0), Vector3.ZERO)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo_material = ShaderMaterial.new()
	_halo_material.shader = HOLE_HALO
	var halo := _part(_hole, QuadMesh.new(), _halo_material, Vector3.ZERO)
	halo.scale = Vector3(HOLE_R * 5.4, HOLE_R * 5.4, 1.0)
	halo.extra_cull_margin = 80.0
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var disc := QuadMesh.new()
	disc.size = Vector2(31.0, 31.0)
	var disc_material := ShaderMaterial.new()
	disc_material.shader = HOLE_ACCRETION
	_hole_disc = _part(_hole, disc, disc_material, Vector3.ZERO, Vector3(-1.32, 0, 0))
	_hole_disc.rotation_order = EULER_ORDER_XYZ
	_hole_disc.extra_cull_margin = 80.0
	_hole_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_graveyard = Node3D.new()
	_graveyard.rotation.x = 0.16
	_hole.add_child(_graveyard)
	var world_material := ShaderMaterial.new()
	world_material.shader = DEAD_WORLD
	for i in 8:
		var size := 0.55 + float(i * 37 % 10) / 10.0 * 1.3
		var mesh := SphereMesh.new()
		mesh.radius = size
		mesh.height = size * 2.0
		mesh.radial_segments = 26
		mesh.rings = 18
		var world := _part(_graveyard, mesh, world_material, Vector3.ZERO)
		world.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_worlds.append([world, i * 2.2, 9.6 + float(i * 53 % 10) / 10.0 * 6.6, 0.05 + float(i * 29 % 10) / 200.0])


## Ash, falling on everything.
func _build_ash() -> void:
	var dot := QuadMesh.new()
	dot.size = Vector2.ONE * 0.34
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.albedo_color = Color(0.54, 0.48, 0.48, 0.75)
	dot.material = material
	_ash = CPUParticles3D.new()
	_ash.mesh = dot
	_ash.amount = 200
	_ash.lifetime = 9.0
	_ash.preprocess = 9.0
	_ash.emitting = false
	_ash.local_coords = false
	_ash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_ash.emission_box_extents = Vector3(30.0, 1.0, 30.0)
	_ash.position = Vector3(0, 20, 0)
	_ash.direction = Vector3.DOWN
	_ash.spread = 8.0
	_ash.gravity = Vector3.ZERO
	_ash.initial_velocity_min = 1.0
	_ash.initial_velocity_max = 2.6
	_ash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ash.visibility_aabb = AABB(Vector3(-60, -40, -60), Vector3(120, 80, 120))
	add_child(_ash)


func _update_hole(delta: float) -> void:
	if _hole == null or not _hole.visible:
		return
	_hole_size = lerpf(_hole_size, _hole_goal, 1.0 - exp(-delta * 3.0))
	_hole.scale = Vector3.ONE * maxf(_hole_size, 0.01)
	# However large it grows, its near edge stays behind the body.
	_hole.position.z = HOLE_AT.z - maxf(_hole_size - 1.0, 0.0) * HOLE_R * 1.05
	_hole_disc.rotation.z = -_clock_fx * 0.32
	_halo_material.set_shader_parameter("power", 0.95 + sin(_clock_fx * 1.7) * 0.08 + maxf(_hole_size - 1.0, 0.0) * 0.3)
	_graveyard.rotation.y = _clock_fx * 0.05
	for world: Array in _worlds:
		var a: float = world[1] + _clock_fx * world[3]
		(world[0] as Node3D).position = Vector3(cos(a) * world[2], sin(a * 1.3) * 0.8, sin(a) * world[2])


func _process(delta: float) -> void:
	update_pose(delta)
	_clock_fx += delta
	_update_hole(delta)
	# The pool stays on the ground when the body leaps.
	_pool.position.y = 0.3 - position.y / maxf(scale.y, 0.01)
	_light.light_energy = (8.0 if _awake else 3.4) + sin(_clock_fx * 19.0) * 0.5
	for wing: Array in _wings:
		var node: Node3D = wing[0]
		node.basis = Basis(Vector3.UP, wing[1] * sin(_clock_fx * 0.9) * 0.05) * wing[2]
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 6.0)
		for m in _toon_materials:
			m.set_shader_parameter("flash", _flash * 0.6)
