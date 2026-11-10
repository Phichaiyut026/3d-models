class_name CosmicWarrior
extends PoseRig
## The player's body: a direct port of the Cosmic Warrior model from
## cosmic_warrior.html, split into joints so it can fight.

const TOON := preload("res://shaders/toon.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")
const COSMIC := preload("res://shaders/cosmic.gdshader")
const FLAT := preload("res://shaders/flat.gdshader")
const GLOW := preload("res://shaders/glow.gdshader")
const FLAME := preload("res://shaders/flame.gdshader")
const AURA := preload("res://shaders/blade_aura.gdshader")
const WING := preload("res://shaders/cosmic_wing.gdshader")
const STAR := preload("res://shaders/star_spark.gdshader")
const GOD_RAYS := preload("res://shaders/god_rays.gdshader")
const MANDALA := preload("res://shaders/mandala.gdshader")

const MODEL_SCALE := 0.36
const GRIP_ANGLE := 0.75
const BLADE_LENGTH := 3.5
const SUPREME_SCALE := 1.9 ## The same growth as the web model.
const GLOW_GOLD := {0x5f8dff: 0xffd98a, 0x8fb8ff: 0xffe3a0, 0x4d6cff: 0xffc24d, 0x7fc8ff: 0xffe6b0}
# Upright and loose in the air, and stretched out at speed.
const FLY_HOVER := {
	"legL": Vector3(-0.22, 0, 0.04), "shinL": Vector3(0.42, 0, 0), "footL": Vector3(0.6, 0, 0),
	"legR": Vector3(0.1, 0, -0.04), "shinR": Vector3(0.3, 0, 0), "footR": Vector3(0.55, 0, 0),
	"root": Vector3.ZERO, "upper": Vector3(0.02, 0, 0),
	"armR": Vector3(-0.2, 0, -0.42), "foreR": Vector3(-0.45, 0, 0), "hand_R": Vector3.ZERO,
	"armL": Vector3(-0.2, 0, 0.42), "foreL": Vector3(-0.45, 0, 0),
}
const FLY_FAST := {
	"legL": Vector3(0.08, 0, 0.02), "shinL": Vector3(0.18, 0, 0), "footL": Vector3(0.9, 0, 0),
	"legR": Vector3(0.24, 0, -0.02), "shinR": Vector3(0.34, 0, 0), "footR": Vector3(0.9, 0, 0),
	"root": Vector3.ZERO, "upper": Vector3(-0.42, 0, 0),
	"armR": Vector3(0.55, 0, -0.16), "foreR": Vector3(-0.12, 0, 0), "hand_R": Vector3.ZERO,
	"armL": Vector3(0.55, 0, 0.16), "foreL": Vector3(-0.12, 0, 0),
}
const ORBIT_HUES := [0xff6ad5, 0x6ae0ff, 0xffd86a, 0x8dff9a, 0xb08cff]
# The supreme form stands at ease, hands open: it has no need to raise them.
const GOD_IDLE := {
	"legL": Vector3(-0.08, 0, 0.03), "shinL": Vector3(0.16, 0, 0),
	"legR": Vector3(0.04, 0, -0.03), "shinR": Vector3(0.22, 0, 0),
	"root": Vector3.ZERO,
	"upper": Vector3(-0.03, 0, 0),
	"armR": Vector3(-0.14, 0, -0.26), "foreR": Vector3(-0.62, 0, 0), "hand_R": Vector3.ZERO,
	"armL": Vector3(-0.14, 0, 0.26), "foreL": Vector3(-0.62, 0, 0),
}

const ARMED_STANCE := {"armR": Vector3(-0.3, 0, 0.42), "foreR": Vector3(-0.95, 0, 0), "hand_R": Vector3(-0.35, 0, 0)}
# Sprinting with the blade swept out behind, clear of the legs.
const ARMED_RUN := {"armR": Vector3(1.0, 0, 0.42), "foreR": Vector3(-0.2, 0, 0), "hand_R": Vector3(1.25, 0, 0)}
# Planted wide and low, shoulders squared, blade held out low and ready.
const ARMED_IDLE := {
	"legL": Vector3(-0.5, 0, 0.04), "shinL": Vector3(0.72, 0, 0),
	"legR": Vector3(0.3, 0, -0.1), "shinR": Vector3(0.62, 0, 0),
	"root": Vector3(0.05, 0.22, 0),
	"upper": Vector3(0.14, -0.3, 0),
	"armR": Vector3(-0.08, 0, -0.12), "foreR": Vector3(-0.4, 0, 0), "hand_R": Vector3(-0.32, 0, -0.55),
	"armL": Vector3(-0.42, 0, -0.42), "foreL": Vector3(-1.15, 0, 0),
}
# Empty-handed: upright and at ease, arms loose at the sides.
const UNARMED_IDLE := {
	"legL": Vector3(-0.14, 0, 0.02), "shinL": Vector3(0.24, 0, 0),
	"legR": Vector3(0.08, 0, -0.02), "shinR": Vector3(0.2, 0, 0),
	"root": Vector3.ZERO,
	"upper": Vector3(0.03, 0, 0),
	"armR": Vector3(-0.08, 0, 0.14), "foreR": Vector3(-0.38, 0, 0), "hand_R": Vector3.ZERO,
	"armL": Vector3(-0.08, 0, -0.14), "foreL": Vector3(-0.38, 0, 0),
}

var forge: MeshForge
var blade_base: Node3D
var blade_tip: Node3D
var shield_flash: MeshInstance3D

var _edge: ShaderMaterial
var _aura: ShaderMaterial
var _blade_light: OmniLight3D
var _sparks: CPUParticles3D
var _blade_power := 0.0
var _blade_goal := 0.0

var is_armed := false
var is_supreme := false
var _body: Node3D
var _god_nodes: Array[Node3D] = []
var _form_swaps: Array = [] ## [material, parameter, first form value, supreme value]
var _suit: ShaderMaterial
var _nebula: Texture2D
var _infinity: Node3D
var _armillary: Node3D
var _orbits: Array = [] ## [spinning node, speed]
var _rays: ShaderMaterial
var _scale_goal := 1.0
var _hover := 0.0
var _blade_growth := 0.0
var _flying := false
var _fly_goal := 0.0
var _fly_pace := 0.0
var _tilt := 0.0
var _mandala_node: Node3D
var _holder: Node3D
var _reveal_point: Node3D
var _draw_sparks: CPUParticles3D
var _rift: SpaceRift
var _rift_image: ImageTexture
var _blade_materials: Array[ShaderMaterial] = []
var _draw_mode := "" ## summon, sheathe or empty
var _draw_time := 0.0
var _draw_length := 1.0
var _portal := Vector3.ZERO
var _reveal := 1000.0
var _burst_done := false

var _wing_materials: Array[ShaderMaterial] = []
var _wing_rim: ShaderMaterial
var _wing_inner := {}
var _thrusters: Array[ShaderMaterial] = []
var _sweep := 0.0
var _sweep_speed := 0.0
var _lift := 0.0
var _lift_speed := 0.0
var _charge := 0.0
var _hit_jolt := 0.0

var _wings := {}
var _hand_materials: Array[ShaderMaterial] = []
var _all_toon: Array[ShaderMaterial] = []
var _flames: Array[ShaderMaterial] = []
var _hand_lights: Array[OmniLight3D] = []
var _energy := 0.0
var _energy_goal := 0.0
var _flap := 0.0
var _flash := 0.0


