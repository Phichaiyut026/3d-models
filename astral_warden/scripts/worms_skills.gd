class_name WormsSkills
extends RefCounted
## The powers of WORMS, from worms.html. Each is telegraphed so it can be dodged, and the worst of
## them, FINAL SYSTEM, can only be outrun or held off by ARGON's FIREWALL.

const RED := Color(1.0, 0.06, 0.19)
const HOT := Color(1.0, 0.45, 0.55)
## `pose` is the body's pose while it plays; `at` is when it fires, as a share of `length`.
const SKILLS := {
	"control": {"pose": "push", "length": 3.2, "at": 0.2, "name": "SYSTEM CONTROL", "hint": "ออกจากกล่องก่อนมันปิด"},
	"domination": {"pose": "wide", "length": 3.6, "at": 0.15, "name": "DATA DOMINATION", "hint": "กลิ้งผ่านวงแหวน"},
	"overwrite": {"pose": "raise", "length": 3.8, "at": 0.1, "name": "REALITY OVERWRITE", "hint": "หลบเสาข้อมูล"},
	"halt": {"pose": "halt", "length": 2.4, "at": 0.45, "name": "HALT", "hint": "กลิ้งตอนมันสั่งหยุด"},
	"erase_power": {"pose": "point", "length": 3.2, "at": 0.15, "name": "ERASE POWER", "hint": "หลบลำแสง ไม่งั้นร่างจะถูกลบ"},
	"final": {"pose": "sky", "length": 5.0, "at": 0.08, "name": "FINAL SYSTEM", "hint": "หนีออกจากวง หรือตั้ง FIREWALL"},
}
const ROTATION := ["control", "domination", "erase_power", "overwrite", "halt"]
const FINAL_RADIUS := 34.0


static func _casting(boss: Enemy, run: int) -> bool:
	return boss.is_alive() and boss.state == "skill" and run == Game.run_id and Game.state == "play"


static func _wait(seconds: float) -> void:
	await Game.get_tree().create_timer(seconds).timeout


static func _ground(pos: Vector3) -> Vector3:
	return Vector3(pos.x, Game.ground_height(pos.x, pos.z), pos.z)


static func _model(boss: Enemy) -> WormsModel:
	return boss.rig as WormsModel


static func fire(boss: Enemy, skill: String) -> void:
	var info: Dictionary = SKILLS[skill]
	Game.hud.banner(info["name"], info["hint"], RED, 1.6)
	match skill:
		"control":
			_control(boss)
		"domination":
			_domination(boss)
		"overwrite":
			_overwrite(boss)
		"halt":
			_halt(boss)
		"erase_power":
			_erase_power(boss)
		"final":
			_final(boss)


static func _player_flat_distance(pos: Vector3) -> float:
	var to := Game.player.global_position - pos
	to.y = 0.0
	return to.length()


