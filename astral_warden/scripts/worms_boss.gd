class_name WormsBoss
extends Enemy
## WORMS, the one who controls everything in the system: the last fight. It waits outside the system
## until OBLIVION falls, then comes down over the tower's arena. Only GEMINI ARGON hurts it properly.

const HP := 30000.0
const ARGON_ARMOUR := 0.5 ## Share of each blow that gets through from ARGON...
const ARGON_MIN_HIT := 30.0
const ARGON_MAX_HIT := 900.0
const ARGON_MAX_PER_SECOND := 1100.0
const ARMOUR := 0.04 ## ...and from anything less.
const MIN_HIT := 5.0
const MAX_HIT := 60.0
const MAX_PER_SECOND := 90.0
const WAKE_RANGE := 40.0
const BLINK_RANGE := 42.0
const CHEST := 13.8 * WormsModel.BODY_SCALE
const HEAD := 16.2 * WormsModel.BODY_SCALE
const ATTACKS := [
	{"anim": "push", "length": 1.6, "from": 0.42, "to": 0.56, "damage": 100.0, "reach": 9.0, "arc": 150.0, "lunge": 9.0},
	{"anim": "grab", "length": 1.5, "from": 0.4, "to": 0.55, "damage": 115.0, "reach": 8.5, "arc": 110.0, "lunge": 11.0},
]

var _final_cooldown := 0.0
var _hinted := false


func setup_worms(pos: Vector3) -> WormsBoss:
	is_boss = true
	kind = "worms"
	home = pos
	position = pos
	max_hp = HP
	hp = max_hp
	radius = 1.6
	reward = 0
	move_speed = 7.5
	engage_reach = 8.0
	max_posture = INF
	return self


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(50.0)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = 10.0
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	add_child(shape)
	_capsule = capsule
	_shape = shape
	rig = WormsModel.new()
	rig.run_speed = move_speed
	add_child(rig)
	_go_dormant()


func is_alive() -> bool:
	return state != "dead" and state != "dormant"


func chest_position() -> Vector3:
	return global_position + Vector3(0, CHEST, 0)


func head_position() -> Vector3:
	return global_position + Vector3(0, HEAD, 0)


func _go_dormant() -> void:
	state = "dormant"
	visible = false
	collision_layer = 0
	collision_mask = 0
	hp = max_hp
	_enraged = false
	global_position = home
	velocity = Vector3.ZERO
	rig.position.y = 0.0
	rig.stop_action()


## It is only part of the world once OBLIVION has fallen, and stays gone once beaten.
func reset() -> void:
	if not Game.boss_defeated or Game.worms_defeated:
		_go_dormant()
		return
	super.reset()
	_final_cooldown = 0.0


