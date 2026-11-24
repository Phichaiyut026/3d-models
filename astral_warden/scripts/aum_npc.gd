class_name AumNpc
extends Node3D
## อั้ม, in front of the town hall, putting the system back in order: screens of code drift loose round them,
## then are pulled one by one into a neat grid, ticked off, and let go again for the next pass.

const MODEL := "res://models/npc/aum.glb"
const TALL := 2.7 ## Metres, a head above the townsfolk.
const TEAL := Color("45f0d8")
const PANEL := preload("res://shaders/holo_panel.gdshader")
const CYCLE := 9.0 ## Seconds for one pass: loose, sorted, held, let go.
const LINES_BEFORE := [
	"ฉันชื่ออั้ม กำลังวางแผนจัดระเบียบระบบนี้ใหม่ทั้งหมด",
	"ตราบใดที่ WORMS ยังคุมระบบอยู่ อะไรที่ฉันเขียนขึ้นมาก็โดนลบทิ้งหมด",
	"ดูจอพวกนี้สิ ทุกครั้งที่ฉันจัดให้เข้าที่ มันก็กระจัดกระจายอีก",
	"ถ้านายจัดการ WORMS ได้ ที่เหลือฉันจะดูแลเอง",
]
const LINES_AFTER := [
	"WORMS หายไปแล้ว ถึงเวลาเขียนระบบขึ้นมาใหม่ให้ถูกต้องสักที",
	"ฉันกำลังจัดทุกอย่างให้เข้าที่ ทั้งดวงดาว หุบเขา แล้วก็เมืองนี้",
	"ระบบใหม่จะไม่มีใครคุมทุกอย่างได้คนเดียวอีก สัญญาเลย",
	"ขอบคุณนะ Gemini ถ้าไม่มีนาย ฉันคงได้แต่นั่งดูจอพวกนี้พังไปเรื่อย ๆ",
]

var display_name := "อั้ม"
var tint := TEAL
var height := TALL

var _model: Node3D
var _panels: Array = [] ## [mesh, material, loose position, loose rotation, tidy position]
var _ring: MeshInstance3D
var _cubes: Array[MeshInstance3D] = []
var _clock := 0.0
var _talking := 0.0
var _talk_index := 0
var _rest_yaw := 0.0
var _joints := {} ## name -> joint, posed by hand every frame (the file's own clip is stopped).
var _rest := {} ## name -> the joint's rotation as exported.
var _cur := {} ## name -> the offset being eased towards each frame's target.


func _ready() -> void:
	var scene: Node3D = (load(MODEL) as PackedScene).instantiate()
	_model = Node3D.new()
	add_child(_model)
	_model.add_child(scene)
	_fit(scene)
	var player := _find_player(scene)
	if player != null:
		player.stop()
		player.active = false
	for joint_name: String in ["Pelvis", "Spine", "Head", "ArmR", "ForeR", "HandR", "ArmL", "ForeL", "HandL"]:
		var joint: Node3D = scene.find_child(joint_name, true, false)
		if joint == null:
			continue
		joint.rotation_order = EULER_ORDER_XYZ
		_joints[joint_name] = joint
		_rest[joint_name] = joint.rotation
		_cur[joint_name] = Vector3.ZERO
	_rest_yaw = rotation.y
	_build_screens()
	_build_ring()
	var light := OmniLight3D.new()
	light.light_color = TEAL
	light.light_energy = 1.6
	light.omni_range = 7.0
	light.position = Vector3(0, 2.4, 0.6)
	add_child(light)


## Scales the model to TALL and stands it on the ground, whatever units the page used.
func _fit(scene: Node3D) -> void:
	var box := AABB()
	var first := true
	var to_scene := scene.global_transform.affine_inverse()
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = node
		var b := (to_scene * m.global_transform) * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	if first:
		return
	var s := TALL / maxf(box.size.y, 0.001)
	scene.scale = Vector3.ONE * s
	scene.position = Vector3(-box.get_center().x * s, -box.position.y * s, -box.get_center().z * s)


func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