func _init() -> void:
	unit = 2.6
	pivot = Vector3(0, 2.6, 0)
	thigh = 1.01
	shin_length = 1.09
	leg_metres = (thigh + shin_length) * MODEL_SCALE
	forge = MeshForge.new(_make_materials())
	_build()
	_build_supreme()
	forge.commit()
	_clone_wings()
	forge = null
	set_armed_instant(false)


func _make_materials() -> Dictionary:
	var outline := _hull(Color.hex(0x120a3aff), 0.02)
	var rim := _hull(Color.hex(0x4a27b0ff), 0.05)
	_wing_rim = rim
	var blade_outline := _hull(Color.hex(0x120a3aff), 0.02)
	var nebula := ImageTexture.create_from_image(AstralTerrain.make_nebula_tile(512, 11))
	_nebula = nebula
	var wing_image := ImageTexture.create_from_image(AstralTerrain.make_wing_image(1024, 23))

	var cosmic := ShaderMaterial.new()
	cosmic.shader = COSMIC
	cosmic.set_shader_parameter("nebula", nebula)
	cosmic.set_shader_parameter("u_scale", MeshForge.TILE)
	cosmic.next_pass = outline
	var wing := ShaderMaterial.new()
	wing.shader = WING
	wing.set_shader_parameter("nebula", wing_image)
	wing.next_pass = rim
	_wing_materials = [wing]
	_rift_image = wing_image

	var blade_cosmic := ShaderMaterial.new()
	blade_cosmic.shader = COSMIC
	blade_cosmic.set_shader_parameter("nebula", nebula)
	blade_cosmic.set_shader_parameter("u_scale", MeshForge.TILE)
	blade_cosmic.next_pass = blade_outline
	var blade_deep := _toon(0x35197f, blade_outline)
	var blade_lite := _toon(0x7450e4, blade_outline)
	var blade_ice := _flat(0xc4ecff, 1.8)

	var hand_suit := _toon(0x211d6a, outline)
	var hand_deep := _toon(0x35197f, outline)
	_hand_materials = [hand_suit, hand_deep]
	_edge = _flat(0xc4ecff, 1.8)
	_blade_materials = [blade_cosmic, blade_outline, blade_deep, blade_lite, blade_ice, _edge]
	var made := {
		"armor": _toon(0x4f2db4, outline), "lite": _toon(0x7450e4, outline), "deep": _toon(0x35197f, outline),
		"suit": _toon(0x211d6a, outline), "sole": _toon(0x241254, outline),
		"handSuit": hand_suit, "handDeep": hand_deep,
		"cosmic": cosmic, "wing": wing,
		"white": _flat(0xffffff, 2.2), "ice": _flat(0xc4ecff, 1.8), "line": _flat(0xbfdcff, 1.6), "neon": _flat(0x6f8dff, 1.8),
		"god_gold": _flat(0xf4c95d, 1.5),
		"blade_edge": _edge, "blade_cosmic": blade_cosmic, "blade_deep": blade_deep, "blade_lite": blade_lite, "blade_ice": blade_ice,
	}
	_suit = made["suit"]
	# The new palette from cosmic_warrior.html: white and gold over the night sky.
	for pair: Array in [["armor", 0xf0ecff], ["lite", 0xf4c95d], ["deep", 0x1c1450], ["sole", 0xb88a2c], ["handSuit", 0xf0ecff], ["handDeep", 0xf4c95d], ["blade_deep", 0x1c1450], ["blade_lite", 0xf4c95d]]:
		_remember(made[pair[0]], "albedo", pair[1])
	for pair: Array in [["ice", 0xfff6d8], ["line", 0xfff2c4], ["neon", 0xffe9a8], ["blade_ice", 0xfff6d8], ["blade_edge", 0xfff6d8]]:
		_remember(made[pair[0]], "color", pair[1])
	_remember(rim, "color", 0xf4c95d)
	_remember(hand_suit, "emissive", 0xffd98a)
	_remember(hand_deep, "emissive", 0xffd98a)
	return made


func _remember(material: ShaderMaterial, parameter: String, supreme_hex: int) -> void:
	_form_swaps.append([material, parameter, material.get_shader_parameter(parameter), Color.hex((supreme_hex << 8) | 0xff)])


func _hull(color: Color, thickness: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = OUTLINE
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("thickness", thickness)
	return m


func _toon(hex: int, outline: ShaderMaterial) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = TOON
	m.set_shader_parameter("albedo", Color.hex((hex << 8) | 0xff))
	m.next_pass = outline
	_all_toon.append(m)
	return m


func _flat(hex: int, boost: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FLAT
	m.set_shader_parameter("color", Color.hex((hex << 8) | 0xff))
	m.set_shader_parameter("boost", boost)
	return m


func _glow(parent: Node3D, xf: Transform3D, size: float, hex: int, strength := 1.0) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var m := ShaderMaterial.new()
	m.shader = GLOW
	m.set_shader_parameter("color", Color.hex((hex << 8) | 0xff))
	m.set_shader_parameter("strength", strength)
	if GLOW_GOLD.has(hex):
		_remember(m, "color", GLOW_GOLD[hex])
	quad.material = m
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.transform = xf
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)


func _child_joint(joint_name: String, parent: Node3D, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	register(joint_name, node)
	node.position = pos
	parent.add_child(node)
	return node


func _build() -> void:
	var body := Node3D.new()
	body.scale = Vector3.ONE * MODEL_SCALE
	add_child(body)
	_body = body
	root_joint = Node3D.new()
	root_joint.name = "Root"
	root_joint.rotation_order = EULER_ORDER_XYZ
	body.add_child(root_joint)
	var root := root_joint
	var upper := _child_joint("upper", root, Vector3.ZERO)

	_build_helmet(upper)
	_build_torso(root, upper)
	_build_wings(upper)
	for s: float in [-1.0, 1.0]:
		_build_arm(upper, s)
		_build_leg(root, s)
	_build_blade(joints["hand_R"])
	_build_shield_flash(joints["foreL"])


func _build_helmet(upper: Node3D) -> void:
	var f := forge
	var I := Transform3D.IDENTITY
	var center := Vector2(0.0, 4.72)
	var rim: Array[Vector2] = [Vector2(1.05, 4.76), Vector2(0.3, 4.93), Vector2(0, 5.73), Vector2(-0.3, 4.93), Vector2(-1.05, 4.76), Vector2(-0.42, 4.42), Vector2(0, 3.97), Vector2(0.42, 4.42)]
	var ring := func(k: float, z: float) -> Array:
		var out := []
		for p in rim:
			out.append(Vector3(center.x + (p.x - center.x) * k, center.y + (p.y - center.y) * k, z))
		return out
	var shell := func(outer: Array, inner: Array, flip: bool) -> PackedVector3Array:
		var v := PackedVector3Array()
		for i in 8:
			var j := (i + 1) % 8
			var a: Vector3 = outer[i]
			var b: Vector3 = outer[j]
			var c: Vector3 = inner[j]
			var d: Vector3 = inner[i]
			if flip:
				v.append_array([a, c, b, a, d, c])
			else:
				v.append_array([a, b, c, a, c, d])
		return v
	var raw := func(tris: PackedVector3Array) -> MeshForge.Geo:
		var g := MeshForge.Geo.new()
		g.points = tris
		return g

	var r0: Array = ring.call(1.0, 0.0)
	var r1: Array = ring.call(0.87, 0.2)
	var r2: Array = ring.call(0.5, 0.52)
	var r3: Array = ring.call(0.001, 0.62)
	f.add(upper, I, raw.call(shell.call(r0, r1, false)), "lite")
	var face: PackedVector3Array = shell.call(r1, r2, false)
	face.append_array(shell.call(r2, r3, false))
	f.add(upper, I, raw.call(face), "cosmic")

	# The rear stays shallow before the spike, which gives the concave star profile from the side.
	var waist: Array = ring.call(0.38, -0.2)
	var apex: Array = ring.call(0.001, -0.9)
	var rear: PackedVector3Array = shell.call(r0, waist, true)
	rear.append_array(shell.call(waist, apex, true))
	f.add(upper, I, raw.call(rear), "armor")

	for s: float in [-1.0, 1.0]:
		var pts := []
		for q: Array in [[-0.15, -0.075], [0.06, -0.075], [0.17, 0.085], [-0.03, 0.085]]:
			pts.append([s * q[0], q[1]])
		var eye := MeshForge.xform(Vector3(s * 0.24, 4.66, 0.61), Vector3(0, s * 0.3, 0))
		f.add(upper, eye, MeshForge.shape_geo(pts, 0.02), "white")
		_glow(upper, eye * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.02)), 0.9, 0x5f8dff, 0.9)


