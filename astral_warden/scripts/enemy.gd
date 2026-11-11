class_name Enemy
extends CharacterBody3D
## Valley soldiers and the tower's warden share this state machine.

const GRAVITY := 24.0

const SOLDIER_ATTACKS := [
	{"anim": "slash1", "length": 1.3, "from": 0.42, "to": 0.58, "damage": 62.0, "reach": 3.0, "arc": 130.0, "lunge": 4.5},
	{"anim": "slash3", "length": 1.55, "from": 0.48, "to": 0.62, "damage": 88.0, "reach": 3.1, "arc": 80.0, "lunge": 5.5},
]
const BOSS_ATTACKS := [
	{"anim": "o_cleave", "length": 1.9, "from": 0.44, "to": 0.54, "damage": 104.0, "reach": 6.0, "arc": 170.0, "lunge": 6.5},
	{"anim": "o_reaper", "length": 1.8, "from": 0.38, "to": 0.5, "damage": 96.0, "reach": 6.0, "arc": 170.0, "lunge": 6.5},
	{"anim": "o_thrust", "length": 1.75, "from": 0.36, "to": 0.48, "damage": 150.0, "reach": 6.6, "arc": 70.0, "lunge": 8.0},
	{"anim": "slam", "length": 1.9, "from": 0.72, "to": 0.78, "damage": 135.0, "reach": 7.5, "arc": 360.0, "lunge": 0.0},
]

## The four soldiers. `body` is the rig's scale, `pace` stretches each swing, `power` scales its damage.
const SOLDIERS := {
	"process": {"hp": 150.0, "radius": 0.6, "speed": 5.0, "reach": 2.7, "posture": 55.0, "reward": 110, "body": 1.05, "pace": 0.85, "power": 0.75},
	"firewall": {"hp": 420.0, "radius": 0.95, "speed": 2.9, "reach": 3.4, "posture": 140.0, "reward": 260, "body": 1.52, "pace": 1.25, "power": 1.1},
	"daemon": {"hp": 110.0, "radius": 0.55, "speed": 4.4, "reach": 2.5, "posture": 40.0, "reward": 180, "body": 1.2, "pace": 1.0, "power": 1.0},
	"rootkit": {"hp": 1200.0, "radius": 1.2, "speed": 4.2, "reach": 5.2, "posture": 230.0, "reward": 900, "body": 2.15, "pace": 1.1, "power": 1.6},
}
const SHIELD_DOWN_TIME := 5.0
const SHIELD_BREAK_POISE := 60.0

const FIRST_BOSS_HP := 1500.0
const OBLIVION_HP := 6000.0
const OBLIVION_BODY := 2.7
const OBLIVION_ARMOUR := 0.12 ## Share of each blow that gets through.
const OBLIVION_MIN_HIT := 15.0 ## Even the first form's weakest cut must count for something.
const OBLIVION_MAX_HIT := 120.0
const OBLIVION_MAX_PER_SECOND := 120.0 ## So a storm of small hits cannot erase it either.

var is_boss := false
var kind := "process"
var summoned := false
var oblivion := false
var max_hp := 150.0
var hp := max_hp
var radius := 0.55
var reward := 140
var move_speed := 3.9
var engage_reach := 2.5
var max_posture := 55.0
var state := "idle" ## idle, chase, attack, skill, stagger, rebirth, dead
var last_hit_time := -100.0

var rig: PoseRig
var home := Vector3.ZERO

