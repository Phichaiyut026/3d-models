class_name CosmicShow
extends Node3D
## Plays a power the way cosmic_warrior.html does. The stage is the web scene placed at the
## warrior: its +Z is the way the warrior faces, and one web unit is `K` metres.

const K := 0.36
const CREAM := Color("fff2d0")
const AMBER := Color("ffc86a")
const FALL := Vector3(0.28, -1.0, 0.22)
const HOLE_POS := Vector3(0, 25, 12)
const WORLD_C := Vector3(0, 16, 0)
const GALAXY_POS := Vector3(0, 15, -10)
const DOME_RADIUS := 1600.0
const SKY_DOME := preload("res://shaders/sky_dome.gdshader")
const HOLE_DISC := preload("res://shaders/hole_disc.gdshader")
const UNIVERSE := preload("res://shaders/universe.gdshader")
const ARGON_SCAN := preload("res://shaders/argon_scan.gdshader")
const ARGON_WALL := preload("res://shaders/argon_wall.gdshader")
const ARGON_CUBE := preload("res://shaders/argon_cube.gdshader")
const ARGON_RIFT := preload("res://shaders/argon_rift.gdshader")
const ARGON_INSTALL := preload("res://shaders/argon_install.gdshader")
const CYAN := Color("3fe8ff")
const MINT := Color("7dffc8")
const PALE_CYAN := Color("e0fffa")
const THREAT := Color("ff2f4a")
const SIGIL_POS := Vector3(0, 30, 45) ## In front and above, so the camera behind the warrior sees it.
const WALL_TIME := 3.5 ## The FIREWALL outlasts the move that raised it, but not by much.

var wide := 0.0 ## How far the camera pulls out, read by the player.
var turn := 0.0 ## How far the camera swings round the warrior, in radians, read by the player.

var _p: Player
var _move := {}
var _q := 0.0
var _shake := 0.0
var _flash := 0.0
var _was_armed := false
var _stage: Node3D
var _light: OmniLight3D
var _dome: MeshInstance3D
var _dome_mat: ShaderMaterial
var _galaxy: MeshInstance3D
var _galaxy_mat: ShaderMaterial
var _hole_core: MeshInstance3D
var _hole_disc: MeshInstance3D
var _hole_mat: ShaderMaterial
var _nova: MeshInstance3D
var _nova_mat: ShaderMaterial
var _rift_floor: MeshInstance3D
var _rift_mat: ShaderMaterial
var _rift_flame: Array
var _tail: Array
var _core: Array
var _universes: Array = [] ## [node, home, delay, size]
var _meteors: Array = [] ## [node, material, landing point]
var _meteor_center := Vector3.ZERO
var _inflow_clock := 0.0
var _white_on := false
var _shatter_on := false
var _scan_disc: MeshInstance3D
var _scan_mat: ShaderMaterial
var _scan_origin := Vector3.ZERO
var _wall: MeshInstance3D
var _wall_mat: ShaderMaterial
var _wall_center := Vector3.ZERO
var _wall_left := 0.0
var _wall_age := 9.0
var _sigil: MeshInstance3D
var _sigil_mat: ShaderMaterial
var _patch_rings: Array = [] ## [node, material]
var _cubes: Array = [] ## [node, material, enemy, age, crushing]
var _move_id := ""
var _unity: UnitedWave


