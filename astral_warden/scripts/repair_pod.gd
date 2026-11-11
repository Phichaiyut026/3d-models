class_name RepairPod
extends Node3D
## A repair cradle in Safe Mode, putting a beaten fighter back together very slowly.
## Local -Z faces the middle of the room; +Z runs back towards the server racks.

const GLASS := preload("res://shaders/repair_glass.gdshader")
const PANEL := preload("res://shaders/repair_panel.gdshader")
const HEAL := Color(0.35, 1.0, 0.75)
const BED := 0.3 ## Height of the pad the body lies on.
const RADIUS := 2.7
const RATE := 0.0012 ## Repair gained per second. Nobody here is getting up soon.

var progress := 0.2
var _height := 4.5
var _focus := Vector3.ZERO
var _clock := 0.0
var _scan: MeshInstance3D
var _arms: Array[Dictionary] = []
var _panel: ShaderMaterial
var _readout: Label3D
var _glow: OmniLight3D
var _metal: StandardMaterial3D
var _trim: StandardMaterial3D


## `body_height` is how tall the body lies; `focus` is the worst of its damage, in this node's space.
func build(body_height: float, accent: Color, focus: Vector3, start: float, who: String) -> RepairPod:
	progress = start
	_focus = focus
	_height = maxf(body_height + 1.6, 4.4)
	_clock = randf() * 20.0
	_metal = StandardMaterial3D.new()
	_metal.albedo_color = Color(0.07, 0.09, 0.1)
	_metal.metallic = 0.75
	_metal.roughness = 0.35
	_trim = StandardMaterial3D.new()
	_trim.albedo_color = Color(0.16, 0.19, 0.2)
	_trim.metallic = 0.6
	_trim.roughness = 0.45
	_build_base()
	_build_canopy()
	_build_arms()
	_build_motes()
	_build_panel(accent, who)
	_build_cables()
	_glow = OmniLight3D.new()
	_glow.light_color = HEAL
	_glow.omni_range = 8.0
	_glow.light_energy = 1.2
	_glow.position = Vector3(0, _height * 0.6, 0)
	add_child(_glow)
	return self