var _posture := 0.0
var _state_time := 0.0
var _state_length := 0.0
var _attack: Dictionary
var _did_hit := false
var _cooldown := 0.0
var _strafe := 1.0
var _patrol_clock := 0.0
var _slam_from := Vector3.ZERO
var _slam_to := Vector3.ZERO
var _enraged := false
var _attack_index := 0
var _hide_clock := 0.0
var _knock := Vector3.ZERO
var _tick_from := Vector3.ZERO
var _tick_to := Vector3.ZERO
var _skill := ""
var _skill_cooldown := 0.0
var _skill_order := 0
var _world_end_cooldown := 0.0
var _skill_fired := false
var _capsule: CapsuleShape3D
var _shape: CollisionShape3D
var _rebirth_started := false
var _taken_this_second := 0.0
var _second_clock := 0.0
var _body := 1.0
var _pace := 1.0
var _power := 1.0
var _shield_down := 0.0
var _call_next := false


func setup(pos: Vector3, boss: bool, soldier_kind := "process") -> Enemy:
	is_boss = boss
	home = pos
	position = pos
	if boss:
		max_hp = 1500.0
		radius = 1.15
		reward = 0
		move_speed = 4.9
		engage_reach = 5.0
		max_posture = 200.0
	else:
		kind = soldier_kind
		var stats: Dictionary = SOLDIERS[kind]
		max_hp = stats["hp"]
		radius = stats["radius"]
		reward = stats["reward"]
		move_speed = stats["speed"]
		engage_reach = stats["reach"]
		max_posture = stats["posture"]
		_body = stats["body"]
		_pace = stats["pace"]
		_power = stats["power"]
	hp = max_hp
	return self


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	floor_snap_length = 0.5
	floor_max_angle = deg_to_rad(50.0)
	_strafe = 1.0 if randf() > 0.5 else -1.0

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 1.05 if is_boss else 0.42 * _body
	capsule.height = 4.0 if is_boss else 2.0 * _body
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	add_child(shape)
	_capsule = capsule
	_shape = shape

	rig = OverlordModel.new() if is_boss else SoldierModel.new(kind)
	rig.run_speed = move_speed
	rig.scale = Vector3.ONE * (0.62 if is_boss else _body)
	rig.rotation.y = randf() * TAU
	add_child(rig)


func is_alive() -> bool:
	return state != "dead"


func forward() -> Vector3:
	return Vector3(sin(rig.rotation.y), 0, cos(rig.rotation.y))


func body_scale() -> float:
	return OBLIVION_BODY if oblivion else 1.0


func chest_position() -> Vector3:
	return global_position + Vector3(0, 3.6 * body_scale() if is_boss else 1.3 * _body + (0.7 if kind == "daemon" else 0.0), 0)


func head_position() -> Vector3:
	return global_position + Vector3(0, 5.8 * body_scale() if is_boss else 2.35 * _body + (0.7 if kind == "daemon" else 0.0), 0)


## Stops mid-swing or mid-power, so a scene starts from a clean stance.
func halt_for_scene() -> void:
	state = "idle"
	rig.position.y = 0.0
	rig.stop_action()


## The first form is gone: from here on the fight is against OBLIVION.
func become_oblivion() -> void:
	oblivion = true
	_enraged = false
	_posture = 0.0
	_attack_index = 0
	max_hp = OBLIVION_HP
	hp = max_hp
	radius = 2.8
	move_speed = 6.4
	engage_reach = 11.0
	max_posture = INF
	_set_body(2.8, 10.8)
	state = "idle"
	rig.stop_action()
	rig.run_speed = move_speed
	(rig as OverlordModel).awaken()


## For a new run.
func restore_first_form() -> void:
	if not is_boss:
		return
	oblivion = false
	_rebirth_started = false
	max_hp = FIRST_BOSS_HP
	radius = 1.15
	move_speed = 4.9
	engage_reach = 5.0
	max_posture = 200.0
	_set_body(1.05, 4.0)
	rig.run_speed = move_speed
	(rig as OverlordModel).revert_form()


func _set_body(capsule_radius: float, height: float) -> void:
	_capsule.radius = capsule_radius
	_capsule.height = height
	_shape.position.y = height * 0.5


func is_engaged() -> bool:
	return state == "chase" or state == "attack" or state == "stagger" or state == "skill"


