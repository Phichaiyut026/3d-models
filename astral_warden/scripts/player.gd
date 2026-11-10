class_name Player
extends CharacterBody3D
## Third-person controller, stamina combat and the follow camera.

const WALK_SPEED := 3.0
const RUN_SPEED := 6.8
const GUARD_SPEED := 2.2
const ROLL_SPEED := 9.2
const GRAVITY := 24.0
const MOUSE_SENSITIVITY := 0.0026
const START_POINT := Vector3(0, 0.2, 67)
const MAX_FLASKS := 4
const PLAY_RADIUS := 222.0
const SHEATHE_AFTER := 5.0 ## Seconds out of combat before the blade is put away.

const ATTACKS := {
	"light1": {"anim": "cut1", "length": 0.8, "from": 0.36, "to": 0.52, "damage": 34.0, "poise": 16.0, "stamina": 16.0, "lunge": 9.0, "reach": 3.6, "arc": 150.0, "tint": Color(0.62, 0.46, 1.0), "trail": 1.45, "trail_from": 0.33, "impact": 0.7, "stop": 0.085, "kick": 0.15},
	"light2": {"anim": "cut2", "length": 0.68, "from": 0.26, "to": 0.48, "damage": 36.0, "poise": 16.0, "stamina": 16.0, "lunge": 4.5, "reach": 3.4, "arc": 150.0, "tint": Color(0.38, 0.55, 1.0), "trail": 1.0},
	"light3": {"anim": "cut3", "length": 0.9, "from": 0.34, "to": 0.56, "damage": 58.0, "poise": 34.0, "stamina": 22.0, "lunge": 6.0, "reach": 3.8, "arc": 90.0, "tint": Color(0.9, 0.42, 1.0), "trail": 1.25, "wave": 1.57, "wave_width": 5.0, "ground": true},
	"heavy": {"anim": "cleave", "length": 1.3, "from": 0.4, "to": 0.6, "damage": 104.0, "poise": 70.0, "stamina": 34.0, "lunge": 5.0, "reach": 4.1, "arc": 90.0, "tint": Color(1.0, 0.72, 0.95), "trail": 1.5, "wave": -0.85, "wave_width": 7.0, "ground": true},
}
const CHAIN := {"light1": "light2", "light2": "light3", "light3": "light1"}

const TRANSFORM_TIME := 1.9
const REVERT_TIME := 0.9
const TRANSFORM_COOLDOWN := 3.0
const SUPREME_POWER := 12.0
const SUPREME_REACH := 3.2
const SUPREME_ARC := 1.8
const SUPREME_SPEED := 1.7
const SUPREME_FOCUS_REGEN := 90.0
const SUPREME_HP := 999999.0
const SUPREME_DAMAGE_TAKEN := 0.02 ## With the health above, close enough to immortal.
const SUPREME_HP_REGEN := 0.05 ## Share of health restored each second.
const SUPREME_WAVE_RANGE := 40.0
const SUPREME_WAVE_WIDTH := 6.0
## The five powers of the supreme form. `at` is when the blow lands, as a share of `length`.
const SKILLS := {
	"skill_1": {"id": "edge", "name": "ดาบอนันต์", "anim": "edge", "length": 1.8, "at": 0.6, "cost": 20.0, "cooldown": 1.5, "tint": Color(1.0, 0.78, 0.4)},
	"skill_2": {"id": "genesis", "name": "กำเนิดจักรวาล", "anim": "sky_spread", "length": 2.4, "at": 0.14, "cost": 30.0, "cooldown": 4.0, "tint": Color(0.45, 0.6, 1.0)},
	"skill_3": {"id": "multiverse", "name": "พหุจักรวาล", "anim": "sky_spread", "length": 2.3, "at": 0.05, "cost": 40.0, "cooldown": 5.0, "tint": Color(1.0, 0.45, 0.82)},
	"skill_4": {"id": "erasure", "name": "ลบล้าง", "anim": "erasure", "length": 2.2, "at": 0.14, "cost": 50.0, "cooldown": 7.0, "tint": Color(0.82, 0.74, 1.0)},
	"skill_5": {"id": "bigbang", "name": "บิกแบง", "anim": "bigbang", "length": 3.6, "at": 0.62, "cost": 80.0, "cooldown": 10.0, "tint": Color(1.0, 0.94, 0.72)},
}
const SKILL_KEYS := ["skill_1", "skill_2", "skill_3", "skill_4", "skill_5"]
## The first form's powers, on the keys 1 to 7.
const FIRST_SKILLS := {
	"skill_1": {"id": "nova", "name": "โนวา", "anim": "erasure", "length": 1.0, "at": 0.2, "cost": 18.0, "cooldown": 3.0, "tint": Color(0.82, 0.74, 1.0)},
	"skill_2": {"id": "comet", "name": "ดาวหาง", "anim": "comet", "length": 0.85, "at": 0.0, "cost": 22.0, "cooldown": 4.0, "tint": Color(0.66, 0.5, 1.0), "dash": 34.0},
	"skill_3": {"id": "galaxy", "name": "กาแล็กซี", "anim": "sky_spread", "length": 1.9, "at": 0.1, "cost": 30.0, "cooldown": 8.0, "tint": Color(0.45, 0.6, 1.0)},
	"skill_4": {"id": "barrage", "name": "ระดมดาว", "anim": "erasure", "length": 1.75, "at": 0.08, "cost": 26.0, "cooldown": 6.0, "tint": Color(0.72, 0.62, 1.0)},
	"skill_5": {"id": "starfall", "name": "ดาวตก", "anim": "sky_spread", "length": 2.2, "at": 0.12, "cost": 40.0, "cooldown": 12.0, "tint": Color(1.0, 0.82, 0.96)},
	"skill_6": {"id": "hole", "name": "หลุมดำ", "anim": "sky_spread", "length": 2.3, "at": 0.08, "cost": 50.0, "cooldown": 16.0, "tint": Color(0.5, 0.34, 0.9)},
	"skill_7": {"id": "supernova", "name": "ซูเปอร์โนวา", "anim": "bigbang", "length": 2.9, "at": 0.62, "cost": 70.0, "cooldown": 24.0, "tint": Color(0.95, 0.9, 1.0)},
}
const FIRST_FOCUS_REGEN := 5.0
const FLY_SPEED := 18.0
const FLY_FAST_SPEED := 46.0
const FLY_CLIMB := 16.0
const FLY_CEILING := 160.0