func _ready() -> void:
	_stage = Node3D.new()
	add_child(_stage)
	_unity = UnitedWave.new()
	add_child(_unity)
	_light = OmniLight3D.new()
	_light.light_color = AMBER
	_light.omni_range = 70.0
	_light.position = Vector3(0, 12, 0)
	_stage.add_child(_light)

	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 32
	sphere.rings = 22
	var made := _piece(sphere, SKY_DOME, self)
	_dome = made[0]
	_dome_mat = made[1]
	_dome.scale = Vector3.ONE * DOME_RADIUS

	made = _piece(QuadMesh.new(), CosmicFx.GALAXY, _stage)
	_galaxy = made[0]
	_galaxy_mat = made[1]
	_galaxy.position = GALAXY_POS

	var core_mesh := SphereMesh.new()
	core_mesh.radius = 1.0
	core_mesh.height = 2.0
	core_mesh.material = Fx.flat_material(Color.BLACK, 1.0)
	_hole_core = MeshInstance3D.new()
	_hole_core.mesh = core_mesh
	_hole_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_hole_core.position = HOLE_POS
	_stage.add_child(_hole_core)
	made = _piece(QuadMesh.new(), HOLE_DISC, _stage)
	_hole_disc = made[0]
	_hole_mat = made[1]
	_hole_disc.position = HOLE_POS

	var shell := SphereMesh.new()
	shell.radius = 1.0
	shell.height = 2.0
	shell.radial_segments = 40
	shell.rings = 24
	made = _piece(shell, CosmicFx.NOVA, _stage)
	_nova = made[0]
	_nova_mat = made[1]
	_nova.position = Vector3(0, 15, 0)

	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE
	made = _piece(plane, CosmicFx.RIFT, _stage)
	_rift_floor = made[0]
	_rift_mat = made[1]
	_rift_floor.scale = Vector3(26, 1, 300)
	_rift_floor.position = Vector3(0, 0.3, 0)

	_rift_flame = CosmicFx.flame(170.0, 4.4, Color("ffd98a"), self)
	_tail = CosmicFx.flame(34.0, 6.0, Color("ffd98a"), self)
	_core = CosmicFx.flame(0.02, 7.0, Color("fff0c8"), self)

	for i in 72:
		var quad := QuadMesh.new()
		var piece := _piece(quad, UNIVERSE, _stage)
		(piece[1] as ShaderMaterial).set_shader_parameter("hue", CosmicFx.HUES[i % CosmicFx.HUES.size()])
		var y := 0.05 + fposmod(i * 0.618, 1.0) * 0.95
		var around := i * 2.39996
		var ring := sqrt(1.0 - y * y)
		var reach := 56.0 + (i * 37 % 40)
		var home := Vector3(cos(around) * ring * reach, y * reach * 0.75 + 6.0, sin(around) * ring * reach)
		_universes.append([piece[0], home, (i * 13 % 60) / 100.0, 6.0 + (i * 29 % 11)])
	_build_argon()
	_hide_all()


## The stage pieces of GEMINI ARGON's powers.
func _build_argon() -> void:
	var disc := PlaneMesh.new()
	disc.size = Vector2(2, 2)
	var made := _piece(disc, ARGON_SCAN, self)
	_scan_disc = made[0]
	_scan_mat = made[1]
	var dome := SphereMesh.new()
	dome.is_hemisphere = true
	dome.radius = 1.0
	dome.height = 1.0
	dome.radial_segments = 64
	dome.rings = 24
	made = _piece(dome, ARGON_WALL, self)
	_wall = made[0]
	_wall_mat = made[1]
	_wall.visible = false
	made = _piece(QuadMesh.new(), ARGON_INSTALL, _stage)
	_sigil = made[0]
	_sigil_mat = made[1]
	for i in 7:
		var torus := TorusMesh.new()
		torus.inner_radius = 0.955
		torus.outer_radius = 1.045
		torus.rings = 6
		torus.ring_segments = 6
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		material.albedo_color = Color(MINT, 0.0)
		torus.material = material
		var node := MeshInstance3D.new()
		node.mesh = torus
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		_patch_rings.append([node, material])


func _piece(mesh: Mesh, shader: Shader, parent: Node3D) -> Array:
	var material := ShaderMaterial.new()
	material.shader = shader
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.extra_cull_margin = 2000.0
	parent.add_child(node)
	return [node, material]


func start(p: Player, id: String) -> void:
	_p = p
	_move_id = id
	_move = CosmicMoves.all()[id]
	_q = 0.0
	var ahead := p.forward()
	_stage.global_transform = Transform3D(Basis.looking_at(-ahead, Vector3.UP).scaled(Vector3.ONE * K), p.global_position)
	_was_armed = p.rig.is_armed
	if id == "unity":
		_unity.begin(p, _stage)
	# ARGON plays the same stage in the colours of a clean system.
	var argon := _move.has("argon")
	_rift_mat.shader = ARGON_RIFT if argon else CosmicFx.RIFT
	_rift_flame[1].set_shader_parameter("color", MINT if argon else Color("ffd98a"))
	_core[1].set_shader_parameter("color", Color("dcfffa") if argon else Color("fff0c8"))
	_nova_mat.set_shader_parameter("inner", Color(0.25, 0.9, 1.0) if argon else Color(1.0, 0.66, 0.26))
	_light.light_color = CYAN if argon else AMBER
	if _move.has("blade"):
		p.rig.set_armed_instant(true)
	if id == "starfall":
		_meteor_center = CosmicSkills.aim_point(p, 15.0)


## `q` is how far through the move the player is, from 0 to 1.
func update(q: float) -> void:
	if _move.is_empty():
		return
	q = minf(q, 1.0)
	var fx: Array = _move["fx"]
	for event: Array in fx:
		if _q < event[0] and q >= event[0]:
			_fire(event[1], event[2] if event.size() > 2 else 0.0)
	_q = q
	_apply()


func channel(key: String) -> float:
	return 0.0 if _move.is_empty() else CosmicMoves.channel(_move, key, _q)


func finish() -> void:
	if _move.is_empty():
		return
	if _move.has("blade") and not _was_armed:
		_p.rig.set_armed_instant(false)
	_end()


