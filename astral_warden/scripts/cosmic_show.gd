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

var wide := 0.0 ## How far the camera pulls out, read by the player.

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


func _ready() -> void:
	_stage = Node3D.new()
	add_child(_stage)
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
	_hide_all()


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
	_move = CosmicMoves.all()[id]
	_q = 0.0
	var ahead := p.forward()
	_stage.global_transform = Transform3D(Basis.looking_at(-ahead, Vector3.UP).scaled(Vector3.ONE * K), p.global_position)
	_was_armed = p.rig.is_armed
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


## Cuts a power short. Meteors still in the air go too.
func stop() -> void:
	for meteor: Array in _meteors:
		meteor[0].queue_free()
	_meteors.clear()
	_end()


func _end() -> void:
	if _p != null:
		_p.rig.set_blade_growth(0.0)
	_move = {}
	_q = 0.0
	_hide_all()


func _hide_all() -> void:
	wide = 0.0
	_flash = 0.0
	_light.light_energy = 0.0
	for node: Node3D in [_dome, _galaxy, _hole_core, _hole_disc, _nova, _rift_floor, _rift_flame[0], _tail[0], _core[0]]:
		node.visible = false
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
	for node: Node3D in [_dome, _galaxy, _hole_core, _hole_disc, _nova, _rift_floor, _rift_flame[0], _tail[0], _core[0]]:
		node.visible = true
	(_universes[0][0] as Node3D).visible = true


func _apply() -> void:
	var p := _p
	wide = channel("wide")
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

	if _move.has("blade"):
		var out := minf(channel("blade"), 1.0)
		p.rig.set_blade_growth(channel("bladeS") / 5.0)
		p.rig.set_blade_power(out * 0.85 + channel("Bp"))
		p.rig.set_blade_sparks(channel("Bt") > 0.3)


func _process(delta: float) -> void:
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
			CosmicFx.inflow(_core[0].global_position, 5, 7.0 * K, 0.45)
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
	land.y = Game.terrain.get_height(land.x, land.z)
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


func _fire(effect: String, arg: float) -> void:
	var p := _p
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
