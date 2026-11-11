class_name OverlordSkills
extends RefCounted
## The powers of System Overlord, from system_overlord.html. Each one is telegraphed so it can be dodged.

const RED := Color(1.0, 0.13, 0.2)
const PALE := Color(1.0, 0.7, 0.68)
const ZONE := preload("res://shaders/danger_zone.gdshader")
## `at` is a share of `length`. `anim_length` is set when the pose should end before the skill does.
const SKILLS := {
	"glitch": {"anim": "cast", "length": 1.9, "at": 0.24},
	"shards": {"anim": "erasure", "length": 2.3, "at": 0.16},
	"spikes": {"anim": "slam", "length": 2.5, "at": 0.46, "anim_length": 1.6},
	"beam": {"anim": "boss_beam", "length": 3.2, "at": 0.3},
	"delete": {"anim": "sky_spread", "length": 3.5, "at": 0.08},
	"worldend": {"anim": "bigbang", "length": 5.2, "at": 0.06},
	"devour": {"anim": "sky_spread", "length": 5.4, "at": 0.12},
	"ray": {"anim": "boss_beam", "length": 5.2, "at": 0.3},
	"horizon": {"anim": "sky_spread", "length": 6.4, "at": 0.1},
	"flick": {"anim": "cast", "length": 9.4, "at": 0.08, "anim_length": 9.4},
	"daemon_beam": {"anim": "cast", "length": 2.3, "at": 0.02, "anim_length": 2.3},
	"rootkit_wave": {"anim": "slash3", "length": 1.5, "at": 0.54},
	"rootkit_call": {"anim": "sky_spread", "length": 1.8, "at": 0.4},
}
const ROTATION := ["shards", "spikes", "glitch", "beam", "delete"]
const OBLIVION_ROTATION := ["devour", "glitch", "ray", "spikes", "horizon", "delete", "shards"]
const WEB := 0.62 ## Metres per unit of system_overlord.html.
const FLICK_SAFE := 20.0
const DOOM := preload("res://shaders/doom_sheet.gdshader")
const SKY := preload("res://shaders/sky_dome.gdshader")


static func _casting(boss: Enemy, run: int) -> bool:
	return boss.is_alive() and boss.state == "skill" and run == Game.run_id and Game.state == "play"


static func _wait(seconds: float) -> void:
	await Game.get_tree().create_timer(seconds).timeout


static func _ground(pos: Vector3) -> Vector3:
	return Vector3(pos.x, Game.terrain.get_height(pos.x, pos.z), pos.z)


static func fire(boss: Enemy, skill: String) -> void:
	match skill:
		"glitch":
			_glitch(boss)
		"shards":
			_shards(boss)
		"spikes":
			_spikes(boss)
		"beam":
			_beam(boss)
		"delete":
			_delete(boss)
		"worldend":
			_world_end(boss)
		"devour":
			_devour(boss)
		"ray":
			_ray(boss)
		"horizon":
			_horizon(boss)
		"flick":
			_flick(boss)
		"daemon_beam":
			SoldierSkills.beam(boss)
		"rootkit_wave":
			SoldierSkills.wave(boss)
		"rootkit_call":
			SoldierSkills.call_processes(boss)


## OBLIVION's powers turn the sky to blood-red space while they last.
static func _sky(seconds: float) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = 1600.0
	sphere.height = 3200.0
	sphere.radial_segments = 32
	sphere.rings = 22
	var material := ShaderMaterial.new()
	material.shader = SKY
	material.set_shader_parameter("red", 1.0)
	var node := MeshInstance3D.new()
	node.mesh = sphere
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.extra_cull_margin = 2000.0
	Game.world.add_child(node)
	node.global_position = Game.player.global_position
	var set_a := func(v: float) -> void: material.set_shader_parameter("a", v)
	var tween := node.create_tween()
	tween.tween_method(set_a, 0.0, 1.0, 0.5)
	tween.tween_interval(maxf(seconds - 1.0, 0.1))
	tween.tween_method(set_a, 1.0, 0.0, 0.5)
	tween.tween_callback(node.queue_free)


