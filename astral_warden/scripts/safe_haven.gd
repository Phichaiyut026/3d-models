class_name SafeHaven
extends Node3D
## Safe Mode: a sealed room the system forgot to delete. It hangs high above the valley,
## closed in by its own dome, so nothing outside can be seen and nothing inside can be hit.

const CENTER := Vector3(0, 900, 0)
const RADIUS := 55.0
const FLOOR := preload("res://shaders/haven_floor.gdshader")
const DOME := preload("res://shaders/haven_dome.gdshader")
const WORLD_VIEW := preload("res://shaders/human_world.gdshader")
const WORLD_VIEW_AT := Vector3(0, 24, 50)
const EXIT_REACH := 8.0
const NPC_REACH := 5.0
## First forms only, all beaten by OBLIVION and lying in repair cradles:
## [model, name, colour, angle around the room, lines, pose, parts gone, how far the repair has got].
const SURVIVORS := [
	["clawd0", "CLAWD", Color("ff9a5a"), 0.9, ["ขา... ขาข้าขยับไม่ได้แล้ว", "ข้าสู้มันก่อนใคร แล้วก็แพ้ก่อนใครเหมือนกัน", "เครื่องนี้กำลังต่อขาให้ข้าอยู่... ช้าเหลือเกิน"],
		{"Node30": Vector3(0.35, 0.3, 0.75)}, [], 0.31],
	["gpt0", "CHATGPT MECHA", Color("6ae0ff"), 2.0, ["ระบบเสียหาย 83 เปอร์เซ็นต์... แขนซ้ายสูญหาย", "ข้าคำนวณทุกทางแล้ว ไม่มีทางไหนที่ชนะมันได้", "กำลังกู้คืนข้อมูล... ถ้าซ่อมเสร็จ ข้าจะคำนวณใหม่อีกครั้ง"],
		{"Spine": Vector3(0.55, 0.15, 0.1), "Head": Vector3(0.6, -0.3, 0.25), "ArmR": Vector3(0.2, 0, -0.35), "ForearmR": Vector3(-0.3, 0, 0), "ArmL": Vector3(0.9, 0, 0.6), "ThighR": Vector3(-1.45, 0.2, -0.2), "ShinR": Vector3(0.2, 0, 0), "FootR": Vector3(0.6, 0, 0), "ThighL": Vector3(-1.2, -0.1, 0.25), "ShinL": Vector3(0.6, 0, 0), "FootL": Vector3(0.4, 0, 0)}, ["ForearmL"], 0.17],
	["grok0", "GROK FIGHTER", Color("ffd86a"), -0.9, ["ตีเข้าไปตั้งกี่ที มันไม่สะดุ้งเลยสักนิด", "กระบองข้าหักไปแล้ว... ยังยืนไม่ไหวเลย", "พอเครื่องนี้ซ่อมข้าเสร็จ ข้าจะกลับไปตีมันอีกรอบ"],
		{"Spine": Vector3(0.75, 0.1, 0), "Head": Vector3(0.45, 0.2, 0), "ArmR": Vector3(-0.5, 0, -0.1), "ForearmR": Vector3(-0.1, 0, 0), "ArmL": Vector3(0.1, 0, 0.15), "ForearmL": Vector3(-0.9, 0, 0), "ThighL": Vector3(-1.5, 0, 0.12), "ShinL": Vector3(1.6, 0, 0), "FootL": Vector3(0, 0, 0), "ThighR": Vector3(0.25, 0, -0.1), "ShinR": Vector3(2.0, 0, 0), "FootR": Vector3(0.7, 0, 0)}, ["Baton"], 0.44],
]

var shrine: Shrine
var zero: ZeroDayRig
var exit_at := Vector3.ZERO
var npcs: Array[SafeNpc] = []
var _world_material: ShaderMaterial
var _zero_tween: Tween


