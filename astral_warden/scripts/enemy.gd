class_name Enemy
extends CharacterBody3D
## Valley soldiers and the tower's warden share this state machine.

const GRAVITY := 24.0

const SOLDIER_ATTACKS := [
	{"anim": "slash1", "length": 1.3, "from": 0.42, "to": 0.58, "damage": 62.0, "reach": 3.0, "arc": 130.0, "lunge": 4.5},
	{"anim": "slash3", "length": 1.55, "from": 0.48, "to": 0.62, "damage": 88.0, "reach": 3.1, "arc": 80.0, "lunge": 5.5},
]
const BOSS_ATTACKS := [
	{"anim": "slash1", "length": 1.45, "from": 0.42, "to": 0.58, "damage": 104.0, "reach": 6.0, "arc": 170.0, "lunge": 6.5},
	{"anim": "slash2", "length": 1.15, "from": 0.4, "to": 0.58, "damage": 96.0, "reach": 6.0, "arc": 170.0, "lunge": 6.5},
	{"anim": "slash3", "length": 1.75, "from": 0.5, "to": 0.62, "damage": 150.0, "reach": 6.6, "arc": 70.0, "lunge": 8.0},
	{"anim": "slam", "length": 1.9, "from": 0.72, "to": 0.78, "damage": 135.0, "reach": 7.5, "arc": 360.0, "lunge": 0.0},
]

var is_boss := false
var max_hp := 150.0
var hp := max_hp
var radius := 0.55
var reward := 140
var move_speed := 3.9
var engage_reach := 2.5
var max_posture := 55.0
var state := "idle" ## idle, chase, attack, stagger, dead
var last_hit_time := -100.0

var rig: SentinelModel
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


func setup(pos: Vector3, boss: bool) -> Enemy:
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
	capsule.radius = 1.05 if is_boss else 0.42
	capsule.height = 4.0 if is_boss else 2.0
	shape.shape = capsule
	shape.position.y = capsule.height * 0.5
	add_child(shape)

	rig = SentinelModel.new(is_boss)
	rig.run_speed = move_speed
	if is_boss:
		rig.scale = Vector3.ONE * 2.05
	rig.rotation.y = randf() * TAU
	add_child(rig)


func is_alive() -> bool:
	return state != "dead"


func forward() -> Vector3:
	return Vector3(sin(rig.rotation.y), 0, cos(rig.rotation.y))


func chest_position() -> Vector3:
	return global_position + Vector3(0, 2.6 if is_boss else 1.3, 0)


func head_position() -> Vector3:
	return global_position + Vector3(0, 4.9 if is_boss else 2.35, 0)


func is_engaged() -> bool:
	return state == "chase" or state == "attack" or state == "stagger"


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


func _physics_process(delta: float) -> void:
	if Game.terrain == null:
		return
	_state_time += delta
	_cooldown -= delta
	var horizontal := Vector3.ZERO
	if Game.state == "play" or state == "attack":
		match state:
			"idle":
				horizontal = _idle(delta)
			"chase":
				horizontal = _chase(delta)
			"attack":
				horizontal = _attacking(delta)
			"stagger":
				if _state_time >= _state_length:
					state = "chase"
					_posture = 0.0
	if state == "dead":
		_hide_clock += delta
		if _hide_clock > 3.5 and visible:
			Fx.burst(chest_position() - Vector3(0, 1, 0), Color(1.0, 0.8, 0.35), 30, 4.0)
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
	if Game.player.is_alive() and Game.state == "play":
		if is_boss:
			if Vector2(Game.player.global_position.x - home.x, Game.player.global_position.z - home.z).length() < 27.0:
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


func _wake() -> void:
	state = "chase"
	_cooldown = 0.5
	if is_boss:
		Game.boss = self
		Game.boss_active = true


func _chase(delta: float) -> Vector3:
	if not Game.player.is_alive():
		state = "idle"
		return Vector3.ZERO
	var to := _to_player()
	var distance := to.length()
	if not is_boss and home.distance_to(global_position) > 60.0:
		state = "idle"
		global_position = home
		hp = max_hp
		return Vector3.ZERO
	_face(to, 9.0, delta)
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


func _start_attack() -> void:
	state = "attack"
	_state_time = 0.0
	var pace := 0.82 if _enraged else 1.0
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
			_did_hit = Game.player.take_damage(_attack["damage"], global_position)
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
	rig.position.y = sin(f * PI) * 7.0


func _land_slam() -> void:
	_did_hit = true
	rig.position.y = 0.0
	var at := global_position
	Fx.ring(at, _attack["reach"], Color(1.0, 0.75, 0.3), 0.4)
	Fx.burst(at + Vector3(0, 0.3, 0), Color(1.0, 0.75, 0.3), 46, 13.0, 0.09)
	Game.shake(0.65)
	if _to_player().length() < _attack["reach"]:
		Game.player.take_damage(_attack["damage"], at)


func _player_in_arc() -> bool:
	var to := _to_player()
	if to.length() > _attack["reach"] + 0.4:
		return false
	return to.length() < 0.8 or rad_to_deg(forward().angle_to(to)) <= _attack["arc"] * 0.5


func take_hit(damage: float, poise: float, from: Vector3, blockable: bool, tint := Color(0.72, 0.6, 1.0), impact := -1.0) -> void:
	if state == "dead":
		return
	if state == "idle":
		_wake()
	last_hit_time = Time.get_ticks_msec() / 1000.0

	var to := from - global_position
	to.y = 0.0
	var at := chest_position()
	# Soldiers catch frontal swings on the shield unless they are mid-attack.
	var guarded := blockable and not is_boss and state == "chase" and rad_to_deg(forward().angle_to(to)) < 65.0 and randf() < 0.38
	if guarded:
		damage *= 0.25
		poise *= 0.45
		Fx.impact(at + to.normalized() * (radius + 0.3), Color(1.0, 0.78, 0.35), 0.15)
	else:
		var force := impact if impact >= 0.0 else clampf(poise / 70.0, 0.1, 1.0)
		Fx.impact(at + to.normalized() * radius, tint, force)
		# The body takes the blow: shoved back, and flinching unless mid-swing.
		_knock = -to.normalized() * lerpf(2.5, 9.0, force) * (0.2 if is_boss else 1.0)
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
		Fx.ring(global_position, 11.0, Color(1.0, 0.5, 0.2), 0.7)
		Game.shake(0.4)
	if _posture >= max_posture and _attack.get("anim", "") != "slam":
		_stagger()


func _stagger() -> void:
	_posture = 0.0
	state = "stagger"
	_state_time = 0.0
	_state_length = 1.15
	rig.position.y = 0.0
	rig.play("stagger", _state_length)


func _die() -> void:
	hp = 0.0
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