func _mesh(mesh: Mesh, material: Material, at: Vector3, glow := false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = at
	if glow:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node


func _ring(inner: float, outer: float, material: Material, at: Vector3) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = inner
	torus.outer_radius = outer
	torus.rings = 48
	torus.ring_segments = 8
	return _mesh(torus, material, at, true)


## Lays a unit box from `from` to `to`, `width` across.
func _span(node: MeshInstance3D, from: Vector3, to: Vector3, width: float) -> void:
	var along := to - from
	var length := maxf(along.length(), 0.001)
	var up := Vector3.UP if absf(along.normalized().y) < 0.95 else Vector3.RIGHT
	node.transform = Transform3D(Basis.looking_at(along, up).scaled_local(Vector3(width, width, length)), (from + to) * 0.5)


func _build_base() -> void:
	var pad := CylinderMesh.new()
	pad.top_radius = RADIUS + 0.2
	pad.bottom_radius = RADIUS + 0.45
	pad.height = BED
	pad.radial_segments = 40
	_mesh(pad, _metal, Vector3(0, BED * 0.5, 0))
	var bed := CylinderMesh.new()
	bed.top_radius = RADIUS - 0.3
	bed.bottom_radius = RADIUS - 0.3
	bed.height = 0.03
	bed.radial_segments = 40
	_mesh(bed, Fx.flat_material(HEAL * 0.35, 1.0), Vector3(0, BED + 0.01, 0), true)
	_ring(RADIUS - 0.12, RADIUS + 0.05, Fx.flat_material(HEAL, 2.6), Vector3(0, BED + 0.02, 0))
	# Clamps around the rim, like the pad was bolted down in a hurry.
	var clamp := BoxMesh.new()
	clamp.size = Vector3(0.5, BED + 0.16, 0.7)
	for i in 8:
		var a := i * TAU / 8.0 + PI / 8.0
		var node := _mesh(clamp, _trim, Vector3(sin(a), 0, cos(a)) * (RADIUS + 0.35) + Vector3(0, (BED + 0.16) * 0.5, 0))
		node.rotation.y = a


func _build_canopy() -> void:
	var tube := CylinderMesh.new()
	tube.top_radius = RADIUS
	tube.bottom_radius = RADIUS
	tube.height = _height
	tube.radial_segments = 48
	tube.rings = 1
	tube.cap_top = false
	tube.cap_bottom = false
	var glass := ShaderMaterial.new()
	glass.shader = GLASS
	glass.set_shader_parameter("color", HEAL)
	glass.set_shader_parameter("height", _height)
	_mesh(tube, glass, Vector3(0, BED + _height * 0.5, 0), true)

	# Four ribs on the diagonals, so the front stays open to look in.
	var rib := BoxMesh.new()
	rib.size = Vector3(0.26, _height + 0.4, 0.34)
	var strip := BoxMesh.new()
	strip.size = Vector3(0.07, _height - 0.6, 0.05)
	for i in 4:
		var a := PI * 0.25 + i * PI * 0.5
		var at := Vector3(sin(a), 0, cos(a)) * (RADIUS + 0.12)
		var node := _mesh(rib, _metal, at + Vector3(0, BED + (_height + 0.4) * 0.5, 0))
		node.rotation.y = a
		var light := _mesh(strip, Fx.flat_material(HEAL, 2.2), Vector3(0, 0, -0.18), true)
		light.reparent(node, false)

	# The emitter overhead: a heavy cap with a ring of light shining down on the body.
	var top := BED + _height
	var cap := CylinderMesh.new()
	cap.top_radius = RADIUS * 0.7
	cap.bottom_radius = RADIUS + 0.35
	cap.height = 0.55
	cap.radial_segments = 40
	_mesh(cap, _metal, Vector3(0, top + 0.27, 0))
	_ring(RADIUS - 0.1, RADIUS + 0.12, Fx.flat_material(HEAL, 2.4), Vector3(0, top, 0))
	var lens := CylinderMesh.new()
	lens.top_radius = 1.2
	lens.bottom_radius = 1.2
	lens.height = 0.05
	_mesh(lens, Fx.flat_material(HEAL, 3.0), Vector3(0, top - 0.02, 0), true)
	_ring(0.95, 1.05, Fx.flat_material(Color.WHITE, 2.0), Vector3(0, top - 0.04, 0))

	_scan = _ring(RADIUS - 0.18, RADIUS - 0.05, Fx.flat_material(HEAL, 3.2), Vector3(0, BED + 0.4, 0))


## Two repair arms hang from the back ribs and keep welding at the worst of the damage.
func _build_arms() -> void:
	var tip_mesh := SphereMesh.new()
	tip_mesh.radius = 0.12
	tip_mesh.height = 0.24
	for side: float in [-1.0, 1.0]:
		var root := Vector3(side * (RADIUS - 0.4), BED + _height * 0.82, RADIUS - 0.5)
		var upper := _mesh(BoxMesh.new(), _trim, Vector3.ZERO)
		var fore := _mesh(BoxMesh.new(), _metal, Vector3.ZERO)
		var joint := _mesh(SphereMesh.new(), _trim, Vector3.ZERO)
		joint.scale = Vector3.ONE * 0.36
		var tip := _mesh(tip_mesh, Fx.flat_material(Color.WHITE, 3.0), Vector3.ZERO, true)
		var beam := _mesh(BoxMesh.new(), Fx.flat_material(HEAL, 3.5), Vector3.ZERO, true)
		_arms.append({"root": root, "side": side, "upper": upper, "fore": fore, "joint": joint, "tip": tip, "beam": beam})


func _build_motes() -> void:
	var cross := BoxMesh.new()
	cross.size = Vector3(0.09, 0.09, 0.09)
	cross.material = Fx.flat_material(HEAL, 3.0)
	var motes := CPUParticles3D.new()
	motes.mesh = cross
	motes.amount = 28
	motes.lifetime = 3.5
	motes.preprocess = 3.5
	motes.position = Vector3(0, BED + 0.2, 0)
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	motes.emission_ring_axis = Vector3.UP
	motes.emission_ring_radius = RADIUS - 0.4
	motes.emission_ring_inner_radius = 0.6
	motes.emission_ring_height = 0.1
	motes.direction = Vector3.UP
	motes.spread = 6.0
	motes.gravity = Vector3.ZERO
	motes.initial_velocity_min = 0.6
	motes.initial_velocity_max = 1.3
	motes.angular_velocity_min = -90.0
	motes.angular_velocity_max = 90.0
	motes.scale_amount_min = 0.5
	motes.scale_amount_max = 1.4
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(motes)


## A screen on a post at the front-right: heartbeat, repair bar, and the name over it.
func _build_panel(accent: Color, who: String) -> void:
	var stand := Node3D.new()
	stand.position = Vector3(RADIUS + 0.9, 0, -RADIUS + 0.2)
	stand.rotation.y = 0.55
	add_child(stand)
	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.18, 1.5, 0.18)
	post.mesh = post_mesh
	post.material_override = _metal
	post.position = Vector3(0, 0.75, 0)
	stand.add_child(post)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.9, 1.15)
	_panel = ShaderMaterial.new()
	_panel.shader = PANEL
	_panel.set_shader_parameter("color", HEAL)
	_panel.set_shader_parameter("accent", accent)
	_panel.set_shader_parameter("progress", progress)
	_panel.set_shader_parameter("beat_rate", randf_range(0.28, 0.42))
	var screen := MeshInstance3D.new()
	screen.mesh = quad
	screen.material_override = _panel
	screen.position = Vector3(0, 2.05, 0)
	screen.rotation.y = PI # Faces -Z, towards the room.
	screen.rotation.x = -0.12
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stand.add_child(screen)
	_readout = Label3D.new()
	_readout.font_size = 48
	_readout.pixel_size = 0.006
	_readout.outline_size = 10
	_readout.modulate = Color(HEAL.lightened(0.3))
	_readout.outline_modulate = Color(0, 0.05, 0.04)
	_readout.position = Vector3(0, 2.95, 0)
	_readout.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_readout.set_meta("who", who)
	stand.add_child(_readout)
	_update_readout()


