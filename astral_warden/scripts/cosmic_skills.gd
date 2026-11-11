class_name CosmicSkills
extends RefCounted
## What the powers do to the valley. CosmicShow plays how they look and calls these on the beat.

## These powers end worlds, so the numbers are meant to be absurd.
const GENESIS_RADIUS := 70.0
const MULTIVERSE_RANGE := 9999.0 ## Every enemy alive, anywhere.
const ERASURE_RADIUS := 400.0
const BANG_RADIUS := 300.0
const EDGE_LENGTH := 320.0
const EDGE_WIDTH := 9.0
const WORLD_ENDING := 999999.0
const VIOLET := Color(0.66, 0.5, 1.0)
const STARLIGHT := Color(0.88, 0.84, 1.0)

static var _genesis_center := Vector3.ZERO
static var _erased: Array[Enemy] = []
static var _pull_tick := 0


static func _strike(p: Player, enemy: Enemy, damage: float, poise: float, tint: Color, force: float) -> void:
	enemy.take_hit(damage * p.damage_scale, poise, p.global_position, false, tint, force)


## Where a ranged power should land: the locked target, or a fixed way ahead.
static func aim_point(p: Player, ahead: float) -> Vector3:
	if p.target != null and p.target.is_alive():
		return p.target.global_position
	var at := p.global_position + p.forward() * ahead
	at.y = Game.terrain.get_height(at.x, at.z)
	return at


# ------------------------------------------------------------- the first form

## A burst of starlight from the open hand, in a wide cone.
static func nova(p: Player) -> void:
	var ahead := p.forward()
	Game.hit_stop(0.05)
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var to := enemy.global_position - p.global_position
		to.y = 0.0
		if to.length() <= 12.0 + enemy.radius and rad_to_deg(ahead.angle_to(to)) <= 55.0:
			_strike(p, enemy, 130.0, 70.0, VIOLET, 0.9)


## COMET comes down: everything around the landing is thrown back.
static func crater(p: Player) -> void:
	Game.hit_stop(0.08)
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(p.global_position) <= 12.0 + enemy.radius:
			_strike(p, enemy, 220.0, 110.0, STARLIGHT, 1.0)


## GALAXY throws two crescents down the line the blade faces.
static func cleave(p: Player) -> void:
	var ahead := p.forward()
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var to := enemy.global_position - p.global_position
		to.y = 0.0
		var along := to.dot(ahead)
		if along > -enemy.radius and along < 24.0 and (to - ahead * along).length() < 5.0 + enemy.radius:
			_strike(p, enemy, 150.0, 60.0, CosmicFx.GOLD, 0.9)


static func throw_star(p: Player, from: Vector3) -> void:
	var aim := p.forward()
	if p.target != null and p.target.is_alive():
		aim = (p.target.chest_position() - from).normalized()
	aim = aim.rotated(Vector3.UP, randf_range(-0.1, 0.1))
	var bolt := StarBolt.new()
	bolt.direction = aim.normalized()
	bolt.damage = 24.0 * p.damage_scale
	bolt.tint = CosmicFx.GOLD
	Game.world.add_child(bolt)
	bolt.global_position = from


static func meteor(p: Player, land: Vector3) -> void:
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(land) <= 5.0 + enemy.radius:
			_strike(p, enemy, 72.0, 30.0, VIOLET, 0.5)


## Every physics tick while the black hole is open.
static func hole_pull(p: Player, at: Vector3, strength: float) -> void:
	_pull_tick += 1
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var to := at - enemy.global_position
		to.y = 0.0
		if to.length() < 22.0:
			enemy.pull(to.normalized() * (16.0 if not enemy.is_boss else 4.0) * strength)
			if _pull_tick % 20 == 0:
				_strike(p, enemy, 22.0, 12.0, VIOLET, 0.2)


static func hole_blast(p: Player, at: Vector3) -> void:
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var to := at - enemy.global_position
		to.y = 0.0
		if to.length() <= 15.0 + enemy.radius:
			_strike(p, enemy, 240.0, 120.0, STARLIGHT, 1.0)


## The first form's last resort.
static func supernova(p: Player) -> void:
	Game.hit_stop(0.12)
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var d := enemy.global_position.distance_to(p.global_position)
		if d <= 34.0 + enemy.radius:
			_strike(p, enemy, lerpf(380.0, 150.0, clampf(d / 34.0, 0.0, 1.0)), 220.0, STARLIGHT, 1.0)


# ------------------------------------------------------------ the supreme form

## Everything on one line, however far it stands.
static func edge(p: Player) -> void:
	var origin := p.global_position
	var ahead := p.forward()
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
static func genesis_start(p: Player) -> void:
	_genesis_center = p.global_position
	p.hp = p.max_hp
	p.fp = p.max_fp


static func genesis_tick(p: Player) -> void:
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(_genesis_center) <= GENESIS_RADIUS + enemy.radius:
			_strike(p, enemy, 1200.0, 20.0, CosmicFx.HUES[randi() % CosmicFx.HUES.size()], 0.4)


## Whole universes fall on everything in range at once.
static func multiverse(p: Player) -> void:
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(p.global_position) <= MULTIVERSE_RANGE:
			_strike(p, enemy, WORLD_ENDING, 22.0, CosmicFx.PALE, 1.0)


## The world breaks and holds still; when it mends, those caught in it pay.
static func erasure_snap(p: Player, seconds: float) -> void:
	_erased.clear()
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(p.global_position) <= ERASURE_RADIUS:
			enemy.freeze(seconds)
			_erased.append(enemy)


static func erasure_restore(p: Player) -> void:
	for enemy in _erased:
		if enemy.is_alive():
			_strike(p, enemy, WORLD_ENDING, 500.0, CosmicFx.PALE, 1.0)
	_erased.clear()


## Everything in the valley's view goes up at once.
static func big_bang(p: Player) -> void:
	Game.hit_stop(0.16)
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var d := enemy.global_position.distance_to(p.global_position)
		if d <= BANG_RADIUS + enemy.radius:
			_strike(p, enemy, WORLD_ENDING, 900.0, CosmicFx.GOLD, 1.0)
