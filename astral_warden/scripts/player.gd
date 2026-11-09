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

var max_hp := 420.0
var max_fp := 140.0
var max_stamina := 150.0
var hp := max_hp
var fp := max_fp
var stamina := max_stamina
var flasks := MAX_FLASKS
var damage_scale := 1.0
var upgrades := 0

var state := "move" ## move, attack, roll, cast, drink, hit, rest, dead
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
	refill()
	target = null
	global_position = shrine.global_position + Vector3(0, 0.3, -3.5)
	velocity = Vector3.ZERO
	_knockback = Vector3.ZERO
	rig.stop_action()
	rig.set_energy(0.0)
	rig.set_armed_instant(false)
	_after_summon = ""
	_set_state("move", 0.0)


func new_game() -> void:
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


func _spend(amount: float) -> void:
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
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

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
	rig.set_motion(horizontal if state == "move" or state == "sheathe" or state == "summon" else Vector3.ZERO)
	_update_blade_effects()


func _regen(delta: float) -> void:
	_input_lock -= delta
	_stamina_delay -= delta
	if _stamina_delay <= 0.0 and state != "roll" and state != "attack":
		var rate := 18.0 if blocking else 48.0
		stamina = minf(max_stamina, stamina + rate * delta)
	fp = minf(max_fp, fp + 1.2 * delta)


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

	var running := Input.is_action_pressed("run") and stamina > 2.0 and not blocking and dir.length() > 0.1 and target == null
	var move_speed := GUARD_SPEED if blocking else (RUN_SPEED if running else WALK_SPEED)
	if running:
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
	if Input.is_action_just_pressed("roll") and stamina > 8.0:
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
	_trail.tint = _attack["tint"]
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
		if _queued == "roll" and stamina > 8.0:
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
		if to.length() > _attack["reach"] + enemy.radius:
			continue
		if to.length() > 0.8 and rad_to_deg(facing.angle_to(to)) > _attack["arc"] * 0.5:
			continue
		_hit_list.append(enemy)
		enemy.take_hit(_attack["damage"] * damage_scale, _attack["poise"], global_position, true, _attack["tint"], _attack.get("impact", -1.0))
		Game.shake(0.16)
		Game.hit_stop(_attack.get("stop", 0.045))


func _update_blade_effects() -> void:
	rig.guarding = blocking
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
	if not _wave_fired and _attack.has("wave") and t >= lerpf(from, to, 0.62):
		_wave_fired = true
		_release_wave()


## The closing blows throw a crescent of light and strike the ground. Purely visual.
func _release_wave() -> void:
	var tint: Color = _attack["tint"]
	var ahead := forward()
	Fx.crescent(chest() + ahead * 1.4, ahead, _attack["wave"], tint, _attack["wave_width"])
	var at := rig.blade_tip.global_position
	Fx.ground_strike(Vector3(at.x, Game.terrain.get_height(at.x, at.z), at.z), tint)
	Game.shake(0.22)


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
	var anchor := drawn + Vector3(0, 2.05, 0)
	_cam_root.global_position = _cam_root.global_position.lerp(anchor, 1.0 - exp(-14.0 * delta))
	_cam_root.rotation = Vector3(cam_pitch, cam_yaw, 0)
	_arm.spring_length = lerpf(_arm.spring_length, 3.8 if Game.state == "title" else 5.7, 1.0 - exp(-5.0 * delta))
	# On the menu the warrior stands right of centre, clear of the buttons.
	_title_shift = lerpf(_title_shift, 1.0 if Game.state == "title" else 0.0, 1.0 - exp(-5.0 * delta))

	_fov_punch = lerpf(_fov_punch, 0.0, 1.0 - exp(-7.0 * delta))
	_camera.fov = 58.0 + _fov_punch
	var shake := Game.take_shake(delta)
	_camera.h_offset = randf_range(-shake, shake) * 0.5 - _title_shift * 1.25
	_camera.v_offset = randf_range(-shake, shake) * 0.5