# ------------------------------------------------------------- the supreme form

func _god_node(parent: Node3D, pos := Vector3.ZERO) -> Node3D:
	var node := Node3D.new()
	node.position = pos
	node.visible = false
	node.rotation_order = EULER_ORDER_XYZ
	parent.add_child(node)
	_god_nodes.append(node)
	return node


## Everything the new form wears that the first does not, hidden until the change.
func _build_supreme() -> void:
	var f := forge
	var I := Transform3D.IDENTITY
	var upper: Node3D = joints["upper"]
	var dress := _god_node(upper)

	# A star crown over the helmet, and the sign of infinity above it.
	f.add(dress, MeshForge.xform(Vector3(0, 5.98, -0.05), Vector3(PI * 0.5, 0, 0)), MeshForge.torus_geo(1.0, 0.04, 8, 64), "lite", true)
	for i in 12:
		var a := i / 12.0 * TAU
		var tall := 0.42 if i % 2 == 1 else 0.8
		f.limb(dress, I, Vector3(cos(a), 5.98, sin(a) - 0.05), Vector3(cos(a) * 1.24, 5.98 + tall, sin(a) * 1.24 - 0.05), [[0.0, 0.055], [1.0, 0.006]], "lite", 1.0, 6)
	_infinity = _god_node(upper, Vector3(0, 7.15, -0.05))
	var point := func(u: float) -> Vector3:
		var t := u * TAU
		var d := 1.0 + pow(sin(t), 2.0)
		return Vector3(0.68 * cos(t) / d, 0.68 * sin(t) * cos(t) / d * 1.5, 0)
	var previous: Vector3 = point.call(0.0)
	for i in range(1, 49):
		var next: Vector3 = point.call(i / 48.0)
		f.limb(_infinity, I, previous, next, [[0.0, 0.05], [1.0, 0.05]], "ice", 1.0, 6)
		previous = next
	_glow(_infinity, I, 3.0, 0xffe6b0, 0.85)

	# A mantle of the night sky, hemmed in gold.
	var mantle := func(k: float) -> Array:
		return [[-0.55 * k, 3.95], [0.55 * k, 3.95], [1.08 * k, 0.38], [0.52 * k, 0.2], [0.0, 0.05], [-0.52 * k, 0.2], [-1.08 * k, 0.38]]
	var sheet := func(k: float, z: float, mat: String) -> void:
		var geo := MeshForge.shape_geo(mantle.call(k), 0.02)
		for i in geo.points.size():
			var p := geo.points[i]
			p.z += z - (3.95 - p.y) * 0.24 # Trails out behind the legs.
			geo.points[i] = p
		var soup := f.prepare(geo)
		for i in soup.pos.size():
			soup.uv[i] = Vector2(absf(soup.pos[i].x) / 2.9, 1.0 - (soup.pos[i].y - 2.1) / 3.1)
		f.add_soup(dress, I, soup, mat)
	sheet.call(1.07, -0.69, "lite")
	sheet.call(1.0, -0.66, "wing")
	sheet.call(0.97, -0.72, "wing")

	# A sunburst on the breast, bracers and greaves.
	for i in 16:
		var a := i / 16.0 * TAU
		var r := 0.78 if i % 2 == 1 else 1.02
		f.plate(dress, MeshForge.xform(Vector3(cos(a) * 0.6, 3.48 + sin(a) * 0.6, 0.66), Vector3(0, 0, a - PI * 0.5)), [[-0.045, 0.0], [0.045, 0.0], [0.0, r - 0.6]], 0.02, "neon")
	for s: float in [-1.0, 1.0]:
		var suffix := "L" if s > 0.0 else "R"
		f.add(_god_node(joints["fore" + suffix]), MeshForge.xform(Vector3(s * 0.36, -0.48, 0.07), Vector3(1.25, s * 0.35, 0)), MeshForge.torus_geo(0.31, 0.05, 8, 22), "lite", true)
		f.add(_god_node(joints["shin" + suffix]), MeshForge.xform(Vector3(s * 0.08, -0.86, 0.02), Vector3(PI * 0.5, 0, 0)), MeshForge.torus_geo(0.36, 0.05, 8, 22), "lite", true)

	# The armillary of the multiverse: tilted orbits, each carrying small universes.
	_armillary = _god_node(root_joint, Vector3(0, 3.2, 0))
	var n := 0
	for orbit: Array in [[3.2, Vector3(1.2, 0, 0.3), 0.23], [2.96, Vector3(0.3, 0.5, 1.3), -0.31], [3.08, Vector3(PI * 0.5 + 0.55, 0.9, 0), 0.17]]:
		var tilt := _god_node(_armillary)
		tilt.rotation = orbit[1]
		var spin := _god_node(tilt)
		f.add(tilt, I, MeshForge.torus_geo(orbit[0], 0.022, 6, 110), "god_gold", true)
		for i in 5:
			var a: float = i / 5.0 * TAU + n
			var at := Vector3(cos(a) * orbit[0], sin(a) * orbit[0], 0)
			var size: float = 0.11 + (i * 7 % 5) * 0.022
			f.add(spin, MeshForge.xform(at), MeshForge.sphere_geo(size, 12, 10), "cosmic", true)
			_add_orbit_spark(spin, at, size * 11.0, ORBIT_HUES[i])
		_orbits.append([spin, orbit[2]])
		n += 1

	# Light of creation, always behind the body.
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	_rays = ShaderMaterial.new()
	_rays.shader = GOD_RAYS
	_rays.set_shader_parameter("half_size", 10.5 * MODEL_SCALE * SUPREME_SCALE)
	_rays.set_shader_parameter("depth", 1.5)
	quad.material = _rays
	var rays := MeshInstance3D.new()
	rays.mesh = quad
	rays.position = Vector3(0, 3.2, 0)
	rays.extra_cull_margin = 30.0
	rays.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_god_node(root_joint).add_child(rays)

	# The mandala of creation under the feet. It stays on the ground when the body rises.
	var plane := PlaneMesh.new()
	plane.size = Vector2(7.4, 7.4)
	var mandala_material := ShaderMaterial.new()
	mandala_material.shader = MANDALA
	plane.material = mandala_material
	var mandala := MeshInstance3D.new()
	mandala.mesh = plane
	mandala.position.y = 0.12
	mandala.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mandala_node = _god_node(_body)
	_mandala_node.add_child(mandala)


func _add_orbit_spark(parent: Node3D, at: Vector3, size: float, hex: int) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var material := ShaderMaterial.new()
	material.shader = STAR
	material.set_shader_parameter("tint", Color.hex((hex << 8) | 0xff))
	material.set_shader_parameter("boost", 1.2)
	quad.material = material
	var spark := MeshInstance3D.new()
	spark.mesh = quad
	spark.position = at
	spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(spark)