var max_hp := 420.0
var max_fp := 140.0
var max_stamina := 150.0
var hp := max_hp
var fp := max_fp
var stamina := max_stamina
var flasks := MAX_FLASKS
var damage_scale := 1.0
var upgrades := 0

var state := "move" ## move, attack, roll, cast, drink, hit, rest, dead, transform, skill
var state_time := 0.0
var state_length := 1.0
var blocking := false
var target: Enemy

var rig: CosmicWarrior
var cam_yaw := 0.0
var cam_pitch := -0.17

var _cam_root: Node3D
var _arm: SpringArm3D
var _camera: Camera3D
var _trail: BladeTrail
var _attack: Dictionary
var _attack_name := ""
var _hit_list: Array[Enemy] = []
var _queued := ""
var _stamina_delay := 0.0
var _roll_dir := Vector3.FORWARD
var _did_event := false
var _knockback := Vector3.ZERO
var _rest_shrine: Shrine
var _input_lock := 0.0
var _wave_fired := false
var _kick_fired := false
var _idle_time := 0.0
var _title_clock := 0.0
var _title_shift := 1.0
var _tick_from := Vector3.ZERO
var _tick_to := Vector3.ZERO
var _after_summon := ""
var _fov_punch := 0.0
var _skill_cooldowns := {}
var _skill_key := ""
var _transform_cooldown := 0.0
var _transform_goal := false
var _cam_height := 2.05
var _first_max_hp := 420.0
var _hp_boosted := false
var flying := false
var _fly_climb := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	floor_max_angle = deg_to_rad(48.0)
	floor_snap_length = 0.5

	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 2.0
	shape.shape = capsule
	shape.position.y = 1.0
	add_child(shape)

	rig = CosmicWarrior.new()
	rig.run_speed = RUN_SPEED
	rig.rotation.y = PI
	add_child(rig)

	_trail = BladeTrail.new()
	_trail.follow(rig.blade_base, rig.blade_tip)
	add_child(_trail)

	_cam_root = Node3D.new()
	_cam_root.top_level = true
	_cam_root.rotation_order = EULER_ORDER_YXZ
	add_child(_cam_root)
	_arm = SpringArm3D.new()
	_arm.spring_length = 5.7
	_arm.margin = 0.25
	_arm.collision_mask = 1
	var probe := SphereShape3D.new()
	probe.radius = 0.2
	_arm.shape = probe
	_cam_root.add_child(_arm)
	_camera = Camera3D.new()
	_camera.fov = 58.0
	_camera.near = 0.08
	_camera.far = 2200.0
	_camera.current = true
	_arm.add_child(_camera)
	Game.camera = _camera
	_cam_root.global_position = global_position + Vector3(0, 2.0, 0)


func reset_camera() -> void:
	_cam_root.global_position = global_position + Vector3(0, 2.05, 0)
	cam_yaw = PI - 0.45 if Game.state == "title" else 0.0


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Game.state != "title":
		add_look(event.relative)