## Thick cables run from the pad back to the racks along the wall.
func _build_cables() -> void:
	var cable := BoxMesh.new()
	cable.size = Vector3.ONE
	for x: float in [-1.1, -0.5, 0.6, 1.2]:
		var node := _mesh(cable, _metal, Vector3.ZERO)
		_span(node, Vector3(x, 0.09, RADIUS + 0.3), Vector3(x * 2.2, 0.09, RADIUS + 11.0), 0.18)
		var strip := _mesh(cable, Fx.flat_material(HEAL, 1.6), Vector3.ZERO, true)
		_span(strip, Vector3(x, 0.19, RADIUS + 0.3), Vector3(x * 2.2, 0.19, RADIUS + 11.0), 0.04)


func _update_readout() -> void:
	_readout.text = "%s\nกำลังซ่อมแซม %d%%" % [_readout.get_meta("who"), int(progress * 100.0)]


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_clock += delta
	var before := int(progress * 100.0)
	progress = minf(progress + RATE * delta, 0.99)
	_panel.set_shader_parameter("progress", progress)
	if int(progress * 100.0) != before:
		_update_readout()

	var climb := 0.5 - 0.5 * cos(_clock * 0.9)
	_scan.position.y = BED + 0.3 + climb * (_height - 0.6)
	_glow.light_energy = 1.0 + 0.25 * sin(_clock * 2.1)

	for arm: Dictionary in _arms:
		var side: float = arm["side"]
		var root: Vector3 = arm["root"]
		var wander := Vector3(sin(_clock * 1.3 + side) * 0.35, sin(_clock * 0.9 + side * 2.0) * 0.25, cos(_clock * 1.1 + side) * 0.3)
		var target := _focus + wander
		var elbow := root.lerp(target, 0.45) + Vector3(side * 0.6, 0.7, 0.2)
		var tip := target + (elbow - target).normalized() * 1.1
		_span(arm["upper"], root, elbow, 0.22)
		_span(arm["fore"], elbow, tip, 0.16)
		(arm["joint"] as Node3D).position = elbow
		(arm["tip"] as Node3D).position = tip
		var weld := 0.5 + 0.5 * sin(_clock * 31.0 + side * 3.0)
		_span(arm["beam"], tip, target, 0.03 + weld * 0.04)