## Six wings: the original pair, a greater pair above and a lesser pair below.
func _clone_wings() -> void:
	for s: float in [-1.0, 1.0]:
		var wing: Node3D = _wings[s]
		var pieces: Array[Node] = []
		for child in wing.get_children():
			if not child is CPUParticles3D:
				pieces.append(child)
		for pair: Array in [[0.62, 1.2], [-0.58, 0.86]]:
			var group := _god_node(wing)
			group.rotation.z = s * pair[0]
			group.scale = Vector3.ONE * pair[1]
			for piece in pieces:
				group.add_child(piece.duplicate())


## Swaps the whole body between its two forms. `snap` skips the change of size.
func set_form(supreme: bool, snap := false) -> void:
	is_supreme = supreme
	for swap: Array in _form_swaps:
		swap[0].set_shader_parameter(swap[1], swap[3] if supreme else swap[2])
	# Beneath the armour the supreme body is the universe itself.
	_suit.shader = COSMIC if supreme else TOON
	if supreme:
		_suit.set_shader_parameter("nebula", _nebula)
		_suit.set_shader_parameter("u_scale", MeshForge.TILE)
	for node in _god_nodes:
		node.visible = supreme
	for m in _flames:
		m.set_shader_parameter("gold", 1.0 if supreme else 0.0)
	var warm := Color(1.0, 0.82, 0.5)
	var cool := Color(0.62, 0.5, 1.0)
	_blade_light.light_color = warm if supreme else cool
	for light in _hand_lights:
		light.light_color = Color.hex(0xffd98aff) if supreme else Color.hex(0xb49cffff)
	_aura.set_shader_parameter("tint", Color(1.0, 0.72, 0.3) if supreme else Color(0.6, 0.48, 1.0))
	_scale_goal = SUPREME_SCALE if supreme else 1.0
	if snap:
		scale = Vector3.ONE * _scale_goal
		_hover = 0.0
	set_blade_growth(0.0)
	_apply_grip()


## 0 is the normal blade; 1 is the sword of INFINITY EDGE.
func set_blade_growth(amount: float) -> void:
	# The supreme form's sword is never less than half drawn out of the universe.
	var size := maxf(amount, 0.5 if is_supreme else 0.0)
	_blade_growth = size
	_holder.scale = Vector3(1.0 + size * 1.4, 1.0 + size * 1.4, 1.0 + size * 3.5)


## `pace` runs from 0 (hovering) to 1 (flat out).
func set_flight(on: bool, pace: float) -> void:
	if on != _flying:
		_flying = on
		_apply_grip()
	_fly_goal = pace


func _update_flight(delta: float) -> void:
	_fly_pace = lerpf(_fly_pace, _fly_goal if _flying else 0.0, 1.0 - exp(-delta * 5.0))
	if _flying:
		var blended := {}
		for joint_name: String in FLY_HOVER:
			blended[joint_name] = (FLY_HOVER[joint_name] as Vector3).lerp(FLY_FAST[joint_name], _fly_pace)
		if is_armed:
			for joint_name: String in ["armR", "foreR", "hand_R"]:
				blended[joint_name] = ARMED_IDLE[joint_name]
		idle_pose = blended
	var tilt_goal := _fly_pace * 1.2 if _flying and action == "" else 0.0
	_tilt = lerpf(_tilt, tilt_goal, 1.0 - exp(-delta * 7.0))
	# Pitched about the waist, so the body does not swing forward off its own position.
	var waist := Vector3(0, pivot.y * MODEL_SCALE, 0)
	_body.transform.basis = Basis(Vector3.RIGHT, _tilt) * Basis.from_scale(Vector3.ONE * MODEL_SCALE)
	_body.position = waist - Basis(Vector3.RIGHT, _tilt) * waist
	_mandala_node.visible = is_supreme and not _flying


func _update_supreme(delta: float) -> void:
	scale = scale.lerp(Vector3.ONE * _scale_goal, 1.0 - exp(-delta * 7.0))
	_update_flight(delta)
	if not is_supreme:
		_hover = lerpf(_hover, 0.0, 1.0 - exp(-delta * 10.0))
	else:
		# Floats while still, and sets its feet down to run.
		var still := 1.0 - clampf(speed / 2.0, 0.0, 1.0)
		var hovering := (action == "" or action == "drink") and not _flying
		var goal := (0.26 + sin(_flap * 1.1) * 0.05) * still if hovering else 0.0
		_hover = lerpf(_hover, goal, 1.0 - exp(-delta * 6.0))
		_infinity.rotation.y = _flap * 0.5
		_armillary.rotation.y = _flap * 0.05
		for orbit: Array in _orbits:
			orbit[0].rotation.z = _flap * orbit[1]
		_rays.set_shader_parameter("power", 0.5 + _charge * 0.25 + sin(_flap * 2.2) * 0.03)
	root_joint.position.y += _hover / MODEL_SCALE


