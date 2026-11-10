class_name CosmicSkills
extends RefCounted
## What the supreme form's five powers do to the valley. Keys match Player.SKILLS.

## These powers end worlds, so the numbers are meant to be absurd.
const GENESIS_RADIUS := 70.0
const MULTIVERSE_RANGE := 9999.0 ## Every enemy alive, anywhere.
const ERASURE_RADIUS := 400.0
const BANG_RADIUS := 300.0
const EDGE_LENGTH := 320.0
const EDGE_WIDTH := 9.0
const WORLD_ENDING := 999999.0


static func _strike(p: Player, enemy: Enemy, damage: float, poise: float, tint: Color, force: float) -> void:
	enemy.take_hit(damage * p.damage_scale, poise, p.global_position, false, tint, force)


static func _still_running(run: int) -> bool:
	return run == Game.run_id and Game.state == "play"


static func fire(p: Player, skill: String) -> void:
	match skill:
		"edge":
			_edge(p)
		"genesis":
			_genesis(p)
		"multiverse":
			_multiverse(p)
		"erasure":
			_erasure(p)
		"bigbang":
			_big_bang(p)
		"nova":
			_nova(p)
		"galaxy":
			_galaxy(p)
		"barrage":
			_barrage(p)
		"starfall":
			_starfall(p)
		"hole":
			_black_hole(p)
		"supernova":
			_supernova(p)


# ------------------------------------------------------------- the first form

const VIOLET := Color(0.66, 0.5, 1.0)
const STARLIGHT := Color(0.88, 0.84, 1.0)


## Where a ranged power should land: the locked target, or a fixed way ahead.
static func _aim_point(p: Player, ahead: float) -> Vector3:
	if p.target != null and p.target.is_alive():
		return p.target.global_position
	var at := p.global_position + p.forward() * ahead
	at.y = Game.terrain.get_height(at.x, at.z)
	return at


## A burst of starlight from the open hand, in a wide cone.
static func _nova(p: Player) -> void:
	var ahead := p.forward()
	var at := p.chest() + ahead * 1.6
	CosmicFx.star_at(at, 7.0, STARLIGHT, 0.1)
	Fx.crescent(at, ahead, 0.0, VIOLET, 9.0, 11.0)
	Fx.burst(at, VIOLET, 50, 15.0, 0.08)
	Fx.ring(p.global_position + ahead * 2.0, 8.0, STARLIGHT, 0.4)
	Game.shake(0.45)
	Game.hit_stop(0.05)
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var to := enemy.global_position - p.global_position
		to.y = 0.0
		if to.length() <= 12.0 + enemy.radius and rad_to_deg(ahead.angle_to(to)) <= 55.0:
			_strike(p, enemy, 130.0, 70.0, VIOLET, 0.9)


## Called every tick of the COMET dash: whatever the warrior passes through is struck once.
static func comet_tick(p: Player, hit: Array[Enemy]) -> void:
	Fx.burst(p.chest() + Vector3(randf_range(-0.5, 0.5), randf_range(-0.6, 0.6), randf_range(-0.5, 0.5)), VIOLET, 5, 3.0, 0.1)
	for enemy in Game.enemies:
		if enemy.is_alive() and not enemy in hit and enemy.global_position.distance_to(p.global_position) < 3.0 + enemy.radius:
			hit.append(enemy)
			_strike(p, enemy, 150.0, 90.0, STARLIGHT, 1.0)
			Game.shake(0.35)


## A slow spiral on the ground that grinds down whatever stands on it.
static func _galaxy(p: Player) -> void:
	var run := Game.run_id
	var center := p.global_position
	var radius := 13.0
	CosmicFx.galaxy(Vector3(center.x, Game.terrain.get_height(center.x, center.z) + 0.6, center.z), p.forward(), radius * 1.15, 1.8, 0.0)
	Fx.ring(center, radius, VIOLET, 0.6)
	Game.shake(0.3)
	for tick in 5:
		await Game.get_tree().create_timer(0.28).timeout
		if not _still_running(run):
			return
		Game.shake(0.12)
		for enemy in Game.enemies:
			if enemy.is_alive() and enemy.global_position.distance_to(center) <= radius + enemy.radius:
				_strike(p, enemy, 38.0, 16.0, VIOLET, 0.3)


