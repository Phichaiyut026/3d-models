class_name WormsModel
extends PoseRig
## WORMS, the one who controls everything in the system. The mesh is exported from worms.html
## (joints named for the game) and posed the way that page poses it: it never walks, it hangs in the air.

const MODEL := "res://models/worms.glb"
const BODY_SCALE := 0.55 ## Metres per unit of worms.html.
const ARMOR := preload("res://shaders/worms_armor.gdshader")
const HULL := preload("res://shaders/worms_hull.gdshader")
const CAPE := preload("res://shaders/worms_cape.gdshader")
const FLAT_DOUBLE := preload("res://shaders/flat_double.gdshader")
const GLOW := preload("res://shaders/glow.gdshader")
const RED := Color(1.0, 0.06, 0.19)
## The page's armours: [colour, veins, rim].
const ARMOURS := {"plate": [0x0e0c12, 0.6, 1.0], "dark": [0x050407, 0.4, 0.8], "mid": [0x1d1a25, 0.5, 1.1], "suit": [0x020103, 1.4, 0.6]}
## The page's glowing parts: [colour, boost].
const LIGHTS := {"red": [Color(1.0, 0.042, 0.116), 1.9], "hot": [Color(1.0, 0.19, 0.27), 2.6], "white": [Color(1.0, 0.73, 0.8), 3.0], "ember": [Color(1.0, 0.033, 0.11), 0.9]}
## Every pose of worms.html. Joints are Euler XYZ; `curl` closes the fingers, `palm` turns the right palm to the sky.
const POSES := {
	"idle": {
		"upperR": Vector3(-0.35, 0, -0.94), "elbowR": Vector3(-1.59, 0, -0.91), "wristR": Vector3.ZERO,
		"upperL": Vector3(0.1, 0, 0.26), "elbowL": Vector3(-0.28, 0, -0.1), "wristL": Vector3(0, -1.44, 0),
		"thighR": Vector3(-0.03, 0, -0.035), "thighL": Vector3(0.05, 0, 0.04), "kneeR": Vector3(0.08, 0, 0), "kneeL": Vector3(0.03, 0, 0),
		"curl": 0.45, "palm": 1.0, "neck": Vector3(0.04, 0.1, 0), "spine": Vector3(0, -0.06, 0),
	},
	"raise": {
		"upperR": Vector3(-0.9, 0, -0.8), "elbowR": Vector3(-1.5, 0, -0.6),
		"upperL": Vector3(-0.2, 0, 0.5), "elbowL": Vector3(-0.6, 0, 0),
		"curl": 0.25, "palm": 1.0, "neck": Vector3(-0.1, 0.05, 0), "spine": Vector3(-0.05, -0.05, 0),
	},
	"wide": {
		"upperR": Vector3(-0.2, 0, -1.35), "elbowR": Vector3(-0.4, 0, 0),
		"upperL": Vector3(-0.2, 0, 1.35), "elbowL": Vector3(-0.4, 0, 0),
		"curl": 0.1, "palm": 0.0, "neck": Vector3(0.1, 0, 0), "spine": Vector3(0.06, 0, 0),
	},
	"sky": {
		"upperR": Vector3(-2.6, 0, -0.45), "elbowR": Vector3(-0.3, 0, 0),
		"upperL": Vector3(-2.6, 0, 0.45), "elbowL": Vector3(-0.3, 0, 0),
		"curl": 0.3, "palm": 0.0, "neck": Vector3(-0.35, 0, 0), "spine": Vector3(-0.12, 0, 0),
	},
	"push": {
		"upperR": Vector3(-1.45, 0.1, -0.3), "elbowR": Vector3(-0.2, 0, 0), "wristR": Vector3(-0.9, 0, 0),
		"upperL": Vector3(0.25, 0, 0.45), "elbowL": Vector3(-0.9, 0, 0),
		"curl": 0.1, "palm": 0.0, "neck": Vector3(0, 0.15, 0), "spine": Vector3(0, -0.2, 0),
	},
	"point": {
		"upperL": Vector3(-0.54, 0, 0.6), "elbowL": Vector3(-0.08, 0, 0), "wristL": Vector3(-0.25, 0, 0),
		"curl": 0.2, "neck": Vector3(0.05, -0.35, 0), "spine": Vector3(0, 0.12, 0),
	},
	"grab": {
		"upperL": Vector3(-0.6, 0, 0.58), "elbowL": Vector3(-0.2, 0, 0), "wristL": Vector3(-0.1, 0, 0),
		"curl": 1.35, "neck": Vector3(0.08, -0.35, 0), "spine": Vector3(0, 0.14, 0),
	},
	"halt": {
		"upperL": Vector3(-0.8, 0, 0.55), "elbowL": Vector3(-0.02, 0, 0), "wristL": Vector3(1.0, 0, 0),
		"curl": 0.0, "neck": Vector3(-0.02, -0.32, 0), "spine": Vector3(0, 0.1, 0),
	},
}
## Actions the fight asks for that are not poses of their own.
const ALIASES := {"hit": "idle", "stagger": "halt", "death": "sky"}