static func _hole(boss: Enemy, size: float) -> void:
	(boss.rig as OverlordModel).set_hole(size)


## The hole opens wide and drags the player in, crushing what it catches.
static func _devour(boss: Enemy) -> void:
	var run := Game.run_id
	Game.hud.banner("DEVOUR", "อย่าให้ถูกดูดเข้าไป", RED, 1.6)
	_sky(4.6)
	_hole(boss, 2.0)
	for i in 36:
		if not _casting(boss, run):
			break
		var p := Game.player
		var to := boss.global_position - p.global_position
		to.y = 0.0
		p.drag(to.normalized() * 8.0)
		Game.shake(0.3)
		if i % 4 == 0:
			_crush(boss, run, p.global_position)
		await _wait(0.12)
	_hole(boss, 1.0)
	if _casting(boss, run):
		CosmicFx.shock(boss.chest_position(), 30.0, 2.4, 0.9, RED)
		Game.shake(1.2)


static func _crush(boss: Enemy, run: int, pos: Vector3) -> void:
	var radius := 6.0
	zone(pos, radius, 0.7)
	await _wait(0.7)
	if not _casting(boss, run):
		return
	CosmicFx.shock(_ground(pos) + Vector3(0, 1.0, 0), 9.0, 2.0, 0.6, RED)
	Fx.burst(_ground(pos) + Vector3(0, 0.5, 0), RED, 30, 14.0, 0.1)
	Game.shake(0.5)
	var to := Game.player.global_position - pos
	to.y = 0.0
	if to.length() < radius:
		Game.player.take_damage(110.0, pos)


## HAWKING RAY: what the black hole breathes out. It chases the player, slowly.
static func _ray(boss: Enemy) -> void:
	var run := Game.run_id
	var length := 150.0 * WEB
	Game.hud.banner("HAWKING RAY", "วิ่งหลบลำแสง", RED, 1.4)
	_sky(3.6)
	_hole(boss, 1.9)
	var made := CosmicFx.flame(150.0, 5.0, Color("ff1030"), Game.world)
	var beam: MeshInstance3D = made[0]
	(made[1] as ShaderMaterial).set_shader_parameter("world_scale", WEB)
	(made[1] as ShaderMaterial).set_shader_parameter("power", 2.4)
	var origin := boss.chest_position() + Vector3(0, 3.0, 0)
	var aim := (Game.player.chest() - origin).normalized()
	for tick in 30:
		if not _casting(boss, run):
			break
		var p := Game.player
		origin = boss.chest_position() + Vector3(0, 3.0, 0)
		aim = aim.slerp((p.chest() - origin).normalized(), 0.06).normalized()
		boss.rig.rotation.y = atan2(aim.x, aim.z)
		beam.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, aim)), origin)
		Game.shake(0.35)
		if tick % 3 == 0:
			CosmicFx.shock(origin + aim * randf_range(8.0, length), randf_range(6.0, 11.0), 1.8, 0.55, RED)
		var along := (p.chest() - origin).dot(aim)
		if along > 0.0 and along < length and (p.chest() - origin - aim * along).length() < 3.6:
			p.take_damage(34.0, origin)
			Fx.burst(p.chest(), RED, 10, 7.0)
		await _wait(0.1)
	beam.queue_free()
	_hole(boss, 1.0)


