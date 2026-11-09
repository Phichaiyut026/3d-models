class_name SentinelModel
extends PoseRig
## Hooded gold-shield soldier of the valley. Built in metres, arms hanging straight.

var blade_tip: Node3D
var _materials := {}
var _flash := 0.0


func _init(boss := false) -> void:
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
	var forge := MeshForge.new(_make_materials(boss))
	_build(forge, boss)
	forge.commit()


func _surface(color: Color, metallic: float, roughness: float, emission := Color.BLACK) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 3.0
	return m


func _make_materials(boss: bool) -> Dictionary:
	_materials = {
		"cloth": _surface(Color(0.62, 0.51, 0.36) if not boss else Color(0.34, 0.12, 0.14), 0.0, 0.95),
		"cloth_dark": _surface(Color(0.23, 0.17, 0.12), 0.0, 0.95),
		"steel": _surface(Color(0.3, 0.3, 0.32) if not boss else Color(0.55, 0.42, 0.18), 0.85, 0.5),
		"gold": _surface(Color(0.8, 0.6, 0.2), 0.95, 0.42),
		"dark": _surface(Color(0.06, 0.05, 0.05), 0.2, 0.8),
		"leather": _surface(Color(0.18, 0.12, 0.08), 0.0, 0.85),
		"ember": _surface(Color(1.0, 0.65, 0.2), 0.0, 0.5, Color(1.0, 0.55, 0.12)),
	}
	return _materials