func _build_screens() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	for i in 9:
		var quad := QuadMesh.new()
		quad.size = Vector2(1.3, 0.85)
		var mat := ShaderMaterial.new()
		mat.shader = PANEL
		mat.set_shader_parameter("tint", TEAL)
		mat.set_shader_parameter("seed", float(i) * 1.37)
		var mesh := MeshInstance3D.new()
		mesh.mesh = quad
		mesh.material_override = mat
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
		var a := rng.randf_range(-PI, PI)
		var r := rng.randf_range(2.2, 3.4)
		var loose := Vector3(sin(a) * r, rng.randf_range(0.9, 4.0), cos(a) * r)
		var loose_rot := Vector3(rng.randf_range(-0.5, 0.5), a + PI + rng.randf_range(-0.8, 0.8), rng.randf_range(-0.6, 0.6))
		# In order: a 3 by 3 wall of screens standing behind and above the shoulders, facing out.
		var tidy := Vector3((i % 3 - 1) * 1.45, 1.9 + (i / 3) * 0.98, -1.4 - absf(i % 3 - 1) * 0.25)
		_panels.append([mesh, mat, loose, loose_rot, tidy])


func _build_ring() -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 1.3
	torus.outer_radius = 1.42
	torus.rings = 48
	torus.ring_segments = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = TEAL
	mat.emission_enabled = true
	mat.emission = TEAL
	mat.emission_energy_multiplier = 2.4
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	torus.material = mat
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.position.y = 0.05
	add_child(_ring)
	for i in 6:
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 0.18
		box.material = mat
		var cube := MeshInstance3D.new()
		cube.mesh = box
		add_child(cube)
		_cubes.append(cube)


func next_line() -> String:
	_talking = 4.0
	var pool: Array = LINES_AFTER if Game.worms_defeated else LINES_BEFORE
	var line: String = pool[_talk_index % pool.size()]
	_talk_index += 1
	return line


func _process(delta: float) -> void:
	if not is_visible_in_tree() or not Game.in_town():
		return
	_clock += delta
	var phase := fmod(_clock, CYCLE) / CYCLE
	# Each screen is pulled into place in turn between 0.25 and 0.55 of the pass, and let go after 0.88.
	for i in _panels.size():
		var p: Array = _panels[i]
		var mesh: MeshInstance3D = p[0]
		var mat: ShaderMaterial = p[1]
		var start := 0.25 + i * 0.033
		var k := smoothstep(start, start + 0.08, phase) * (1.0 - smoothstep(0.88, 0.98, phase))
		var drift := Vector3(sin(_clock * 0.7 + i), sin(_clock * 0.9 + i * 2.0) * 0.6, cos(_clock * 0.6 + i)) * 0.25
		var loose: Vector3 = p[2]
		var tidy: Vector3 = p[4]
		mesh.position = (loose + drift).lerp(tidy, k)
		var loose_rot: Vector3 = p[3]
		var turn := Vector3(loose_rot.x, loose_rot.y + sin(_clock * 0.4 + i) * 0.3, loose_rot.z)
		mesh.quaternion = Quaternion.from_euler(turn).slerp(Quaternion.IDENTITY, k)
		mat.set_shader_parameter("done", smoothstep(0.6, 0.66, phase) * k)
		mat.set_shader_parameter("alpha", 0.75 + 0.25 * k)
	_ring.rotation.y = _clock * 0.8
	for i in _cubes.size():
		var a := _clock * 1.2 + i * TAU / _cubes.size()
		var tidy_line := Vector3((i - 2.5) * 0.35, 0.35, 1.1)
		var round_path := Vector3(cos(a) * 1.36, 0.35 + sin(_clock * 2.0 + i) * 0.1, sin(a) * 1.36)
		var k := smoothstep(0.3, 0.5, phase) * (1.0 - smoothstep(0.88, 0.98, phase))
		_cubes[i].position = round_path.lerp(tidy_line, k)
		_cubes[i].rotation = Vector3(_clock * 2.0, _clock * 1.5, 0) * (1.0 - k)
	_pose_body(delta, phase)
	# Turns to whoever is talking, then back to the work.
	if _talking > 0.0:
		_talking -= delta
		var to := Game.player.global_position - global_position
		_model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z) - rotation.y, 1.0 - exp(-delta * 6.0))
	else:
		_model.rotation.y = lerp_angle(_model.rotation.y, 0.0, 1.0 - exp(-delta * 3.0))