func _neon(joint: Node3D, xf: Transform3D, pts: Array, z: float, width: float, mat: String) -> void:
	for i in pts.size() - 1:
		var a: Array = pts[i]
		var b: Array = pts[i + 1]
		var length := Vector2(b[0] - a[0], b[1] - a[1]).length()
		var local := MeshForge.xform(Vector3((a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5, z), Vector3(0, 0, atan2(b[1] - a[1], b[0] - a[0])))
		forge.add(joint, xf * local, MeshForge.box_geo(length + width, width, 0.012), mat)


func _build_torso(root: Node3D, upper: Node3D) -> void:
	var f := forge
	var I := Transform3D.IDENTITY
	var at := func(x: float, y: float, z: float) -> Transform3D: return MeshForge.xform(Vector3(x, y, z))

	f.loft(upper, I, [[3.9, 0.3, 0.28], [4.25, 0.26, 0.26]], "suit")
	f.loft(upper, at.call(0, 0, -0.02), [[3.92, 0.46, 0.38], [4.14, 0.34, 0.32]], "deep")
	f.loft(upper, I, [[2.5, 0.5, 0.34], [2.75, 0.46, 0.31], [3.25, 0.55, 0.38]], "suit", 0.75)
	f.loft(upper, I, [[3.1, 0.56, 0.38], [3.5, 0.66, 0.47], [3.82, 0.64, 0.46], [4.02, 0.38, 0.32]], "armor", 0.7)
	f.loft(upper, I, [[2.5, 0.55, 0.375], [2.64, 0.56, 0.385]], "armor", 0.7)
	f.loft(root, I, [[2.03, 0.22, 0.24], [2.3, 0.42, 0.32], [2.54, 0.5, 0.34]], "suit", 0.75)
	f.plate(root, at.call(0, 0, 0.25), [[-0.2, 2.42], [0.2, 2.42], [0.09, 2.12], [0.0, 2.03], [-0.09, 2.12]], 0.3, "deep", 0.02)
	for s: float in [-1.0, 1.0]:
		f.plate(root, I, [[s * 0.28, 2.52], [s * 0.56, 2.5], [s * 0.54, 2.2], [s * 0.36, 2.1]], 0.5, "armor", 0.02)

	# Chest plate, star medallion and lower glowing panel.
	f.plate(upper, at.call(0, 0, 0.28), [[-0.62, 3.92], [-0.66, 3.52], [-0.36, 3.26], [0.0, 3.03], [0.36, 3.26], [0.66, 3.52], [0.62, 3.92], [0.26, 3.99], [0.0, 3.86], [-0.26, 3.99]], 0.5, "lite", 0.03)
	f.plate(upper, at.call(0, 3.48, 0.57), MeshForge.star4(0.47, 0.17, 0.55), 0.08, "lite", 0.015)
	f.plate(upper, at.call(0, 3.48, 0.625), MeshForge.star4(0.35, 0.09, 0.42), 0.02, "white")
	_glow(upper, at.call(0, 3.48, 0.645), 1.5, 0x8fb8ff, 1.0)

	f.plate(upper, at.call(0, 0, 0.12), [[-0.48, 3.22], [0.48, 3.22], [0.46, 2.76], [0.0, 2.38], [-0.46, 2.76]], 0.55, "suit")
	for s: float in [-1.0, 1.0]:
		_neon(upper, I, [[s * 0.13, 3.74], [s * 0.3, 3.74], [s * 0.46, 3.62]], 0.535, 0.018, "neon")
	_neon(upper, I, [[-0.4, 3.0], [-0.37, 2.8], [0.0, 2.47], [0.37, 2.8], [0.4, 3.0]], 0.402, 0.035, "line")
	_neon(upper, I, [[-0.25, 3.02], [-0.22, 2.88], [0.0, 2.66], [0.22, 2.88], [0.25, 3.02]], 0.402, 0.035, "line")
	_glow(upper, at.call(0, 2.76, 0.415), 1.5, 0x4d6cff, 0.9)

	# Back shield, thruster rings and spine lights.
	f.plate(upper, at.call(0, 0, -0.47), [[-0.55, 4.0], [0.55, 4.0], [0.6, 3.45], [0.36, 3.12], [0.0, 2.86], [-0.36, 3.12], [-0.6, 3.45]], 0.12, "armor", 0.03)
	f.plate(upper, at.call(0, 0, -0.55), [[-0.3, 3.9], [0.3, 3.9], [0.3, 3.32], [0.0, 3.05], [-0.3, 3.32]], 0.08, "lite", 0.02)
	for s: float in [-1.0, 1.0]:
		_neon(upper, I, [[s * 0.34, 3.0], [s * 0.28, 2.8]], -0.37, 0.03, "neon")
		f.limb(upper, I, Vector3(s * 0.55, 3.73, -0.3), Vector3(s * 0.73, 3.73, -0.78), [[0.0, 0.17], [1.0, 0.2]], "deep")
		f.add(upper, at.call(s * 0.73, 3.73, -0.8), MeshForge.torus_geo(0.2, 0.07, 8, 18), "armor", true)
		f.add(upper, MeshForge.xform(Vector3(s * 0.73, 3.73, -0.8), Vector3(PI * 0.5, 0, 0)), MeshForge.cylinder_geo(0.13, 0.13, 0.05, 16), "deep")
		f.add(upper, at.call(s * 0.73, 3.73, -0.83), MeshForge.torus_geo(0.07, 0.025, 6, 14), "lite", true)


func _build_wings(upper: Node3D) -> void:
	var f := forge
	var outer := [[0.55, 4.12], [2.55, 5.1], [2.02, 4.08], [2.73, 3.51], [1.72, 3.1], [2.0, 2.28], [1.08, 2.85], [0.55, 3.0]]
	var inner := [[0.62, 3.42], [1.16, 3.3], [1.13, 2.18], [0.74, 2.72]]
	for s: float in [-1.0, 1.0]:
		var anchor := Vector3(s * 0.6, 3.6, -0.72)
		var wing := _child_joint("wingL" if s > 0.0 else "wingR", upper, anchor)
		_wings[s] = wing
		for piece: Array in [[outer, 0.0], [inner, 0.12]]:
			var pts := []
			for q: Array in piece[0]:
				pts.append([s * q[0], q[1]])
			var geo := MeshForge.shape_geo(pts, 0.05)
			for i in geo.points.size():
				var p := geo.points[i]
				p.z += piece[1]
				p.z = p.z - 0.72 - maxf(0.0, abs(p.x) - 0.5) * 0.55
				geo.points[i] = p - anchor
			var soup := f.prepare(geo)
			# The image is keyed to sheet coordinates, so each wing shows the same galaxy.
			for i in soup.pos.size():
				var q := soup.pos[i] + anchor
				soup.uv[i] = Vector2(abs(q.x) / 2.9, 1.0 - (q.y - 2.1) / 3.1)
			var panel := wing
			if piece[0] == inner:
				panel = _child_joint("wingInner" + ("L" if s > 0.0 else "R"), wing, Vector3.ZERO)
				_wing_inner[s] = panel
			f.add_soup(panel, Transform3D.IDENTITY, soup, "wing")
		_add_wing_dust(wing, s)
		_add_thruster(upper, s)


func _add_wing_dust(wing: Node3D, s: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.24, 0.24)
	var material := ShaderMaterial.new()
	material.shader = STAR
	material.set_shader_parameter("tint", Color(0.72, 0.62, 1.0))
	quad.material = material
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	var dust := CPUParticles3D.new()
	dust.mesh = quad
	dust.amount = 18
	dust.lifetime = 1.3
	dust.local_coords = false
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(1.1, 0.95, 0.05)
	dust.position = Vector3(s * 1.05, 0.05, -0.75)
	dust.gravity = Vector3(0, -0.5, 0)
	dust.spread = 180.0
	dust.initial_velocity_min = 0.05
	dust.initial_velocity_max = 0.3
	dust.scale_amount_min = 0.25
	dust.scale_amount_max = 0.9
	dust.color_ramp = fade
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wing.add_child(dust)


func _add_thruster(upper: Node3D, s: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(1.5, 1.5)
	var material := ShaderMaterial.new()
	material.shader = GLOW
	material.set_shader_parameter("color", Color(0.45, 0.5, 1.0))
	material.set_shader_parameter("strength", 0.3)
	material.set_shader_parameter("pulse_amount", 0.1)
	quad.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.position = Vector3(s * 0.73, 3.73, -0.9)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	upper.add_child(instance)
	_thrusters.append(material)


func _build_arm(upper: Node3D, s: float) -> void:
	var f := forge
	var I := Transform3D.IDENTITY
	var suffix := "L" if s > 0.0 else "R"
	var shoulder := Vector3(s * 0.88, 3.72, 0)
	var elbow := Vector3(s * 1.42, 2.95, 0.02)
	var wrist := Vector3(s * 1.88, 2.32, 0.1)
	var arm := _child_joint("arm" + suffix, upper, shoulder)
	var to_e := elbow - shoulder
	var to_w := wrist - elbow

	f.add(arm, I, MeshForge.sphere_geo(0.27, 12, 10), "suit", true)
	f.limb(arm, I, Vector3.ZERO, to_e, [[0.0, 0.24], [0.5, 0.25], [1.0, 0.2]], "suit")

	# Shoulder shield with a galaxy inset and a star.
	var pad := Transform3D(MeshForge.orient(Vector3(s * 0.86, 0.22, 0.46)), Vector3(s * 0.25, 0.1, 0.06))
	var hex := func(k: float) -> Array:
		return [[0.0, 0.45 * k], [0.35 * k, 0.27 * k], [0.38 * k, -0.16 * k], [0.11 * k, -0.46 * k], [-0.16 * k, -0.46 * k], [-0.4 * k, -0.16 * k], [-0.35 * k, 0.27 * k]]
	f.plate(arm, pad, hex.call(1.0), 0.14, "lite", 0.03)
	f.plate(arm, pad * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.09)), hex.call(0.76), 0.02, "cosmic")
	f.plate(arm, pad * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.115)), MeshForge.star4(0.26, 0.055, 0.29), 0.02, "ice")
	_glow(arm, pad * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.135)), 0.8, 0x7fc8ff, 0.9)

	var fore := _child_joint("fore" + suffix, arm, to_e)
	f.limb(fore, I, Vector3.ZERO, to_w, [[0.0, 0.2], [0.18, 0.3], [0.72, 0.28], [1.0, 0.19]], "cosmic", 0.85)
	f.limb(fore, I, Vector3.ZERO, to_w, [[0.0, 0.23], [0.15, 0.32], [0.2, 0.31], [0.2, 0.2]], "lite", 0.85)
	f.limb(fore, I, Vector3.ZERO, to_w, [[0.8, 0.2], [0.84, 0.28], [0.98, 0.23], [0.98, 0.15]], "lite", 0.85)

	# Outer forearm kite with a small lens.
	var d := to_w.normalized()
	var n := Vector3(s, 0.1, -0.05)
	n = (n - d * n.dot(d)).normalized()
	var kite := Transform3D(Basis(d.cross(n).normalized(), d, n), to_w * 0.5 + n * 0.29)
	var kp := func(k: float) -> Array:
		return [[0.0, 0.62 * k], [0.24 * k, 0.28 * k], [0.25 * k, -0.3 * k], [0.0, -0.68 * k], [-0.25 * k, -0.3 * k], [-0.24 * k, 0.28 * k]]
	f.plate(fore, kite, kp.call(1.0), 0.1, "lite", 0.02)
	f.plate(fore, kite * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.065)), kp.call(0.72), 0.02, "cosmic")
	f.add(fore, kite * Transform3D(Basis.IDENTITY, Vector3(0, 0.24, 0.09)), MeshForge.torus_geo(0.08, 0.022, 6, 16), "ice", true)
	_neon(fore, kite, [[0.0, 0.1], [0.0, -0.4]], 0.085, 0.022, "ice")
	_glow(fore, kite * Transform3D(Basis.IDENTITY, Vector3(0, 0.24, 0.105)), 0.42, 0x7fc8ff, 0.8)

	var hand := _child_joint("hand_" + suffix, fore, to_w)
	var palm := _child_joint("palm" + suffix, hand, Vector3.ZERO)
	f.limb(palm, I, Vector3(0, 0.04, 0), Vector3(0, -0.3, 0.03), [[0.0, 0.15, 0.11], [0.5, 0.2, 0.1], [1.0, 0.2, 0.09]], "handSuit", 0.75)
	var finger_offsets := [-0.135, -0.045, 0.045, 0.135]
	for i in 4:
		var o: float = finger_offsets[i]
		var long_finger := 1 if i == 1 or i == 2 else 0
		var b := Vector3(s * o, -0.28, 0.04)
		var m := Vector3(b.x + s * o * 0.25, -0.48 - 0.04 * long_finger, 0.09)
		var e := Vector3(m.x + s * o * 0.05, -0.66 - 0.05 * long_finger, 0.19)
		f.limb(palm, I, b, m, [[0.0, 0.05], [1.0, 0.046]], "handSuit", 1.0, 8)
		f.limb(palm, I, m, e, [[0.0, 0.046], [0.7, 0.04], [1.0, 0.012]], "handDeep", 1.0, 8)
	var th := Vector3(s * 0.18, -0.1, 0.08)
	var tm := Vector3(s * 0.36, -0.28, 0.15)
	f.limb(palm, I, th, tm, [[0.0, 0.065], [1.0, 0.05]], "handSuit", 1.0, 8)
	f.limb(palm, I, tm, Vector3(s * 0.39, -0.46, 0.2), [[0.0, 0.05], [1.0, 0.014]], "handDeep", 1.0, 8)

	_add_flames(hand, s)