## OBLIVION is gone: WORMS comes down into the arena.
func appear() -> void:
	if Game.worms_defeated:
		return
	state = "arrive"
	hp = max_hp
	_enraged = false
	global_position = home
	visible = true
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	rig.stop_action()
	rig.play("sky", 3.2)
	rig.rotation.y = atan2(Game.player.global_position.x - home.x, Game.player.global_position.z - home.z)
	rig.position.y = 60.0
	# With scenes on, it comes down while it talks; the scene starts the fight.
	if Game.cutscene.worms_intro(self, _landed):
		return
	CosmicFx.flash(Color(1.0, 0.06, 0.15), 0.7, 1.2)
	Game.hud.banner("WORMS", "ผู้ควบคุมทุกสิ่งในระบบ · มีแค่ร่าง ARGON (G) ที่ทำร้ายมันได้", WormsSkills.RED, 5.0)
	Game.shake(0.8)
	var tween := rig.create_tween()
	tween.tween_property(rig, "position:y", 0.0, 3.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await tween.finished
	if state != "arrive":
		return
	CosmicFx.shock(global_position, 30.0, 2.6, 1.0, WormsSkills.RED, true)
	CosmicFx.pillar(global_position, 200.0, 1.0, WormsSkills.RED, 8.0)
	Game.shake(1.6)
	_landed()


func _landed() -> void:
	SoldierSkills.pixels(chest_position(), 120, 3.0)
	if state == "arrive":
		state = "idle"


func _idle(delta: float) -> Vector3:
	_face(_to_player(), 2.0, delta)
	if Game.player.is_alive() and Game.state == "play" and not Game.in_haven() and _to_player().length() < WAKE_RANGE:
		_wake()
	return Vector3.ZERO


func _waiting_for_intro() -> bool:
	return false


func _wake() -> void:
	state = "chase"
	_cooldown = 0.6
	_skill_cooldown = 2.0
	_final_cooldown = 12.0
	Game.boss = self
	Game.boss_active = true


func _chase(delta: float) -> Vector3:
	if not Game.player.is_alive():
		state = "idle"
		return Vector3.ZERO
	var to := _to_player()
	var distance := to.length()
	_face(to, 7.0, delta)
	_final_cooldown -= delta
	if _cooldown <= 0.0 and distance > BLINK_RANGE:
		_blink()
		return Vector3.ZERO
	if _skill_cooldown <= 0.0 and _cooldown <= 0.0:
		begin_skill(_next_skill())
		return Vector3.ZERO
	if distance <= engage_reach + 0.6 and _cooldown <= 0.0:
		_begin_attack()
		return Vector3.ZERO
	if distance > engage_reach:
		return to.normalized() * move_speed * (1.3 if _enraged else 1.0)
	return to.normalized().cross(Vector3.UP) * _strafe * 2.4


## It does not walk after anyone: it is simply somewhere else.
func _blink() -> void:
	_cooldown = 1.0
	var p := Game.player
	SoldierSkills.pixels(chest_position(), 80, 2.5)
	var side := p.forward().cross(Vector3.UP) * (1.0 if randf() > 0.5 else -1.0)
	var at := p.global_position + side * 12.0 + p.forward() * 6.0
	global_position = Vector3(at.x, Game.ground_height(at.x, at.z) + 0.15, at.z)
	rig.rotation.y = atan2(p.global_position.x - at.x, p.global_position.z - at.z)
	SoldierSkills.pixels(chest_position(), 80, 2.5)
	Game.shake(0.3)


func _next_skill() -> String:
	if _enraged and _final_cooldown <= 0.0:
		_final_cooldown = 30.0
		return "final"
	_skill_order += 1
	return WormsSkills.ROTATION[_skill_order % WormsSkills.ROTATION.size()]


func begin_skill(skill: String) -> void:
	var info: Dictionary = WormsSkills.SKILLS[skill]
	_skill = skill
	_skill_fired = false
	state = "skill"
	_state_time = 0.0
	_state_length = info["length"]
	rig.play(info["pose"], info["length"])


func _using_skill(delta: float) -> void:
	var info: Dictionary = WormsSkills.SKILLS[_skill]
	var t := _state_time / _state_length
	if not _skill_fired:
		_face(_to_player(), 7.0, delta)
		if t >= info["at"]:
			_skill_fired = true
			WormsSkills.fire(self, _skill)
	if t >= 1.0:
		state = "chase"
		_cooldown = randf_range(0.4, 1.0)
		_skill_cooldown = randf_range(3.5, 6.0) * (0.6 if _enraged else 1.0)


func _begin_attack() -> void:
	_attack = ATTACKS[_attack_index % ATTACKS.size()]
	_attack_index += 1
	_start_attack()
	_slash_later(_attack, _state_length)


func _slash_later(attack: Dictionary, length: float) -> void:
	var run := Game.run_id
	await get_tree().create_timer(length * float(attack["from"])).timeout
	if state != "attack" or run != Game.run_id:
		return
	Fx.crescent(chest_position() - Vector3(0, 2.0, 0), forward(), -0.6 if attack["anim"] == "push" else 0.7, WormsSkills.RED, 9.0, 8.0)
	Game.shake(0.25)


func take_hit(damage: float, poise: float, from: Vector3, _blockable: bool, tint := Color(0.72, 0.6, 1.0), impact := -1.0) -> void:
	if not is_alive() or state == "arrive":
		return
	if state == "idle":
		_wake()
	var argon := Game.player.rig.is_argon
	if argon:
		damage = clampf(damage * ARGON_ARMOUR, ARGON_MIN_HIT, ARGON_MAX_HIT)
		damage = minf(damage, maxf(ARGON_MAX_PER_SECOND - _taken_this_second, 0.0))
	else:
		damage = clampf(damage * ARMOUR, MIN_HIT, MAX_HIT)
		damage = minf(damage, maxf(MAX_PER_SECOND - _taken_this_second, 0.0))
		if not _hinted:
			_hinted = true
			Game.hud.banner("WORMS ควบคุมทุกสิ่ง", "การโจมตีแทบไม่ระคายมัน · กด G เป็นร่าง ARGON", WormsSkills.RED, 3.0)
	_taken_this_second += damage
	_lose(damage, from, tint, poise, impact)


## UNITED WAVE: the power of every hero at once goes straight through its armour.
func take_wave(share: float, tint: Color) -> void:
	if not is_alive() or state == "arrive":
		return
	if state == "idle":
		_wake()
	_lose(max_hp * share, Game.player.global_position, tint, 900.0, 1.0)
	Fx.ring(global_position, 18.0, tint, 0.8)


func _lose(damage: float, from: Vector3, tint: Color, poise: float, impact: float) -> void:
	last_hit_time = Time.get_ticks_msec() / 1000.0
	var to := from - global_position
	to.y = 0.0
	var force := impact if impact >= 0.0 else clampf(poise / 70.0, 0.1, 1.0)
	Fx.impact(chest_position() + to.normalized() * radius, tint, force)
	rig.flash_hit()
	hp -= damage
	if hp <= 0.0:
		_die()
		return
	if not _enraged and hp < max_hp * 0.5:
		_enraged = true
		_final_cooldown = 0.0
		Fx.ring(global_position, 14.0, WormsSkills.RED, 0.7)
		CosmicFx.flash(Color(1.0, 0.06, 0.15), 0.6, 0.8)
		Game.hud.banner("ROOT ACCESS", "WORMS เริ่มเอาจริง", WormsSkills.RED, 2.0)
		Game.shake(0.6)


## Nothing holds it still or drags it anywhere.
func pull(_force: Vector3) -> void:
	pass


func freeze(_seconds: float) -> void:
	pass


func _die() -> void:
	hp = 0.0
	state = "dead"
	_hide_clock = 0.0
	rig.position.y = 0.0
	rig.play("death", 3.0, true)
	collision_layer = 0
	collision_mask = 0
	if Game.player.target == self:
		Game.player.target = null
	SoldierSkills.pixels(chest_position(), 160, 3.5)
	CosmicFx.flash(Color(1.0, 1.0, 1.0), 0.8, 1.2)
	Game.shake(1.8)
	Game.on_worms_defeated()