func add_look(relative: Vector2) -> void:
	var rate: float = MOUSE_SENSITIVITY * Game.settings["mouse"]
	if target == null:
		cam_yaw -= relative.x * rate
	var vertical := -relative.y if Game.settings["invert_y"] else relative.y
	cam_pitch = clampf(cam_pitch - vertical * rate, -1.05, 0.38)


func forward() -> Vector3:
	return Vector3(sin(rig.rotation.y), 0, cos(rig.rotation.y))


func chest() -> Vector3:
	return global_position + Vector3(0, 1.3, 0)


func is_alive() -> bool:
	return state != "dead"


func refill() -> void:
	hp = max_hp
	fp = max_fp
	stamina = max_stamina
	flasks = MAX_FLASKS


func respawn(shrine: Shrine) -> void:
	_set_supreme_health(false)
	set_flying(false)
	refill()
	target = null
	global_position = shrine.global_position + Vector3(0, 0.3, -3.5)
	velocity = Vector3.ZERO
	_knockback = Vector3.ZERO
	rig.stop_action()
	rig.set_energy(0.0)
	rig.set_form(false, true)
	rig.set_armed_instant(false)
	_after_summon = ""
	_skill_cooldowns.clear()
	_transform_cooldown = 0.0
	_set_state("move", 0.0)


func new_game() -> void:
	_set_supreme_health(false)
	max_hp = 420.0
	damage_scale = 1.0
	upgrades = 0
	respawn(Game.shrines[0])
	global_position = Vector3(START_POINT.x, Game.terrain.get_height(START_POINT.x, START_POINT.z) + 0.2, START_POINT.z)
	rig.rotation.y = PI
	_title_clock = 0.0
	reset_camera()


func upgrade() -> bool:
	var cost := upgrade_cost()
	if Game.stardust < cost:
		return false
	Game.stardust -= cost
	upgrades += 1
	if _hp_boosted:
		_first_max_hp += 36.0
	else:
		max_hp += 36.0
	damage_scale += 0.08
	refill()
	return true


func upgrade_cost() -> int:
	return 300 + upgrades * 200


func _set_state(new_state: String, length: float) -> void:
	state = new_state
	state_time = 0.0
	state_length = length
	_did_event = false


## The supreme form swaps in its own near-endless health, and gives it back on leaving.
func _set_supreme_health(on: bool) -> void:
	if on == _hp_boosted:
		return
	_hp_boosted = on
	if on:
		_first_max_hp = max_hp
		max_hp = SUPREME_HP
	else:
		max_hp = _first_max_hp
	hp = max_hp


func _spend(amount: float) -> void:
	if rig.is_supreme:
		return
	stamina = maxf(0.0, stamina - amount)
	_stamina_delay = 0.75


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	var horizontal := Vector3.ZERO

	if Game.state == "play" and state != "dead":
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		dir = Vector3(input.x, 0, input.y).rotated(Vector3.UP, cam_yaw)
		_update_lock_on()
		state_time += delta
		_regen(delta)
		_update_sheathe_timer(delta)
		horizontal = _run_state(delta, dir)
	elif state == "dead":
		state_time += delta

	_knockback = _knockback.move_toward(Vector3.ZERO, 24.0 * delta)
	velocity.x = horizontal.x + _knockback.x
	velocity.z = horizontal.z + _knockback.z
	if flying:
		var climb := 0.0
		if Game.state == "play" and state != "dead" and _input_lock <= 0.0:
			climb = (1.0 if Input.is_action_pressed("roll") else 0.0) - (1.0 if Input.is_action_pressed("fly_down") else 0.0)
		_fly_climb = move_toward(_fly_climb, climb * FLY_CLIMB, 70.0 * delta)
		velocity.y = _fly_climb
	elif is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()
	if flying:
		var ceiling := Game.terrain.get_height(global_position.x, global_position.z) + FLY_CEILING
		if global_position.y > ceiling:
			global_position.y = ceiling

	var flat := Vector2(global_position.x, global_position.z)
	if flat.length() > PLAY_RADIUS:
		flat = flat.normalized() * PLAY_RADIUS
		global_position.x = flat.x
		global_position.z = flat.y
	var ground := Game.terrain.get_height(global_position.x, global_position.z)
	if global_position.y < ground - 0.2:
		global_position.y = ground + 0.1
		velocity.y = 0.0

	_tick_from = _tick_to
	_tick_to = global_position
	var walking := not flying and (state == "move" or state == "sheathe" or state == "summon")
	rig.set_motion(horizontal if walking else Vector3.ZERO)
	rig.set_flight(flying, clampf(Vector2(horizontal.x, horizontal.z).length() / FLY_FAST_SPEED * 1.4, 0.0, 1.0))
	_update_blade_effects()