func reset() -> void:
	hp = max_hp
	_posture = 0.0
	state = "idle"
	_enraged = false
	_attack_index = 0
	global_position = home
	velocity = Vector3.ZERO
	rig.position.y = 0.0
	rig.stop_action()
	visible = true
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	last_hit_time = -100.0
	_shield_down = 0.0
	if kind == "firewall" and rig is SoldierModel:
		(rig as SoldierModel).set_shield(true)


func _physics_process(delta: float) -> void:
	if Game.terrain == null:
		return
	_state_time += delta
	_cooldown -= delta
	_skill_cooldown -= delta
	_world_end_cooldown -= delta
	if _shield_down > 0.0:
		_shield_down -= delta
		if _shield_down <= 0.0 and state != "dead":
			(rig as SoldierModel).set_shield(true)
			Fx.ring(global_position, 3.0, Color(1.0, 0.13, 0.2), 0.3)
	_second_clock += delta
	if _second_clock >= 1.0:
		_second_clock = 0.0
		_taken_this_second = 0.0
	if state == "rebirth" and not _rebirth_started and Game.state == "play":
		_rebirth_started = Game.cutscene.boss_rebirth(self)
	var horizontal := Vector3.ZERO
	if Game.state == "play" or state == "attack":
		match state:
			"idle":
				horizontal = _idle(delta)
			"chase":
				horizontal = _chase(delta)
			"attack":
				horizontal = _attacking(delta)
			"skill":
				_using_skill(delta)
			"stagger":
				if _state_time >= _state_length:
					state = "chase"
					_posture = 0.0
	if state == "dead":
		_hide_clock += delta
		if _hide_clock > (3.5 if is_boss else 1.0) and visible:
			if is_boss:
				Fx.burst(chest_position() - Vector3(0, 1, 0), Color(1.0, 0.8, 0.35), 30, 4.0)
			else:
				SoldierSkills.pixels(chest_position() - Vector3(0, 0.4 * _body, 0), int(40 * _body), 0.5 * _body)
			visible = false

	_knock = _knock.move_toward(Vector3.ZERO, 26.0 * delta)
	velocity.x = horizontal.x + _knock.x
	velocity.z = horizontal.z + _knock.z
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= GRAVITY * delta
	if state != "dead":
		move_and_slide()
		var ground := Game.terrain.get_height(global_position.x, global_position.z)
		if global_position.y < ground - 0.2:
			global_position.y = ground + 0.1
	_tick_from = _tick_to
	_tick_to = global_position
	rig.set_motion(horizontal if state == "chase" or state == "idle" else Vector3.ZERO)


func _process(_delta: float) -> void:
	if _tick_from.distance_to(_tick_to) > 1.5:
		_tick_from = _tick_to
	var offset := _tick_from.lerp(_tick_to, Engine.get_physics_interpolation_fraction()) - global_position
	rig.position.x = offset.x
	rig.position.z = offset.z


func _face(dir: Vector3, rate: float, delta: float) -> void:
	if dir.length() > 0.001:
		rig.rotation.y = lerp_angle(rig.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-rate * delta))


func _to_player() -> Vector3:
	var to := Game.player.global_position - global_position
	to.y = 0.0
	return to


func _idle(delta: float) -> Vector3:
	var to := _to_player()
	if Game.player.is_alive() and Game.state == "play" and not Game.in_haven():
		if is_boss:
			if Vector2(Game.player.global_position.x - home.x, Game.player.global_position.z - home.z).length() < 27.0:
				if _waiting_for_intro():
					Game.cutscene.boss_intro(self)
				else:
					_wake()
				return Vector3.ZERO
		elif to.length() < 17.0 and rad_to_deg(forward().angle_to(to)) < 105.0 or to.length() < 6.0:
			_wake()
			return Vector3.ZERO
	if is_boss:
		_face(_to_player(), 2.0, delta)
		return Vector3.ZERO

	# Short walks around the post.
	_patrol_clock += delta
	var offset := Vector3(sin(_patrol_clock * 0.17 + home.x) * 5.0, 0, cos(_patrol_clock * 0.23 + home.z) * 5.0)
	var goal := home + offset - global_position
	goal.y = 0.0
	if goal.length() < 0.8:
		return Vector3.ZERO
	_face(goal, 3.0, delta)
	return goal.normalized() * 1.3