## SYSTEM CONTROL: the cube leaves its hand, grows into a cage round the player, and closes.
static func _control(boss: Enemy) -> void:
	var run := Game.run_id
	var model := _model(boss)
	var at := _ground(Game.player.global_position)
	var size := 7.0
	OverlordSkills.zone(at, size * 0.62, 1.0)
	var cage := WormsModel.wire_cube(size, 0.12, RED)
	Game.world.add_child(cage)
	cage.global_position = at + Vector3(0, size * 0.5, 0)
	cage.scale = Vector3.ONE * 0.05
	model.cube_override = true
	var from := model.cube.global_position
	var tween := cage.create_tween().set_parallel(true)
	tween.tween_property(cage, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(cage, "rotation", Vector3(0, PI * 0.5, 0), 1.0)
	var cube_tween := model.cube.create_tween()
	cube_tween.tween_property(model.cube, "global_position", at + Vector3(0, size * 0.5, 0), 0.5).from(from)
	await _wait(1.0)
	if not _casting(boss, run):
		cage.queue_free()
		model.cube_override = false
		return
	var shut := cage.create_tween()
	shut.tween_property(cage, "scale", Vector3.ONE * 0.12, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	shut.tween_callback(cage.queue_free)
	await _wait(0.18)
	model.cube_override = false
	CosmicFx.shock(at + Vector3(0, 2.0, 0), 9.0, 2.0, 0.5, RED)
	SoldierSkills.pixels(at + Vector3(0, 1.5, 0), 60, 2.0)
	Game.shake(0.6)
	if _casting(boss, run) and _player_flat_distance(at) < size * 0.62:
		if Game.player.take_damage(110.0, boss.global_position):
			Game.player.halt(1.0)


## DATA DOMINATION: three red rings run out across the ground. Roll through them, or be above them.
static func _domination(boss: Enemy) -> void:
	var run := Game.run_id
	var center := boss.global_position
	_model(boss).power = 1.0
	for i in 3:
		if not _casting(boss, run):
			break
		_ring(boss, run, center, 4.0 + i * 0.2)
		await _wait(0.55)
	await _wait(1.0)
	_model(boss).power = 0.0


static func _ring(boss: Enemy, run: int, center: Vector3, seconds: float) -> void:
	var reach := 60.0
	CosmicFx.shock(center, reach, 2.6, seconds, RED, true)
	Game.shake(0.35)
	var hit := false
	var steps := int(seconds / 0.05)
	for i in steps:
		if not boss.is_alive() or run != Game.run_id or Game.state != "play":
			return
		# The shock ring's visible edge eases out the same way.
		var v := float(i) / steps
		var r := (1.0 - (1.0 - v) * (1.0 - v)) * 0.9 * reach
		var p := Game.player
		var off_ground := p.global_position.y - Game.ground_height(p.global_position.x, p.global_position.z) > 2.5
		if not hit and not off_ground and absf(_player_flat_distance(center) - r) < 1.6:
			hit = true
			p.take_damage(90.0, center)
		await _wait(0.05)


## REALITY OVERWRITE: columns of data burst out of the ground around the player.
static func _overwrite(boss: Enemy) -> void:
	var run := Game.run_id
	_model(boss).power = 1.0
	for wave in 3:
		if not _casting(boss, run):
			break
		var around := Game.player.global_position
		_pillar(boss, run, around)
		for i in 5:
			var a := randf() * TAU
			var r := randf_range(4.0, 16.0)
			_pillar(boss, run, around + Vector3(cos(a) * r, 0, sin(a) * r))
		await _wait(0.9)
	_model(boss).power = 0.0


static func _pillar(boss: Enemy, run: int, pos: Vector3) -> void:
	var radius := 3.6
	OverlordSkills.zone(pos, radius, 0.95)
	await _wait(0.95)
	if not _casting(boss, run):
		return
	var at := _ground(pos)
	var column := Node3D.new()
	Game.world.add_child(column)
	column.global_position = at
	var height := randf_range(8.0, 16.0)
	var material := Fx.flat_material(RED, 1.6)
	var count := int(height / 1.1)
	for k in count:
		var box := BoxMesh.new()
		box.size = Vector3(radius * 0.7, 0.8, radius * 0.7)
		box.material = Fx.flat_material(HOT, 2.4) if k == count - 1 else material
		var slab := MeshInstance3D.new()
		slab.mesh = box
		slab.position.y = k * 1.1 + 0.4
		slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		column.add_child(slab)
	column.scale = Vector3(1, 0.01, 1)
	var tween := column.create_tween()
	tween.tween_property(column, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.9)
	tween.tween_property(column, "scale", Vector3(1, 0.01, 1), 0.3)
	tween.tween_callback(column.queue_free)
	SoldierSkills.pixels(at + Vector3(0, 1.0, 0), 24, 1.6)
	Game.shake(0.3)
	if _player_flat_distance(at) < radius:
		Game.player.take_damage(120.0, at)


## HALT: it raises its hand and orders everything to stop. Only someone mid-roll slips the order.
static func _halt(boss: Enemy) -> void:
	var run := Game.run_id
	var model := _model(boss)
	var hand := model.left_hand()
	CosmicFx.shock(hand, 6.0, 2.0, 0.5, RED)
	Fx.ring(boss.global_position, 18.0, RED, 0.5)
	await _wait(0.25)
	if not _casting(boss, run):
		return
	CosmicFx.shock(hand, 40.0, 2.4, 0.7, Color.WHITE)
	CosmicFx.flash(Color(1.0, 0.08, 0.15), 0.55, 0.6)
	Game.shake(0.8)
	var p := Game.player
	if p.global_position.distance_to(boss.global_position) < 70.0 and p.take_damage(50.0, boss.global_position):
		p.halt(1.6)
		SoldierSkills.pixels(p.chest(), 40, 1.2)


## ERASE POWER: a line from its left hand. Whatever form it touches is deleted back to the first.
static func _erase_power(boss: Enemy) -> void:
	var run := Game.run_id
	var model := _model(boss)
	var p := Game.player
	var length := 90.0
	var made := CosmicFx.flame(length / CosmicFx.WEB, 7.0, RED, Game.world)
	var beam: MeshInstance3D = made[0]
	var material: ShaderMaterial = made[1]
	material.set_shader_parameter("power", 0.8)
	material.set_shader_parameter("rad", 1.2)
	var aim := (p.chest() - model.left_hand()).normalized()
	# The aim follows for a moment, then locks: that is the moment to step aside.
	for i in 14:
		if not _casting(boss, run):
			beam.queue_free()
			return
		var origin := model.left_hand()
		if i < 9:
			aim = aim.slerp((Game.player.chest() - origin).normalized(), 0.35).normalized()
		boss.rig.rotation.y = atan2(aim.x, aim.z)
		beam.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, aim)), origin)
		await _wait(0.08)
	if not _casting(boss, run):
		beam.queue_free()
		return
	material.set_shader_parameter("power", 3.0)
	material.set_shader_parameter("rad", 7.0)
	var origin := model.left_hand()
	CosmicFx.shock(origin, 8.0, 2.4, 0.4, Color.WHITE)
	Game.shake(0.9)
	var to := Game.player.chest() - origin
	var along := to.dot(aim)
	if along > 0.0 and along < length and (to - aim * along).length() < 2.6:
		if Game.player.take_damage(80.0, origin):
			Game.player.erase_power()
	var tween := beam.create_tween()
	tween.tween_method(func(v: float) -> void: material.set_shader_parameter("power", v), 3.0, 0.0, 0.4)
	tween.tween_callback(beam.queue_free)