func _build_leg(root: Node3D, s: float) -> void:
	var f := forge
	var I := Transform3D.IDENTITY
	var suffix := "L" if s > 0.0 else "R"
	var hip := Vector3(s * 0.33, 2.4, 0)
	var knee := Vector3(s * 0.57, 1.42, 0.03)
	var ankle := Vector3(s * 0.71, 0.34, 0.02)
	var leg := _child_joint("leg" + suffix, root, hip)
	var to_k := knee - hip
	var to_a := ankle - knee

	f.limb(leg, I, Vector3.ZERO, to_k, [[0.0, 0.32, 0.33], [0.5, 0.33, 0.34], [1.0, 0.24, 0.26]], "suit")
	f.limb(leg, I, Vector3(s * 0.13, -0.06, 0.03), Vector3(to_k.x + s * 0.11, to_k.y + 0.2, to_k.z + 0.02), [[0.0, 0.17, 0.28], [0.5, 0.22, 0.3], [1.0, 0.13, 0.22]], "armor", 0.8)

	var shin := _child_joint("shin" + suffix, leg, to_k)
	f.add(shin, I, MeshForge.sphere_geo(0.26, 12, 10), "suit", true)
	f.limb(shin, I, Vector3(0, -0.12, -0.01), to_a, [[0.0, 0.33, 0.34], [0.2, 0.34, 0.37], [0.65, 0.26, 0.31], [1.0, 0.24, 0.28]], "armor", 0.8)
	f.limb(shin, I, Vector3(0, -0.12, -0.01), to_a, [[0.0, 0.24, 0.25], [0.0, 0.36, 0.36], [0.09, 0.37, 0.4], [0.09, 0.25, 0.26]], "lite", 0.8)

	var neon_x := to_a.x * 0.5
	for o: float in [-1.0, 1.0]:
		f.add(shin, MeshForge.xform(Vector3(neon_x + o * 0.13, to_a.y * 0.5 - 0.05, 0.33), Vector3(-0.1, 0, s * 0.1)), MeshForge.box_geo(0.014, 0.52, 0.012), "neon")

	# Knee guard.
	var guard := Transform3D(MeshForge.orient(Vector3(s * 0.14, 0.12, 1.0)), Vector3(0, 0.05, 0.3))
	var kk := func(k: float) -> Array:
		return [[0.0, 0.46 * k], [0.2 * k, 0.12 * k], [0.17 * k, -0.3 * k], [0.0, -0.56 * k], [-0.17 * k, -0.3 * k], [-0.2 * k, 0.12 * k]]
	f.plate(shin, guard, kk.call(1.0), 0.12, "lite", 0.02)
	f.plate(shin, guard * Transform3D(Basis.IDENTITY, Vector3(0, 0, 0.075)), kk.call(0.7), 0.02, "cosmic")

	var foot := _child_joint("foot" + suffix, shin, to_a)
	f.limb(foot, I, Vector3(0, -0.14, -0.42), Vector3(0, -0.14, 0.7), [[0.0, 0.22, 0.16], [0.3, 0.3, 0.2, 0.01], [0.7, 0.28, 0.15, 0.05], [1.0, 0.15, 0.09, 0.1]], "armor", 0.75)
	f.add(foot, MeshForge.xform(Vector3(0, -0.3, 0.1)), MeshForge.box_geo(0.54, 0.07, 1.0), "sole")
	f.loft(foot, I, [[-0.17, 0.27, 0.3, 0.12], [-0.08, 0.27, 0.3, 0.12]], "lite", 0.75)