## Cuts a power short. Meteors still in the air go too, and so does the FIREWALL.
func stop() -> void:
	for meteor: Array in _meteors:
		meteor[0].queue_free()
	_meteors.clear()
	_wall_left = 0.0
	_wall.visible = false
	for cube: Array in _cubes:
		cube[0].queue_free()
	_cubes.clear()
	_end()


func _end() -> void:
	if _p != null:
		_p.rig.set_blade_growth(0.0)
		_p.rig.argon_orbit = 0.0
		_p.rig.argon_shield = 0.0
	_move = {}
	_move_id = ""
	_q = 0.0
	_hide_all()
	_unity.hide_all()


func _hide_all() -> void:
	wide = 0.0
	turn = 0.0
	_flash = 0.0
	_light.light_energy = 0.0
	for node: Node3D in [_dome, _galaxy, _hole_core, _hole_disc, _nova, _rift_floor, _rift_flame[0], _tail[0], _core[0], _scan_disc, _sigil]:
		node.visible = false
	for ring: Array in _patch_rings:
		ring[0].visible = false
	for universe: Array in _universes:
		universe[0].visible = false
	if _white_on and Game.hud != null:
		Game.hud.screen_flash.visible = false
	if _shatter_on and Game.hud != null:
		Game.hud.screen_shatter.visible = false
	_white_on = false
	_shatter_on = false


## Shows every piece once behind the loading screen, so its first real use cannot hitch.
func warm(at: Vector3) -> void:
	_stage.global_position = at
	for node: Node3D in [_dome, _galaxy, _hole_core, _hole_disc, _nova, _rift_floor, _rift_flame[0], _tail[0], _core[0], _scan_disc, _sigil, _wall]:
		node.visible = true
	_scan_disc.global_position = at
	_wall.global_position = at
	(_universes[0][0] as Node3D).visible = true
	(_patch_rings[0][0] as Node3D).visible = true
	_add_cube(null, at)
	_unity.warm(_stage, at)


func _apply() -> void:
	var p := _p
	wide = channel("wide")
	turn = channel("camTurn")
	if _move_id == "unity":
		_unity.apply(self, Time.get_ticks_msec() / 1000.0)
	var dom := channel("dom")
	_dome.visible = dom > 0.01
	_dome_mat.set_shader_parameter("a", dom)

	var gal := channel("gal")
	_galaxy.visible = gal > 0.004
	_galaxy.basis = Basis(Vector3.RIGHT, -1.16) * Basis(Vector3.BACK, Time.get_ticks_msec() * 0.00008) * Basis.from_scale(Vector3.ONE * (10.0 + gal * 250.0))
	_galaxy_mat.set_shader_parameter("fade", minf(1.0, gal * 1.6))

	var bh := channel("bh")
	_hole_core.visible = bh > 0.02
	_hole_disc.visible = _hole_core.visible
	_hole_core.scale = Vector3.ONE * maxf(bh * 5.4, 0.01)
	_hole_disc.scale = Vector3.ONE * maxf(bh * 32.0, 0.01)
	_hole_mat.set_shader_parameter("a", minf(1.0, bh * 1.5))
	if _hole_core.visible:
		CosmicSkills.hole_pull(p, _stage.to_global(HOLE_POS), bh)

	var sn := channel("sn")
	_nova.visible = sn > 0.002 and sn < 0.995
	_nova.scale = Vector3.ONE * maxf(sn * 170.0, 0.01)
	_nova_mat.set_shader_parameter("fade", (1.0 - sn) * 1.4)

	var rift := channel("rift")
	_rift_floor.visible = rift > 0.01
	_rift_mat.set_shader_parameter("fade", rift)
	_rift_flame[0].visible = _rift_floor.visible
	_rift_flame[1].set_shader_parameter("power", rift)
	_rift_flame[0].global_position = _stage.to_global(Vector3(0, 0, 16))

	var tail := channel("tail")
	_tail[0].visible = tail > 0.01
	_tail[1].set_shader_parameter("power", tail)
	_tail[0].global_position = p.chest() + Vector3(0, channel("leap") * 1.8 * K, 0)

	var core := channel("core")
	_core[0].visible = core > 0.01
	_core[1].set_shader_parameter("power", core)
	_core[0].global_position = p.chest() + Vector3(0, channel("leap") * 1.8 * K + 0.4, 0) + p.forward() * 0.3

	var mv := channel("mv")
	var collapse := channel("mvC")
	var turn := Time.get_ticks_msec() * 0.00007
	var c := cos(turn)
	var s := sin(turn)
	for universe: Array in _universes:
		var grow := clampf((mv - universe[2] * 0.7) / 0.3, 0.0, 1.0)
		var node: Node3D = universe[0]
		node.visible = grow > 0.01
		if node.visible:
			var home: Vector3 = universe[1]
			node.position = Vector3(home.x * c - home.z * s, home.y, home.x * s + home.z * c).lerp(WORLD_C, collapse * collapse)
			node.scale = Vector3.ONE * universe[3] * grow * (1.0 - collapse * collapse * 0.75)

	var white := channel("white")
	if white > 0.003 or _white_on:
		_white_on = white > 0.003
		Game.hud.screen_flash.color = Color(1, 1, 1, white)
		Game.hud.screen_flash.visible = _white_on

	var shatter := channel("shatter")
	if shatter > 0.004 or _shatter_on:
		_shatter_on = shatter > 0.004
		var rect := Game.hud.screen_shatter
		var material: ShaderMaterial = rect.material
		material.set_shader_parameter("aspect", rect.size.x / maxf(rect.size.y, 1.0))
		material.set_shader_parameter("p", shatter)
		rect.visible = _shatter_on

	if _move.has("argon"):
		_apply_argon()

	if _move.has("blade"):
		var out := minf(channel("blade"), 1.0)
		p.rig.set_blade_growth(channel("bladeS") / 5.0)
		p.rig.set_blade_power(out * 0.85 + channel("Bp"))
		p.rig.set_blade_sparks(channel("Bt") > 0.3)