## EVENT HORIZON: everything near it is pulled in, then it collapses. Get far away.
static func _horizon(boss: Enemy) -> void:
	var run := Game.run_id
	var radius := 40.0
	var seconds := 4.8
	var center := boss.global_position
	Game.hud.banner("EVENT HORIZON", "วิ่งออกจากวงให้ทัน", RED, 2.2)
	_sky(5.8)
	_hole(boss, 3.2)
	zone(center, radius, seconds)
	var ticks := int(seconds / 0.12)
	for i in ticks:
		if not _casting(boss, run):
			_hole(boss, 1.0)
			return
		var p := Game.player
		var to := center - p.global_position
		to.y = 0.0
		p.drag(to.normalized() * 5.0)
		Game.shake(0.3)
		await _wait(0.12)
	_hole(boss, 1.0)
	if not _casting(boss, run):
		return
	for r: float in [24.0, 48.0, 80.0]:
		CosmicFx.shock(boss.chest_position(), r, 2.6, 1.0, RED)
	CosmicFx.shock(center, radius, 2.6, 1.2, RED, true)
	CosmicFx.flash(Color(1.0, 0.25, 0.25), 0.85, 0.8)
	Game.shake(2.4)
	var away := Game.player.global_position - center
	away.y = 0.0
	if away.length() < radius:
		Game.player.take_damage(300.0, center)


## FLICK OF DOOM: one finger, and reality drains away. Only standing at its feet survives.
static func _flick(boss: Enemy) -> void:
	var run := Game.run_id
	var seconds := 7.2
	Game.hud.banner("FLICK OF DOOM", "วิ่งเข้าไปประชิดบอส!", RED, 3.0)
	_sky(8.6)
	var rect := Game.hud.screen_doom
	var material: ShaderMaterial = rect.material
	material.set_shader_parameter("aspect", rect.size.x / maxf(rect.size.y, 1.0))
	material.set_shader_parameter("p", 0.0)
	rect.visible = true
	var steps := int(seconds / 0.1)
	for i in steps:
		if not _casting(boss, run):
			rect.visible = false
			return
		material.set_shader_parameter("p", float(i) / steps * 0.72)
		if i % 8 == 0:
			Fx.ring(boss.global_position, FLICK_SAFE, Color.WHITE, 0.7)
		Game.shake(0.25)
		await _wait(0.1)
	rect.visible = false
	if not _casting(boss, run):
		return
	CosmicFx.flash(Color(0.0, 0.0, 0.0), 1.0, 1.2)
	Game.shake(2.6)
	var to := Game.player.global_position - boss.global_position
	to.y = 0.0
	if to.length() > FLICK_SAFE:
		Game.player.take_damage(1500.0, boss.global_position)


## A disc on the ground that fills up over `seconds`, then frees itself.
static func zone(pos: Vector3, radius: float, seconds: float) -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(2, 2)
	var material := ShaderMaterial.new()
	material.shader = ZONE
	plane.material = material
	var node := MeshInstance3D.new()
	node.mesh = plane
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.extra_cull_margin = 30.0
	Game.world.add_child(node)
	node.global_position = _ground(pos) + Vector3(0, 0.25, 0)
	node.scale = Vector3(radius, 1.0, radius)
	var tween := node.create_tween()
	tween.tween_method(func(v: float) -> void: material.set_shader_parameter("fill", v), 0.0, 1.0, seconds)
	tween.tween_callback(node.queue_free)


## Comes apart, reappears at the player's side and swings.
static func _glitch(boss: Enemy) -> void:
	var run := Game.run_id
	var p := Game.player
	Fx.burst(boss.chest_position(), RED, 50, 13.0, 0.1)
	Fx.ring(boss.global_position, 6.0, RED, 0.3)
	# Beside the player, not behind: behind would put the whole body on top of the camera.
	var side := p.forward().cross(Vector3.UP) * (1.0 if randf() > 0.5 else -1.0)
	var at := p.global_position + side * 5.5 * boss.body_scale()
	boss.global_position = _ground(at) + Vector3(0, 0.15, 0)
	var to := p.global_position - boss.global_position
	boss.rig.rotation.y = atan2(to.x, to.z)
	Fx.burst(boss.chest_position(), RED, 50, 10.0, 0.1)
	boss.rig.play("o_reaper", 1.3)
	Game.shake(0.3)
	await _wait(0.5)
	if not _casting(boss, run):
		return
	Fx.crescent(boss.chest_position(), boss.forward(), -0.7, RED, 9.0, 8.0)
	Game.shake(0.4)
	if p.global_position.distance_to(boss.global_position) < 7.2 * boss.body_scale():
		p.take_damage(125.0, boss.global_position)