func _regen(delta: float) -> void:
	_input_lock -= delta
	_stamina_delay -= delta
	if _stamina_delay <= 0.0 and state != "roll" and state != "attack":
		var rate := 18.0 if blocking else 48.0
		stamina = minf(max_stamina, stamina + rate * delta)
	fp = minf(max_fp, fp + (SUPREME_FOCUS_REGEN if rig.is_supreme else FIRST_FOCUS_REGEN) * delta)
	if rig.is_supreme:
		hp = minf(max_hp, hp + max_hp * SUPREME_HP_REGEN * delta)
	_transform_cooldown -= delta
	for key: String in _skill_cooldowns:
		_skill_cooldowns[key] = maxf(0.0, _skill_cooldowns[key] - delta)


func _run_state(delta: float, dir: Vector3) -> Vector3:
	match state:
		"move":
			return _state_move(delta, dir)
		"attack":
			return _state_attack(delta, dir)
		"roll":
			_face(_roll_dir, 30.0, delta)
			var fade := 1.0 - smoothstep(0.65, 1.0, state_time / state_length)
			if state_time >= state_length:
				_finish_action()
				return Vector3.ZERO
			return _roll_dir * ROLL_SPEED * fade
		"cast":
			_state_cast(delta)
		"transform":
			_state_transform()
		"skill":
			return _state_skill()
		"summon":
			if target != null:
				_face(target.global_position - global_position, 14.0, delta)
			if state_time >= state_length:
				var next := _after_summon
				_after_summon = ""
				_finish_action()
				if next != "":
					_start_attack(next, dir)
			return dir * GUARD_SPEED
		"sheathe":
			if Input.is_action_just_pressed("fly") and rig.is_supreme:
				set_flying(not flying) # Putting the blade away should not swallow the key.
			if dir.length() > 0.05:
				_face(dir, 11.0, delta)
			if state_time >= state_length:
				_finish_action()
			return dir * WALK_SPEED
		"drink":
			if not _did_event and state_time > state_length * 0.55:
				_did_event = true
				hp = minf(max_hp, hp + max_hp * 0.5)
				Fx.burst(chest(), Color(0.6, 0.85, 1.0), 26, 3.5)
			if state_time >= state_length:
				_finish_action()
			return dir * 1.2
		"hit":
			if state_time >= state_length:
				_finish_action()
		"rest":
			if not _did_event and state_time > 0.9:
				_did_event = true
				Game.rest_at(_rest_shrine)
			if state_time >= state_length:
				rig.stop_action()
				_finish_action()
	return Vector3.ZERO


func _finish_action() -> void:
	collision_mask = 1 | 4
	rig.set_energy(0.0)
	_trail.active = false
	_set_state("move", 0.0)


func _state_move(delta: float, dir: Vector3) -> Vector3:
	blocking = Input.is_action_pressed("block") and stamina > 1.0
	rig.set_block(0.0)
	if blocking:
		rig.set_block(0.55)
	rig.stance["armL"] = Vector3(-0.8, 0, -0.75) if blocking else Vector3.ZERO
	rig.stance["foreL"] = Vector3(-1.45, 0, 0) if blocking else Vector3.ZERO

	if _try_actions(dir):
		return Vector3.ZERO

	if flying:
		if target != null:
			_face(target.global_position - global_position, 14.0, delta)
		elif dir.length() > 0.05:
			_face(dir, 8.0, delta)
		return dir * (FLY_FAST_SPEED if Input.is_action_pressed("run") else FLY_SPEED)

	var running := Input.is_action_pressed("run") and stamina > 2.0 and not blocking and dir.length() > 0.1 and target == null
	var move_speed := GUARD_SPEED if blocking else (RUN_SPEED if running else WALK_SPEED)
	if rig.is_supreme and not blocking:
		move_speed *= SUPREME_SPEED
	if running and not rig.is_supreme:
		stamina = maxf(0.0, stamina - 14.0 * delta)
		_stamina_delay = 0.4
	if target != null:
		_face((target.global_position - global_position), 14.0, delta)
	elif dir.length() > 0.05:
		_face(dir, 11.0, delta)
	return dir * move_speed


func lock_input(seconds: float) -> void:
	_input_lock = seconds