func _apply_argon() -> void:
	var p := _p
	p.rig.argon_orbit = channel("orb")
	p.rig.argon_shield = channel("shield")

	var scan_a := channel("scanA")
	_scan_disc.visible = scan_a > 0.01
	if _scan_disc.visible:
		var reach := channel("scan")
		_scan_disc.global_position = _scan_origin + Vector3(0, 0.3, 0)
		_scan_disc.scale = Vector3(CosmicSkills.SCAN_RADIUS, 1.0, CosmicSkills.SCAN_RADIUS)
		_scan_mat.set_shader_parameter("p", reach)
		_scan_mat.set_shader_parameter("a", scan_a)
		for enemy in CosmicSkills.scan_reach(p, _scan_origin, reach * CosmicSkills.SCAN_RADIUS):
			Fx.ring(enemy.global_position, 3.0 + enemy.radius, THREAT, 0.4)
			CosmicFx.shock(enemy.chest_position(), 3.0 + enemy.radius, 1.4, 0.4, THREAT)

	var sg := channel("sig")
	_sigil.visible = sg > 0.01
	if _sigil.visible:
		_sigil.position = SIGIL_POS
		_sigil.basis = Basis(Vector3.RIGHT, -0.12) * Basis(Vector3.BACK, Time.get_ticks_msec() * 0.00005) * Basis.from_scale(Vector3.ONE * (20.0 + sg * 110.0))
		_sigil_mat.set_shader_parameter("a", sg)
		_sigil_mat.set_shader_parameter("prog", channel("prog"))

	var pr := channel("patch")
	for i in _patch_rings.size():
		var node: MeshInstance3D = _patch_rings[i][0]
		var material: StandardMaterial3D = _patch_rings[i][1]
		var k := pr * 1.6 - i * 0.09
		node.visible = k > 0.0 and k < 1.0
		if node.visible:
			node.global_position = p.global_position + Vector3(0, k * 17.0 * K, 0)
			node.rotation = Vector3(0, Time.get_ticks_msec() * 0.0006 + i, 0)
			node.scale = Vector3.ONE * CosmicWarrior.ARGON_SCALE * K * (2.0 - k * 0.9)
			material.albedo_color = Color(MINT, sin(k * PI))


## Whether ARGON's FIREWALL stands between `at` and a blow from `from`. A blocked blow ripples the dome.
func firewall_blocks(at: Vector3, from: Vector3) -> bool:
	if _wall_left <= 0.0 or at.distance_to(_wall_center) > CosmicSkills.WALL_RADIUS:
		return false
	var d := from - _wall_center
	d.y = maxf(d.y, CosmicSkills.WALL_RADIUS * 0.3)
	_wall_mat.set_shader_parameter("hit", d.normalized())
	_wall_age = 0.0
	var q := _wall_center + d.normalized() * CosmicSkills.WALL_RADIUS
	CosmicFx.shock(q, 3.0, 1.8, 0.35, CYAN)
	return true


func _add_cube(enemy: Enemy, at := Vector3.ZERO) -> void:
	var box := BoxMesh.new()
	var made := _piece(box, ARGON_CUBE, self)
	var node: MeshInstance3D = made[0]
	node.global_position = enemy.chest_position() if enemy != null else at
	node.scale = Vector3.ONE * 0.01
	_cubes.append([node, made[1], enemy, 0.0, false])