## A storm of crystals from the wings.
static func _shards(boss: Enemy) -> void:
	var run := Game.run_id
	for i in 16:
		if not _casting(boss, run):
			return
		var p := Game.player
		var side := -1.0 if i % 2 == 0 else 1.0
		var right := boss.forward().cross(Vector3.UP)
		var from := boss.global_position + (right * side * randf_range(1.5, 3.5) + Vector3(0, randf_range(4.5, 6.2), 0)) * boss.body_scale()
		var aim := (p.chest() + Vector3(randf_range(-1.2, 1.2), randf_range(-0.5, 0.8), randf_range(-1.2, 1.2)) - from).normalized()
		var shard := BossShard.new()
		shard.direction = aim
		Game.world.add_child(shard)
		shard.global_position = from
		Game.shake(0.08)
		await _wait(0.085)


## Rings of data spikes that burst outward from the blow.
static func _spikes(boss: Enemy) -> void:
	var run := Game.run_id
	var center := boss.global_position
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.75
	mesh.height = 1.0
	mesh.radial_segments = 5
	mesh.rings = 1
	mesh.material = Fx.flat_material(Color(0.5, 0.05, 0.1), 2.0)
	Fx.burst(center + Vector3(0, 0.4, 0), RED, 50, 15.0, 0.1)
	Game.shake(0.7)
	for ring in 4:
		if not _casting(boss, run):
			return
		var radius := 5.0 + ring * 5.0
		var count := 12 + ring * 6
		for i in count:
			var a := i * TAU / count + ring * 0.7
			var spike := MeshInstance3D.new()
			spike.mesh = mesh
			spike.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			Game.world.add_child(spike)
			var tall := randf_range(3.2, 6.5)
			spike.global_position = _ground(center + Vector3(cos(a), 0, sin(a)) * radius)
			spike.scale = Vector3(1.0, 0.02, 1.0)
			var tween := spike.create_tween()
			tween.tween_method(_grow.bind(spike), 0.02, tall, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tween.tween_interval(0.45)
			tween.tween_method(_grow.bind(spike), tall, 0.02, 0.2)
			tween.tween_callback(spike.queue_free)
		Fx.ring(center, radius, RED, 0.25)
		Game.shake(0.3)
		var away := Game.player.global_position - center
		away.y = 0.0
		if absf(away.length() - radius) < 2.3:
			Game.player.take_damage(90.0, center)
		await _wait(0.22)


static func _grow(height: float, spike: MeshInstance3D) -> void:
	spike.scale.y = height
	var base := Game.terrain.get_height(spike.global_position.x, spike.global_position.z)
	spike.global_position.y = base + height * 0.5


## The beam from the broken core. It chases the player, but slowly.
static func _beam(boss: Enemy) -> void:
	var run := Game.run_id
	var length := 90.0
	var outer := CylinderMesh.new()
	outer.top_radius = 1.9
	outer.bottom_radius = 1.9
	outer.height = length
	outer.cap_top = false
	outer.cap_bottom = false
	outer.material = Fx.flat_material(RED, 2.4)
	var inner := CylinderMesh.new()
	inner.top_radius = 0.75
	inner.bottom_radius = 0.75
	inner.height = length
	inner.material = Fx.flat_material(Color(1.0, 0.85, 0.82), 4.0)
	var holder := Node3D.new()
	Game.world.add_child(holder)
	for mesh: CylinderMesh in [outer, inner]:
		var part := MeshInstance3D.new()
		part.mesh = mesh
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		part.extra_cull_margin = 40.0
		holder.add_child(part)
	var aim := (Game.player.chest() - boss.chest_position()).normalized()
	Game.shake(0.5)
	for tick in 16:
		if not _casting(boss, run):
			break
		var p := Game.player
		var origin := boss.chest_position() + boss.forward() * 1.4
		var wanted := (p.chest() - origin).normalized()
		aim = aim.slerp(wanted, 0.11).normalized()
		boss.rig.rotation.y = atan2(aim.x, aim.z)
		holder.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, aim)), origin + aim * length * 0.5)
		Game.shake(0.18)
		var along := (p.chest() - origin).dot(aim)
		if along > 0.0 and along < length and (p.chest() - origin - aim * along).length() < 2.3:
			p.take_damage(34.0, origin)
			Fx.burst(p.chest(), RED, 10, 7.0)
		await _wait(0.1)
	holder.queue_free()