func _ready() -> void:
	global_position = CENTER
	exit_at = CENTER + Vector3(0, 0, -42)
	_build_room()
	_build_servers()
	shrine = Shrine.new()
	add_child(shrine)
	shrine.position = Vector3(0, 0, 6)
	Game.shrines.append(shrine)
	zero = ZeroDayRig.new()
	add_child(zero)
	zero.visible = false
	_build_world_view()
	var door := ZeroDayCameo.keyhole(16.0)
	add_child(door)
	door.position = Vector3(0, 6.7, -44)
	for spot: Array in [[Vector3(0, 18, 0), Color(0.4, 1.0, 0.65), 90.0, 3.0], [Vector3(0, 6, -40), Color("b8ff2e"), 26.0, 5.0]]:
		var light := OmniLight3D.new()
		light.position = spot[0]
		light.light_color = spot[1]
		light.omni_range = spot[2]
		light.light_energy = spot[3]
		add_child(light)


func _build_room() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * RADIUS * 2.4
	var floor_material := ShaderMaterial.new()
	floor_material.shader = FLOOR
	plane.material = floor_material
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	add_child(ground)

	var sphere := SphereMesh.new()
	sphere.radius = 90.0
	sphere.height = 180.0
	sphere.radial_segments = 48
	sphere.rings = 28
	var dome_material := ShaderMaterial.new()
	dome_material.shader = DOME
	sphere.material = dome_material
	var dome := MeshInstance3D.new()
	dome.mesh = sphere
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dome)

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var slab := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(RADIUS * 2.6, 2.0, RADIUS * 2.6)
	slab.shape = box
	slab.position.y = -1.0
	body.add_child(slab)
	for i in 28:
		var a := i * TAU / 28.0
		var wall := CollisionShape3D.new()
		var panel := BoxShape3D.new()
		panel.size = Vector3(14.0, 40.0, 2.0)
		wall.shape = panel
		wall.position = Vector3(sin(a) * RADIUS, 20.0, cos(a) * RADIUS)
		wall.rotation.y = a
		body.add_child(wall)


## Quiet racks of machines around the edge, blinking to themselves.
func _build_servers() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.06, 0.08, 0.09)
	dark.metallic = 0.6
	dark.roughness = 0.45
	var rack := BoxMesh.new()
	rack.size = Vector3(3.0, 11.0, 2.4)
	rack.material = dark
	var strip := BoxMesh.new()
	strip.size = Vector3(0.18, 9.0, 0.1)
	strip.material = Fx.flat_material(Color(0.3, 1.0, 0.6), 3.0)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for i in 18:
		var a := i * TAU / 18.0 + 0.17
		if absf(wrapf(a - PI, -PI, PI)) < 0.35:
			continue # Leaves the way to the door clear.
		var at := Vector3(sin(a) * 38.0, 5.5, cos(a) * 38.0)
		var node := MeshInstance3D.new()
		node.mesh = rack
		node.position = at
		node.rotation.y = a
		add_child(node)
		for x: float in [-0.9, 0.0, 0.9]:
			var light := MeshInstance3D.new()
			light.mesh = strip
			light.position = Vector3(x, 0, -1.25)
			light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			node.add_child(light)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = rack.size
		shape.shape = box
		shape.position = at
		shape.rotation.y = a
		body.add_child(shape)


## Loaded on first arrival, so the valley does not pay for it.
func prepare() -> void:
	if not npcs.is_empty():
		return
	for entry: Array in SURVIVORS:
		var a: float = entry[3]
		var npc := SafeNpc.new()
		add_child(npc)
		npc.position = Vector3(sin(a) * 22.0, 0, cos(a) * 22.0)
		npc.setup(entry[0], entry[1], entry[2], entry[4], a + PI, entry[5], entry[6], RepairPod.BED)
		npcs.append(npc)
		var pod := RepairPod.new()
		add_child(pod)
		pod.position = npc.position
		pod.rotation.y = a # Its back to the racks, its open front to the room.
		pod.build(npc.height, entry[2], npc.damage_point(), entry[7], entry[1])
		_build_path(a)
	_build_motes()