func _try_actions(dir: Vector3) -> bool:
	if _input_lock > 0.0:
		return false
	if Input.is_action_just_pressed("roll") and stamina > 8.0 and not flying:
		_start_roll(dir)
		return true
	if Input.is_action_just_pressed("attack") and stamina > 2.0:
		_attack_or_summon("light1", dir)
		return true
	if Input.is_action_just_pressed("heavy") and stamina > 2.0:
		_attack_or_summon("heavy", dir)
		return true
	if Input.is_action_just_pressed("weapon"):
		if rig.is_armed:
			_start_sheathe()
		else:
			_start_summon("", 0.8)
		return true
	if Input.is_action_just_pressed("bolt") and fp >= 22.0:
		_start_cast()
		return true
	if Input.is_action_just_pressed("transform") and _transform_cooldown <= 0.0:
		_start_transform()
		return true
	if Input.is_action_just_pressed("fly") and rig.is_supreme:
		set_flying(not flying)
		return true
	for key: String in skill_keys():
		if Input.is_action_just_pressed(key) and skill_ready(key):
			_start_skill(key)
			return true
	if Input.is_action_just_pressed("vial") and flasks > 0 and hp < max_hp:
		flasks -= 1
		rig.play("drink", 0.95)
		_set_state("drink", 0.95)
		return true
	var shrine := Game.nearest_shrine(global_position, 3.6)
	if shrine != null:
		if Input.is_action_just_pressed("interact"):
			_rest_shrine = shrine
			rig.set_armed_instant(false)
			rig.play("rest", 2.0)
			_set_state("rest", 2.0)
			return true
		if Input.is_action_just_pressed("upgrade") and upgrade():
			shrine.kindle()
			Game.hud.banner("เสริมพลัง", "พลังชีวิตและความแรงเพิ่มขึ้น", Color(0.72, 0.62, 1.0), 1.6)
	return false


func warm_trail(at: Vector3) -> void:
	_trail.warm(at)


func _attack_or_summon(attack_name: String, dir: Vector3) -> void:
	if rig.is_armed:
		_start_attack(attack_name, dir)
	else:
		_snap_face(dir)
		_start_summon(attack_name, 0.55)


## Drawing straight into a swing is quicker than drawing the blade at leisure.
func _start_summon(then: String, length: float) -> void:
	_after_summon = then
	_idle_time = 0.0
	blocking = false
	rig.set_block(0.0)
	rig.begin_summon(length)
	_set_state("summon", length)


func _start_sheathe() -> void:
	blocking = false
	rig.set_block(0.0)
	rig.begin_sheathe(0.62)
	_set_state("sheathe", 0.62)


func _update_sheathe_timer(delta: float) -> void:
	if not rig.is_armed or state != "move" or blocking:
		_idle_time = 0.0 if state == "attack" else _idle_time
		return
	_idle_time += delta
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.is_engaged() and enemy.global_position.distance_to(global_position) < 22.0:
			_idle_time = 0.0
			return
	if _idle_time >= SHEATHE_AFTER:
		_idle_time = 0.0
		_start_sheathe()


func _start_roll(dir: Vector3) -> void:
	_spend(26.0)
	blocking = false
	rig.set_block(0.0)
	_roll_dir = dir.normalized() if dir.length() > 0.1 else forward()
	collision_mask = 1
	rig.play("roll", 0.6)
	_set_state("roll", 0.6)


func _start_attack(attack_name: String, dir: Vector3) -> void:
	_attack_name = attack_name
	_attack = ATTACKS[attack_name]
	_spend(_attack["stamina"])
	blocking = false
	rig.set_block(0.0)
	_hit_list.clear()
	_queued = ""
	_wave_fired = false
	_kick_fired = false
	_trail.tint = _attack_tint()
	_trail.strength = _attack["trail"]
	_snap_face(dir)
	rig.play(_attack["anim"], _attack["length"])
	_set_state("attack", _attack["length"])


func _snap_face(dir: Vector3) -> void:
	if target != null:
		var to := target.global_position - global_position
		rig.rotation.y = atan2(to.x, to.z)
	elif dir.length() > 0.1:
		rig.rotation.y = atan2(dir.x, dir.z)
	else:
		rig.rotation.y = atan2(-sin(cam_yaw), -cos(cam_yaw))


func _attack_tint() -> Color:
	var tint: Color = _attack["tint"]
	return tint.lerp(Color(1.0, 0.76, 0.34), 0.8) if rig.is_supreme else tint


func skill_keys() -> Array:
	return SKILL_KEYS if rig.is_supreme else FIRST_SKILLS.keys()


func skill_info(key: String) -> Dictionary:
	return SKILLS[key] if rig.is_supreme else FIRST_SKILLS[key]


## Cooldowns follow the power, so changing form cannot reset them.
func skill_cooldown(key: String) -> float:
	return _skill_cooldowns.get(skill_info(key)["id"], 0.0)


func skill_ready(key: String) -> bool:
	return skill_cooldown(key) <= 0.0 and fp >= skill_info(key)["cost"]


func set_flying(on: bool) -> void:
	if on == flying:
		return
	flying = on
	_fly_climb = 0.0
	if on:
		velocity.y = 0.0
		global_position.y += 0.6
		Fx.ring(global_position, 7.0, CosmicFx.GOLD, 0.4)
		Fx.burst(global_position + Vector3(0, 0.3, 0), CosmicFx.GOLD, 26, 9.0)