var cube: Node3D ## The cube of the system, held over the right palm.
var cube_override := false ## Set by the powers when they move the cube themselves.
var power := 0.0 ## Lights the cracks in the armour during its powers.

var _root: Node3D
var _j := {}
var _fingers := {"R": [], "L": []} ## [finger, tip]
var _thumb_tips := {}
var _palm_basis := Basis.IDENTITY
var _cur := {}
var _pose := "idle"
var _armour: Array[ShaderMaterial] = []
var _hulls: Array[ShaderMaterial] = []
var _cape: ShaderMaterial
var _flash := 0.0
var _t := 0.0
var _lean := 0.0
var _sink := 0.0
var _cube_spin: Node3D
var _ground_rings: Array[Node3D] = []
var _gem_light: OmniLight3D


func _ready() -> void:
	var scene: Node3D = (load(MODEL) as PackedScene).instantiate()
	scene.scale = Vector3.ONE * BODY_SCALE
	add_child(scene)
	_root = scene.find_child("Worms", true, false)
	for joint_name: String in ["hips", "spine", "chest", "neck", "head", "haloSpin", "upperR", "elbowR", "wristR", "handR", "upperL", "elbowL", "wristL", "handL", "thighR", "kneeR", "thighL", "kneeL"]:
		var joint: Node3D = _root.find_child(joint_name, true, false)
		joint.rotation_order = EULER_ORDER_XYZ
		_j[joint_name] = joint
	for side: String in ["R", "L"]:
		for i in 4:
			var finger: Node3D = _root.find_child("finger%s%d" % [side, i], true, false)
			var tip: Node3D = _root.find_child("tip%s%d" % [side, i], true, false)
			finger.rotation_order = EULER_ORDER_XYZ
			tip.rotation_order = EULER_ORDER_XYZ
			_fingers[side].append([finger, tip])
		var thumb_tip: Node3D = _root.find_child("thumbTip" + side, true, false)
		thumb_tip.rotation_order = EULER_ORDER_XYZ
		_thumb_tips[side] = thumb_tip
	_palm_basis = (_j["handR"] as Node3D).basis
	for key: String in POSES["idle"]:
		var v: Variant = POSES["idle"][key]
		_cur[key] = v
	_dress(_root)
	_add_glows()
	_build_cube()
	_build_ground()


## Swaps the plain glTF materials for the page's own look.
func _dress(node: Node) -> void:
	var made := {}
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		stack.append_array(current.get_children())
		if not current is MeshInstance3D:
			continue
		var mesh_node: MeshInstance3D = current
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for i in mesh_node.mesh.get_surface_count():
			var old := mesh_node.mesh.surface_get_material(i)
			var key: String = old.resource_name if old != null else "plate"
			if not made.has(key):
				made[key] = _material_for(key)
			mesh_node.set_surface_override_material(i, made[key])
			if key == "cape":
				mesh_node.extra_cull_margin = 8.0


func _material_for(key: String) -> Material:
	var m := ShaderMaterial.new()
	if ARMOURS.has(key):
		var spec: Array = ARMOURS[key]
		m.shader = ARMOR
		m.set_shader_parameter("base", Color.hex((int(spec[0]) << 8) | 0xff))
		m.set_shader_parameter("veins", spec[1])
		m.set_shader_parameter("rim_amt", spec[2])
		var hull := ShaderMaterial.new()
		hull.shader = HULL
		m.next_pass = hull
		_armour.append(m)
		_hulls.append(hull)
	elif LIGHTS.has(key):
		m.shader = FLAT_DOUBLE
		m.set_shader_parameter("color", LIGHTS[key][0])
		m.set_shader_parameter("boost", LIGHTS[key][1])
	elif key == "cape":
		m.shader = CAPE
		_cape = m
	else:
		m.shader = ARMOR
		_armour.append(m)
	return m


