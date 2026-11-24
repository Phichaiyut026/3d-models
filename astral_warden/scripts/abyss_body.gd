class_name AbyssBody
extends Node3D
## อั้ม in the form of the ABYSS, as in aum.html: a body of pure black with nothing of the suit or hair showing,
## two white eyes burning very bright, a dark aura with red embers in it, and red lightning crawling over him.
## It has no bones of its own to drive: every frame it copies the pose of the player's rig, joint for joint.

const MODEL := "res://models/npc/aum.glb"
const TALL := 2.5 ## Metres. A head above Gemini.
const RIG_UNIT := 0.36 ## CosmicWarrior.MODEL_SCALE: rig units to metres.
const PIVOT := Vector3(0, 4.3, 0) ## Where the body tumbles round, in the model's own units.
## The rig's joints and the model's joints that follow them. Shins and feet are found under each thigh.
const FOLLOW := {
	"upper": "Spine", "armR": "ArmR", "foreR": "ForeR", "hand_R": "HandR",
	"armL": "ArmL", "foreL": "ForeL", "hand_L": "HandL", "legR": "ThighR", "legL": "ThighL",
}
const RED := Color(1.0, 0.08, 0.14)
const VIOLET := Color(0.62, 0.16, 1.0)

var rig: PoseRig
var size_scale := 1.0 ## Model units to metres.

var _model: Node3D
var _root: Node3D
var _joints := {} ## rig joint name -> [model joint, rest rotation]
var _eyes: Array[Node3D] = []
var _hands: Array[Node3D] = []
var _bolts: Array = [] ## [mesh instance, seconds left, length]
var _anchors: Array[Node3D] = [] ## Points on the body that the red lightning jumps between.
var _clock := 0.0
var _void: StandardMaterial3D
var _eye_mat: StandardMaterial3D


func _ready() -> void:
	var scene: Node3D = (load(MODEL) as PackedScene).instantiate()
	_model = Node3D.new()
	add_child(_model)
	_model.add_child(scene)
	var anim := scene.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim != null:
		anim.stop()
		anim.active = false
	_root = scene.find_child("Aum", true, false) as Node3D
	if _root == null:
		_root = scene
	_fit(scene)
	_paint(scene)
	_find_joints(scene)
	_build_eyes(scene)
	_build_aura()
	_build_pool()
	_build_anchors(scene)


## Stands the model on the ground at TALL metres, whatever units the page used.
func _fit(scene: Node3D) -> void:
	var box := AABB()
	var first := true
	var to_scene := scene.global_transform.affine_inverse()
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = node
		var b := (to_scene * m.global_transform) * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	size_scale = TALL / maxf(box.size.y, 0.01)
	_model.scale = Vector3.ONE * size_scale
	_model.position.y = -box.position.y * size_scale


## Everything goes black: no suit, no hair, no detail. Only the eyes will give light.
func _paint(scene: Node3D) -> void:
	_void = StandardMaterial3D.new()
	_void.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_void.disable_fog = true
	_void.albedo_color = Color(0, 0, 0)
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = node
		m.material_override = _void
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _find_joints(scene: Node3D) -> void:
	for rig_name: String in FOLLOW:
		_add_joint(rig_name, scene.find_child(FOLLOW[rig_name], true, false) as Node3D)
	for hand_name: String in ["HandR", "HandL"]:
		var hand := scene.find_child(hand_name, true, false) as Node3D
		if hand != null:
			var palm := Node3D.new()
			palm.position = Vector3(0, -0.45, 0)
			hand.add_child(palm)
			_hands.append(palm)
	for side: String in ["R", "L"]:
		var thigh := scene.find_child("Thigh" + side, true, false) as Node3D
		if thigh == null:
			continue
		var shin := thigh.find_child("Shin", true, false) as Node3D
		_add_joint("shin" + side, shin)
		if shin != null:
			_add_joint("foot" + side, shin.find_child("Foot", true, false) as Node3D)


func _add_joint(rig_name: String, joint: Node3D) -> void:
	if joint == null:
		return
	joint.rotation_order = EULER_ORDER_XYZ
	_joints[rig_name] = [joint, joint.rotation]


