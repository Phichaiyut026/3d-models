class_name SoldierModel
extends PoseRig
## The soldiers of System Overlord: programs in layered black armour, veined with red.
## Toon-shaded and outlined like the boss. Built in metres on one skeleton, in four builds.

const TOON := preload("res://shaders/toon.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")
const FLAT := preload("res://shaders/flat.gdshader")

var blade_tip: Node3D
var kind := "process"
var _toons: Array[ShaderMaterial] = []
var _flash := 0.0
var _shield: Node3D
var _tails: Array[Node3D] = []
var _rings: Array[Node3D] = []
var _orb_light: OmniLight3D
var f: MeshForge
var w := 1.0 ## How broad this build is.


func _init(soldier_kind := "process") -> void:
	kind = soldier_kind
	w = {"process": 1.0, "firewall": 1.28, "daemon": 0.95, "rootkit": 1.12}[kind]
	unit = 1.0
	pivot = Vector3(0, 1.0, 0)
	thigh = 0.47
	shin_length = 0.42
	leg_metres = thigh + shin_length
	run_speed = 5.0
	stance = {
		"armL": Vector3(-0.55, 0.0, -0.55),
		"foreL": Vector3(-1.25, 0.0, 0.0),
		"armR": Vector3(-0.25, 0.0, -0.12),
		"foreR": Vector3(-0.9, 0.0, 0.0),
	}
	f = MeshForge.new(_make_materials())
	_build()
	f.commit()


# ------------------------------------------------------------------ materials