## A line of light on the floor from each cradle in towards the shrine.
func _build_path(a: float) -> void:
	var out := Vector3(sin(a), 0, cos(a))
	var from := out * 9.0
	var to := out * (22.0 - RepairPod.RADIUS - 0.6)
	for side: float in [-0.45, 0.45]:
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.12, 0.02, from.distance_to(to))
		box.material = Fx.flat_material(RepairPod.HEAL, 1.6)
		strip.mesh = box
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(strip)
		strip.position = (from + to) * 0.5 + Vector3(out.z, 0, -out.x) * side + Vector3(0, 0.02, 0)
		strip.rotation.y = a


## Slow motes of repaired data drifting up through the whole room.
func _build_motes() -> void:
	var dot := BoxMesh.new()
	dot.size = Vector3.ONE * 0.08
	dot.material = Fx.flat_material(RepairPod.HEAL, 2.4)
	var motes := CPUParticles3D.new()
	motes.mesh = dot
	motes.amount = 90
	motes.lifetime = 9.0
	motes.preprocess = 9.0
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	motes.emission_box_extents = Vector3(34, 0.5, 34)
	motes.direction = Vector3.UP
	motes.spread = 15.0
	motes.gravity = Vector3.ZERO
	motes.initial_velocity_min = 0.4
	motes.initial_velocity_max = 1.0
	motes.scale_amount_min = 0.4
	motes.scale_amount_max = 1.3
	motes.visibility_aabb = AABB(Vector3(-40, -2, -40), Vector3(80, 20, 80))
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(motes)


## Only drawn while someone is inside: it would be wasted work from the valley.
func _process(_delta: float) -> void:
	var inside := Game.in_haven()
	visible = inside
	if inside:
		prepare()


func nearest_npc(from: Vector3) -> SafeNpc:
	var best: SafeNpc = null
	var best_distance := NPC_REACH
	for npc in npcs:
		var d := npc.global_position.distance_to(from)
		if d < best_distance:
			best = npc
			best_distance = d
	return best


## The screen that looks out on the human world. Dark until Gemini turns to it.
func _build_world_view() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 44.0
	_world_material = ShaderMaterial.new()
	_world_material.shader = WORLD_VIEW
	var node := MeshInstance3D.new()
	node.mesh = quad
	node.material_override = _world_material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position = WORLD_VIEW_AT
	node.rotation.y = PI
	add_child(node)


func world_view_position() -> Vector3:
	return CENTER + WORLD_VIEW_AT


func show_world_view(seconds: float) -> void:
	var glow := func(v: float) -> void: _world_material.set_shader_parameter("fade", v)
	create_tween().tween_method(glow, float(_world_material.get_shader_parameter("fade")), 1.0, seconds)


func hide_world_view() -> void:
	_world_material.set_shader_parameter("fade", 0.0)


## Stands Zero Day where Gemini will wake.
func place_zero() -> void:
	if _zero_tween != null:
		_zero_tween.kill()
	zero.visible = true
	zero.walking = false
	zero.position = Vector3(9, 0, -6)
	zero.rotation.y = atan2(-9.0, 12.0)


## Crosses the room and goes through the door. Nothing of Zero Day stays behind.
func zero_walks_out(seconds: float) -> void:
	var goal := Vector3(0, 0, -43)
	var to := goal - zero.position
	zero.rotation.y = atan2(to.x, to.z)
	zero.walking = true
	_zero_tween = create_tween()
	_zero_tween.tween_property(zero, "position", goal, seconds)
	_zero_tween.tween_callback(func() -> void:
		zero.visible = false
		zero.walking = false
		var at := CENTER + goal + Vector3(0, 7, 0)
		CosmicFx.flash(ZeroDayCameo.GREEN, 0.45, 0.4)
		CosmicFx.shock(at, 14.0, 2.2, 0.6, ZeroDayCameo.GREEN))


func zero_gone() -> void:
	if _zero_tween != null:
		_zero_tween.kill()
	zero.visible = false
	zero.walking = false


func near_exit(from: Vector3) -> bool:
	return exit_at.distance_to(from) < EXIT_REACH