## A star-glass blade. It is mounted so that it points forward in the ready stance.
func _build_blade(hand: Node3D) -> void:
	var f := forge
	var holder := Node3D.new()
	holder.name = "BladeHolder"
	# The blade continues the forearm, tipped forward by the wrist's natural grip angle,
	# with its edges leading along the arc the arm sweeps through.
	var along := Vector3(-0.46, -0.63, 0.08).normalized()
	var grip_forward := (Vector3.BACK - along * along.dot(Vector3.BACK)).normalized()
	var blade_axis := (along * cos(GRIP_ANGLE) + grip_forward * sin(GRIP_ANGLE)).normalized()
	var sweep := Vector3.BACK.cross(along)
	sweep = (sweep - blade_axis * blade_axis.dot(sweep)).normalized()
	holder.transform = Transform3D(Basis(sweep, blade_axis.cross(sweep), blade_axis), Vector3(0, -0.36, 0.06))
	hand.add_child(holder)

	var I := Transform3D.IDENTITY
	var length := BLADE_LENGTH
	_holder = holder
	f.limb(holder, I, Vector3(0, 0, -0.42), Vector3(0, 0, 0.2), [[0.0, 0.09], [1.0, 0.075]], "blade_deep", 0.9, 8)
	f.plate(holder, MeshForge.xform(Vector3(0, 0, 0.22), Vector3(0, 0, 0)), MeshForge.star4(0.52, 0.12, 0.2), 0.14, "blade_lite", 0.02)
	f.plate(holder, MeshForge.xform(Vector3(0, 0, 0.31)), MeshForge.star4(0.3, 0.06, 0.12), 0.02, "blade_ice")
	var blade := [[-0.17, 0.0], [0.17, 0.0], [0.15, length - 0.75], [0.0, length], [-0.15, length - 0.75]]
	f.plate(holder, MeshForge.xform(Vector3(0, 0, 0.3), Vector3(PI * 0.5, 0, 0)), blade, 0.09, "blade_cosmic", 0.012)
	var edge := [[-0.02, 0.15], [0.02, 0.15], [0.02, length - 0.7], [0.0, length - 0.12], [-0.02, length - 0.7]]
	f.plate(holder, MeshForge.xform(Vector3(0, 0, 0.3), Vector3(PI * 0.5, 0, 0)), edge, 0.11, "blade_edge")

	blade_base = Node3D.new()
	blade_base.position = Vector3(0, 0, 1.15)
	holder.add_child(blade_base)
	blade_tip = Node3D.new()
	blade_tip.position = Vector3(0, 0, 0.3 + length)
	holder.add_child(blade_tip)
	_build_blade_effects(holder, length)


func _build_blade_effects(holder: Node3D, length: float) -> void:
	_aura = ShaderMaterial.new()
	_aura.shader = AURA
	for roll: float in [0.0, PI * 0.5]:
		var quad := QuadMesh.new()
		quad.size = Vector2(1.5, length + 0.5)
		quad.material = _aura
		var instance := MeshInstance3D.new()
		instance.mesh = quad
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.transform = Transform3D(Basis(Vector3.BACK, roll) * Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, 0.3 + length * 0.5))
		holder.add_child(instance)

	_blade_light = OmniLight3D.new()
	_blade_light.light_color = Color(0.62, 0.5, 1.0)
	_blade_light.light_energy = 0.0
	_blade_light.omni_range = 6.0
	_blade_light.position = Vector3(0, 0, 0.3 + length * 0.6)
	holder.add_child(_blade_light)

	var quad := QuadMesh.new()
	quad.size = Vector2(0.55, 0.55)
	var material := ShaderMaterial.new()
	material.shader = STAR
	material.set_shader_parameter("tint", Color(0.8, 0.7, 1.0))
	quad.material = material
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	_sparks = CPUParticles3D.new()
	_sparks.mesh = quad
	_sparks.amount = 48
	_sparks.lifetime = 0.42
	_sparks.local_coords = false
	_sparks.emitting = false
	_sparks.gravity = Vector3(0, -2.5, 0)
	_sparks.spread = 180.0
	_sparks.initial_velocity_min = 0.3
	_sparks.initial_velocity_max = 2.0
	_sparks.scale_amount_min = 0.5
	_sparks.scale_amount_max = 1.5
	_sparks.color_ramp = fade
	_sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	blade_tip.add_child(_sparks)

	_reveal_point = Node3D.new()
	holder.add_child(_reveal_point)
	_draw_sparks = _sparks.duplicate()
	_draw_sparks.amount = 26
	_draw_sparks.scale_amount_max = 0.8
	_draw_sparks.lifetime = 0.5
	_draw_sparks.initial_velocity_max = 4.0
	_draw_sparks.emitting = false
	_reveal_point.add_child(_draw_sparks)
	_rift = SpaceRift.new(_rift_image)
	add_child(_rift)


func _set_reveal(value: float) -> void:
	_reveal = value
	for m in _blade_materials:
		m.set_shader_parameter("reveal_z", value)
	_reveal_point.position.z = minf(value, 0.3 + BLADE_LENGTH)


func set_armed_instant(armed: bool) -> void:
	is_armed = armed
	_draw_mode = ""
	_holder.visible = armed
	_set_reveal(1000.0)
	_draw_sparks.emitting = false
	_rift.vanish()
	_apply_grip()


func _apply_grip() -> void:
	for joint_name: String in ARMED_STANCE:
		if is_armed:
			stance[joint_name] = ARMED_STANCE[joint_name]
		else:
			stance.erase(joint_name)
	idle_pose = ARMED_IDLE if is_armed else (GOD_IDLE if is_supreme else UNARMED_IDLE)
	run_hold = ARMED_RUN if is_armed else {}
	right_hand_free = not is_armed
	set_palms(1.6 if is_armed else 2.18)


func warm_effects(at: Vector3) -> void:
	_rift.tear_open(at, 2.0)
	set_blade_sparks(true)
	_draw_sparks.emitting = true
	set_energy(1.0)


func is_drawing() -> bool:
	return _draw_mode != ""


## Opens a tear above the right shoulder; the hand reaches in and hauls the blade out.
func begin_summon(length: float) -> void:
	_draw_mode = "summon"
	_draw_time = 0.0
	_draw_length = length
	_burst_done = false
	is_armed = true
	_apply_grip()
	_holder.visible = false
	_set_reveal(0.45)
	_portal = joints["hand_R"].global_position
	_rift.tear_open(_portal, 2.5)
	play("summon", length)


## The blade drains tip-first into a small tear that rides down it.
func begin_sheathe(length: float) -> void:
	_draw_mode = "sheathe"
	_draw_time = 0.0
	_draw_length = length
	_burst_done = false
	_set_reveal(0.3 + BLADE_LENGTH)
	play("sheathe", length)


func cancel_draw() -> void:
	if _draw_mode != "":
		stop_action()
		set_armed_instant(false)


func _update_draw(delta: float) -> void:
	if _draw_mode == "":
		return
	_draw_time += delta
	var t := clampf(_draw_time / _draw_length, 0.0, 1.0)
	if _draw_mode == "summon":
		_charge = maxf(_charge, 1.0 - t * 0.5)
		if t < 0.4:
			# The tear is dragged open by the reaching hand, then stays where the blade is gripped.
			_portal = joints["hand_R"].global_position
			_rift.global_position = _portal
		if t >= 0.4:
			_holder.visible = true
			_draw_sparks.emitting = _reveal < 100.0
			var drawn := _holder.global_position.distance_to(_portal) / MODEL_SCALE + 0.45
			_set_reveal(maxf(_reveal, drawn))
		if not _burst_done and (t >= 0.82 or _reveal >= 0.3 + BLADE_LENGTH):
			_burst_done = true
			_set_reveal(1000.0)
			_draw_sparks.emitting = false
			_rift.seal()
			Fx.impact(blade_tip.global_position, Color(0.72, 0.58, 1.0), 0.15)
		if t >= 1.0:
			_draw_mode = ""
	else:
		_charge = maxf(_charge, 0.45)
		if t >= 0.14 and not _rift.visible:
			_rift.tear_open(_reveal_point.global_position, 1.3)
			_rift.follow = _reveal_point
			_draw_sparks.emitting = true
		var k := smoothstep(0.18, 0.78, t)
		_set_reveal(lerpf(0.3 + BLADE_LENGTH, 0.3, k))
		if not _burst_done and t >= 0.8:
			_burst_done = true
			_draw_sparks.emitting = false
			_rift.seal()
			Fx.burst(_holder.global_position, Color(0.75, 0.62, 1.0), 26, 3.5, 0.04)
			_holder.visible = false
		if t >= 1.0:
			_draw_mode = ""
			is_armed = false
			_apply_grip()
			_set_reveal(1000.0)