## The change of form takes a moment, and nothing can touch the warrior during it.
func _start_transform() -> void:
	_transform_goal = not rig.is_supreme
	var length := TRANSFORM_TIME if _transform_goal else REVERT_TIME
	blocking = false
	rig.set_block(0.0)
	_trail.active = false
	rig.set_energy(1.0)
	rig.play("ascend", length)
	_set_state("transform", length)
	Game.shake(0.2)
	Fx.ring(global_position, 5.0, CosmicFx.GOLD if _transform_goal else Color(0.7, 0.55, 1.0), 0.6)


func _state_transform() -> void:
	var t := state_time / state_length
	if not _did_event and t >= 0.62:
		_did_event = true
		rig.set_form(_transform_goal)
		_set_supreme_health(_transform_goal)
		if not _transform_goal:
			set_flying(false)
		if _transform_goal:
			CosmicFx.pillar(global_position, 200.0, 1.3, CosmicFx.GOLD, 16.0)
			CosmicFx.flash(Color(1.0, 0.92, 0.7), 0.9, 0.7)
			Fx.burst(chest(), CosmicFx.GOLD, 60, 16.0, 0.09)
			Fx.ring(global_position, 40.0, CosmicFx.PALE, 0.9)
			Game.shake(1.5)
			# The arrival alone is enough to flatten anything standing close.
			for enemy in Game.enemies:
				if enemy.is_alive() and enemy.global_position.distance_to(global_position) < 30.0:
					enemy.take_hit(3000.0 * damage_scale, 300.0, global_position, false, CosmicFx.GOLD, 1.0)
			Game.hud.banner("ร่างสูงสุด", "COSMIC WARRIOR · SUPREME", CosmicFx.GOLD, 2.4)
		else:
			Fx.burst(chest(), Color(0.7, 0.55, 1.0), 40, 9.0)
			Game.shake(0.3)
	if t >= 1.0:
		_transform_cooldown = TRANSFORM_COOLDOWN
		_finish_action()


func _start_skill(key: String) -> void:
	var skill: Dictionary = skill_info(key)
	fp -= skill["cost"]
	_skill_cooldowns[skill["id"]] = skill["cooldown"]
	_skill_key = key
	_hit_list.clear()
	blocking = false
	rig.set_block(0.0)
	_trail.active = false
	_snap_face(Vector3.ZERO)
	if skill["id"] == "edge" and not rig.is_armed:
		rig.set_armed_instant(true)
		Fx.burst(rig.blade_tip.global_position, CosmicFx.GOLD, 24, 6.0)
	rig.set_energy(1.0)
	rig.play(skill["anim"], skill["length"])
	_set_state("skill", skill["length"])
	Game.hud.banner(skill["name"], "", skill["tint"], 1.3)
	if skill["id"] == "bigbang":
		CosmicSkills.big_bang_charge(self, skill["length"] * skill["at"])
	elif skill["id"] == "supernova":
		CosmicSkills.supernova_charge(self, skill["length"] * skill["at"])


func _state_skill() -> Vector3:
	var skill: Dictionary = skill_info(_skill_key)
	var t := state_time / state_length
	if skill["id"] == "edge":
		rig.set_blade_growth(smoothstep(0.1, 0.42, t) * (1.0 - smoothstep(0.76, 0.97, t)))
		rig.set_blade_power(1.0)
	if not _did_event and t >= skill["at"]:
		_did_event = true
		if not skill.has("dash"):
			CosmicSkills.fire(self, skill["id"])
	var motion := Vector3.ZERO
	if skill.has("dash") and t < 0.92:
		motion = forward() * float(skill["dash"])
		CosmicSkills.comet_tick(self, _hit_list)
	if t >= 1.0:
		rig.set_blade_growth(0.0)
		_finish_action()
	return motion


func _start_cast() -> void:
	fp -= 22.0
	_spend(10.0)
	_snap_face(Vector3.ZERO)
	rig.set_energy(1.0)
	rig.play("cast", 0.72)
	_set_state("cast", 0.72)


func _state_cast(_delta: float) -> void:
	if not _did_event and state_time > state_length * 0.5:
		_did_event = true
		var bolt := StarBolt.new()
		var aim := forward()
		if target != null:
			aim = (target.chest_position() - chest()).normalized()
		bolt.direction = aim
		if rig.is_supreme:
			bolt.tint = CosmicFx.GOLD
			bolt.damage = StarBolt.DAMAGE * SUPREME_POWER
		Game.world.add_child(bolt)
		bolt.global_position = chest() + forward() * 1.1
		Fx.burst(bolt.global_position, Color(0.72, 0.6, 1.0), 12, 4.0)
	if state_time >= state_length:
		_finish_action()