func _update_cubes(delta: float) -> void:
	for i in range(_cubes.size() - 1, -1, -1):
		var cube: Array = _cubes[i]
		var node: MeshInstance3D = cube[0]
		var material: ShaderMaterial = cube[1]
		var held: Variant = cube[2]
		var enemy: Enemy = held if held != null and is_instance_valid(held) else null
		cube[3] += delta
		var age: float = cube[3]
		var size := 3.0 if enemy == null else (enemy.radius * 2.0 + 2.2) * (2.6 if enemy.is_boss else 1.0)
		if enemy != null:
			node.global_position = enemy.chest_position()
		node.rotation = Vector3(age * 0.4, age * 0.7, 0)
		if cube[4]:
			var k := minf(1.0, age / 0.32)
			node.scale = Vector3.ONE * maxf(size * (1.0 - k), 0.01)
			material.set_shader_parameter("a", 1.2 + k * 2.0)
			if k >= 1.0:
				CosmicFx.shock(node.global_position, size * 1.6, 1.8, 0.45, MINT)
				CosmicFx.sparks(node.global_position, 60, 16.0)
				node.queue_free()
				_cubes.remove_at(i)
			continue
		var pop := minf(1.0, age / 0.25)
		node.scale = Vector3.ONE * size * (2.2 - 1.2 * pop)
		material.set_shader_parameter("a", pop * 1.2)
		if enemy == null or not enemy.is_alive() or age > CosmicSkills.SEAL_SECONDS + 0.5:
			node.queue_free()
			_cubes.remove_at(i)


func _crush_cubes() -> void:
	for cube: Array in _cubes:
		if not cube[4]:
			cube[4] = true
			cube[3] = 0.0


func _update_wall(delta: float) -> void:
	if _wall_left <= 0.0:
		return
	_wall_left -= delta
	_wall_age += delta
	var grow := clampf((WALL_TIME - _wall_left) / 0.45, 0.0, 1.0)
	var fade := clampf(_wall_left / 0.6, 0.0, 1.0)
	_wall_mat.set_shader_parameter("a", minf(grow, fade))
	_wall_mat.set_shader_parameter("hit_age", _wall_age)
	_wall.visible = _wall_left > 0.0


func _process(delta: float) -> void:
	_update_wall(delta)
	_update_cubes(delta)
	if Game.camera != null and _dome.visible:
		_dome.global_position = Game.camera.global_position
	_flash *= exp(-delta * 8.0)
	_light.light_energy = _flash / 40.0
	_inflow_clock -= delta
	if _inflow_clock <= 0.0 and not _move.is_empty():
		_inflow_clock = 0.08
		if _hole_core.visible:
			CosmicFx.inflow(_stage.to_global(HOLE_POS), 6, 9.0 * K, 0.5)
		if channel("core") > 0.1 and _p != null:
			CosmicFx.inflow(_core[0].global_position, 5, 7.0 * K, 0.45, Color("dcfffa") if _move.has("argon") else Color("fff0c8"))
	_move_meteors(delta)


func _kick(shake: float, flash: float) -> void:
	Game.shake(shake * 0.45)
	_flash = maxf(_flash, flash)


func _at(local: Vector3) -> Vector3:
	return _stage.to_global(local)


func _dir(local: Vector3) -> Vector3:
	return _stage.global_transform.basis * local


func _fist(side: float) -> Vector3:
	var joint: Node3D = _p.rig.joints["hand_R" if side < 0.0 else "foreL"]
	return joint.global_position + _p.forward() * 0.2


func _drop_meteor() -> void:
	var a := _dir(Vector3(randf_range(-32.0, 32.0), 0.0, randf_range(-23.0, 23.0)))
	var land := _meteor_center + a
	land.y = Game.ground_height(land.x, land.z)
	var fall := _dir(FALL.normalized()).normalized()
	var made := CosmicFx.flame(20.0, 2.3, AMBER, self)
	var node: MeshInstance3D = made[0]
	node.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, -fall)), land - fall * (84.0 * K / absf(fall.y)))
	(made[1] as ShaderMaterial).set_shader_parameter("power", 1.9)
	_meteors.append([node, made[1], land])


func _move_meteors(delta: float) -> void:
	for i in range(_meteors.size() - 1, -1, -1):
		var meteor: Array = _meteors[i]
		var node: MeshInstance3D = meteor[0]
		var land: Vector3 = meteor[2]
		var step := 104.0 * K * delta
		var to := land - node.global_position
		if to.length() <= step:
			node.queue_free()
			_meteors.remove_at(i)
			CosmicFx.shock(land, 17.0 * K, 1.7, 0.6, AMBER, true)
			CosmicFx.sparks(land + Vector3(0, 0.2, 0), 60, 18.0)
			_kick(0.7, 60.0)
			if _p != null:
				CosmicSkills.meteor(_p, land)
		else:
			node.global_position += to.normalized() * step


