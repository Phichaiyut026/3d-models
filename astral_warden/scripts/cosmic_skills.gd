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

const ARGON_CYAN := Color(0.25, 0.91, 1.0)
const ARGON_MINT := Color(0.49, 1.0, 0.78)
const SCAN_RADIUS := 60.0
const MARK_SECONDS := 15.0
const MARK_BONUS := 1.5 ## Anything SCAN has marked takes this much more from every blow.
const SEAL_RANGE := 70.0
const SEAL_SECONDS := 4.0
const WALL_RADIUS := 12.0
const PURGE_LENGTH := 320.0
const PURGE_WIDTH := 9.0
const INSTALL_RADIUS := 90.0
const SCAN_DAMAGE := 260.0
const SEAL_DAMAGE := 1600.0
const WALL_PUSH_DAMAGE := 220.0
const WALL_REFLECT_DAMAGE := 60.0
const PURGE_DAMAGE := 2200.0
const PATCH_HEAL := 0.45 ## Share of health PATCH gives back.
const INSTALL_DAMAGE := 3500.0
const UNITY_LENGTH := 95.0 ## UNITED WAVE: metres the wave reaches,
const UNITY_WIDTH := 7.0 ## its half-width before FULL POWER swells it,
const UNITY_DAMAGE := 9000.0 ## and what each of its two blows deals.
const UNITY_WORMS_SHARE := 0.22 ## Each blow takes this share of WORMS' health, past its armour.
const ARGON_PURPLE := Color(0.7, 0.55, 1.0)

static var _genesis_center := Vector3.ZERO
static var _sealed: Array[Enemy] = []
static var _scan_id := 0
static var _erased: Array[Enemy] = []
static var _pull_tick := 0


static func _strike(p: Player, enemy: Enemy, damage: float, poise: float, tint: Color, force: float) -> void:
	enemy.take_hit(damage * p.damage_scale * (MARK_BONUS if is_marked(enemy) else 1.0), poise, p.global_position, false, tint, force)


## Where a ranged power should land: the locked target, or a fixed way ahead.
static func aim_point(p: Player, ahead: float) -> Vector3:
	if p.target != null and p.target.is_alive():
		return p.target.global_position
	var at := p.global_position + p.forward() * ahead
	at.y = Game.ground_height(at.x, at.z)
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


# ------------------------------------------------------------- GEMINI ARGON

static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


static func is_marked(enemy: Enemy) -> bool:
	return enemy.has_meta("argon_mark") and _now() < float(enemy.get_meta("argon_mark"))


static func _mark(enemy: Enemy) -> void:
	enemy.set_meta("argon_mark", _now() + MARK_SECONDS)


static func marked_count() -> int:
	var n := 0
	for enemy in Game.enemies:
		if enemy.is_alive() and is_marked(enemy):
			n += 1
	return n


static func scan_start() -> void:
	_scan_id += 1


## SCAN's front has reached `radius`: everything it passes is marked, and stung.
static func scan_reach(p: Player, center: Vector3, radius: float) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for enemy in Game.enemies:
		if not enemy.is_alive() or int(enemy.get_meta("argon_scan", -1)) == _scan_id:
			continue
		var to := enemy.global_position - center
		to.y = 0.0
		if to.length() <= radius + enemy.radius:
			enemy.set_meta("argon_scan", _scan_id)
			_mark(enemy)
			found.append(enemy)
			_strike(p, enemy, SCAN_DAMAGE, 40.0, ARGON_CYAN, 0.4)
	return found


## QUARANTINE sees threats even when nothing has been scanned.
static func auto_scan(p: Player) -> void:
	_sealed.clear()
	if marked_count() > 0:
		return
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(p.global_position) <= SEAL_RANGE:
			_mark(enemy)


## Seals the nearest marked threat in a cube that holds it still. Returns it, or null.
static func seal_next(p: Player) -> Enemy:
	var best: Enemy = null
	var best_distance := SEAL_RANGE * 2.0
	for enemy in Game.enemies:
		if not enemy.is_alive() or not is_marked(enemy) or enemy in _sealed:
			continue
		var d := enemy.global_position.distance_to(p.global_position)
		if d < best_distance:
			best = enemy
			best_distance = d
	if best != null:
		_sealed.append(best)
		best.freeze(SEAL_SECONDS)
	return best


static func crush_sealed(p: Player) -> int:
	var n := 0
	for enemy in _sealed:
		if enemy.is_alive():
			_strike(p, enemy, SEAL_DAMAGE, 500.0, ARGON_MINT, 1.0)
			n += 1
	_sealed.clear()
	return n


## The dome goes up: whatever stands inside is thrown out of it.
static func firewall_push(p: Player, center: Vector3, radius: float) -> void:
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var away := enemy.global_position - center
		away.y = 0.0
		if away.length() <= radius + enemy.radius:
			enemy.pull(away.normalized() * 30.0)
			_strike(p, enemy, WALL_PUSH_DAMAGE, 120.0, ARGON_CYAN, 0.8)


## Every attack the dome turns away goes back to whoever stands at its wall.
static func firewall_tick(p: Player, center: Vector3, radius: float) -> void:
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(center) <= radius + 4.0 + enemy.radius:
			_strike(p, enemy, WALL_REFLECT_DAMAGE, 20.0, ARGON_CYAN, 0.3)


## A cut down one line through the world, and through every marked threat wherever it is.
static func purge(p: Player) -> void:
	var origin := p.global_position
	var ahead := p.forward()
	Game.hit_stop(0.1)
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var to := enemy.global_position - origin
		to.y = 0.0
		var along := to.dot(ahead)
		var in_line := along > -enemy.radius and along < PURGE_LENGTH + enemy.radius and (to - ahead * along).length() <= PURGE_WIDTH + enemy.radius
		if in_line or is_marked(enemy):
			_strike(p, enemy, PURGE_DAMAGE, 500.0, ARGON_MINT, 1.0)


## The update installs: some health comes back, and stamina is full.
static func patch(p: Player) -> void:
	p.hp = minf(p.max_hp, p.hp + p.max_hp * PATCH_HEAL)
	p.stamina = p.max_stamina


## The whole system is formatted, and everything hostile in it goes.
static func clean_install(p: Player) -> void:
	Game.hit_stop(0.16)
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.global_position.distance_to(p.global_position) <= INSTALL_RADIUS + enemy.radius:
			_strike(p, enemy, INSTALL_DAMAGE, 900.0, ARGON_CYAN, 1.0)


## UNITED WAVE: everyone's power in one wave down the line Gemini faces. `swell` widens it at FULL POWER.
static func united_wave(p: Player, origin: Vector3, ahead: Vector3, swell: float) -> void:
	Game.hit_stop(0.14)
	var width := UNITY_WIDTH * swell
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var to := enemy.global_position - origin
		to.y = 0.0
		var along := to.dot(ahead)
		if along < -enemy.radius or along > UNITY_LENGTH + enemy.radius or (to - ahead * along).length() > width + enemy.radius:
			continue
		if enemy is WormsBoss:
			(enemy as WormsBoss).take_wave(UNITY_WORMS_SHARE, ARGON_MINT)
		else:
			_strike(p, enemy, UNITY_DAMAGE, 900.0, ARGON_MINT, 1.0)


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