func _state_attack(_delta: float, dir: Vector3) -> Vector3:
	var t := state_time / state_length
	var striking: bool = t >= _attack["from"] and t <= _attack["to"]
	# The ribbon starts once the blade has stopped travelling into its wind-up.
	_trail.active = t >= _attack.get("trail_from", _attack["from"] + 0.06) and t <= _attack["to"] + 0.04
	if not _kick_fired and t >= _attack["from"] and _attack.has("kick"):
		_kick_fired = true
		Game.shake(_attack["kick"])
		_fov_punch = -5.0
	if striking:
		_apply_hits()

	if Input.is_action_just_pressed("attack"):
		_queued = "attack"
	elif Input.is_action_just_pressed("roll"):
		_queued = "roll"

	if t > 0.68 and _queued != "":
		if _queued == "attack" and CHAIN.has(_attack_name) and stamina > 2.0:
			_start_attack(CHAIN[_attack_name], dir)
			return Vector3.ZERO
		if _queued == "roll" and stamina > 8.0 and not flying:
			_trail.active = false
			_start_roll(dir)
			return Vector3.ZERO
	if t >= 1.0:
		_finish_action()
		return Vector3.ZERO

	var from: float = _attack["from"]
	var lunge: float = _attack["lunge"] * (1.0 - smoothstep(from, from + 0.25, t)) * smoothstep(from - 0.2, from, t)
	if target != null and target.global_position.distance_to(global_position) < 2.2:
		lunge = 0.0
	return forward() * lunge


func _apply_hits() -> void:
	var facing := forward()
	for enemy in Game.enemies:
		if not enemy.is_alive() or enemy in _hit_list:
			continue
		var to := enemy.global_position - global_position
		to.y = 0.0
		if to.length() > _attack["reach"] * (SUPREME_REACH if rig.is_supreme else 1.0) + enemy.radius:
			continue
		if to.length() > 0.8 and rad_to_deg(facing.angle_to(to)) > _attack["arc"] * 0.5 * (SUPREME_ARC if rig.is_supreme else 1.0):
			continue
		_hit_list.append(enemy)
		enemy.take_hit(_attack["damage"] * damage_scale * (SUPREME_POWER if rig.is_supreme else 1.0), _attack["poise"], global_position, true, _attack_tint(), _attack.get("impact", -1.0))
		Game.shake(0.16)
		Game.hit_stop(_attack.get("stop", 0.045))


func _update_blade_effects() -> void:
	rig.guarding = blocking
	if state == "skill":
		return
	if state != "attack":
		rig.set_blade_power(0.14 if state == "move" and rig.is_armed else 0.0)
		rig.set_blade_sparks(false)
		_trail.active = false
		return
	var t := state_time / state_length
	var from: float = _attack["from"]
	var to: float = _attack["to"]
	var striking := t >= from and t <= to
	rig.set_blade_power(1.0 if striking else (0.4 if t < from else 0.12))
	rig.set_blade_sparks(striking)
	if not _wave_fired and (_attack.has("wave") or rig.is_supreme) and t >= lerpf(from, to, 0.62):
		_wave_fired = true
		_release_wave()


## The closing blows throw a crescent of light and strike the ground. Purely visual.
func _release_wave() -> void:
	var tint := _attack_tint()
	var ahead := forward()
	var roll: float = _attack.get("wave", 0.6 if _attack_name == "light1" else -0.6)
	var width: float = _attack.get("wave_width", 5.0)
	if rig.is_supreme:
		Fx.crescent(chest() + ahead * 2.0, ahead, roll, tint, width * 3.0, SUPREME_WAVE_RANGE)
		_wave_hits(ahead)
	else:
		Fx.crescent(chest() + ahead * 1.4, ahead, roll, tint, width)
	var at := rig.blade_tip.global_position
	Fx.ground_strike(Vector3(at.x, Game.terrain.get_height(at.x, at.z), at.z), tint)
	Game.shake(0.22)


## Every swing of the supreme form throws its edge far down the line.
func _wave_hits(ahead: Vector3) -> void:
	for enemy in Game.enemies:
		if not enemy.is_alive() or enemy in _hit_list:
			continue
		var to := enemy.global_position - global_position
		to.y = 0.0
		var along := to.dot(ahead)
		if along > 0.0 and along < SUPREME_WAVE_RANGE and (to - ahead * along).length() < SUPREME_WAVE_WIDTH + enemy.radius:
			_hit_list.append(enemy)
			enemy.take_hit(_attack["damage"] * damage_scale * SUPREME_POWER, _attack["poise"], global_position, false, _attack_tint(), 1.0)