## Two eyes, each a hot core with a wide halo and a long flare, bright enough to read from across the valley.
func _build_eyes(scene: Node3D) -> void:
	var head := scene.find_child("Head", true, false) as Node3D
	if head == null:
		return
	_eye_mat = StandardMaterial3D.new()
	_eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_eye_mat.disable_fog = true
	_eye_mat.albedo_color = Color(1, 1, 1)
	for s: float in [-1.0, 1.0]:
		var eye := Node3D.new()
		# The eyes of aum.html sit at about (±0.15, 7.5, 0.4); the head joint stands at (0, 6.72, 0.02).
		eye.position = Vector3(s * 0.15, 0.78, 0.44)
		head.add_child(eye)
		_eyes.append(eye)
		var ball := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.08
		sphere.height = 0.09
		ball.mesh = sphere
		ball.material_override = _eye_mat
		eye.add_child(ball)
		for glow: Array in [[Vector2(0.55, 0.32), 1.6], [Vector2(1.5, 0.85), 0.7], [Vector2(2.6, 0.08), 1.0], [Vector2(4.6, 0.05), 0.55]]:
			eye.add_child(_glow_quad(glow[0], Color(1, 1, 1), glow[1]))


func _glow_quad(quad_size: Vector2, tint: Color, strength: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = quad_size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_fog = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.no_depth_test = false
	m.albedo_texture = _soft_dot()
	m.albedo_color = Color(tint.r * strength, tint.g * strength, tint.b * strength)
	quad.material = m
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


static var _dot: Texture2D
static func _soft_dot() -> Texture2D:
	if _dot != null:
		return _dot
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.25, Color(1, 1, 1, 0.6))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	_dot = t
	return _dot


## Black smoke rising off him, and inside it violet and red embers.
func _build_aura() -> void:
	for layer: Array in [
		[160, Color(0.03, 0.0, 0.05, 0.55), BaseMaterial3D.BLEND_MODE_MIX, 0.9, 1.9],
		[90, Color(0.5, 0.12, 0.95, 0.5), BaseMaterial3D.BLEND_MODE_ADD, 0.35, 0.8],
		[60, Color(1.0, 0.08, 0.12, 0.6), BaseMaterial3D.BLEND_MODE_ADD, 0.3, 0.7],
	]:
		var p := CPUParticles3D.new()
		p.amount = layer[0]
		p.lifetime = 1.6
		p.preprocess = 1.6
		p.local_coords = false
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(0.55, 1.15, 0.3)
		p.position = Vector3(0, 1.2, 0)
		p.direction = Vector3(0, 1, 0)
		p.spread = 25.0
		p.gravity = Vector3(0, 1.2, 0)
		p.initial_velocity_min = 0.2
		p.initial_velocity_max = 0.8
		p.scale_amount_min = layer[3]
		p.scale_amount_max = layer[4]
		var curve := Curve.new()
		curve.add_point(Vector2(0, 0.4))
		curve.add_point(Vector2(0.5, 1.0))
		curve.add_point(Vector2(1, 0.0))
		p.scale_amount_curve = curve
		var quad := QuadMesh.new()
		quad.size = Vector2(0.6, 0.6)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.disable_fog = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = layer[2]
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.vertex_color_use_as_albedo = true
		m.albedo_texture = _soft_dot()
		quad.material = m
		p.mesh = quad
		var fade := Gradient.new()
		var c: Color = layer[1]
		fade.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
		fade.colors = PackedColorArray([Color(c, 0.0), c, Color(c, 0.0)])
		p.color_ramp = fade
		add_child(p)