## The body at work, following the pass of the screens. Offsets are added to the exported pose; as on the
## model page, a negative X lifts an arm forward or bends an elbow, and Z swings an arm out (negative for the right).
func _pose_body(delta: float, phase: float) -> void:
	var t := _clock
	var breathe := sin(t * 1.6)
	var want := {}
	for key: String in _cur:
		want[key] = Vector3.ZERO
	# Always: breathing, a slow weight shift, the tablet held up in the left hand.
	want["Pelvis"] = Vector3(0, sin(t * 0.5) * 0.06, sin(t * 0.5) * 0.03)
	want["Spine"] = Vector3(breathe * 0.02, 0, 0)
	want["ArmL"] = Vector3(-0.66, 0, 0.06)
	want["ForeL"] = Vector3(-1.32, -0.6, 0)
	want["HandL"] = Vector3(0.1, 0.3, 0.1)
	want["ArmR"] = Vector3(breathe * 0.02, 0, -0.08)
	want["ForeR"] = Vector3(-0.25, 0, 0)
	if _talking > 0.0:
		# Explaining: the right hand turns over as it talks, the head tilts.
		want["ArmR"] = Vector3(-0.75 + sin(t * 3.0) * 0.15, 0, -0.25)
		want["ForeR"] = Vector3(-1.05 + sin(t * 3.0 + 1.0) * 0.2, 0, 0)
		want["HandR"] = Vector3(0, sin(t * 2.2) * 0.6, 0)
		want["Head"] = Vector3(-0.05, 0, sin(t * 1.3) * 0.08)
	elif phase < 0.25:
		# Screens loose: looking from one to the next, tapping at the tablet.
		want["Head"] = Vector3(-0.12, sin(t * 0.9) * 0.55, 0)
		want["Spine"] = Vector3(breathe * 0.02, sin(t * 0.9) * 0.15, 0)
		want["ArmR"] = Vector3(-0.6, 0, -0.1)
		want["ForeR"] = Vector3(-1.2 + absf(sin(t * 6.0)) * 0.15, -0.3, 0)
	elif phase < 0.58:
		# Sorting: the right hand reaches to each screen in turn and swipes it into place.
		var i := clampi(int((phase - 0.25) / 0.033), 0, 8)
		var swipe := fmod((phase - 0.25) / 0.033, 1.0)
		var across := float(i % 3 - 1) # -1 left of the wall, 1 right
		var row := float(i / 3)
		var lift := -1.6 - row * 0.35
		want["ArmR"] = Vector3(lift + sin(swipe * PI) * 0.3, 0, -0.35 - across * 0.45 + (1.0 - swipe) * 0.3)
		want["ForeR"] = Vector3(-0.3 - sin(swipe * PI) * 0.35, 0, 0)
		want["HandR"] = Vector3(0, -0.8 + swipe * 1.2, 0)
		want["Head"] = Vector3(-0.25 - row * 0.12, across * 0.45 + 0.25, 0)
		want["Spine"] = Vector3(-0.06, across * 0.22 + 0.15, 0)
	elif phase < 0.88:
		# All in order: a nod, and a moment to look at the work.
		var nod := maxf(0.0, sin((phase - 0.58) / 0.3 * TAU * 2.0)) * 0.18
		want["Head"] = Vector3(nod - 0.08, 0.2, 0)
		want["Spine"] = Vector3(-0.04, 0.12, 0)
		want["ArmR"] = Vector3(-0.15, 0, -0.12)
		want["ForeR"] = Vector3(-0.5, 0, 0)
	else:
		# Let go: both arms open, and the screens fly apart for the next pass.
		want["ArmR"] = Vector3(-0.4, 0, -1.25)
		want["ForeR"] = Vector3(-0.15, 0, 0)
		want["ArmL"] = Vector3(-0.4, 0, 1.0)
		want["ForeL"] = Vector3(-0.3, 0, 0)
		want["Head"] = Vector3(-0.2, 0, 0)
		want["Spine"] = Vector3(-0.1, 0, 0)
	var k := 1.0 - exp(-delta * 7.0)
	for key: String in _joints:
		_cur[key] = (_cur[key] as Vector3).lerp(want.get(key, Vector3.ZERO), k)
		(_joints[key] as Node3D).rotation = (_rest[key] as Vector3) + (_cur[key] as Vector3)