func _update_wings(delta: float) -> void:
	var pace := clampf(speed / run_speed, 0.0, 1.0)
	_flap += delta
	var goal_sweep := 0.62 * pow(pace, 1.2)
	var goal_lift := -0.1 * pace + sin(_flap * 1.25) * 0.055 * (1.0 - pace) + sin(_phase * 2.0) * 0.05 * pace

	var charge_goal := 0.12 + pace * 0.18
	match action:
		"roll":
			goal_sweep = 1.15
			goal_lift = -0.55
			charge_goal = 0.8
		"summon":
			goal_sweep = -0.42
			goal_lift = 0.38
		"sheathe":
			goal_sweep = 0.15
			goal_lift = 0.18
		"cut1", "cut2", "cut3", "cleave":
			# Pulled back through the wind-up, thrown wide on the blow.
			goal_sweep = 0.55 if _blade_goal < 0.9 else -0.32
			goal_lift = 0.08 if _blade_goal < 0.9 else 0.3
			charge_goal = 0.35 if _blade_goal < 0.9 else 1.0
		"ascend", "sky_spread", "edge", "erasure", "bigbang":
			goal_sweep = -0.45
			goal_lift = 0.34
			charge_goal = 1.0
		"death":
			goal_sweep = 0.5
			goal_lift = -0.7
			charge_goal = 0.0
		"rest":
			goal_sweep = 0.9
			goal_lift = -0.35
	if _flying and action == "":
		goal_sweep = 0.1 + _fly_pace * 0.55
		goal_lift = 0.2 + sin(_flap * 3.2) * (0.16 - _fly_pace * 0.1)
		charge_goal = 0.45 + _fly_pace * 0.45
	if guarding:
		goal_sweep = -0.75
		goal_lift = 0.05
		charge_goal = 0.5

	# Springs, so the wings overshoot and settle like something with mass.
	var steps := 2
	var dt := delta / steps
	for i in steps:
		_sweep_speed += (150.0 * (goal_sweep - _sweep) - 15.0 * _sweep_speed) * dt
		_sweep += _sweep_speed * dt
		_lift_speed += (120.0 * (goal_lift - _lift) - 12.0 * _lift_speed) * dt
		_lift += _lift_speed * dt

	_hit_jolt = maxf(0.0, _hit_jolt - delta * 5.0)
	var jolt := sin(_flap * 40.0) * _hit_jolt * 0.14
	_wings[1.0].rotation = Vector3(0, _sweep, _lift + jolt)
	_wings[-1.0].rotation = Vector3(0, -_sweep, -_lift - jolt)
	# The inner panel trails the main wing a little.
	_wing_inner[1.0].rotation.y = _sweep_speed * 0.022 + _sweep * 0.22
	_wing_inner[-1.0].rotation.y = -_sweep_speed * 0.022 - _sweep * 0.22

	_charge = lerpf(_charge, charge_goal, 1.0 - exp(-delta * (22.0 if charge_goal > _charge else 4.5)))
	for m in _wing_materials:
		m.set_shader_parameter("charge", _charge)
	_wing_rim.set_shader_parameter("boost", 1.0 + _charge * 4.5 + sin(_flap * 2.4) * 0.25)
	_wing_rim.set_shader_parameter("thickness", 0.05 + _charge * 0.035)
	for m in _thrusters:
		m.set_shader_parameter("strength", 0.25 + pace * 1.1 + _charge * 0.9)


## 0 is at rest, about 0.4 while winding up, 1 through the cut.
func set_blade_power(goal: float) -> void:
	_blade_goal = goal


func set_blade_sparks(on: bool) -> void:
	if _sparks.emitting != on:
		_sparks.emitting = on


func _build_shield_flash(fore: Node3D) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(4.2, 4.2)
	var m := ShaderMaterial.new()
	m.shader = GLOW
	m.set_shader_parameter("color", Color(0.55, 0.45, 1.0))
	m.set_shader_parameter("strength", 0.0)
	m.set_shader_parameter("pulse_amount", 0.0)
	quad.material = m
	shield_flash = MeshInstance3D.new()
	shield_flash.mesh = quad
	shield_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fore.add_child(shield_flash)
	shield_flash.position = Vector3(0.3, -0.3, 0.6)


func _add_flames(hand: Node3D, s: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	var m := ShaderMaterial.new()
	m.shader = FLAME
	m.set_shader_parameter("flame_seed", 3.7 if s > 0.0 else 11.3)
	m.set_shader_parameter("size", 1.15 * MODEL_SCALE)
	quad.material = m
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.position = Vector3(0, -0.36, 0)
	instance.extra_cull_margin = 100.0
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hand.add_child(instance)
	_flames.append(m)
	var light := OmniLight3D.new()
	light.light_color = Color.hex(0xb49cffff)
	light.light_energy = 0.0
	light.omni_range = 3.5
	light.position = instance.position
	hand.add_child(light)
	_hand_lights.append(light)


# ------------------------------------------------------------------ runtime

func preview_attacks() -> Array:
	var out := []
	for attack: Dictionary in Player.ATTACKS.values():
		out.append([attack["anim"], attack["length"]])
	return out


func set_palms(amount: float) -> void:
	joints["palmR"].rotation.y = amount
	joints["palmL"].rotation.y = -2.18


func set_energy(goal: float) -> void:
	_energy_goal = goal


func flash_hit() -> void:
	_flash = 1.0
	_hit_jolt = 1.0


func set_block(amount: float) -> void:
	var m: ShaderMaterial = (shield_flash.mesh as QuadMesh).material
	m.set_shader_parameter("strength", amount * 1.3)


func _process(delta: float) -> void:
	update_pose(delta)
	_update_draw(delta)
	_update_wings(delta)
	_update_supreme(delta)

	_blade_power = lerpf(_blade_power, _blade_goal, 1.0 - exp(-delta * (26.0 if _blade_goal > _blade_power else 7.0)))
	_edge.set_shader_parameter("boost", 1.8 + _blade_power * 5.5)
	_aura.set_shader_parameter("power", _blade_power if _reveal > 100.0 else 0.0)
	_blade_light.light_energy = _blade_power * 3.2
	_blade_light.visible = _blade_power > 0.25 # A live light over the grass is expensive.

	_energy += (_energy_goal - _energy) * (1.0 - exp(-delta * 8.0))
	for m in _flames:
		m.set_shader_parameter("power", _energy)
		m.set_shader_parameter("size", 1.15 * MODEL_SCALE * (0.55 + 0.45 * _energy))
	for light in _hand_lights:
		light.light_energy = _energy * 2.5
		light.visible = _energy > 0.02
	for m in _hand_materials:
		m.set_shader_parameter("emissive_energy", _energy * 0.85)

	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 5.0)
		for m in _all_toon:
			m.set_shader_parameter("flash", _flash * 0.6)
