class_name SoldierSkills
extends RefCounted
## What the System Overlord's soldiers can do beyond swinging a sword.

const RED := Color(1.0, 0.13, 0.2)
const MAX_SUMMONS := 4


static func _wait(seconds: float) -> void:
	await Game.get_tree().create_timer(seconds).timeout


static func _casting(enemy: Enemy, run: int) -> bool:
	return is_instance_valid(enemy) and enemy.is_alive() and enemy.state == "skill" and run == Game.run_id and Game.state == "play"


## A soldier coming apart into red pixels.
static func pixels(pos: Vector3, amount: int, spread: float) -> void:
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.12
	box.material = Fx.flat_material(RED, 3.0)
	var p := CPUParticles3D.new()
	p.mesh = box
	p.amount = amount
	p.lifetime = 1.1
	p.one_shot = true
	p.explosiveness = 0.9
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = spread
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0, -2.5, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.6
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.finished.connect(p.queue_free)
	Game.world.add_child(p)
	p.global_position = pos
	p.emitting = true


## DAEMON: a thin line marks the shot, then the beam follows it.
static func beam(enemy: Enemy) -> void:
	var run := Game.run_id
	var origin := enemy.chest_position()
	var aim := (Game.player.chest() - origin).normalized()
	var length := 46.0
	var made := CosmicFx.flame(length / CosmicFx.WEB, 0.5, RED, Game.world)
	var line: MeshInstance3D = made[0]
	var material: ShaderMaterial = made[1]
	material.set_shader_parameter("power", 0.8)
	for tick in 13:
		if not _casting(enemy, run):
			line.queue_free()
			return
		origin = enemy.chest_position()
		aim = aim.slerp((Game.player.chest() - origin).normalized(), 0.12).normalized()
		enemy.rig.rotation.y = atan2(aim.x, aim.z)
		line.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, aim)), origin)
		await _wait(0.1)
	await _wait(0.18) # The aim holds still here: this is the moment to step aside.
	if not _casting(enemy, run):
		line.queue_free()
		return
	material.set_shader_parameter("rad", 3.2)
	material.set_shader_parameter("power", 2.6)
	CosmicFx.shock(origin, 3.0, 2.0, 0.3, RED)
	Game.shake(0.3)
	var p := Game.player
	var along := (p.chest() - origin).dot(aim)
	if along > 0.0 and along < length and (p.chest() - origin - aim * along).length() < 1.5:
		p.take_damage(70.0, origin)
	await _wait(0.3)
	line.queue_free()


## DAEMON: comes apart and reassembles somewhere else around the player.
static func teleport(enemy: Enemy) -> void:
	pixels(enemy.chest_position(), 24, 0.6)
	var p := Game.player
	var a := randf() * TAU
	var at := p.global_position + Vector3(cos(a), 0, sin(a)) * randf_range(16.0, 22.0)
	at.y = Game.terrain.get_height(at.x, at.z) + 0.15
	enemy.global_position = at
	pixels(enemy.chest_position(), 24, 0.6)


## ROOTKIT: a red crescent thrown down the line.
static func wave(enemy: Enemy) -> void:
	var ahead := enemy.forward()
	var from := enemy.chest_position()
	Fx.crescent(from + ahead * 1.5, ahead, -0.6, RED, 9.0, 24.0)
	Game.shake(0.4)
	var to := Game.player.global_position - enemy.global_position
	to.y = 0.0
	var along := to.dot(ahead)
	if along > 0.0 and along < 24.0 and (to - ahead * along).length() < 3.0:
		Game.player.take_damage(90.0, enemy.global_position)


## ROOTKIT: calls fresh processes out of the ground.
static func call_processes(enemy: Enemy) -> void:
	var alive := 0
	for other in Game.enemies:
		if other.summoned and other.is_alive():
			alive += 1
	var count := mini(3, MAX_SUMMONS - alive)
	Game.hud.banner("ROOTKIT", "เรียกกำลังเสริม", RED, 1.2)
	for i in count:
		var a := i * TAU / 3.0 + randf()
		var at := enemy.global_position + Vector3(cos(a), 0, sin(a)) * 6.0
		at.y = Game.terrain.get_height(at.x, at.z) + 0.1
		var soldier := Enemy.new().setup(at, false, "process")
		soldier.summoned = true
		soldier.reward = 0
		Game.world.add_child(soldier)
		Game.enemies.append(soldier)
		soldier._wake()
		pixels(at + Vector3(0, 1.0, 0), 30, 0.8)
		Fx.ring(at, 3.0, RED, 0.4)