## FINAL SYSTEM: the cube rises over everything, grows, and goes off. Enraged only.
static func _final(boss: Enemy) -> void:
	var run := Game.run_id
	var model := _model(boss)
	var center := boss.global_position
	var seconds := 3.6
	OverlordSkills.zone(center, FINAL_RADIUS, seconds)
	model.cube_override = true
	model.power = 1.0
	var top := center + Vector3(0, 25.0 * WormsModel.BODY_SCALE + 8.0, 0)
	var tween := model.cube.create_tween().set_parallel(true)
	tween.tween_property(model.cube, "global_position", top, seconds * 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(model.cube, "scale", Vector3.ONE * 4.2, seconds * 0.7)
	for i in int(seconds / 0.3):
		if not _casting(boss, run):
			model.cube_override = false
			model.power = 0.0
			return
		CosmicFx.inflow(top, 10, 14.0, 0.5, RED)
		Fx.ring(center, FINAL_RADIUS, RED, 0.3)
		Game.shake(0.25)
		await _wait(0.3)
	model.cube_override = false
	model.power = 0.0
	if not _casting(boss, run):
		return
	CosmicFx.flash(Color(1.0, 0.1, 0.18), 0.85, 1.0)
	CosmicFx.nova(top, 30.0, 1.0, RED)
	CosmicFx.shock(center, FINAL_RADIUS * 1.3, 2.8, 1.2, RED, true)
	CosmicFx.pillar(center, 200.0, 1.0, RED, FINAL_RADIUS * 0.4)
	for i in 40:
		var dir := Vector3(randf_range(-1, 1), randf_range(-0.2, 1), randf_range(-1, 1)).normalized()
		CosmicFx.shoot(top, dir * randf_range(20.0, 50.0), 1.4, 1.4, RED)
	Game.shake(2.4)
	if _player_flat_distance(center) < FINAL_RADIUS:
		Game.player.take_damage(330.0, top)


static func warm(at: Vector3) -> void:
	var cage := WormsModel.wire_cube(1.0, 0.1, RED)
	Game.world.add_child(cage)
	cage.global_position = at
	cage.get_tree().create_timer(0.2).timeout.connect(cage.queue_free)