func _face(dir: Vector3, rate: float, delta: float) -> void:
	if dir.length() < 0.001:
		return
	rig.rotation.y = lerp_angle(rig.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-rate * delta))


func _update_lock_on() -> void:
	if target != null and (not target.is_alive() or target.global_position.distance_to(global_position) > 34.0):
		target = null
	if Input.is_action_just_pressed("lock_on"):
		target = null if target != null else _find_target()


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_score := INF
	var look := Vector3(-sin(cam_yaw), 0, -cos(cam_yaw))
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var to := enemy.global_position - global_position
		to.y = 0.0
		if to.length() > 30.0:
			continue
		var score := to.length() + rad_to_deg(look.angle_to(to)) * 0.25
		if score < best_score:
			best = enemy
			best_score = score
	return best


func take_damage(amount: float, from: Vector3) -> bool:
	if state == "dead" or Game.state != "play":
		return false
	if state == "roll" and state_time / state_length < 0.78:
		return false
	if state == "transform" or state == "skill":
		return false
	if rig.is_supreme:
		# Blows land on the aura: no flinch, no knockback, nothing interrupted.
		hp = maxf(1.0, hp - amount * SUPREME_DAMAGE_TAKEN)
		Fx.burst(chest() + (from - global_position).normalized() * 1.2, CosmicFx.GOLD, 10, 5.0, 0.05)
		return true

	var to := from - global_position
	to.y = 0.0
	var away := (-to).normalized()
	if blocking and rad_to_deg(forward().angle_to(to)) < 80.0:
		stamina -= amount * 0.75
		_stamina_delay = 1.0
		_knockback = away * 5.0
		Fx.burst(chest() + forward() * 0.9, Color(0.6, 0.5, 1.0), 14, 5.0)
		Game.shake(0.14)
		if stamina > 0.0:
			hp -= amount * 0.12
			return true
		stamina = 0.0
		amount *= 0.6

	blocking = false
	rig.set_block(0.0)
	rig.cancel_draw()
	_after_summon = ""
	hp -= amount
	rig.flash_hit()
	_trail.active = false
	_knockback = away * 8.0
	Game.shake(0.3)
	Fx.burst(chest(), Color(0.75, 0.55, 1.0), 16, 5.0)
	if hp <= 0.0:
		hp = 0.0
		_die()
		return true
	collision_mask = 1 | 4
	rig.play("hit", 0.42)
	_set_state("hit", 0.42)
	return true


func _die() -> void:
	target = null
	collision_mask = 1 | 4
	rig.set_energy(0.0)
	rig.play("death", 1.2, true)
	_set_state("dead", 0.0)
	Game.on_player_died()


func _process(delta: float) -> void:
	if Game.state == "title":
		_title_clock += delta
		cam_yaw = PI - 0.45 + sin(_title_clock * 0.2) * 0.2
		cam_pitch = -0.04
	elif target != null:
		var to := target.global_position - _cam_root.global_position
		var wanted := atan2(-to.x, -to.z)
		cam_yaw = lerp_angle(cam_yaw, wanted, 1.0 - exp(-9.0 * delta))
		cam_pitch = lerpf(cam_pitch, -0.26, 1.0 - exp(-4.0 * delta))

	# Physics runs at a fixed 60 Hz and rendering does not, so the body is drawn between ticks.
	if _tick_from.distance_to(_tick_to) > 1.5:
		_tick_from = _tick_to
	var drawn := _tick_from.lerp(_tick_to, Engine.get_physics_interpolation_fraction())
	rig.position = drawn - global_position
	_cam_height = lerpf(_cam_height, 3.1 if rig.is_supreme else 2.05, 1.0 - exp(-5.0 * delta))
	var anchor := drawn + Vector3(0, _cam_height, 0)
	_cam_root.global_position = _cam_root.global_position.lerp(anchor, 1.0 - exp(-14.0 * delta))
	_cam_root.rotation = Vector3(cam_pitch, cam_yaw, 0)
	var arm_goal := 3.8 if Game.state == "title" else (8.8 if rig.is_supreme else 5.7)
	_arm.spring_length = lerpf(_arm.spring_length, arm_goal, 1.0 - exp(-5.0 * delta))
	# On the menu the warrior stands right of centre, clear of the buttons.
	_title_shift = lerpf(_title_shift, 1.0 if Game.state == "title" else 0.0, 1.0 - exp(-5.0 * delta))

	_fov_punch = lerpf(_fov_punch, 0.0, 1.0 - exp(-7.0 * delta))
	_camera.fov = 58.0 + _fov_punch
	var shake := Game.take_shake(delta)
	_camera.h_offset = randf_range(-shake, shake) * 0.5 - _title_shift * 1.25
	_camera.v_offset = randf_range(-shake, shake) * 0.5