## A pool of darkness on the ground at his feet, with a ring of red and violet light at its edge.
func _build_pool() -> void:
	var disc := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(3.4, 3.4)
	quad.orientation = PlaneMesh.FACE_Y
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float a = smoothstep(1.0, 0.25, d) * 0.85;
	float ang = atan(p.y, p.x);
	float rim = exp(-pow((d - 0.82 - sin(ang * 7.0 + TIME * 2.0) * 0.04) / 0.035, 2.0));
	vec3 col = mix(vec3(0.5, 0.15, 0.9), vec3(1.0, 0.1, 0.15), 0.5 + 0.5 * sin(ang * 3.0 - TIME * 3.0)) * rim * 2.0;
	ALBEDO = col;
	ALPHA = max(a, rim);
}
"""
	var m := ShaderMaterial.new()
	m.shader = shader
	quad.material = m
	disc.mesh = quad
	disc.position.y = 0.04
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)


## Empty markers pinned to the joints, for the lightning to run between.
func _build_anchors(scene: Node3D) -> void:
	for joint_name: String in ["Spine", "Head", "ArmR", "ForeR", "HandR", "ArmL", "ForeL", "HandL", "ThighR", "ThighL", "Pelvis"]:
		var joint := scene.find_child(joint_name, true, false) as Node3D
		if joint == null:
			continue
		for i in 3:
			var a := Node3D.new()
			a.position = Vector3(randf_range(-0.4, 0.4), randf_range(-1.2, 0.4), randf_range(-0.3, 0.3))
			joint.add_child(a)
			_anchors.append(a)


func _process(delta: float) -> void:
	_clock += delta
	_follow_rig()
	var flicker := 0.85 + sin(_clock * 6.0) * 0.15
	if _eye_mat != null:
		_eye_mat.albedo_color = Color(flicker, flicker, flicker)
	_update_bolts(delta)
	# Red lightning crawls over the body: a short arc from one point on him to another close by.
	if visible and _anchors.size() > 1 and randf() < 0.55:
		var a := _anchors[randi() % _anchors.size()].global_position
		for tries in 6:
			var b := _anchors[randi() % _anchors.size()].global_position
			var d := a.distance_to(b)
			if d > 0.15 and d < 0.9:
				spark(a, b, RED, randf_range(0.08, 0.16), 0.012)
				break


func _follow_rig() -> void:
	if rig == null:
		return
	for rig_name: String in _joints:
		if not rig.joints.has(rig_name):
			continue
		var entry: Array = _joints[rig_name]
		(entry[0] as Node3D).rotation = (entry[1] as Vector3) + (rig.joints[rig_name] as Node3D).rotation
	# The rig's root: the bob, the lift and the tumble of rolls and falls, carried over to this body's size.
	var rot: Vector3 = rig._rot.get("root", Vector3.ZERO)
	var lift: Vector3 = rig._rot.get("lift", Vector3.ZERO) * rig.unit * RIG_UNIT / size_scale
	var tumble := Basis.from_euler(rot, EULER_ORDER_XYZ)
	_root.transform = Transform3D(tumble, PIVOT - tumble * PIVOT + lift)


## A jagged arc of lightning from `a` to `b`, gone in `life` seconds.
func spark(a: Vector3, b: Vector3, tint: Color, life: float, width: float) -> void:
	var mesh := ImmediateMesh.new()
	var d := b - a
	var n := 7
	var side := d.cross(Vector3.UP).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var up := side.cross(d).normalized()
	var pts: Array[Vector3] = [a]
	for i in range(1, n):
		var amp := d.length() * 0.3 * sin(float(i) / n * PI)
		pts.append(a + d * (float(i) / n) + side * randf_range(-amp, amp) + up * randf_range(-amp, amp))
	pts.append(b)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_fog = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, m)
	var cam := get_viewport().get_camera_3d()
	for i in pts.size() - 1:
		var p0 := pts[i]
		var p1 := pts[i + 1]
		var view := (cam.global_position - p0).normalized() if cam != null else Vector3.FORWARD
		var w := (p1 - p0).cross(view).normalized()
		for layer: Array in [[width * 4.0, Color(tint, 0.35)], [width, Color(1.0, 0.75, 0.7, 1.0)]]:
			var half: Vector3 = w * layer[0]
			var c: Color = layer[1]
			for v: Vector3 in [p0 - half, p0 + half, p1 + half, p0 - half, p1 + half, p1 - half]:
				mesh.surface_set_color(c)
				mesh.surface_add_vertex(v)
	mesh.surface_end()
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.top_level = true
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(inst)
	inst.global_transform = Transform3D.IDENTITY
	_bolts.append([inst, life, life])


func _update_bolts(delta: float) -> void:
	for i in range(_bolts.size() - 1, -1, -1):
		var entry: Array = _bolts[i]
		entry[1] -= delta
		if entry[1] <= 0.0:
			(entry[0] as Node).queue_free()
			_bolts.remove_at(i)
		else:
			(entry[0] as Node3D).visible = randf() > 0.25


## Gives the black body a thin violet edge, for a shadow that must read against a black sky.
func set_rim(tint: Color) -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, fog_disabled;
uniform vec3 rim = vec3(0.5, 0.12, 0.9);
void fragment() {
	ALBEDO = rim * pow(1.0 - abs(dot(NORMAL, VIEW)), 2.2) * 1.3;
}
"""
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("rim", Vector3(tint.r, tint.g, tint.b))
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		if mesh.material_override == _void:
			mesh.material_override = m


## Between the two hands, where the powers gather.
func hands_point() -> Vector3:
	if _hands.size() == 2:
		return _hands[0].global_position.lerp(_hands[1].global_position, 0.5)
	return global_position + Vector3(0, TALL * 0.55, 0) + global_basis.z * 0.6


## Where the eyes are, for powers that fire from them.
func eye_point() -> Vector3:
	return _eyes[0].global_position.lerp(_eyes[1].global_position, 0.5) if _eyes.size() == 2 else global_position + Vector3(0, TALL * 0.92, 0)