func _hull(color: Color, thickness: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = OUTLINE
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("thickness", thickness)
	return m


func _toon(hex: int, hull: ShaderMaterial) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", Color.hex((hex << 8) | 0xff))
	m.next_pass = hull
	_toons.append(m)
	return m


func _flat(color: Color, boost: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FLAT
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("boost", boost)
	return m


func _make_materials() -> Dictionary:
	var hull := _hull(Color(0.02, 0.015, 0.03), 0.012)
	var shield := StandardMaterial3D.new()
	shield.albedo_color = Color(0.45, 0.02, 0.06, 0.42)
	shield.emission_enabled = true
	shield.emission = Color(1.0, 0.05, 0.12)
	shield.emission_energy_multiplier = 1.4
	shield.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shield.cull_mode = BaseMaterial3D.CULL_DISABLED
	return {
		"plate": _toon(0x1d1f29, hull),
		"mid": _toon(0x2d303c, hull),
		"lite": _toon(0x555b6e, hull),
		"void": _toon(0x08080d, hull),
		"cape": _toon(0x4a0a14, hull),
		"gold": _toon(0x9a7230, hull),
		"red": _flat(Color(1.0, 0.06, 0.14), 3.2),
		"dim": _flat(Color(0.6, 0.03, 0.08), 2.0),
		"shield": shield,
	}


# -------------------------------------------------------------------- helpers

func _joint(joint_name: String, parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	register(joint_name, node)
	node.position = pos
	parent.add_child(node)
	return node


func _plate(joint: Node3D, pos: Vector3, rot: Vector3, pts: Array, depth: float, mat: String, bevel := 0.006) -> void:
	f.plate(joint, MeshForge.xform(pos, rot), pts, depth, mat, bevel)


func _box(joint: Node3D, pos: Vector3, size: Vector3, mat: String, rot := Vector3.ZERO) -> void:
	f.add(joint, MeshForge.xform(pos, rot), MeshForge.box_geo(size.x, size.y, size.z), mat)


func _ball(joint: Node3D, pos: Vector3, r: float, mat: String) -> void:
	f.add(joint, MeshForge.xform(pos), MeshForge.sphere_geo(r, 10, 8), mat, true)


func _flip(pts: Array, s: float) -> Array:
	var out := []
	for p: Array in pts:
		out.append([p[0] * s, p[1]])
	return out


## A thin glowing line on a surface: the soldier's circuits.
func _trace(joint: Node3D, a: Vector3, b: Vector3, width := 0.012) -> void:
	f.limb(joint, Transform3D.IDENTITY, a, b, [[0.0, width, width * 0.5], [1.0, width, width * 0.5]], "red", 1.0, 4)


# ----------------------------------------------------------------------- body

func _build() -> void:
	root_joint = Node3D.new()
	root_joint.name = "Root"
	root_joint.rotation_order = EULER_ORDER_XYZ
	add_child(root_joint)
	var upper := _joint("upper", root_joint, Vector3(0, 1.02, 0))
	if kind == "daemon":
		_build_daemon(upper)
		return
	_build_hips()
	_build_torso(upper)
	_build_head(upper)
	for s: float in [-1.0, 1.0]:
		_build_arm(upper, s)
		_build_leg(s)
	match kind:
		"process":
			_build_sword(1.12, 0.045)
		"firewall":
			_build_shield()
			_build_sword(0.78, 0.085)
		"rootkit":
			_build_rootkit(upper)
			_build_sword(1.5, 0.075)


func _build_hips() -> void:
	var r := root_joint
	var I := Transform3D.IDENTITY
	f.loft(r, I, [[0.84, 0.13 * w, 0.1], [0.92, 0.17 * w, 0.12], [1.0, 0.185 * w, 0.13]], "void", 0.85)
	f.loft(r, I, [[0.98, 0.195 * w, 0.135], [1.06, 0.2 * w, 0.14]], "mid", 0.7)
	# The belt buckle: a small red diamond in a dark frame.
	_plate(r, Vector3(0, 1.02, 0.145), Vector3.ZERO, [[0.0, 0.05], [0.05, 0.0], [0.0, -0.05], [-0.05, 0.0]], 0.02, "plate")
	_plate(r, Vector3(0, 1.02, 0.158), Vector3.ZERO, [[0.0, 0.028], [0.028, 0.0], [0.0, -0.028], [-0.028, 0.0]], 0.01, "red", 0.0)
	# Faulds front and back.
	_plate(r, Vector3(0, 0.93, 0.13), Vector3(-0.12, 0, 0), [[-0.09 * w, 0.06], [0.09 * w, 0.06], [0.07 * w, -0.1], [0.0, -0.14], [-0.07 * w, -0.1]], 0.02, "plate")
	_plate(r, Vector3(0, 0.94, -0.13), Vector3(0.15, 0, 0), [[-0.13 * w, 0.06], [0.13 * w, 0.06], [0.1 * w, -0.12], [-0.1 * w, -0.12]], 0.02, "plate")


func _build_torso(upper: Node3D) -> void:
	var I := Transform3D.IDENTITY
	# Under-suit and three ribbed abdominal bands.
	f.loft(upper, I, [[-0.02, 0.16 * w, 0.11], [0.14, 0.17 * w, 0.12], [0.26, 0.2 * w, 0.13]], "void", 0.8)
	for i in 3:
		var y := 0.02 + i * 0.075
		f.loft(upper, I, [[y, (0.165 + i * 0.012) * w, 0.122 + i * 0.004], [y + 0.05, (0.172 + i * 0.012) * w, 0.128 + i * 0.004]], "mid", 0.6)
	# The breastplate, angular, with a raised ridge down its middle.
	f.loft(upper, I, [[0.24, 0.21 * w, 0.14], [0.32, 0.27 * w, 0.165, 0.01], [0.42, 0.3 * w, 0.18, 0.015], [0.5, 0.28 * w, 0.165], [0.56, 0.2 * w, 0.125]], "plate", 0.55, 16)
	_plate(upper, Vector3(0, 0.4, 0.19), Vector3(-0.08, 0, 0), [[-0.02, 0.14], [0.02, 0.14], [0.03, -0.12], [0.0, -0.16], [-0.03, -0.12]], 0.03, "lite")
	for s: float in [-1.0, 1.0]:
		_plate(upper, Vector3(s * 0.12 * w, 0.42, 0.17), Vector3(-0.12, s * 0.38, 0), _flip([[0.0, 0.1], [0.15, 0.07], [0.16, -0.03], [0.05, -0.1], [-0.01, -0.06]], s), 0.025, "mid")
		_trace(upper, Vector3(s * 0.05, 0.3, 0.165), Vector3(s * 0.13 * w, 0.18, 0.14))
		_trace(upper, Vector3(s * 0.13 * w, 0.18, 0.14), Vector3(s * 0.13 * w, 0.04, 0.135))
	# The core: what makes it one of the system's own.
	_plate(upper, Vector3(0, 0.33, 0.188), Vector3.ZERO, [[0.0, 0.055], [0.04, 0.0], [0.0, -0.055], [-0.04, 0.0]], 0.02, "red", 0.0)
	_trace(upper, Vector3(0, 0.27, 0.18), Vector3(0, 0.02, 0.135), 0.01)
	# Backplate with vent slats, and the collar.
	_plate(upper, Vector3(0, 0.4, -0.17), Vector3(0.1, 0, 0), [[-0.22 * w, 0.14], [0.22 * w, 0.14], [0.16 * w, -0.18], [-0.16 * w, -0.18]], 0.03, "mid")
	for i in 4:
		_box(upper, Vector3(0, 0.46 - i * 0.05, -0.19), Vector3(0.16 * w, 0.015, 0.02), "dim" if i % 2 == 0 else "void")
	f.loft(upper, I, [[0.54, 0.13, 0.1], [0.6, 0.12, 0.095], [0.64, 0.07, 0.065]], "mid", 0.7)


func _build_head(upper: Node3D) -> void:
	var I := Transform3D.IDENTITY
	var y := -0.03 if kind == "firewall" else 0.0
	if kind == "firewall":
		# A bucket helm: flat-topped, one narrow slit.
		f.loft(upper, I, [[0.6 + y, 0.12, 0.13], [0.68 + y, 0.14, 0.15], [0.84 + y, 0.14, 0.15], [0.88 + y, 0.12, 0.13]], "plate", 0.45, 12)
		_box(upper, Vector3(0, 0.77 + y, 0.142), Vector3(0.2, 0.022, 0.02), "red")
		for i in 4:
			_box(upper, Vector3(0, 0.69 + y - i * 0.0, 0.15) + Vector3((i - 1.5) * 0.045, 0, 0), Vector3(0.012, 0.06, 0.012), "void")
		_box(upper, Vector3(0, 0.89 + y, 0), Vector3(0.05, 0.03, 0.22), "lite")
		return
	f.loft(upper, I, [[0.6, 0.085, 0.09], [0.66, 0.11, 0.12], [0.75, 0.115, 0.125], [0.82, 0.1, 0.11], [0.87, 0.06, 0.07]], "plate", 0.7, 14)
	# A pointed faceplate, the visor slit across it and a cheek vent on each side.
	_plate(upper, Vector3(0, 0.71, 0.105), Vector3(0.1, 0, 0), [[-0.085, 0.07], [0.085, 0.07], [0.07, -0.03], [0.0, -0.09], [-0.07, -0.03]], 0.025, "mid")
	_box(upper, Vector3(0, 0.75, 0.122), Vector3(0.15, 0.018, 0.012), "red")
	if kind == "process":
		_box(upper, Vector3(0, 0.71, 0.124), Vector3(0.016, 0.07, 0.01), "red")
	for s: float in [-1.0, 1.0]:
		_plate(upper, Vector3(s * 0.11, 0.72, 0.03), Vector3(0, s * 1.3, 0), [[-0.04, 0.03], [0.04, 0.03], [0.03, -0.04], [-0.03, -0.04]], 0.015, "lite")
		_box(upper, Vector3(s * 0.112, 0.715, 0.03), Vector3(0.01, 0.035, 0.05), "dim")
	# A low fin from brow to nape.
	_plate(upper, Vector3(0, 0.85, -0.01), Vector3(0, PI * 0.5, 0), [[-0.1, 0.0], [0.08, 0.0], [0.04, 0.05], [-0.06, 0.035]], 0.02, "lite")


func _build_arm(upper: Node3D, s: float) -> void:
	var I := Transform3D.IDENTITY
	var suffix := "L" if s > 0.0 else "R"
	var big := w * (1.35 if kind == "firewall" else 1.0)
	var arm := _joint("arm" + suffix, upper, Vector3(s * 0.3 * w, 0.48, 0))
	_ball(arm, Vector3.ZERO, 0.06, "void")
	# A pauldron of three overlapping lames.
	f.limb(arm, I, Vector3(-s * 0.02, 0.07, 0), Vector3(s * 0.07, -0.1, 0), [[0.0, 0.1 * big, 0.11 * big], [0.45, 0.13 * big, 0.13 * big], [1.0, 0.1 * big, 0.11 * big]], "plate", 0.6)
	for i in 2:
		f.limb(arm, I, Vector3(s * (0.06 + i * 0.015), -0.1 - i * 0.05, 0), Vector3(s * (0.075 + i * 0.015), -0.15 - i * 0.05, 0), [[0.0, 0.1 * big, 0.11 * big], [1.0, 0.095 * big, 0.105 * big]], "mid", 0.6)
	_trace(arm, Vector3(s * 0.1 * big, 0.04, 0.09), Vector3(s * 0.13 * big, -0.08, 0.06))
	if kind == "firewall" or kind == "rootkit":
		for i in 3:
			var at := Vector3(s * (0.04 + i * 0.04) * big, 0.09 - i * 0.02, -0.03 + i * 0.03)
			f.limb(arm, I, at, at + Vector3(s * 0.05, 0.11 - i * 0.02, -0.02), [[0.0, 0.025, 0.02], [1.0, 0.002]], "gold" if kind == "rootkit" else "lite", 1.0, 5)
	f.limb(arm, I, Vector3.ZERO, Vector3(0, -0.3, 0), [[0.0, 0.055 * w], [1.0, 0.05 * w]], "void")
	f.limb(arm, I, Vector3(0, -0.12, 0), Vector3(0, -0.28, 0.005), [[0.0, 0.065 * w], [1.0, 0.058 * w]], "mid", 0.7)
	var fore := _joint("fore" + suffix, arm, Vector3(0, -0.32, 0))
	_ball(fore, Vector3.ZERO, 0.055, "void")
	_plate(fore, Vector3(0, 0.0, -0.06), Vector3(0, PI, 0), [[0.0, 0.07], [0.05, 0.0], [0.0, -0.06], [-0.05, 0.0]], 0.025, "lite")
	# Bracer, flared at the wrist, with a red stripe.
	f.limb(fore, I, Vector3(0, -0.03, 0), Vector3(0, -0.27, 0), [[0.0, 0.055 * big, 0.055 * big], [0.6, 0.07 * big, 0.068 * big], [1.0, 0.065 * big, 0.062 * big]], "plate", 0.65)
	_trace(fore, Vector3(s * 0.045 * big, -0.06, 0.04), Vector3(s * 0.05 * big, -0.25, 0.045))
	# The gauntlet: a back plate, a knuckle guard and four fingers.
	_box(fore, Vector3(0, -0.33, 0), Vector3(0.07 * big, 0.08, 0.075), "mid")
	_box(fore, Vector3(0, -0.36, 0.035), Vector3(0.075 * big, 0.025, 0.02), "lite")
	for i in 4:
		_box(fore, Vector3((i - 1.5) * 0.017 * big, -0.395, 0.02), Vector3(0.014, 0.05, 0.02), "void")


func _build_leg(s: float) -> void:
	var I := Transform3D.IDENTITY
	var suffix := "L" if s > 0.0 else "R"
	var leg := _joint("leg" + suffix, root_joint, Vector3(s * 0.11 * w, 1.0, 0))
	f.limb(leg, I, Vector3.ZERO, Vector3(0, -0.47, 0.02), [[0.0, 0.085 * w], [1.0, 0.065 * w]], "void")
	# Tasset hanging from the belt, and the cuisse over the front of the thigh.
	_plate(leg, Vector3(s * 0.04, -0.06, 0.06), Vector3(-0.1, 0, s * 0.18), [[-0.08 * w, 0.04], [0.08 * w, 0.04], [0.07 * w, -0.12], [-0.06 * w, -0.14]], 0.022, "mid")
	f.limb(leg, I, Vector3(0, -0.12, 0.035), Vector3(0, -0.42, 0.045), [[0.0, 0.075 * w, 0.06], [0.5, 0.08 * w, 0.065], [1.0, 0.065 * w, 0.05]], "plate", 0.6)
	_trace(leg, Vector3(s * 0.04 * w, -0.16, 0.1), Vector3(s * 0.035 * w, -0.38, 0.1))
	var shin := _joint("shin" + suffix, leg, Vector3(0, -0.47, 0.02))
	_ball(shin, Vector3.ZERO, 0.06, "void")
	# A pointed knee cop.
	_plate(shin, Vector3(0, 0.02, 0.08), Vector3(-0.15, 0, 0), [[0.0, 0.08], [0.06, 0.02], [0.04, -0.06], [0.0, -0.09], [-0.04, -0.06], [-0.06, 0.02]], 0.03, "lite")
	f.limb(shin, I, Vector3.ZERO, Vector3(0, -0.42, -0.02), [[0.0, 0.065 * w], [1.0, 0.05 * w]], "void")
	f.limb(shin, I, Vector3(0, -0.06, 0.015), Vector3(0, -0.38, 0.0), [[0.0, 0.072 * w, 0.07], [0.4, 0.078 * w, 0.075], [1.0, 0.06 * w, 0.058]], "plate", 0.6)
	_plate(shin, Vector3(0, -0.2, 0.08), Vector3(0.05, 0, 0), [[-0.015, 0.12], [0.015, 0.12], [0.02, -0.12], [-0.02, -0.12]], 0.02, "mid")
	_trace(shin, Vector3(s * 0.05 * w, -0.1, 0.05), Vector3(s * 0.045 * w, -0.34, 0.04))
	var foot := _joint("foot" + suffix, shin, Vector3(0, -0.42, -0.02))
	# Sabaton: a heel, three overlapping plates and a pointed toe.
	f.limb(foot, I, Vector3(0, -0.06, -0.08), Vector3(0, -0.06, 0.08), [[0.0, 0.065 * w, 0.06], [1.0, 0.07 * w, 0.055]], "void", 0.8, 8)
	for i in 3:
		_box(foot, Vector3(0, -0.035 + i * 0.012, 0.05 + i * 0.045), Vector3(0.13 * w, 0.03, 0.06), "mid" if i % 2 == 0 else "plate", Vector3(0.25, 0, 0))
	_plate(foot, Vector3(0, -0.07, 0.2), Vector3(PI * 0.5, 0, 0), [[-0.06 * w, -0.05], [0.06 * w, -0.05], [0.0, 0.06]], 0.04, "plate")


# ------------------------------------------------------------------- weapons

func _stance_inverse(arm: String, fore: String) -> Basis:
	var ready_pose := Basis.from_euler(stance[arm], EULER_ORDER_XYZ) * Basis.from_euler(stance[fore], EULER_ORDER_XYZ)
	return ready_pose.inverse()


func _build_sword(length: float, width: float) -> void:
	var holder := Node3D.new()
	holder.name = "Sword"
	holder.transform = Transform3D(_stance_inverse("armR", "foreR") * Basis.from_euler(Vector3(-0.35, 0, 0), EULER_ORDER_XYZ), Vector3.ZERO)
	var hand := _joint("hand_R", joints["foreR"], Vector3(0, -0.36, 0))
	hand.add_child(holder)
	var I := Transform3D.IDENTITY
	# Grip wrapped in bands, a pommel, and a swept crossguard.
	f.limb(holder, I, Vector3(0, 0, -0.17), Vector3(0, 0, 0.12), [[0.0, 0.024], [1.0, 0.024]], "void", 1.0, 8)
	for i in 4:
		f.limb(holder, I, Vector3(0, 0, -0.12 + i * 0.06), Vector3(0, 0, -0.1 + i * 0.06), [[0.0, 0.029], [1.0, 0.029]], "mid", 1.0, 8)
	_ball(holder, Vector3(0, 0, -0.19), 0.04, "lite" if kind != "rootkit" else "gold")
	var guard := [[-0.18 - width, 0.03], [-0.05, 0.0], [0.05, 0.0], [0.18 + width, 0.03], [0.14 + width, -0.03], [-0.14 - width, -0.03]]
	_plate(holder, Vector3(0, 0, 0.14), Vector3(PI * 0.5, 0, 0), guard, 0.05, "plate" if kind != "rootkit" else "gold")
	# A dark spine with the glowing edge set into it.
	var blade := [[-width, 0.0], [width, 0.0], [width * 0.85, length - width * 2.8], [0.0, length], [-width * 0.85, length - width * 2.8]]
	var core := [[-width * 0.45, 0.04], [width * 0.45, 0.04], [width * 0.35, length - width * 3.4], [0.0, length - width * 0.6], [-width * 0.35, length - width * 3.4]]
	_plate(holder, Vector3(0, 0, 0.16), Vector3(PI * 0.5, 0, 0), blade, 0.03, "plate", 0.004)
	_plate(holder, Vector3(0, 0, 0.16), Vector3(PI * 0.5, 0, 0), core, 0.036, "red", 0.0)
	blade_tip = Node3D.new()
	blade_tip.position = Vector3(0, 0, 0.16 + length)
	holder.add_child(blade_tip)


## FIREWALL: a frame of hexagons holding a wall of red light, carried on the left arm.
func _build_shield() -> void:
	_shield = Node3D.new()
	_shield.name = "Shield"
	_shield.transform = Transform3D(_stance_inverse("armL", "foreL"), Vector3(0, -0.2, 0))
	joints["foreL"].add_child(_shield)
	var outline := [[-0.3, 0.95], [0.4, 0.95], [0.72, 0.42], [0.72, -0.5], [0.22, -1.0], [-0.3, -1.0], [-0.72, -0.5], [-0.72, 0.42]]
	_plate(_shield, Vector3(0, 0, 0.2), Vector3.ZERO, outline, 0.02, "shield", 0.0)
	for i in outline.size():
		var a: Array = outline[i]
		var b: Array = outline[(i + 1) % outline.size()]
		f.limb(_shield, Transform3D.IDENTITY, Vector3(a[0], a[1], 0.22), Vector3(b[0], b[1], 0.22), [[0.0, 0.05, 0.035], [1.0, 0.05, 0.035]], "plate", 0.6, 6)
		_ball(_shield, Vector3(a[0], a[1], 0.24), 0.05, "mid")
	# A honeycomb of light across the face.
	for row in range(-3, 4):
		for col in range(-2, 3):
			var x := col * 0.26 + (0.13 if row % 2 != 0 else 0.0)
			var y := row * 0.23
			if absf(x) > 0.55 or y > 0.78 or y < -0.8:
				continue
			var hex := []
			for k in 6:
				var a := k * TAU / 6.0 + PI / 6.0
				hex.append([x + cos(a) * 0.11, y + sin(a) * 0.11])
			_plate(_shield, Vector3(0, 0, 0.214), Vector3.ZERO, hex, 0.006, "dim", 0.0)
	_plate(_shield, Vector3(0, 0, 0.25), Vector3.ZERO, [[0.0, 0.22], [0.15, 0.0], [0.0, -0.22], [-0.15, 0.0]], 0.04, "plate")
	_plate(_shield, Vector3(0, 0, 0.275), Vector3.ZERO, [[0.0, 0.12], [0.08, 0.0], [0.0, -0.12], [-0.08, 0.0]], 0.02, "red", 0.0)


func set_shield(on: bool) -> void:
	if _shield != null:
		_shield.visible = on


# ------------------------------------------------------------------ the others

## ROOTKIT: a crown, a mantle of shard wings and a cape torn into strips.
func _build_rootkit(upper: Node3D) -> void:
	var I := Transform3D.IDENTITY
	f.loft(upper, I, [[0.82, 0.1, 0.11], [0.86, 0.105, 0.115]], "gold", 0.8)
	for i in 7:
		var a := -1.2 + i * 0.4
		var base := Vector3(sin(a) * 0.1, 0.85, cos(a) * 0.11)
		var tall := 0.17 - absf(a) * 0.05
		f.limb(upper, I, base, base + Vector3(sin(a) * 0.05, tall, cos(a) * 0.02), [[0.0, 0.022, 0.016], [1.0, 0.002]], "gold", 1.0, 5)
	_plate(upper, Vector3(0, 0.875, 0.112), Vector3.ZERO, [[0.0, 0.03], [0.02, 0.0], [0.0, -0.03], [-0.02, 0.0]], 0.012, "red", 0.0)
	# Shard wings fanning from the shoulder blades.
	for s: float in [-1.0, 1.0]:
		for i in 3:
			var spread := 0.5 + i * 0.42
			var length := 0.95 - i * 0.18
			var shard := [[0.0, -0.04], [length * 0.3, 0.06], [length, 0.0], [length * 0.3, -0.09]]
			_plate(upper, Vector3(s * 0.12, 0.44 - i * 0.04, -0.22 - i * 0.02), Vector3(-0.35, s * 0.35, s * spread), _flip(shard, s), 0.018, "plate" if i != 1 else "lite")
			_trace(upper, Vector3(s * 0.12, 0.44 - i * 0.04, -0.23 - i * 0.02), Vector3(s * 0.12, 0.44 - i * 0.04, -0.23 - i * 0.02) + Basis.from_euler(Vector3(-0.35, s * 0.35, s * spread), EULER_ORDER_XYZ) * Vector3(s * length * 0.8, 0, 0), 0.008)
	# Cape: seven tapered strips from the collar.
	for i in 7:
		var x := (i - 3) * 0.075 * w
		var long := 1.15 - absf(i - 3) * 0.08 + (0.1 if i % 2 == 0 else 0.0)
		var strip := [[-0.045, 0.0], [0.045, 0.0], [0.03, -long], [0.0, -long - 0.08], [-0.03, -long]]
		_plate(upper, Vector3(x, 0.56, -0.2 - absf(i - 3) * 0.01), Vector3(0.12, 0, (i - 3) * 0.06), strip, 0.012, "cape", 0.0)
	_box(upper, Vector3(0, 0.56, -0.19), Vector3(0.56 * w, 0.05, 0.04), "gold")


## DAEMON: a hooded head and mantle with no body under it, one great eye, claws and trailing cables.
func _build_daemon(upper: Node3D) -> void:
	var I := Transform3D.IDENTITY
	# The hood rises to a hooked point; the face inside it is empty.
	f.loft(upper, I, [[0.3, 0.27, 0.26], [0.5, 0.25, 0.25], [0.68, 0.2, 0.22, -0.02], [0.82, 0.12, 0.15, -0.06], [0.94, 0.03, 0.04, -0.13]], "void", 0.8, 16)
	f.loft(upper, I, [[0.36, 0.17, 0.06, 0.2], [0.62, 0.15, 0.06, 0.18], [0.72, 0.08, 0.04, 0.14]], "void", 0.9, 12)
	_plate(upper, Vector3(0, 0.6, 0.15), Vector3(0.1, 0, 0), [[-0.2, 0.15], [0.0, 0.25], [0.2, 0.15], [0.17, -0.2], [-0.17, -0.2]], 0.01, "plate")
	# The eye: a red core inside two broken rings.
	_ball(upper, Vector3(0, 0.5, 0.22), 0.07, "red")
	f.add(upper, MeshForge.xform(Vector3(0, 0.5, 0.21), Vector3(PI * 0.5, 0, 0)), MeshForge.torus_geo(0.12, 0.012, 6, 24), "dim", true)
	f.add(upper, MeshForge.xform(Vector3(0, 0.5, 0.2), Vector3(PI * 0.5, 0, 0)), MeshForge.torus_geo(0.17, 0.008, 6, 28), "red", true)
	# A mantle of layered plates, and the cloak below it in hanging strips.
	for i in 3:
		f.loft(upper, I, [[0.28 - i * 0.12, 0.3 + i * 0.03, 0.27 + i * 0.03], [0.34 - i * 0.12, 0.29 + i * 0.03, 0.26 + i * 0.03]], "plate" if i % 2 == 0 else "mid", 0.7, 16)
	for i in 10:
		var a := i * TAU / 10.0
		var long := 0.62 + (0.16 if i % 3 == 0 else 0.0)
		var strip := [[-0.07, 0.0], [0.07, 0.0], [0.04, -long], [0.0, -long - 0.1], [-0.04, -long]]
		_plate(upper, Vector3(sin(a) * 0.3, -0.02, cos(a) * 0.28), Vector3(0.12 * cos(a), a, -0.12 * sin(a)), strip, 0.012, "void", 0.0)
	for s: float in [-1.0, 1.0]:
		var suffix := "L" if s > 0.0 else "R"
		var arm := _joint("arm" + suffix, upper, Vector3(s * 0.31, 0.3, 0))
		f.limb(arm, I, Vector3.ZERO, Vector3(0, -0.38, 0), [[0.0, 0.045], [1.0, 0.035]], "plate")
		_plate(arm, Vector3(s * 0.04, -0.02, 0), Vector3(0, 0, s * 0.3), [[-0.06, 0.06], [0.07, 0.04], [0.06, -0.1], [-0.05, -0.08]], 0.03, "mid")
		var fore := _joint("fore" + suffix, arm, Vector3(0, -0.38, 0))
		_ball(fore, Vector3.ZERO, 0.04, "void")
		f.limb(fore, I, Vector3.ZERO, Vector3(0, -0.34, 0), [[0.0, 0.035], [1.0, 0.03]], "mid")
		_trace(fore, Vector3(s * 0.03, -0.04, 0.02), Vector3(s * 0.025, -0.3, 0.02), 0.008)
		# Three long claws curled around an orb of light.
		for k in 3:
			var a := (k - 1) * 1.2
			var base := Vector3(sin(a) * 0.035, -0.35, cos(a) * 0.035)
			f.limb(fore, I, base, base + Vector3(sin(a) * 0.08, -0.12, cos(a) * 0.08), [[0.0, 0.013], [1.0, 0.004]], "lite", 1.0, 5)
		_ball(fore, Vector3(0, -0.45, 0), 0.06, "red")
	blade_tip = joints["foreR"]
	for i in 6:
		var a := i * TAU / 6.0 + 0.3
		var tail := Node3D.new()
		tail.position = Vector3(sin(a) * 0.16, 0.36, cos(a) * 0.14)
		root_joint.add_child(tail)
		f.limb(tail, I, Vector3.ZERO, Vector3(0, -0.62, 0), [[0.0, 0.028], [1.0, 0.018]], "mid", 1.0, 6)
		for k in 3:
			_ball(tail, Vector3(0, -0.15 - k * 0.17, 0), 0.03, "plate")
		_ball(tail, Vector3(0, -0.66, 0), 0.03, "red")
		_tails.append(tail)
	for i in 2:
		var ring := Node3D.new()
		ring.position = Vector3(0, 1.45, 0)
		root_joint.add_child(ring)
		f.add(ring, MeshForge.xform(Vector3.ZERO, Vector3(PI * 0.5 + 0.3 * (i * 2 - 1), 0, 0)), MeshForge.torus_geo(0.52 + i * 0.12, 0.008, 5, 36), "dim", true)
		_rings.append(ring)
	_orb_light = OmniLight3D.new()
	_orb_light.light_color = Color(1.0, 0.1, 0.16)
	_orb_light.omni_range = 5.0
	_orb_light.light_energy = 2.0
	_orb_light.position = Vector3(0, 0.5, 0.5)
	upper.add_child(_orb_light)


func flash_hit() -> void:
	_flash = 1.0


func _process(delta: float) -> void:
	update_pose(delta)
	if kind == "daemon":
		root_joint.position.y += 0.72 + sin(_clock * 1.7) * 0.08
		for i in _tails.size():
			_tails[i].rotation = Vector3(sin(_clock * 1.3 + i) * 0.25, 0, sin(_clock * 0.9 + i * 1.7) * 0.22)
		for i in _rings.size():
			_rings[i].rotation.y = _clock * (0.6 if i == 0 else -0.4)
		_orb_light.light_energy = 2.0 + sin(_clock * 7.0) * 0.6
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 6.0)
		for m in _toons:
			m.set_shader_parameter("flash", _flash * 0.5)