## Marks where the player stands, again and again, and deletes it.
static func _delete(boss: Enemy) -> void:
	var run := Game.run_id
	Game.hud.banner("DELETE", "หลบออกจากวงแดง", RED, 1.4)
	for i in 3:
		if not _casting(boss, run):
			return
		_delete_mark(boss, run, Game.player.global_position)
		await _wait(0.72)


static func _delete_mark(boss: Enemy, run: int, pos: Vector3) -> void:
	var radius := 7.0
	zone(pos, radius, 1.15)
	await _wait(1.15)
	if not _casting(boss, run):
		return
	CosmicFx.pillar(_ground(pos), 70.0, 0.55, RED, radius)
	Fx.burst(_ground(pos) + Vector3(0, 0.5, 0), RED, 40, 18.0, 0.1)
	Game.shake(0.65)
	var to := Game.player.global_position - pos
	to.y = 0.0
	if to.length() < radius:
		Game.player.take_damage(150.0, pos)


## Enraged only: a black sun rises, then falls.
static func _world_end(boss: Enemy) -> void:
	var run := Game.run_id
	var radius := 26.0
	var seconds := 3.3
	var target := Game.player.global_position
	Game.hud.banner("WORLD END", "วิ่งออกจากวงให้ทัน", RED, 2.4)
	zone(target, radius, seconds)
	var mesh := SphereMesh.new()
	mesh.radial_segments = 32
	mesh.rings = 18
	mesh.material = Fx.flat_material(Color(0.0, 0.0, 0.0), 1.0)
	var sun := MeshInstance3D.new()
	sun.mesh = mesh
	sun.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sun.extra_cull_margin = 40.0
	Game.world.add_child(sun)
	var top := target + Vector3(0, 46.0, 0)
	sun.global_position = top
	sun.scale = Vector3.ONE * 0.5
	var tween := sun.create_tween()
	tween.tween_property(sun, "scale", Vector3.ONE * 11.0, seconds * 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sun, "global_position", _ground(target), seconds * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	CosmicFx.nova(top, 24.0, seconds * 0.6, RED)
	Game.shake(0.5)
	await _wait(seconds)
	sun.queue_free()
	if not _casting(boss, run):
		return
	CosmicFx.nova(_ground(target), radius * 1.3, 1.0, RED)
	CosmicFx.pillar(_ground(target), 200.0, 1.0, RED, radius * 0.7)
	CosmicFx.flash(Color(1.0, 0.25, 0.25), 0.85, 1.0)
	Fx.ring(_ground(target), radius, RED, 0.7)
	Game.shake(2.2)
	var to := Game.player.global_position - target
	to.y = 0.0
	if to.length() < radius:
		Game.player.take_damage(360.0, target)


## Draws each effect once behind the loading screen.
static func warm(at: Vector3) -> void:
	zone(at, 2.0, 0.2)
	CosmicFx.nova(at, 2.0, 0.2, RED)