## The boss cannot be touched until it has had its say.
func _waiting_for_intro() -> bool:
	return is_boss and state == "idle" and Game.cutscenes_on and (not Game.boss_intro_seen or Game.state == "cutscene")


func _wake() -> void:
	state = "chase"
	_cooldown = 0.5
	if is_boss:
		Game.boss = self
		Game.boss_active = true
		_skill_cooldown = 2.5
		_world_end_cooldown = 6.0
	elif kind == "daemon":
		_skill_cooldown = 1.5
	elif kind == "rootkit":
		_skill_cooldown = 3.0


## Keeps its distance, shoots, and vanishes if anything gets close.
func _daemon(delta: float, to: Vector3) -> Vector3:
	var distance := to.length()
	_face(to, 8.0, delta)
	if distance < 7.0 and _cooldown <= 0.0:
		_cooldown = 2.5
		SoldierSkills.teleport(self)
		return Vector3.ZERO
	if _skill_cooldown <= 0.0 and distance < 40.0:
		begin_skill("daemon_beam")
		return Vector3.ZERO
	if distance > 26.0:
		return to.normalized() * move_speed
	if distance < 14.0:
		return -to.normalized() * move_speed
	return to.normalized().cross(Vector3.UP) * _strafe * 2.4


func _chase(delta: float) -> Vector3:
	if not Game.player.is_alive():
		state = "idle"
		return Vector3.ZERO
	var to := _to_player()
	var distance := to.length()
	if kind == "daemon" and not is_boss:
		return _daemon(delta, to)
	if kind == "rootkit" and _skill_cooldown <= 0.0 and _cooldown <= 0.0:
		_call_next = not _call_next
		begin_skill("rootkit_call" if _call_next else "rootkit_wave")
		return Vector3.ZERO
	if not is_boss and home.distance_to(global_position) > 60.0:
		state = "idle"
		global_position = home
		hp = max_hp
		return Vector3.ZERO
	_face(to, 9.0, delta)
	if is_boss and _skill_cooldown <= 0.0 and _cooldown <= 0.0:
		begin_skill(_next_skill())
		return Vector3.ZERO
	if distance <= engage_reach + 0.6 and _cooldown <= 0.0:
		_begin_attack()
		return Vector3.ZERO
	if is_boss and distance > 14.0 and _cooldown <= 0.0:
		_begin_slam()
		return Vector3.ZERO
	if distance > engage_reach:
		return to.normalized() * move_speed * (1.25 if _enraged else 1.0)
	# In range and waiting: pace sideways so the fight keeps moving.
	return to.normalized().cross(Vector3.UP) * _strafe * 1.6


func _next_skill() -> String:
	if oblivion:
		if _enraged and _world_end_cooldown <= 0.0:
			_world_end_cooldown = 40.0
			return "flick"
		_skill_order += 1
		return OverlordSkills.OBLIVION_ROTATION[_skill_order % OverlordSkills.OBLIVION_ROTATION.size()]
	if _enraged and _world_end_cooldown <= 0.0:
		_world_end_cooldown = 28.0
		return "worldend"
	_skill_order += 1
	return OverlordSkills.ROTATION[_skill_order % OverlordSkills.ROTATION.size()]


func begin_skill(skill: String) -> void:
	var info: Dictionary = OverlordSkills.SKILLS[skill]
	_skill = skill
	_skill_fired = false
	state = "skill"
	_state_time = 0.0
	_state_length = info["length"]
	rig.position.y = 0.0
	rig.play(info["anim"], info.get("anim_length", info["length"]))


