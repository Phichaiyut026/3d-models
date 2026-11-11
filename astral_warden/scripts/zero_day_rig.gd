class_name ZeroDayRig
extends Node3D
## Zero Day's body, posed every frame the way zero_day.html poses it.

const MODEL := "res://models/zero_day.glb"
const BODY_SCALE := 0.42
const CAPE := preload("res://shaders/zero_cape.gdshader")
const HALO := preload("res://shaders/zero_halo.gdshader")
const THIGH := 3.5
const SHIN := 2.9
const IDLE := {"d": 0.3, "lean": 0.06, "yaw": 0.0, "tilt": 0.0, "rx": -0.42, "ry": 0.1, "rz": -0.2, "re": -0.86, "lx": -0.28, "ly": 1.2, "lz": 0.9, "le": -1.55, "blade": Vector3(0.93, -0.31, 0.21), "stride": 0.0}
const FIGHT := {"d": 1.05, "lean": 0.24, "yaw": -0.18, "tilt": 0.0, "rx": -0.68, "ry": 0.1, "rz": -0.26, "re": -1.15, "lx": -0.5, "ly": 1.0, "lz": 0.78, "le": -1.7, "blade": Vector3(0.7, 0.12, 0.7), "stride": 0.95}
const MOVES := {
	"lockdown": {"dur": 2.2, "keys": [[0.0, {}], [0.22, {"d": 0.6, "lean": -0.14, "lx": -2.3, "ly": 0.55, "lz": 0.78, "le": -0.3}], [0.42, {"d": 1.15, "lean": 0.3, "lx": -1.25, "ly": 0.1, "lz": 0.1, "le": -0.2, "stride": 0.9}], [1.0, {"d": 1.15, "lean": 0.3, "lx": -1.25, "ly": 0.1, "lz": 0.1, "le": -0.2, "stride": 0.9}]]},
	"beckon": {"dur": 1.6, "keys": [[0.0, {}], [0.3, {"lean": 0.1, "lx": -1.5, "ly": 0.5, "lz": 0.5, "le": -1.0}], [0.6, {"lean": 0.14, "lx": -1.3, "ly": 0.5, "lz": 0.5, "le": -1.9}], [1.0, {}]]},
	"talk": {"dur": 2.4, "keys": [[0.0, {}], [0.25, {"tilt": 0.08, "yaw": 0.12, "lx": -0.9, "ly": 1.0, "lz": 0.9, "le": -1.3}], [0.6, {"tilt": -0.06, "yaw": -0.1, "lx": -0.7, "ly": 1.1, "lz": 0.8, "le": -1.75}], [1.0, {}]]},
}

var fight_goal := 0.0
var walking := false

var _root: Node3D
var _j := {}
var _fingers := {"R": [], "L": []}
var _weapon: Node3D
var _locks: Array = [] ## [node, base position, phase]
var _halo: MeshInstance3D
var _fight := 0.0
var _clock := 0.0
var _walk_phase := 0.0
var _walk_weight := 0.0
var _act := ""
var _act_time := 0.0
var _hold := false


func _ready() -> void:
	var scene: Node3D = (load(MODEL) as PackedScene).instantiate()
	scene.scale = Vector3.ONE * BODY_SCALE
	add_child(scene)
	_root = scene.find_child("ZeroDay", true, false)
	for joint_name: String in ["hips", "spine", "chest", "head", "shoulderR", "elbowR", "handR", "shoulderL", "elbowL", "handL", "thighR", "kneeR", "footR", "thighL", "kneeL", "footL"]:
		var joint: Node3D = _root.find_child(joint_name, true, false)
		joint.rotation_order = EULER_ORDER_XZY
		_j[joint_name] = joint
	for side: String in ["R", "L"]:
		for i in 4:
			var row := []
			for suffix: String in ["", "B", "C"]:
				var part: Node3D = _root.find_child("f%s%d%s" % [side, i, suffix], true, false)
				if part != null:
					part.rotation_order = EULER_ORDER_XZY
					row.append(part)
			_fingers[side].append(row)
	_weapon = _root.find_child("skeletonKeySword", true, false)
	var index := 0
	for child in _root.get_children():
		if child != _j["hips"] and child != _weapon and child.name != &"chains":
			_locks.append([child, (child as Node3D).position, index * 1.55])
			index += 1
	_dress_cape(_j["chest"])
	_add_halo()
	_add_data()


func _dress_cape(chest: Node3D) -> void:
	for child in chest.get_children():
		if not child is MeshInstance3D:
			continue
		var node: MeshInstance3D = child
		if node.mesh.get_surface_count() == 1 and node.mesh.surface_get_array_len(0) >= 600:
			var old := node.mesh.surface_get_material(0)
			if old is StandardMaterial3D and old.albedo_texture != null:
				var material := ShaderMaterial.new()
				material.shader = CAPE
				material.set_shader_parameter("tex", old.albedo_texture)
				node.material_override = material
				node.extra_cull_margin = 12.0


func _add_halo() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 24.0
	var material := ShaderMaterial.new()
	material.shader = HALO
	_halo = MeshInstance3D.new()
	_halo.mesh = quad
	_halo.material_override = material
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.position = Vector3(0, 18.2, -4.2)
	_root.add_child(_halo)


## Bright pixels leaking off the body.
func _add_data() -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.16
	box.material = Fx.flat_material(Color("b8ff2e"), 3.0)
	var p := CPUParticles3D.new()
	p.mesh = box
	p.amount = 46
	p.lifetime = 2.6
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(3.2, 3.6, 2.0)
	p.position = Vector3(0, 4.5, 0)
	p.direction = Vector3.UP
	p.spread = 30.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.5
	p.initial_velocity_max = 1.6
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.5
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(p)