## An attack from outside the dome, turned back where it hits.
func _wall_hit() -> void:
	if _wall_left <= 0.0:
		return
	var a := randf() * TAU
	var e := randf_range(0.15, 0.85)
	var c := sqrt(1.0 - e * e)
	var d := Vector3(cos(a) * c, e, sin(a) * c)
	var radius := CosmicSkills.WALL_RADIUS
	var q := _wall_center + d * radius
	var from := _wall_center + d * radius * 3.2
	CosmicFx.shoot(from, (q - from) / 0.22, 0.22, 1.2, THREAT)
	await get_tree().create_timer(0.22).timeout
	if _wall_left <= 0.0 or _p == null:
		return
	_wall_mat.set_shader_parameter("hit", d)
	_wall_age = 0.0
	CosmicFx.shock(q, 7.0 * K, 2.0, 0.4, CYAN)
	CosmicFx.sparks(q, 40, 14.0)
	for i in 3:
		CosmicFx.shoot(q, d * 25.0 + Vector3(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0), randf_range(-10.0, 10.0)), 0.7, 1.0, CYAN)
	_kick(0.35, 40.0)
	CosmicSkills.firewall_tick(_p, _wall_center, radius)


func _fire(effect: String, arg: float) -> void:
	var p := _p
	if _move_id == "unity" and not effect in ["white"]:
		_unity.fire(effect, arg)
		return
	match effect:
		"nova":
			var q := _fist(-1.0)
			CosmicFx.shock(q, 16.0 * K, 2.0, 0.55, CREAM)
			CosmicFx.shock(q, 9.0 * K, 1.6, 0.36, AMBER)
			CosmicFx.sparks(q, 300, 26.0)
			CosmicFx.beam(q, p.forward())
			for i in 36:
				var a := i / 36.0 * TAU
				CosmicFx.shoot(q, _dir(Vector3(cos(a) * 34.0, sin(a) * 34.0, 10.0)), 0.6, 3.4 * K)
			_kick(1.2, 180.0)
			CosmicSkills.nova(p)
		"crater":
			CosmicFx.crater(p.global_position)
			_kick(2.0, 260.0)
			CosmicSkills.crater(p)
		"cleave":
			var tip: Vector3 = p.rig.blade_tip.global_position
			CosmicFx.wave(_at(Vector3(0, 9, 1.4)), p.forward(), arg, 2.8)
			CosmicFx.shock(tip, 11.0 * K, 1.7, 0.45, CREAM)
			CosmicFx.sparks(tip, 220, 26.0)
			_kick(1.3, 170.0)
			CosmicSkills.cleave(p)
		"throwStar":
			var q := _fist(arg)
			for i in 3:
				CosmicFx.shoot(q, _dir(Vector3(randf_range(-17.0, 17.0), randf_range(-7.0, 17.0), 64.0)), 0.8, randf_range(3.0, 4.6) * K)
			CosmicFx.shock(q, 2.4 * K, 0.8, 0.18, AMBER)
			_kick(0.24, 22.0)
			CosmicSkills.throw_star(p, q)
		"meteor":
			_drop_meteor()
		"holeBlast":
			var q := _at(HOLE_POS)
			CosmicFx.shock(q, 46.0 * K, 2.3, 0.8, CREAM)
			CosmicFx.shock(q, 26.0 * K, 1.8, 0.5, AMBER)
			CosmicFx.sparks(q, 620, 42.0)
			for i in 60:
				var a := i / 60.0 * TAU
				CosmicFx.shoot(q, _dir(Vector3(cos(a) * 62.0, sin(a) * 62.0, randf_range(-15.0, 15.0))), 0.8, 4.6 * K)
			_kick(2.4, 340.0)
			CosmicSkills.hole_blast(p, q)
		"supernova":
			var q := _at(Vector3(0, 15, 0.4))
			for pair: Array in [[46.0, 0.6], [84.0, 0.85], [140.0, 1.1]]:
				CosmicFx.shock(q, pair[0] * K, 2.5, pair[1], CREAM)
			CosmicFx.shock(p.global_position, 110.0 * K, 2.6, 1.1, AMBER, true)
			CosmicFx.sparks(q, 900, 58.0)
			_kick(3.0, 520.0)
			CosmicSkills.supernova(p)
		"seed":
			var q := _at(GALAXY_POS)
			CosmicFx.shock(q, 26.0 * K, 2.4, 0.8, CREAM)
			CosmicFx.sparks(q, 420, 34.0)
			_kick(1.4, 220.0)
			CosmicSkills.genesis_start(p)
		"birth":
			var a := randf() * TAU
			var r := randf_range(14.0, 76.0)
			var q := _at(Vector3(cos(a) * r, 15.0 + sin(a) * r * 0.3, -10.0 + sin(a) * r * 0.75))
			var hue: Color = CosmicFx.HUES[randi() % CosmicFx.HUES.size()]
			CosmicFx.shock(q, randf_range(7.0, 17.0) * K, 1.7, 0.55, hue)
			CosmicFx.sparks(q, 50, 18.0)
			CosmicFx.shoot(q, _dir(Vector3(cos(a) * 24.0, 8.0, sin(a) * 24.0)), 0.9, 5.0 * K)
			_kick(0.45, 34.0)
			CosmicSkills.genesis_tick(p)
		"peak":
			var q := _at(GALAXY_POS)
			for r: float in [40.0, 76.0, 120.0]:
				CosmicFx.shock(q, r * K, 2.2, 0.9, CREAM)
			CosmicFx.sparks(q, 500, 46.0)
			_kick(2.2, 340.0)
		"collide":
			var q := _at(WORLD_C)
			for i in CosmicFx.HUES.size():
				CosmicFx.shock(q, (34.0 + i * 24.0) * K, 2.5, 0.7 + i * 0.12, CosmicFx.HUES[i])
			CosmicFx.shock(p.global_position, 150.0 * K, 2.6, 1.2, CREAM, true)
			CosmicFx.sparks(q, 1100, 70.0)
			_kick(3.4, 620.0)
			CosmicSkills.multiverse(p)
		"worldCut":
			for i in 9:
				CosmicFx.shock(_at(Vector3(0, 0.1, -60.0 + i * 18.0)), (15.0 + (i % 3) * 8.0) * K, 2.0, 0.7 + i * 0.03, CREAM if i % 2 == 1 else AMBER, true)
			for i in 14:
				CosmicFx.sparks(_at(Vector3(0, 0.3, -90.0 + i * 14.0)), 44, 34.0)
			_kick(3.6, 700.0)
			CosmicSkills.edge(p)
		"snap":
			var q := _fist(-1.0)
			CosmicFx.shock(q, 12.0 * K, 2.6, 0.35, Color.WHITE)
			CosmicFx.shock(q, 40.0 * K, 1.4, 0.6, CREAM)
			CosmicFx.sparks(q, 200, 30.0)
			_kick(1.4, 260.0)
			CosmicSkills.erasure_snap(p, _move["dur"] * 0.65)
		"restore":
			_kick(1.8, 300.0)
			CosmicSkills.erasure_restore(p)
		"implode":
			CosmicFx.inflow(_at(WORLD_C), 20, 84.0 * K, 0.7)
			_kick(0.4, 0.0)
		"ping":
			var q := _fist(-1.0)
			_scan_origin = p.global_position
			CosmicSkills.scan_start()
			CosmicFx.shock(p.global_position, 30.0 * K, 2.0, 0.6, CYAN, true)
			CosmicFx.shock(q, 10.0 * K, 2.0, 0.45, PALE_CYAN)
			CosmicFx.sparks(q, 160, 22.0)
			_kick(0.8, 120.0)
		"scanDone":
			Game.hud.banner("SCAN COMPLETE", "พบภัยคุกคาม %d จุด · ล็อกเป้าแล้ว" % CosmicSkills.marked_count(), THREAT, 1.8)
		"autoScan":
			CosmicSkills.auto_scan(p)
			CosmicFx.shock(p.chest(), 14.0 * K, 2.0, 0.5, CYAN)
		"seal":
			var enemy := CosmicSkills.seal_next(p)
			if enemy != null:
				_add_cube(enemy)
				CosmicFx.shock(enemy.chest_position(), 3.0 + enemy.radius, 1.6, 0.4, CYAN)
				CosmicFx.shoot(p.chest(), (enemy.chest_position() - p.chest()) / 0.3, 0.3, 1.0, CYAN)
		"crushAll":
			_crush_cubes()
			var n := CosmicSkills.crush_sealed(p)
			CosmicFx.shock(p.chest(), 30.0 * K, 2.4, 0.6, MINT)
			CosmicFx.sparks(p.chest(), 400, 34.0)
			Game.hud.banner("QUARANTINED", "ลบทิ้ง %d / %d · กู้คืนไม่ได้" % [n, n] if n > 0 else "ไม่พบภัยคุกคามในระบบ", MINT, 1.8)
			_kick(1.8, 280.0)
		"wallUp":
			_wall_center = p.global_position
			_wall_left = WALL_TIME
			_wall_age = 9.0
			_wall.global_position = _wall_center
			_wall.scale = Vector3.ONE * CosmicSkills.WALL_RADIUS
			_wall.visible = true
			CosmicFx.shock(_wall_center, CosmicSkills.WALL_RADIUS * 2.2, 2.4, 0.8, CYAN, true)
			CosmicFx.shock(_wall_center, CosmicSkills.WALL_RADIUS * 1.2, 1.8, 0.5, PALE_CYAN, true)
			CosmicFx.sparks(_wall_center + Vector3(0, 1, 0), 300, 30.0)
			CosmicSkills.firewall_push(p, _wall_center, CosmicSkills.WALL_RADIUS)
			Game.hud.banner("FIREWALL · AEGIS", "ไม่มีการโจมตีใดผ่านเข้ามาได้", CYAN, 1.8)
			_kick(1.4, 200.0)
		"wallHit":
			_wall_hit()
		"wallDown":
			Game.hud.banner("BLOCKED", "ดาเมจที่ทะลุเข้ามา 0 · โดมยังตั้งอยู่", MINT, 1.6)
		"purgeLock":
			var tip: Vector3 = p.rig.blade_tip.global_position
			CosmicFx.shock(tip, 14.0 * K, 2.0, 0.5, MINT)
			CosmicFx.sparks(tip, 200, 24.0)
			_kick(1.0, 140.0)
		"purgeCut":
			for i in 9:
				CosmicFx.shock(_at(Vector3(0, 0.1, -60.0 + i * 18.0)), (15.0 + (i % 3) * 8.0) * K, 2.0, 0.7 + i * 0.03, PALE_CYAN if i % 2 == 1 else MINT, true)
			for i in 14:
				CosmicFx.sparks(_at(Vector3(0, 0.3, -90.0 + i * 14.0)), 44, 34.0)
			Game.hud.banner("PURGE", "ลบทิ้งถาวร · ไม่มีถังขยะ ไม่มีการกู้คืน", MINT, 1.8)
			_kick(3.6, 700.0)
			CosmicSkills.purge(p)
		"patchStart":
			CosmicFx.shock(p.chest(), 8.0 * K, 1.6, 0.4, MINT)
		"patched":
			var q := p.chest()
			CosmicFx.shock(q, 22.0 * K, 2.4, 0.6, MINT)
			CosmicFx.shock(p.global_position, 40.0 * K, 2.0, 0.7, MINT, true)
			CosmicFx.sparks(q, 360, 30.0)
			CosmicSkills.patch(p)
			Game.hud.banner("PATCH INSTALLED", "ฟื้นเลือด 45% · stamina เต็ม", MINT, 1.8)
			_kick(1.2, 220.0)
		"installStart":
			var q := _at(SIGIL_POS)
			CosmicFx.shock(q, 40.0 * K, 2.4, 0.8, PALE_CYAN)
			CosmicFx.sparks(q, 300, 34.0)
			_kick(1.4, 200.0)
		"absorb":
			CosmicFx.inflow(_at(SIGIL_POS), 20, 80.0 * K, 0.7, CYAN)
			_kick(0.4, 0.0)
		"install":
			var q := _at(WORLD_C)
			var hues := [CYAN, MINT, Color("b48cff"), PALE_CYAN, CYAN, MINT]
			for i in hues.size():
				CosmicFx.shock(q, (50.0 + i * 34.0) * K, 2.7, 0.7 + i * 0.16, hues[i])
			CosmicFx.shock(p.global_position, 190.0 * K, 2.8, 1.4, PALE_CYAN, true)
			CosmicFx.sparks(q, 1400, 90.0)
			for i in 90:
				var a := i * 2.39996
				var e := i / 90.0 * 2.0 - 1.0
				var c := sqrt(1.0 - e * e)
				CosmicFx.shoot(q, _dir(Vector3(cos(a) * c * 90.0, e * 90.0, sin(a) * c * 90.0)), 1.0, 6.0 * K, CYAN if i % 3 != 0 else MINT)
			_kick(4.4, 900.0)
			CosmicSkills.clean_install(p)
		"installDone":
			Game.hud.banner("INSTALL COMPLETE", "ภัยคุกคามเหลือ 0", MINT, 2.4)
		"bang":
			var q := _at(WORLD_C)
			for i in CosmicFx.HUES.size():
				CosmicFx.shock(q, (50.0 + i * 34.0) * K, 2.7, 0.7 + i * 0.16, CosmicFx.HUES[i])
			CosmicFx.shock(p.global_position, 190.0 * K, 2.8, 1.4, CREAM, true)
			CosmicFx.sparks(q, 1400, 90.0)
			for i in 90:
				var a := i * 2.39996
				var e := i / 90.0 * 2.0 - 1.0
				var c := sqrt(1.0 - e * e)
				CosmicFx.shoot(q, _dir(Vector3(cos(a) * c * 90.0, e * 90.0, sin(a) * c * 90.0)), 1.0, 6.0 * K)
			_kick(4.4, 900.0)
			CosmicSkills.big_bang(p)