func _using_skill(delta: float) -> void:
	var info: Dictionary = OverlordSkills.SKILLS[_skill]
	var t := _state_time / _state_length
	if not _skill_fired:
		_face(_to_player(), 7.0, delta)
		if t >= info["at"]:
			_skill_fired = true
			OverlordSkills.fire(self, _skill)
	if t >= 1.0:
		state = "chase"
		_cooldown = randf_range(0.5, 1.2)
		_skill_cooldown = randf_range(4.5, 7.5) * (0.6 if _enraged else 1.0) * (0.55 if oblivion else 1.0)


func _begin_attack() -> void:
	var table: Array = BOSS_ATTACKS if is_boss else SOLDIER_ATTACKS
	var pool := table.size() - 1 if is_boss else table.size()
	_attack = table[_attack_index % pool] if is_boss else table[randi() % pool]
	_attack_index += 1
	_start_attack()


func _begin_slam() -> void:
	_attack = BOSS_ATTACKS[3]
	_slam_from = global_position
	_slam_to = Game.player.global_position - _to_player().normalized() * 2.0
	_slam_to.y = Game.terrain.get_height(_slam_to.x, _slam_to.z)
	_start_attack()


func _reach() -> float:
	return _attack["reach"] * (2.2 if oblivion else _body)


func _start_attack() -> void:
	state = "attack"
	_state_time = 0.0
	var pace := (0.82 if _enraged else 1.0) * _pace
	_state_length = _attack["length"] * pace
	_did_hit = false
	rig.play(_attack["anim"], _state_length)


func _attacking(delta: float) -> Vector3:
	var t := _state_time / _state_length
	var from: float = _attack["from"]
	var to_player := _to_player()
	if t < from - 0.08:
		_face(to_player, 6.0, delta)

	var result := Vector3.ZERO
	if _attack["anim"] == "slam":
		_move_slam(t)
	else:
		var lunge: float = _attack["lunge"] * (1.0 - smoothstep(from, from + 0.2, t)) * smoothstep(from - 0.2, from, t)
		if to_player.length() < engage_reach * 0.55:
			lunge = 0.0
		result = forward() * lunge

	if not _did_hit and t >= from and t <= _attack["to"]:
		if _attack["anim"] == "slam":
			_land_slam()
		elif _player_in_arc():
			_did_hit = Game.player.take_damage(_attack["damage"] * _power, global_position)
		if is_boss and _attack["anim"] != "slam" and _state_time > 0.0:
			Game.shake(0.05)

	if t >= 1.0:
		rig.position.y = 0.0
		state = "chase"
		_cooldown = randf_range(0.5, 1.4) * (0.55 if _enraged else 1.0)
	return result


func _move_slam(t: float) -> void:
	var from := 0.28
	var to := 0.72
	if t < from or t > to:
		rig.position.y = 0.0
		return
	var f := (t - from) / (to - from)
	var pos := _slam_from.lerp(_slam_to, f)
	global_position.x = pos.x
	global_position.z = pos.z
	rig.position.y = sin(f * PI) * 7.0 * body_scale()


func _land_slam() -> void:
	_did_hit = true
	rig.position.y = 0.0
	var at := global_position
	Fx.ring(at, _reach(), Color(1.0, 0.16, 0.22), 0.4)
	Fx.burst(at + Vector3(0, 0.3, 0), Color(1.0, 0.16, 0.22), 46, 13.0, 0.09)
	Game.shake(0.65)
	if _to_player().length() < _reach():
		Game.player.take_damage(_attack["damage"], at)


func _player_in_arc() -> bool:
	var to := _to_player()
	if to.length() > _reach() + 0.4:
		return false
	return to.length() < 0.8 or rad_to_deg(forward().angle_to(to)) <= _attack["arc"] * 0.5