func _glow(parent: Node3D, at: Vector3, size: float, tint: Color, strength: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var material := ShaderMaterial.new()
	material.shader = GLOW
	material.set_shader_parameter("color", tint)
	material.set_shader_parameter("strength", strength)
	quad.material = material
	var node := MeshInstance3D.new()
	node.mesh = quad
	node.position = at
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)


func _add_glows() -> void:
	var gem: Node3D = _root.find_child("gem", true, false)
	_glow(gem, Vector3(0, 0, 0.3), 2.6, RED, 0.8)
	var head: Node3D = _j["head"]
	for s: float in [-1.0, 1.0]:
		_glow(head, Vector3(s * 0.18, 0.05, 0.5), 0.6, RED, 0.7)
	_gem_light = OmniLight3D.new()
	_gem_light.light_color = RED
	_gem_light.omni_range = 9.0
	_gem_light.light_energy = 2.0
	_gem_light.position = Vector3(0, 0.1, 1.8)
	(_j["chest"] as Node3D).add_child(_gem_light)


## Twelve glowing bars on the edges of a cube, the way the page draws one.
static func wire_cube(size: float, thick: float, color: Color, boost := 1.9) -> Node3D:
	var holder := Node3D.new()
	var material := ShaderMaterial.new()
	material.shader = FLAT_DOUBLE
	material.set_shader_parameter("color", color)
	material.set_shader_parameter("boost", boost)
	var h := size * 0.5
	for axis in 3:
		for a: float in [-1.0, 1.0]:
			for b: float in [-1.0, 1.0]:
				var dims := Vector3.ONE * thick
				dims[axis] = size + thick
				var pos := Vector3.ZERO
				var others := [0, 1, 2]
				others.erase(axis)
				pos[others[0]] = a * h
				pos[others[1]] = b * h
				var box := BoxMesh.new()
				box.size = dims
				box.material = material
				var bar := MeshInstance3D.new()
				bar.mesh = box
				bar.position = pos
				bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				holder.add_child(bar)
	return holder


func _build_cube() -> void:
	cube = Node3D.new()
	cube.top_level = true
	add_child(cube)
	_cube_spin = Node3D.new()
	cube.add_child(_cube_spin)
	var k := BODY_SCALE
	_cube_spin.add_child(wire_cube(1.15 * k, 0.07 * k, LIGHTS["red"][0]))
	var inner := wire_cube(0.6 * k, 0.05 * k, LIGHTS["hot"][0], 2.6)
	inner.rotation = Vector3(0.6, 0.6, 0)
	_cube_spin.add_child(inner)
	var core := BoxMesh.new()
	core.size = Vector3.ONE * 0.26 * k
	core.material = Fx.flat_material(LIGHTS["white"][0], 3.0)
	var core_node := MeshInstance3D.new()
	core_node.mesh = core
	_cube_spin.add_child(core_node)
	_glow(cube, Vector3.ZERO, 4.0 * k, RED, 0.8)
	var light := OmniLight3D.new()
	light.light_color = RED
	light.omni_range = 6.0
	light.light_energy = 2.5
	cube.add_child(light)


## Two red rings turning on the ground under it, and data rising off it.
func _build_ground() -> void:
	for r: float in [5.2, 7.4]:
		var torus := TorusMesh.new()
		torus.inner_radius = r - 0.06
		torus.outer_radius = r
		torus.rings = 96
		torus.ring_segments = 3
		var material := ShaderMaterial.new()
		material.shader = FLAT_DOUBLE
		material.set_shader_parameter("color", LIGHTS["red"][0])
		material.set_shader_parameter("boost", 1.4)
		torus.material = material
		var ring := MeshInstance3D.new()
		ring.mesh = torus
		ring.position.y = 0.12
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		_ground_rings.append(ring)
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.18
	box.material = Fx.flat_material(LIGHTS["red"][0], 2.4)
	var data := CPUParticles3D.new()
	data.mesh = box
	data.amount = 60
	data.lifetime = 3.2
	data.local_coords = false
	data.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	data.emission_box_extents = Vector3(4.0, 3.0, 4.0)
	data.position = Vector3(0, 4.0, 0)
	data.direction = Vector3.UP
	data.spread = 25.0
	data.gravity = Vector3.ZERO
	data.initial_velocity_min = 0.6
	data.initial_velocity_max = 2.0
	data.scale_amount_min = 0.4
	data.scale_amount_max = 1.4
	data.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(data)