## A rapid stream of star shards at whatever is ahead.
static func _barrage(p: Player) -> void:
	var run := Game.run_id
	for i in 16:
		if not _still_running(run) or p.state != "skill":
			return
		var aim := p.forward()
		if p.target != null and p.target.is_alive():
			aim = (p.target.chest_position() - p.chest()).normalized()
		aim = aim.rotated(Vector3.UP, randf_range(-0.13, 0.13))
		aim.y += randf_range(-0.05, 0.08)
		var bolt := StarBolt.new()
		bolt.direction = aim.normalized()
		bolt.damage = 36.0 * p.damage_scale
		Game.world.add_child(bolt)
		bolt.global_position = p.chest() + p.forward() * 1.2 + Vector3(randf_range(-0.8, 0.8), randf_range(-0.3, 0.7), 0)
		Game.shake(0.08)
		await Game.get_tree().create_timer(0.085).timeout


## Meteors out of the sky across the ground ahead.
static func _starfall(p: Player) -> void:
	var run := Game.run_id
	var center := _aim_point(p, 15.0)
	for i in 22:
		if not _still_running(run):
			return
		var a := randf() * TAU
		var land := center + Vector3(cos(a), 0, sin(a)) * sqrt(randf()) * 13.0
		land.y = Game.terrain.get_height(land.x, land.z)
		var meteor := CosmicFx.star_at(land + Vector3(5.0, 34.0, 3.0), 3.6, STARLIGHT, -1.0)
		var tween := meteor.create_tween()
		tween.tween_property(meteor, "global_position", land, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(_meteor_lands.bind(p, meteor, land))
		await Game.get_tree().create_timer(0.07).timeout


static func _meteor_lands(p: Player, meteor: MeshInstance3D, land: Vector3) -> void:
	meteor.queue_free()
	Fx.ring(land, 5.0, VIOLET, 0.3)
	Fx.burst(land + Vector3(0, 0.3, 0), VIOLET, 18, 11.0, 0.08)
	Game.shake(0.22)
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(land) <= 5.0 + enemy.radius:
			_strike(p, enemy, 72.0, 30.0, VIOLET, 0.5)


## A black hole that drags everything in, then gives it all back at once.
static func _black_hole(p: Player) -> void:
	var run := Game.run_id
	var at := _aim_point(p, 13.0)
	at.y += 3.2
	var mesh := SphereMesh.new()
	mesh.radial_segments = 24
	mesh.rings = 14
	mesh.material = Fx.flat_material(Color.BLACK, 1.0)
	var core := MeshInstance3D.new()
	core.mesh = mesh
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Game.world.add_child(core)
	core.global_position = at
	core.scale = Vector3.ONE * 0.2
	var tween := core.create_tween()
	tween.tween_property(core, "scale", Vector3.ONE * 3.6, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	CosmicFx.galaxy(at, p.forward(), 9.0, 1.7, 0.5)
	for tick in 18:
		await Game.get_tree().create_timer(0.08).timeout
		if not _still_running(run):
			core.queue_free()
			return
		Fx.burst(at, STARLIGHT, 4, -7.0, 0.06)
		for enemy in Game.enemies:
			if not enemy.is_alive():
				continue
			var to := at - enemy.global_position
			to.y = 0.0
			if to.length() < 22.0:
				enemy.pull(to.normalized() * (16.0 if not enemy.is_boss else 4.0))
				if tick % 4 == 0:
					_strike(p, enemy, 22.0, 12.0, VIOLET, 0.2)
	core.queue_free()
	CosmicFx.nova(at, 15.0, 0.55, VIOLET)
	CosmicFx.flash(STARLIGHT, 0.5, 0.35)
	Fx.ring(at - Vector3(0, 3.0, 0), 15.0, STARLIGHT, 0.5)
	Game.shake(0.9)
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(at) <= 15.0 + enemy.radius:
			_strike(p, enemy, 240.0, 120.0, STARLIGHT, 1.0)


static func supernova_charge(p: Player, seconds: float) -> void:
	CosmicFx.implode(p.chest() + Vector3(0, 1.0, 0), seconds)
	Game.shake(0.35)


## The first form's last resort.
static func _supernova(p: Player) -> void:
	var center := p.chest()
	CosmicFx.nova(center, 34.0, 0.9, VIOLET)
	CosmicFx.flash(STARLIGHT, 0.9, 0.8)
	CosmicFx.pillar(p.global_position, 90.0, 0.9, VIOLET, 9.0)
	for i in 3:
		Fx.ring(p.global_position, 12.0 + i * 11.0, VIOLET if i % 2 == 0 else STARLIGHT, 0.6 + i * 0.12)
	Fx.burst(center, VIOLET, 70, 34.0, 0.14)
	Game.shake(1.5)
	Game.hit_stop(0.12)
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var d := enemy.global_position.distance_to(p.global_position)
		if d <= 34.0 + enemy.radius:
			_strike(p, enemy, lerpf(380.0, 150.0, clampf(d / 34.0, 0.0, 1.0)), 220.0, STARLIGHT, 1.0)


# ------------------------------------------------------------ the supreme form

## Everything on one line, however far it stands.
static func _edge(p: Player) -> void:
	var origin := p.global_position
	var ahead := p.forward()
	CosmicFx.world_cut(origin, ahead, EDGE_LENGTH, EDGE_WIDTH)
	CosmicFx.flash(CosmicFx.PALE, 0.7, 0.4)
	Game.shake(1.4)
	Game.hit_stop(0.1)
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var to := enemy.global_position - origin
		to.y = 0.0
		var along := to.dot(ahead)
		if along < -enemy.radius or along > EDGE_LENGTH + enemy.radius:
			continue
		if (to - ahead * along).length() <= EDGE_WIDTH + enemy.radius:
			_strike(p, enemy, WORLD_ENDING, 500.0, CosmicFx.GOLD, 1.0)


## A galaxy overhead that burns the ground beneath it and mends its maker.
static func _genesis(p: Player) -> void:
	var run := Game.run_id
	var center := p.global_position
	var ahead := p.forward()
	CosmicFx.galaxy(center + ahead * 55.0 + Vector3(0, 34.0, 0), ahead, GENESIS_RADIUS * 1.6, 2.5)
	Fx.ring(center, GENESIS_RADIUS, CosmicFx.PALE, 0.8)
	p.hp = p.max_hp
	p.fp = p.max_fp
	Fx.burst(p.chest(), CosmicFx.GOLD, 34, 5.0)
	Game.shake(0.8)
	for tick in 6:
		await Game.get_tree().create_timer(0.3).timeout
		if not _still_running(run):
			return
		for i in 12:
			var a := randf() * TAU
			var at := center + Vector3(cos(a), 0, sin(a)) * randf_range(2.0, GENESIS_RADIUS)
			at.y = Game.terrain.get_height(at.x, at.z) + randf_range(1.0, 18.0)
			CosmicFx.star_at(at, randf_range(4.0, 9.0), CosmicFx.HUES[randi() % CosmicFx.HUES.size()], 0.1)
			Fx.burst(at, CosmicFx.GOLD, 10, 7.0)
		Game.shake(0.22)
		for enemy in Game.enemies:
			if enemy.is_alive() and enemy.global_position.distance_to(center) <= GENESIS_RADIUS + enemy.radius:
				_strike(p, enemy, 5000.0, 80.0, CosmicFx.HUES[tick % CosmicFx.HUES.size()], 0.6)


## Whole universes gather in the sky, then fall on everything in range.
static func _multiverse(p: Player) -> void:
	var run := Game.run_id
	var center := p.global_position
	var targets: Array[Enemy] = []
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(center) <= MULTIVERSE_RANGE:
			targets.append(enemy)
	var orbs: Array[MeshInstance3D] = []
	var heading := p.forward()
	for i in 42:
		# Spread across the sky ahead, where the camera can see them gather.
		var side := fposmod(i * 0.618, 1.0) * 2.0 - 1.0
		var reach := 16.0 + fposmod(i * 37.0, 45.0)
		var at := center + heading.rotated(Vector3.UP, side * 1.25) * reach + Vector3(0, 7.0 + fposmod(i * 13.0, 26.0), 0)
		orbs.append(CosmicFx.star_at(at, 7.0 + fposmod(i * 7.0, 8.0), CosmicFx.HUES[i % CosmicFx.HUES.size()], -1.0))
		await Game.get_tree().create_timer(0.018).timeout
		if not _still_running(run):
			for orb in orbs:
				orb.queue_free()
			return
	Game.shake(0.3)
	await Game.get_tree().create_timer(0.55).timeout
	var shares := {}
	for i in orbs.size():
		if not targets.is_empty():
			var enemy: Enemy = targets[i % targets.size()]
			shares[enemy] = shares.get(enemy, 0) + 1
	for i in orbs.size():
		var orb := orbs[i]
		var enemy: Enemy = null if targets.is_empty() else targets[i % targets.size()]
		var goal := (center + heading * 14.0) if enemy == null else enemy.chest_position()
		var tween := orb.create_tween()
		tween.tween_interval(i * 0.012)
		tween.tween_property(orb, "global_position", goal, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(_orb_lands.bind(p, orb, enemy, WORLD_ENDING / maxf(shares.get(enemy, 1), 1.0), i))


static func _orb_lands(p: Player, orb: MeshInstance3D, enemy: Enemy, damage: float, index: int) -> void:
	var tint: Color = CosmicFx.HUES[index % CosmicFx.HUES.size()]
	Fx.impact(orb.global_position, tint, 1.0)
	Fx.ring(orb.global_position, 14.0, tint, 0.5)
	Game.shake(0.6)
	orb.queue_free()
	if enemy != null and enemy.is_alive():
		_strike(p, enemy, damage, 22.0, tint, 0.4)


## The world breaks and holds still; when it mends, those caught in it pay.
static func _erasure(p: Player) -> void:
	var run := Game.run_id
	var caught: Array[Enemy] = []
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(p.global_position) <= ERASURE_RADIUS:
			enemy.freeze(3.0)
			caught.append(enemy)
	CosmicFx.shatter(1.75)
	Game.shake(0.6)
	await Game.get_tree().create_timer(1.75).timeout
	if not _still_running(run):
		return
	CosmicFx.flash(Color.WHITE, 0.95, 0.5)
	Game.shake(0.8)
	for enemy in caught:
		if enemy.is_alive():
			_strike(p, enemy, WORLD_ENDING, 500.0, CosmicFx.PALE, 1.0)


static func big_bang_charge(p: Player, seconds: float) -> void:
	CosmicFx.implode(p.chest() + Vector3(0, 6.0, 0), seconds)
	Game.shake(0.7)


## Everything in the valley's view goes up at once.
static func _big_bang(p: Player) -> void:
	var center := p.chest() + Vector3(0, 6.0, 0)
	CosmicFx.nova(center, BANG_RADIUS, 1.5)
	CosmicFx.flash(Color(1.0, 0.96, 0.84), 1.0, 1.8)
	CosmicFx.pillar(p.global_position, 500.0, 1.6, CosmicFx.GOLD, 45.0)
	for i in CosmicFx.HUES.size():
		Fx.ring(p.global_position, BANG_RADIUS * (0.2 + i * 0.16), CosmicFx.HUES[i], 0.8 + i * 0.14)
	Fx.burst(center, CosmicFx.GOLD, 90, 80.0, 0.3)
	Game.shake(3.0)
	Game.hit_stop(0.16)
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var d := enemy.global_position.distance_to(p.global_position)
		if d <= BANG_RADIUS + enemy.radius:
			_strike(p, enemy, WORLD_ENDING, 900.0, CosmicFx.GOLD, 1.0)