func take_hit(damage: float, poise: float, from: Vector3, _blockable: bool, tint := Color(0.72, 0.6, 1.0), impact := -1.0) -> void:
	if state == "dead" or state == "rebirth":
		return
	if _waiting_for_intro():
		if Game.player.is_alive():
			Game.cutscene.boss_intro(self)
		return
	if state == "idle":
		_wake()
	if oblivion:
		damage = clampf(damage * OBLIVION_ARMOUR, OBLIVION_MIN_HIT, OBLIVION_MAX_HIT)
		damage = minf(damage, maxf(OBLIVION_MAX_PER_SECOND - _taken_this_second, 0.0))
		_taken_this_second += damage
	last_hit_time = Time.get_ticks_msec() / 1000.0

	var to := from - global_position
	to.y = 0.0
	var at := chest_position()
	# A FIREWALL stops everything from the front until something heavy enough breaks the shield.
	if kind == "firewall" and not is_boss and _shield_down <= 0.0 and rad_to_deg(forward().angle_to(to)) < 75.0:
		if poise < SHIELD_BREAK_POISE:
			Fx.impact(at + to.normalized() * (radius + 0.4), Color(1.0, 0.2, 0.25), 0.2)
			Game.shake(0.08)
			return
		_shield_down = SHIELD_DOWN_TIME
		(rig as SoldierModel).set_shield(false)
		SoldierSkills.pixels(at + to.normalized() * (radius + 0.4), 50, 0.8)
		Fx.ring(global_position, 5.0, Color(1.0, 0.13, 0.2), 0.3)
		Game.shake(0.4)
	var force := impact if impact >= 0.0 else clampf(poise / 70.0, 0.1, 1.0)
	Fx.impact(at + to.normalized() * radius, tint, force)
	# The body takes the blow: shoved back, and flinching unless mid-swing.
	_knock = -to.normalized() * lerpf(2.5, 9.0, force) * (0.2 if is_boss else 1.0 / _body)
	if state == "chase" and not is_boss:
		rig.play("hit", 0.3)
	rig.flash_hit()

	hp -= damage
	_posture += poise
	if hp <= 0.0:
		_die()
		return
	if is_boss and not _enraged and hp < max_hp * 0.5:
		_enraged = true
		Fx.ring(global_position, 11.0, Color(1.0, 0.16, 0.22), 0.7)
		Game.shake(0.4)
	if _posture >= max_posture and _attack.get("anim", "") != "slam":
		_stagger()


## Dragged along by a black hole; ignored mid-leap so a slam still lands where it was aimed.
func pull(force: Vector3) -> void:
	if state != "dead" and state != "rebirth" and not oblivion:
		_knock = force


## Held in place by the supreme form's ERASURE.
func freeze(seconds: float) -> void:
	if state == "dead" or state == "rebirth" or oblivion or _waiting_for_intro():
		return
	_posture = 0.0
	state = "stagger"
	_state_time = 0.0
	_state_length = seconds
	rig.position.y = 0.0
	rig.play("stagger", seconds)


func _stagger() -> void:
	_posture = 0.0
	state = "stagger"
	_state_time = 0.0
	_state_length = 1.15
	rig.position.y = 0.0
	rig.play("stagger", _state_length)


func _die() -> void:
	hp = 0.0
	if is_boss and not oblivion and Game.cutscenes_on:
		# Not dead: this was only the first form.
		state = "rebirth"
		_rebirth_started = false
		Game.boss_active = false
		rig.position.y = 0.0
		rig.play("death", 1.1, true)
		if Game.player.target == self:
			Game.player.target = null
		return
	state = "dead"
	_hide_clock = 0.0
	rig.position.y = 0.0
	rig.play("death", 1.1, true)
	collision_layer = 0
	collision_mask = 0
	Game.add_stardust(reward)
	if is_boss:
		Game.on_boss_defeated()
	if Game.player.target == self:
		Game.player.target = null