func play(p_action: String, length: float, hold := false) -> void:
	super.play(p_action, length, hold)
	_pose = ALIASES.get(p_action, p_action) if POSES.has(ALIASES.get(p_action, p_action)) else "idle"


func stop_action() -> void:
	super.stop_action()
	_pose = "idle"
	_sink = 0.0


func flash_hit() -> void:
	_flash = 1.0


## Where the cube rests when nothing else is moving it: just over the open right palm.
func cube_home() -> Vector3:
	var hand: Node3D = _j["handR"]
	return hand.to_global(Vector3(0, -1.3, 0.35)) + Vector3(0, 0.9 * BODY_SCALE, 0)


## The left hand, where its erasing powers leave from.
func left_hand() -> Vector3:
	return (_j["handL"] as Node3D).global_position


func _process(delta: float) -> void:
	if _root == null:
		return
	_t += delta
	if action != "":
		action_time += delta
		if action_time >= action_length and not hold_action:
			stop_action()
	var dying := action == "death"
	var goal: Dictionary = POSES[_pose]
	var idle: Dictionary = POSES["idle"]
	var k := 1.0 - exp(-delta * 6.0)
	for key: String in idle:
		var target: Variant = goal.get(key, idle[key])
		_cur[key] = lerp(_cur[key], target, k)
	for key: String in _cur:
		if _j.has(key):
			(_j[key] as Node3D).rotation = _cur[key]
	for side: String in ["R", "L"]:
		var row: Array = _fingers[side]
		for i in row.size():
			row[i][0].rotation.x = -_cur["curl"] * (0.8 + i * 0.1)
			row[i][1].rotation.x = -_cur["curl"] * 1.2
		(_thumb_tips[side] as Node3D).rotation.x = -_cur["curl"]
	(_j["neck"] as Node3D).rotation = _cur["neck"] + Vector3(0, 0, 0)
	(_j["spine"] as Node3D).rotation = _cur["spine"]
	(_j["chest"] as Node3D).rotation.x = sin(_t * 1.1) * 0.02
	(_j["head"] as Node3D).rotation.y = sin(_t * 0.4) * 0.06
	(_j["haloSpin"] as Node3D).rotation.y = _t * 0.3
	(_j["handR"] as Node3D).basis = Basis.IDENTITY.slerp(_palm_basis, clampf(_cur["palm"], 0.0, 1.0))
	# It hangs in the air, breathing slowly; dying, it falls back and sinks.
	_sink = lerpf(_sink, 1.0 if dying else 0.0, 1.0 - exp(-delta * 1.5))
	_lean = lerpf(_lean, clampf(speed / 8.0, 0.0, 1.0) * 0.18, 1.0 - exp(-delta * 4.0))
	_root.position.y = 0.7 + sin(_t * 1.1) * 0.2 - _sink * 6.0
	_root.rotation.x = _lean - _sink * 0.5
	_gem_light.light_energy = 2.0 + sin(_t * 2.2) * 0.8 + power * 2.0
	for ring in _ground_rings:
		ring.rotation.y += delta * (0.3 + power * 2.0) * (1.0 if ring == _ground_rings[0] else -1.0)
	_flash = maxf(0.0, _flash - delta * 5.0)
	for m in _armour:
		m.set_shader_parameter("flash", _flash * 0.5)
		m.set_shader_parameter("power", power)
	for hull in _hulls:
		hull.set_shader_parameter("boost", 1.0 + power * 1.5 + _flash)
	if _cape != null:
		_cape.set_shader_parameter("flash", _flash)
	# The cube floats over the open palm unless a power has taken it.
	_cube_spin.rotation.x += delta * 0.5 * (1.0 + power * 8.0)
	_cube_spin.rotation.y += delta * 0.8 * (1.0 + power * 8.0)
	if not cube_override:
		cube.global_position = cube.global_position.lerp(cube_home(), 1.0 - exp(-delta * 10.0)) if _t > 0.3 else cube_home()
		cube.scale = Vector3.ONE * (1.0 + sin(_t * 3.0) * 0.05)
	cube.visible = visible and not dying
