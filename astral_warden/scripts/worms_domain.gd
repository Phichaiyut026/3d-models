class_name WormsDomain
extends Node3D
## WORMS' own system: a black-and-red space outside the valley, reached through the red gate that
## opens in the tower's arena once OBLIVION has fallen. Its floor is the ground for everything inside.

const CENTER := Vector3(900, 1600, 900) ## Off the valley's terrain, so nothing there can stand on this floor by mistake.
const RADIUS := 70.0
const ENTRY := Vector3(0, 0, 46) ## Where the gate puts the warrior, from the centre.
const BOSS_HOME := Vector3(0, 0, -10)
const EXIT := Vector3(0, 0, 58)
const REACH := 7.0
const SKY := preload("res://shaders/worms_sky.gdshader")
const FLOOR := preload("res://shaders/worms_floor.gdshader")
const RED := Color(1.0, 0.06, 0.19)

var exit_gate: Node3D
var _slabs: Array = [] ## [node, angle, radius, height, bob]
var _clock := 0.0


static func contains(x: float, z: float) -> bool:
	return Vector2(x - CENTER.x, z - CENTER.z).length() < 400.0


func _ready() -> void:
	global_position = CENTER
	_build_floor()
	_build_sky()
	_build_skyline()
	_build_slabs()
	exit_gate = WormsDomain.gate(RED)
	add_child(exit_gate)
	exit_gate.position = EXIT
	exit_gate.visible = false
	var light := OmniLight3D.new()
	light.light_color = RED
	light.omni_range = 120.0
	light.light_energy = 2.5
	light.position = Vector3(0, 30, 0)
	add_child(light)


func _build_floor() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * RADIUS * 2.4
	var material := ShaderMaterial.new()
	material.shader = FLOOR
	material.set_shader_parameter("radius", RADIUS)
	plane.material = material
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	add_child(ground)
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
	# Unseen walls at the edge of the floor: there is nowhere else in this system to go.
	for i in 32:
		var a := i * TAU / 32.0
		var wall := CollisionShape3D.new()
		var panel := BoxShape3D.new()
		panel.size = Vector3(16.0, 200.0, 2.0)
		wall.shape = panel
		wall.position = Vector3(sin(a) * RADIUS, 100.0, cos(a) * RADIUS)
		wall.rotation.y = a
		body.add_child(wall)


func _build_sky() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 600.0
	sphere.height = 1200.0
	sphere.radial_segments = 32
	sphere.rings = 20
	var material := ShaderMaterial.new()
	material.shader = SKY
	sphere.material = material
	var dome := MeshInstance3D.new()
	dome.mesh = sphere
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dome.extra_cull_margin = 1200.0
	add_child(dome)


## A dead skyline of black towers, a few windows still lit red.
func _build_skyline() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.02, 0.004, 0.012)
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.disable_fog = true # The valley's haze must not reach in here.
	var lit := Fx.flat_material(RED, 1.6)
	for i in 70:
		var a := i / 70.0 * TAU + sin(i * 12.9) * 0.05
		var r := 150.0 + (sin(i * 78.2) * 0.5 + 0.5) * 120.0
		var h := 30.0 + fposmod(i * 37.0, 90.0)
		var w := 8.0 + fposmod(i * 13.0, 10.0)
		var box := BoxMesh.new()
		box.size = Vector3(w, h, w)
		box.material = dark
		var tower := MeshInstance3D.new()
		tower.mesh = box
		tower.position = Vector3(cos(a) * r, h * 0.5 - 20.0, sin(a) * r)
		tower.rotation.y = a
		tower.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tower)
		if i % 3 == 0:
			var light := BoxMesh.new()
			light.size = Vector3(w * 0.3, 0.6, w + 0.1)
			light.material = lit
			var window := MeshInstance3D.new()
			window.mesh = light
			window.position = Vector3(0, h * (0.2 + fposmod(i * 0.37, 0.25)), 0)
			tower.add_child(window)


## Slabs of data hanging in a slow ring overhead.
func _build_slabs() -> void:
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.03, 0.01, 0.02)
	dark.metallic = 0.5
	dark.disable_fog = true
	var edge := Fx.flat_material(RED, 1.8)
	for i in 14:
		var g := Node3D.new()
		add_child(g)
		var box := BoxMesh.new()
		box.size = Vector3(6.0, 9.0, 0.5)
		box.material = dark
		var slab := MeshInstance3D.new()
		slab.mesh = box
		g.add_child(slab)
		var trim := BoxMesh.new()
		trim.size = Vector3(6.2, 0.2, 0.6)
		trim.material = edge
		for y: float in [-4.5, 4.5]:
			var t := MeshInstance3D.new()
			t.mesh = trim
			t.position.y = y
			g.add_child(t)
		_slabs.append([g, i / 14.0 * TAU, 46.0 + (i % 3) * 9.0, 18.0 + (i * 7 % 5) * 4.0, i * 1.7])


## The red gate: a ring of the system's colour with a bright seam through it. Faces +Z.
static func gate(tint: Color) -> Node3D:
	var holder := Node3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 4.6
	torus.outer_radius = 5.2
	torus.rings = 6
	torus.ring_segments = 4
	torus.material = Fx.flat_material(tint, 2.2)
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.rotation.x = PI * 0.5
	ring.position.y = 5.6
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(ring)
	var inner := WormsModel.wire_cube(3.0, 0.14, tint, 2.4)
	inner.position.y = 5.6
	inner.name = "Cube"
	holder.add_child(inner)
	var quad := QuadMesh.new()
	quad.size = Vector2(12, 12)
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/glow.gdshader")
	material.set_shader_parameter("color", tint)
	material.set_shader_parameter("strength", 1.2)
	quad.material = material
	var glow := MeshInstance3D.new()
	glow.mesh = quad
	glow.position.y = 5.6
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(glow)
	var light := OmniLight3D.new()
	light.light_color = tint
	light.omni_range = 18.0
	light.light_energy = 3.0
	light.position.y = 5.6
	holder.add_child(light)
	return holder


func near_exit(at: Vector3) -> bool:
	return exit_gate.visible and to_global(EXIT).distance_to(at) < REACH


func _process(delta: float) -> void:
	_clock += delta
	for s: Array in _slabs:
		var node: Node3D = s[0]
		var a: float = s[1] + _clock * 0.04
		node.position = Vector3(cos(a) * s[2], s[3] + sin(_clock * 0.8 + s[4]) * 0.8, sin(a) * s[2])
		node.rotation.y = -a + PI * 0.5
	if exit_gate.visible:
		(exit_gate.get_node("Cube") as Node3D).rotation = Vector3(_clock * 0.5, _clock * 0.8, 0)