func play(act: String, hold := false) -> void:
	_act = act
	_act_time = 0.0
	_hold = hold


func stop_act() -> void:
	_act = ""


func _sample() -> Dictionary:
	var base := {}
	for key: String in IDLE:
		base[key] = lerp(IDLE[key], FIGHT[key], _fight)
	if _act == "":
		return base
	var move: Dictionary = MOVES[_act]
	var q := minf(_act_time / move["dur"], 1.0)
	var keys: Array = move["keys"]
	var i := 0
	while i < keys.size() - 2 and q >= keys[i + 1][0]:
		i += 1
	var ta: float = keys[i][0]
	var tb: float = keys[i + 1][0]
	var k := clampf((q - ta) / maxf(tb - ta, 0.001), 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var out := {}
	for key: String in base:
		var a: Variant = keys[i][1].get(key, base[key])
		var b: Variant = keys[i + 1][1].get(key, base[key])
		out[key] = lerp(a, b, k)
	return out


func _leg(side: String, sign_x: float, drop: float, stride: float) -> void:
	var height := maxf(1.2, 6.33 - drop)
	var reach := minf(THIGH + SHIN - 0.005, Vector2(height, stride).length())
	var a := acos(clampf((THIGH * THIGH + reach * reach - SHIN * SHIN) / (2.0 * THIGH * reach), -1.0, 1.0))
	var b := acos(clampf((SHIN * SHIN + reach * reach - THIGH * THIGH) / (2.0 * SHIN * reach), -1.0, 1.0))
	var thigh_x := -(atan2(stride, height) + a)
	var knee_x := a + b
	_j["thigh" + side].rotation = Vector3(thigh_x, 0, sign_x * 0.1)
	_j["knee" + side].rotation = Vector3(knee_x, 0, 0)
	_j["foot" + side].rotation = Vector3(-(thigh_x + knee_x), 0, -sign_x * 0.1)


func _curl(side: String, amount: float, spread: float) -> void:
	var row: Array = _fingers[side]
	for i in row.size():
		var parts: Array = row[i]
		if parts.size() < 3:
			continue
		parts[0].rotation = Vector3(-amount * 1.25 + sin(_clock * 1.6 + i) * 0.05, 0, (i - 1.5) * spread)
		parts[1].rotation.x = -amount * 1.35
		parts[2].rotation.x = -amount * 1.05


func _process(delta: float) -> void:
	if _root == null:
		return
	_clock += delta
	var t := _clock
	_fight = lerpf(_fight, fight_goal, 1.0 - exp(-delta * 8.0))
	_walk_weight = lerpf(_walk_weight, 1.0 if walking else 0.0, 1.0 - exp(-delta * 8.0))
	_walk_phase += delta * 5.5 * _walk_weight
	if _act != "":
		_act_time += delta
		if not _hold and _act_time >= MOVES[_act]["dur"]:
			_act = ""
	var p := _sample()
	var b := sin(t * 1.7)
	var big := sin(t * 0.8)
	var step := sin(_walk_phase)
	var drop: float = p["d"] + _walk_weight * (0.25 + absf(step) * -0.18)
	var lean: float = p["lean"] + _walk_weight * 0.12
	var yaw: float = p["yaw"]
	_j["hips"].position = Vector3(0, 7.8 - drop + b * 0.05, 0)
	_j["hips"].rotation = Vector3(lean * 0.3, yaw * 0.4 + step * 0.08 * _walk_weight, big * 0.012)
	_j["spine"].rotation = Vector3(lean * 0.35 + b * 0.012, yaw * 0.3, 0)
	_j["chest"].rotation = Vector3(lean * 0.35 + b * 0.018, yaw * 0.3 - step * 0.1 * _walk_weight, -big * 0.012)
	_j["head"].rotation = Vector3(-lean * 0.5 + p["tilt"] + sin(t * 0.63) * 0.03, -yaw * 0.45 + sin(t * 0.41) * 0.06, 0)
	_j["shoulderR"].rotation = Vector3(p["rx"] + b * 0.018 + step * 0.2 * _walk_weight, p["ry"], p["rz"])
	_j["elbowR"].rotation.x = p["re"]
	_j["shoulderL"].rotation = Vector3(p["lx"] + b * 0.02 - step * 0.2 * _walk_weight, p["ly"], p["lz"])
	_j["elbowL"].rotation.x = p["le"]
	_j["handR"].rotation = Vector3(-0.15, 0, 0)
	_j["handL"].rotation = Vector3(-0.08 + sin(t * 1.2) * 0.05, -1.45, 0.08)
	_curl("R", 0.95, 0.0)
	_curl("L", 0.12 if _act == "lockdown" else 0.3, 0.2)
	var stride: float = p["stride"]
	_leg("R", -1.0, drop, -stride * 0.55 + 0.12 - step * 2.2 * _walk_weight)
	_leg("L", 1.0, drop, stride * 0.9 + 0.12 + step * 2.2 * _walk_weight)
	var hand: Vector3 = _root.to_local((_j["handR"] as Node3D).global_position)
	_weapon.position = hand - Vector3(0, 0.25, 0)
	var blade: Vector3 = p["blade"]
	_weapon.basis = Basis(Quaternion(Vector3.UP, blade.normalized()))
	for lock: Array in _locks:
		var node: Node3D = lock[0]
		var base: Vector3 = lock[1]
		var ph: float = lock[2]
		node.position = base + Vector3(sin(t * 0.7 + ph) * 0.35, sin(t * 1.15 + ph) * 0.55, cos(t * 0.55 + ph) * 0.35)
		node.rotation = Vector3(0, -signf(base.x) * 0.25 + sin(t * 0.8 + ph) * 0.16, sin(t * 0.62 + ph) * 0.09)
	_halo.rotation.z = sin(t * 0.3) * 0.2