func _joint(joint_name: String, parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	register(joint_name, node)
	node.position = pos
	parent.add_child(node)
	return node


func _build(f: MeshForge, boss: bool) -> void:
	var I := Transform3D.IDENTITY
	root_joint = Node3D.new()
	root_joint.name = "Root"
	root_joint.rotation_order = EULER_ORDER_XYZ
	add_child(root_joint)
	var root := root_joint
	var upper := _joint("upper", root, Vector3(0, 1.02, 0))

	# Hips, tabard and belt.
	f.loft(root, I, [[0.86, 0.12, 0.12], [1.02, 0.25, 0.17], [1.14, 0.27, 0.18]], "leather", 0.8)
	f.loft(upper, I, [[0.0, 0.26, 0.17], [0.26, 0.28, 0.19], [0.5, 0.33, 0.22], [0.6, 0.2, 0.15]], "steel", 0.75)
	f.loft(upper, I, [[0.0, 0.285, 0.195], [0.06, 0.285, 0.195]], "gold", 0.75)
	f.plate(upper, MeshForge.xform(Vector3(0, 0, 0.19)), [[-0.22, 0.48], [0.22, 0.48], [0.25, -0.42], [0.0, -0.62], [-0.25, -0.42]], 0.03, "cloth")
	f.plate(upper, MeshForge.xform(Vector3(0, 0, -0.2)), [[-0.26, 0.5], [0.26, 0.5], [0.36, -0.68], [-0.36, -0.68]], 0.03, "cloth")
	f.plate(upper, MeshForge.xform(Vector3(0, 0.06, 0.21)), MeshForge.star4(0.1), 0.02, "gold")

	# Hood and shadowed face.
	f.loft(upper, I, [[0.56, 0.17, 0.17], [0.64, 0.24, 0.24, -0.03], [0.82, 0.22, 0.25, -0.03], [0.98, 0.13, 0.17, -0.07], [1.1, 0.02, 0.03, -0.14]], "cloth", 0.9, 12)
	f.loft(upper, I, [[0.66, 0.15, 0.09, 0.14], [0.82, 0.15, 0.09, 0.14], [0.9, 0.09, 0.05, 0.13]], "dark", 0.9, 10)
	for s: float in [-1.0, 1.0]:
		f.plate(upper, MeshForge.xform(Vector3(s * 0.07, 0.78, 0.235)), [[-0.035, -0.012], [0.035, -0.012], [0.03, 0.012], [-0.03, 0.012]], 0.01, "ember")
	if boss:
		for i in 7:
			var a := -0.9 + i * 0.3
			var base := Vector3(sin(a) * 0.2, 1.0, cos(a) * 0.22 - 0.05)
			f.limb(upper, I, base, base + Vector3(sin(a) * 0.08, 0.32 + 0.1 * cos(a * 2.0), cos(a) * 0.05), [[0.0, 0.05, 0.03], [1.0, 0.004]], "gold", 1.0, 6)
		f.plate(upper, MeshForge.xform(Vector3(0, 0.4, 0.25)), MeshForge.star4(0.3, 0.07, 0.34), 0.04, "gold", 0.01)

	for s: float in [-1.0, 1.0]:
		var suffix := "L" if s > 0.0 else "R"
		var arm := _joint("arm" + suffix, upper, Vector3(s * 0.4, 0.46, 0))
		f.add(arm, I, MeshForge.sphere_geo(0.14, 10, 8), "steel", true)
		f.limb(arm, I, Vector3.ZERO, Vector3(0, -0.34, 0), [[0.0, 0.09], [1.0, 0.075]], "cloth_dark")
		var fore := _joint("fore" + suffix, arm, Vector3(0, -0.34, 0))
		f.limb(fore, I, Vector3.ZERO, Vector3(0, -0.3, 0), [[0.0, 0.08], [0.2, 0.095], [1.0, 0.07]], "steel")
		f.add(fore, MeshForge.xform(Vector3(0, -0.36, 0)), MeshForge.sphere_geo(0.075, 8, 6), "leather", true)

		var leg := _joint("leg" + suffix, root, Vector3(s * 0.15, 1.0, 0))
		f.limb(leg, I, Vector3.ZERO, Vector3(0, -0.47, 0.02), [[0.0, 0.13], [1.0, 0.09]], "cloth_dark")
		var shin := _joint("shin" + suffix, leg, Vector3(0, -0.47, 0.02))
		f.add(shin, MeshForge.xform(Vector3(0, 0.0, 0.06)), MeshForge.sphere_geo(0.095, 8, 6), "steel", true)
		f.limb(shin, I, Vector3.ZERO, Vector3(0, -0.42, -0.02), [[0.0, 0.09], [0.4, 0.1], [1.0, 0.07]], "steel")
		var foot := _joint("foot" + suffix, shin, Vector3(0, -0.42, -0.02))
		f.limb(foot, I, Vector3(0, -0.07, -0.1), Vector3(0, -0.07, 0.24), [[0.0, 0.08, 0.06], [0.5, 0.095, 0.07], [1.0, 0.06, 0.04]], "leather", 0.8, 8)

	_build_shield(f)
	_build_sword(f, boss)


func _stance_inverse(arm: String, fore: String) -> Basis:
	var ready_pose := Basis.from_euler(stance[arm], EULER_ORDER_XYZ) * Basis.from_euler(stance[fore], EULER_ORDER_XYZ)
	return ready_pose.inverse()


## Round gold shield. It is mounted facing forward in the guard stance.
func _build_shield(f: MeshForge) -> void:
	var holder := Node3D.new()
	holder.name = "Shield"
	holder.transform = Transform3D(_stance_inverse("armL", "foreL"), Vector3(0, -0.2, 0.0))
	joints["foreL"].add_child(holder)
	var out := MeshForge.xform(Vector3(0, 0, 0.16), Vector3(PI * 0.5, 0, 0))
	f.add(holder, out, MeshForge.cylinder_geo(0.6, 0.64, 0.05, 28), "gold")
	f.add(holder, out * MeshForge.xform(Vector3(0, 0.035, 0)), MeshForge.cylinder_geo(0.5, 0.55, 0.03, 28), "steel")
	f.add(holder, MeshForge.xform(Vector3(0, 0, 0.215)), MeshForge.shape_geo(MeshForge.star4(0.46, 0.09, 0.46), 0.03), "gold")
	f.add(holder, MeshForge.xform(Vector3(0, 0, 0.23)), MeshForge.sphere_geo(0.11, 10, 8), "gold", true)
	f.add(holder, MeshForge.xform(Vector3(0, 0, 0.17)), MeshForge.torus_geo(0.62, 0.04, 6, 28), "gold", true)


func _build_sword(f: MeshForge, boss: bool) -> void:
	var holder := Node3D.new()
	holder.name = "Sword"
	holder.transform = Transform3D(_stance_inverse("armR", "foreR") * Basis.from_euler(Vector3(-0.35, 0, 0), EULER_ORDER_XYZ), Vector3.ZERO)
	var hand := _joint("hand_R", joints["foreR"], Vector3(0, -0.36, 0))
	hand.add_child(holder)
	var I := Transform3D.IDENTITY
	var length := 1.75 if boss else 1.15
	var width := 0.09 if boss else 0.05
	f.limb(holder, I, Vector3(0, 0, -0.17), Vector3(0, 0, 0.12), [[0.0, 0.03], [1.0, 0.03]], "leather", 1.0, 8)
	f.add(holder, MeshForge.xform(Vector3(0, 0, 0.13)), MeshForge.box_geo(0.34 + width, 0.05, 0.06), "gold")
	var blade := [[-width, 0.0], [width, 0.0], [width * 0.8, length - width * 2.5], [0.0, length], [-width * 0.8, length - width * 2.5]]
	f.plate(holder, MeshForge.xform(Vector3(0, 0, 0.14), Vector3(PI * 0.5, 0, 0)), blade, 0.022, "steel", 0.008)
	blade_tip = Node3D.new()
	blade_tip.position = Vector3(0, 0, 0.14 + length)
	holder.add_child(blade_tip)


func flash_hit() -> void:
	_flash = 1.0


func _process(delta: float) -> void:
	update_pose(delta)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 6.0)
		for key: String in ["cloth", "steel", "gold"]:
			var m: StandardMaterial3D = _materials[key]
			m.emission_enabled = _flash > 0.0
			m.emission = Color(1.0, 0.85, 0.6)
			m.emission_energy_multiplier = _flash * 1.5
