extends Node
## End-to-end smoke test: godot --path . -- --autotest --shots=/some/dir
## Drives the real input actions, saves screenshots and prints PASS/FAIL lines.

var _dir := ""
var _failures := 0


func _ready() -> void:
	get_window().unfocusable = true # Keeps real keystrokes out of the scripted run.
	get_window().mouse_passthrough = true # And real clicks: they would start swings mid-test.
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_dir = arg.substr(8)
	_run()


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		var pl := Game.player
		print("  state=%s attack=%s t=%.2f hp=%.0f stamina=%.0f pos=%s game=%s lock=%.2f" % [pl.state, pl._attack_name, pl.state_time, pl.hp, pl.stamina, pl.global_position, Game.state, pl._input_lock])
	if not ok:
		_failures += 1


## Loading covers the menu, so a click sent any earlier never reaches the buttons.
func _wait_loaded() -> void:
	await _wait(1.0)
	while Game.warming:
		await get_tree().process_frame
	await _wait(2.0)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	if _dir != "":
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_dir, shot_name])


## Waits for a given moment of an attack, re-pressing the button to keep a combo going.
func _shot_at(attack: String, progress: float, shot_name: String, chain := false) -> void:
	var frames := 0
	while frames < 400:
		frames += 1
		await get_tree().process_frame
		var p := Game.player
		if chain and Engine.get_process_frames() % 4 == 0:
			Input.action_release("attack")
			await get_tree().physics_frame
			Input.action_press("attack")
		if p.state == "attack" and p._attack_name == attack and p.state_time / p.state_length >= progress:
			await _shot(shot_name)
			return
	_check("reached " + attack, false)


func _tap(action: String) -> void:
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)


func _place_near(enemy: Enemy, distance: float) -> void:
	var p := Game.player
	var offset := Vector3(0, 0, distance)
	var at := enemy.global_position + offset
	at.y = Game.terrain.get_height(at.x, at.z) + 0.2
	p.global_position = at
	p.velocity = Vector3.ZERO
	p.cam_yaw = 0.0
	p.rig.rotation.y = PI
	p._cam_root.global_position = at + Vector3(0, 2.05, 0)


func _shot_summon(p: Player, progress: float, shot_name: String) -> void:
	var frames := 0
	while frames < 300 and not (p.rig._draw_mode != "" and p.rig._draw_time / p.rig._draw_length >= progress):
		frames += 1
		await get_tree().process_frame
	await _shot(shot_name)


## Reads the real joints in the running game, so a pose bypassed by gameplay state shows up.
func _check_run_arms(p: Player, label: String, mirrored: bool) -> void:
	var worst := 0.0
	var rights: Array[float] = []
	for i in 40:
		await get_tree().process_frame
		var left: Vector3 = p.rig.joints["armL"].rotation
		var right: Vector3 = p.rig.joints["armR"].rotation
		worst = maxf(worst, absf(left.x + right.x))
		rights.append(right.x)
	rights.sort()
	var travel := rights[-1] - rights[0]
	print("ARMS %s: right arm x %.2f..%.2f, mirror error %.2f" % [label, rights[0], rights[-1], worst])
	if mirrored:
		_check("right arm mirrors left when " + label, worst < 0.2 and travel > 0.8)
	else:
		_check("blade arm stays behind when " + label, rights[0] > 0.5 and travel < 0.6)


func _click_button(button: Button) -> void:
	var was := Game.autotest
	Game.autotest = false
	var at := button.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		click.global_position = at
		Input.parse_input_event(click)
		await get_tree().process_frame
		await get_tree().process_frame
	Game.autotest = was


func _press_escape() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	await get_tree().process_frame
	await get_tree().process_frame


func _test_menus(p: Player) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _press_escape()
	_check("Esc opens the pause menu", get_tree().paused and Game.menu.current_screen() == "pause")
	await _shot("menu_pause")
	Game.menu._open("controls", "pause")
	await get_tree().create_timer(0.3).timeout
	await _shot("menu_controls")
	await _press_escape()
	_check("Esc steps back to pause", Game.menu.current_screen() == "pause")
	Game.menu._open("settings", "pause")
	await get_tree().create_timer(0.3).timeout
	await _shot("menu_settings")
	(Game.menu.settings_widgets["render"] as HSlider).value = 0.7
	_check("render slider applies", is_equal_approx(get_viewport().scaling_3d_scale, 0.7))
	(Game.menu.settings_widgets["render"] as HSlider).value = 0.8
	(Game.menu.settings_widgets["invert_y"] as Button).pressed.emit()
	_check("toggle changes its setting", Game.settings["invert_y"] == true)
	(Game.menu.settings_widgets["invert_y"] as Button).pressed.emit()
	(Game.menu.settings_widgets["quality"] as Button).pressed.emit()
	_check("quality cycles", Game.settings["quality"] == 2)
	Game.set_setting("quality", 1)
	await _press_escape()
	await get_tree().create_timer(0.3).timeout
	await _click_button(Game.menu.resume_button)
	_check("resume button unpauses", not get_tree().paused and Game.menu.current_screen() == "")
	await get_tree().physics_frame
	_check("resume click does not swing", p.state == "move")

	Game.add_stardust(10)
	p.upgrades = 3
	p.max_hp = 500.0
	Game.boss_defeated = true
	await _press_escape()
	Game.return_to_title()
	await _wait(0.6)
	_check("back at the main menu", Game.state == "title" and Game.menu.current_screen() == "main")
	_check("a new run starts clean", Game.stardust == 0 and p.upgrades == 0 and p.max_hp == 420.0 and p.hp == 420.0 and not Game.boss_defeated)
	_check("boss is back", Game.boss.is_alive())
	await _wait(1.0)
	await _shot("menu_title_again")
	await _click_button(Game.menu.start_button)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_check("can start again", Game.state == "play" and not get_tree().paused)


func _test_blade_summon(p: Player) -> void:
	# Far from every soldier, so nothing keeps the player in combat.
	await _wait(6.5) # Lets the victory banner clear before the close-ups.
	p.hp = p.max_hp
	p.global_position = Vector3(0, Game.terrain.get_height(0, 88) + 0.3, 88)
	p.velocity = Vector3.ZERO
	p.rig.rotation.y = 0.0
	p.cam_yaw = 0.45
	p._cam_root.global_position = p.global_position + Vector3(0, 2.05, 0)
	p.rig.set_armed_instant(false)
	p.stamina = p.max_stamina
	await _wait(0.5)
	await _shot("wing_idle")
	_check("starts sheathed here", not p.rig.is_armed and not p.rig._holder.visible)

	await _tap("weapon")
	_check("X starts the summon", p.state == "summon")
	await _shot_summon(p, 0.3, "summon_1_reach")
	await _shot_summon(p, 0.5, "summon_2_grip")
	await _shot_summon(p, 0.62, "summon_3_pull")
	await _shot_summon(p, 0.78, "summon_4_out")
	await _wait(0.6)
	_check("blade fully out after summon", p.rig.is_armed and p.rig._holder.visible and p.rig._reveal > 100.0 and p.state == "move")

	await _tap("weapon")
	_check("X starts putting it away", p.state == "sheathe")
	await _shot_summon(p, 0.5, "sheathe_1")
	await _wait(0.7)
	_check("blade gone after sheathe", not p.rig.is_armed and not p.rig._holder.visible)

	await _tap("attack")
	_check("attacking empty-handed summons first", p.state == "summon")
	await _wait(0.7)
	_check("summon flows into the attack", p.state == "attack" and p._attack_name == "light1")
	await _wait(1.0)

	p._idle_time = Player.SHEATHE_AFTER - 0.2
	await _wait(0.45)
	_check("blade put away when idle", p.state == "sheathe" or not p.rig.is_armed)
	await _wait(0.8)
	_check("blade gone after idling", not p.rig.is_armed)

	p.rig.set_armed_instant(false)
	await _tap("weapon")
	await _wait(0.15)
	p.take_damage(5.0, p.global_position + Vector3(0, 0, 3))
	_check("a hit cancels the summon cleanly", not p.rig.is_drawing() and not p.rig.is_armed)
	await _wait(0.6)

	p.cam_yaw = 0.0
	p.rig.rotation.y = PI
	Input.action_press("move_forward")
	Input.action_press("run")
	await _wait(1.3)
	await _shot("wing_run")
	await _check_run_arms(p, "unarmed", true)
	p.cam_yaw = -PI * 0.5
	await _wait(0.5)
	await _shot("run_side_unarmed")
	Input.action_release("run")
	Input.action_release("move_forward")

	p.global_position = Vector3(0, Game.terrain.get_height(0, 88) + 0.3, 88)
	p.cam_yaw = 0.0
	await _wait(0.3)
	await _tap("weapon")
	await _wait(1.0)
	Input.action_press("move_forward")
	Input.action_press("run")
	await _wait(1.2)
	await _shot("run_back_armed")
	await _check_run_arms(p, "armed", false)
	p.cam_yaw = -PI * 0.5
	await _wait(0.5)
	await _shot("run_side_armed")
	Input.action_release("run")
	Input.action_release("move_forward")


## Frame pacing report: godot --path . -- --autotest --bench
func _measure(label: String, seconds: float) -> void:
	var samples: Array[float] = []
	var left := seconds
	while left > 0.0:
		await get_tree().process_frame
		if Engine.time_scale < 1.0: # The deliberate hit-stop freeze is not a stutter.
			continue
		var d := get_process_delta_time()
		left -= d
		samples.append(d * 1000.0)
		var compiled := _pipelines()
		if d > 0.1:
			print("BENCH hitch %.0f ms in %s: pipelines %d -> %d, state=%s, frame_process=%.1f ms" % [d * 1000.0, label, last_pipelines, compiled, Game.player.state, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
		last_pipelines = compiled
	samples.sort()
	var total := 0.0
	var late := 0
	for v in samples:
		total += v
		if v > 25.0:
			late += 1
	print("BENCH %-16s fps %5.1f  p50 %5.1f  p95 %5.1f  p99 %5.1f  max %6.1f ms  over25ms %d/%d" % [label, 1000.0 * samples.size() / total, samples[samples.size() / 2], samples[int(samples.size() * 0.95)], samples[int(samples.size() * 0.99)], samples[-1], late, samples.size()])


var last_pipelines := 0


func _pipelines() -> int:
	return int(Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SURFACE) + Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW) + Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SPECIALIZATION) + Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_MESH))


func _bench() -> void:
	var p := Game.player
	await _wait(2.0)
	Game.start_game()
	await _wait(1.0)
	print("BENCH info vsync=%d physics=%d interp=%s size=%s" % [DisplayServer.window_get_vsync_mode(), Engine.physics_ticks_per_second, get_tree().physics_interpolation, get_window().size])
	await _measure("idle meadow", 4.0)
	Input.action_press("move_forward")
	Input.action_press("run")
	await _measure("run meadow", 5.0)
	Input.action_release("run")
	Input.action_release("move_forward")
	p.cam_yaw = 1.6
	await _measure("idle sideways", 3.0)
	await _tap("weapon")
	await _measure("first summon", 1.2)
	await _tap("attack")
	await _measure("first attack", 1.0)
	await _tap("heavy")
	await _measure("first heavy", 1.6)
	await _tap("roll")
	await _measure("roll", 1.0)
	await _tap("bolt")
	await _measure("first bolt", 1.5)
	print("BENCH objects %d  draw calls %d  primitives %d" % [Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	print("BENCH DONE")
	get_tree().quit()


func _park_front(p: Player, at: Vector3) -> void:
	p.global_position = Vector3(at.x, Game.terrain.get_height(at.x, at.z) + 0.3, at.z)
	p.velocity = Vector3.ZERO
	p.rig.rotation.y = 0.0
	p.cam_yaw = 0.35
	p.cam_pitch = -0.1
	p._cam_root.global_position = p.global_position + Vector3(0, 2.05, 0)


func _wait_skill(p: Player, key: String, progress: float, shot_name: String) -> void:
	var frames := 0
	while frames < 600 and not (p.state == "skill" and p._skill_key == key and p.state_time / p.state_length >= progress):
		frames += 1
		await get_tree().process_frame
	await _shot(shot_name)


func _wait_move(p: Player) -> void:
	var frames := 0
	while frames < 900 and p.state != "move":
		frames += 1
		await get_tree().process_frame


## The first form's seven powers, all aimed at one soldier standing ahead.
func _test_first_skills(p: Player) -> void:
	var soldier: Enemy = null
	for enemy in Game.enemies:
		if not enemy.is_boss:
			soldier = enemy
			break
	for key: String in Player.FIRST_SKILLS:
		var skill: Dictionary = Player.FIRST_SKILLS[key]
		p.fp = p.max_fp
		p._skill_cooldowns.clear()
		_park_front(p, Vector3(0, 0, 88))
		var look := Vector3(-sin(p.cam_yaw), 0, -cos(p.cam_yaw))
		soldier.reset()
		soldier.hp = 99999.0
		soldier.freeze(40.0)
		soldier.global_position = p.global_position + look * 9.0
		soldier.global_position.y = Game.terrain.get_height(soldier.global_position.x, soldier.global_position.z) + 0.2
		await _wait(0.35)
		await _tap(key)
		await _wait(0.05)
		_check("first form " + skill["id"] + " starts", p.state == "skill" and p._skill_key == key)
		_check("first form " + skill["id"] + " spends focus", p.fp < p.max_fp)
		await _wait_skill(p, key, 0.55, "first_%s" % skill["id"])
		await _wait_move(p)
		await _wait(1.0)
		_check("first form " + skill["id"] + " damages enemies", soldier.hp < 99999.0)
	soldier.reset()
	p._skill_cooldowns.clear()
	p.fp = p.max_fp


func _test_flight(p: Player) -> void:
	_park_front(p, Vector3(0, 0, 88))
	await _wait(0.5)
	var ground_y := p.global_position.y
	await _tap("fly")
	await get_tree().physics_frame
	_check("V takes off", p.flying)
	Input.action_press("roll")
	await _wait(1.0)
	Input.action_release("roll")
	_check("Space climbs", p.global_position.y > ground_y + 8.0)
	await _wait(0.2)
	var height := p.global_position.y
	await _wait(0.8)
	_check("holds its height in the air", absf(p.global_position.y - height) < 0.4)
	await _shot("fly_hover")
	var from := p.global_position
	Input.action_press("move_forward")
	Input.action_press("run")
	await _wait(1.2)
	await _shot("fly_fast")
	Input.action_release("run")
	Input.action_release("move_forward")
	_check("flies forward quickly", from.distance_to(p.global_position) > 25.0)
	await _tap("fly")
	await get_tree().physics_frame
	_check("V comes back down", not p.flying)
	await _wait(2.6)
	_check("lands on the ground", p.is_on_floor())
	Input.action_press("move_forward")
	await _wait(0.8)
	Input.action_release("move_forward")
	await _shot("walk_supreme")
	_check("still walks on the ground", p.is_on_floor() and not p.flying)


func _test_supreme(p: Player) -> void:
	Game.player.hp = p.max_hp
	_park_front(p, Vector3(0, 0, 88))
	await _wait(0.8)
	await _shot("form_1_first")
	_check("starts in the first form", not p.rig.is_supreme and p.rig.scale.x < 1.01)
	await _test_first_skills(p)
	_park_front(p, Vector3(0, 0, 88))
	await _wait(0.4)

	await _tap("transform")
	_check("T starts the change", p.state == "transform")
	_check("nothing hurts during the change", not p.take_damage(50.0, p.global_position + Vector3(0, 0, 3)))
	await _wait(0.9)
	await _shot("form_2_gather")
	await _wait(0.4)
	await _shot("form_3_burst")
	await _wait(1.0)
	_check("becomes the supreme form", p.rig.is_supreme and p.state == "move")
	await _wait(1.8)
	_park_front(p, Vector3(0, 0, 88))
	await _wait(1.0)
	await _shot("form_4_supreme")
	_check("the supreme form is larger", p.rig.scale.x > 1.8)
	_check("the supreme form is all but immortal", p.max_hp >= Player.SUPREME_HP and p.hp >= p.max_hp * 0.99)
	var tough_hp := p.hp
	p.take_damage(150.0, p.global_position + Vector3(0, 0, 3))
	_check("big hits barely register", tough_hp - p.hp <= 3.5)
	_check("the supreme form does not flinch", p.state == "move" and p._knockback.length() < 0.01)
	await _wait(0.6)
	_park_front(p, Vector3(0, 0, 88))
	p.cam_yaw = PI
	await _wait(0.5)
	await _shot("form_5_back")
	p.cam_yaw = 0.35

	await _test_flight(p)
	_park_front(p, Vector3(0, 0, 88))
	await _wait(0.5)

	# Soldiers lined up in front, so each power has something to hit.
	var soldiers: Array[Enemy] = []
	for enemy in Game.enemies:
		if not enemy.is_boss and soldiers.size() < 3:
			soldiers.append(enemy)
	var place := func(dist: float) -> void:
		var i := 0
		for s in soldiers:
			s.reset()
			s.hp = 99999.0
			s.freeze(40.0)
			# Skills fire where the camera looks.
			var look := Vector3(-sin(p.cam_yaw), 0, -cos(p.cam_yaw))
			s.global_position = p.global_position + look * (dist + i * 1.5) + look.cross(Vector3.UP) * (i - 1) * 2.0
			s.global_position.y = Game.terrain.get_height(s.global_position.x, s.global_position.z) + 0.2
			i += 1

	for key: String in Player.SKILL_KEYS:
		p.fp = p.max_fp
		p._skill_cooldowns.clear()
		_park_front(p, Vector3(0, 0, 88))
		place.call(11.0)
		await _wait(0.4)
		var hp_before := soldiers[1].hp
		var skill: Dictionary = Player.SKILLS[key]
		await _tap(key)
		await _wait(0.05)
		_check(skill["id"] + " starts", p.state == "skill" and p._skill_key == key)
		_check(skill["id"] + " spends focus", p.fp < p.max_fp)
		_check(skill["id"] + " goes on cooldown", p.skill_cooldown(key) > 0.0 and not p.skill_ready(key))
		_check(skill["id"] + " cannot be hurt", not p.take_damage(50.0, p.global_position + Vector3(0, 0, 3)))
		await _wait_skill(p, key, minf(float(skill["at"]) + 0.08, 0.5) if skill["id"] != "bigbang" else 0.5, "skill_%s_1" % skill["id"])
		if skill["id"] == "edge":
			p.cam_yaw = 1.35 # The cut runs straight away from the usual camera; this shows its length.
		var late := {"edge": 0.72, "genesis": 0.62, "multiverse": 0.45, "erasure": 0.5, "bigbang": 0.68}
		await _wait_skill(p, key, late[skill["id"]], "skill_%s_2" % skill["id"])
		await _wait_move(p)
		await _wait(0.9)
		_check(skill["id"] + " damages enemies", soldiers[1].hp < hp_before)
	for s in soldiers:
		s.reset()

	await _shot("form_6_hud")
	p._transform_cooldown = 0.0
	await _tap("transform")
	_check("T starts the way back", p.state == "transform")
	await _wait(1.3)
	_check("returns to the first form", not p.rig.is_supreme and p.state == "move")
	_check("health returns to normal", p.max_hp < 1000.0 and p.hp == p.max_hp)
	await _wait(1.0)
	_check("back to normal size", p.rig.scale.x < 1.05)
	await _shot("form_7_returned")
	p.rig.set_form(true, true)
	p.respawn(Game.shrines[0])
	_check("dying or respawning clears the form", not p.rig.is_supreme)


func _wait_scene_end(scene: Cutscene) -> void:
	var frames := 0
	while scene.is_playing() and frames < 3000:
		frames += 1
		await get_tree().process_frame


func _test_cutscenes(p: Player) -> void:
	Game.cutscenes_on = true
	var scene: Cutscene = Game.cutscene
	var boss: Enemy = Game.boss
	var soldier: Enemy = null
	for enemy in Game.enemies:
		if not enemy.is_boss:
			soldier = enemy
			break

	# The change of form, watched to the end.
	_park_front(p, Vector3(0, 0, 88))
	await _wait(0.5)
	await _tap("transform")
	_check("T opens the scene", scene.is_playing() and Game.state == "cutscene")
	_check("the form waits for the scene", not p.rig.is_supreme)
	_check("everyone else stops", soldier.process_mode == Node.PROCESS_MODE_DISABLED)
	_check("nothing hurts during the scene", not p.take_damage(50.0, p.global_position + Vector3(0, 0, 3)))
	await _wait(0.9)
	await _shot("scene_form_1")
	await _wait(1.2)
	await _shot("scene_form_2")
	await _wait(1.3)
	await _shot("scene_form_3")
	await _wait(0.95)
	await _shot("scene_form_4_reveal")
	await _wait(1.4)
	await _shot("scene_form_5_hero")
	await _wait_scene_end(scene)
	_check("the scene ends in the supreme form", p.rig.is_supreme and p.state == "move" and Game.state == "play")
	_check("the view is handed back", p.view_camera().current and Game.camera == p.view_camera())
	_check("everyone moves again", soldier.process_mode == Node.PROCESS_MODE_INHERIT)

	p._transform_cooldown = 0.0
	await _tap("transform")
	_check("going back needs no scene", not scene.is_playing() and p.state == "transform")
	await _wait(1.3)
	_check("back in the first form", not p.rig.is_supreme and p.state == "move")

	# Skipping still changes the form.
	p._transform_cooldown = 0.0
	await _wait(0.4)
	await _tap("transform")
	await _wait(0.5)
	await _tap("cutscene_skip")
	await get_tree().process_frame
	_check("Tab skips the scene", not scene.is_playing() and Game.state == "play")
	_check("a skipped scene still changes the form", p.rig.is_supreme and p.state == "move")
	await _wait(0.5)
	p._transform_cooldown = 0.0
	await _tap("transform")
	await _wait(1.3)
	_check("first form again", not p.rig.is_supreme)

	# The boss talks first, and only then fights.
	Game.boss_intro_seen = false
	boss.reset()
	p.refill()
	p.global_position = boss.home + Vector3(0, 0.3, 24)
	await _wait(0.5)
	_check("the boss opens with a scene", scene.is_playing() and Game.state == "cutscene")
	_check("the fight has not started", not Game.boss_active and boss.state == "idle")
	var boss_hp := boss.hp
	boss.take_hit(9999.0, 0.0, p.global_position, false)
	_check("the boss cannot be hit while talking", boss.hp == boss_hp and boss.state == "idle")
	var lines := 0
	while scene.is_playing() and scene.waiting_for_press() and lines < 12:
		lines += 1
		await _wait(0.9)
		await _shot("scene_boss_%d" % lines)
		var at := scene.index
		await _tap("roll")
		await _wait(0.4)
		if scene.is_playing() and scene.index == at:
			await _tap("roll")
			await _wait(0.1)
	_check("every line was shown", lines == 5)
	await _wait(0.6)
	await _shot("scene_boss_title")
	await _wait_scene_end(scene)
	_check("the fight starts after the talk", Game.boss_active and boss.state != "idle" and Game.state == "play")
	_check("the closing press does not swing", p.state == "move")
	await _wait(0.6)
	await _shot("scene_boss_fight")

	# It only says this once per run.
	p.take_damage(p.hp + 10.0, boss.global_position)
	await _wait(3.6)
	_check("back at a shrine", Game.state == "play" and not Game.boss_active)
	p.global_position = boss.home + Vector3(0, 0.3, 24)
	await _wait(0.5)
	_check("the rematch starts straight away", not scene.is_playing() and Game.boss_active)
	p.global_position = Game.shrines[0].global_position + Vector3(0, 0.3, -3.5)
	boss.reset()
	Game.boss_active = false
	await _wait(0.3)

	# Leaving for the menu mid-scene puts everything back.
	p._transform_cooldown = 0.0
	await _tap("transform")
	_check("a scene is running", scene.is_playing())
	Game.return_to_title()
	await get_tree().process_frame
	_check("the menu ends the scene", not scene.is_playing() and Game.state == "title" and p.view_camera().current)
	_check("the menu frees everyone", soldier.process_mode == Node.PROCESS_MODE_INHERIT and not p.rig.is_supreme and p.state == "move")
	_check("a new run hears the boss again", not Game.boss_intro_seen)


func _test_boss_skills(p: Player) -> void:
	var boss: Enemy = Game.boss
	boss.reset()
	await _wait(0.2)
	p.global_position = boss.home + Vector3(0, 0.3, 9)
	p.global_position.y = Game.terrain.get_height(p.global_position.x, p.global_position.z) + 0.3
	p.velocity = Vector3.ZERO
	p.cam_yaw = 0.25
	p.rig.rotation.y = PI
	p._cam_root.global_position = p.global_position + Vector3(0, 2.05, 0)
	await _wait(0.5)
	await _shot("boss_aura")
	_check("the boss wakes with the player near", Game.boss_active)
	for skill: String in OverlordSkills.SKILLS:
		boss.global_position = boss.home
		boss._cooldown = 9.0
		boss._skill_cooldown = 99.0
		p.global_position.x = boss.home.x
		p.global_position.z = boss.home.z + 9.0
		p.hp = 99999.0
		p.state = "move"
		boss.begin_skill(skill)
		await _wait(0.1)
		_check(skill + " starts", boss.state == "skill")
		await _wait(float(OverlordSkills.SKILLS[skill]["length"]) * 0.62)
		await _shot("boss_%s" % skill)
		await _wait(float(OverlordSkills.SKILLS[skill]["length"]) * 0.42 + 0.3)
		_check(skill + " hurts a player who stands still", p.hp < 99999.0)
		_check(skill + " ends", boss.state != "skill")
		boss.state = "chase"
	boss.reset()
	Game.boss_active = false
	p.hp = p.max_hp
	p.state = "move"


func _run() -> void:
	if "--bench" in OS.get_cmdline_user_args():
		await _bench()
		return
	if "--menus" in OS.get_cmdline_user_args():
		await _wait_loaded()
		await _click_button(Game.menu.start_button)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		await _wait(1.0)
		await _test_menus(Game.player)
		print("AUTOTEST DONE failures=%d" % _failures)
		get_tree().quit(1 if _failures > 0 else 0)
		return
	if "--boss" in OS.get_cmdline_user_args():
		await _wait_loaded()
		await _click_button(Game.menu.start_button)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		await _wait(1.0)
		await _test_boss_skills(Game.player)
		print("AUTOTEST DONE failures=%d" % _failures)
		get_tree().quit(1 if _failures > 0 else 0)
		return
	if "--cutscene" in OS.get_cmdline_user_args():
		await _wait_loaded()
		await _click_button(Game.menu.start_button)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		await _wait(1.0)
		await _test_cutscenes(Game.player)
		print("AUTOTEST DONE failures=%d" % _failures)
		get_tree().quit(1 if _failures > 0 else 0)
		return
	if "--supreme" in OS.get_cmdline_user_args():
		await _wait_loaded()
		await _click_button(Game.menu.start_button)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		await _wait(1.0)
		await _test_supreme(Game.player)
		print("AUTOTEST DONE failures=%d" % _failures)
		get_tree().quit(1 if _failures > 0 else 0)
		return
	var p := Game.player
	await _wait_loaded()
	await _shot("01_title")

	_check("menu is open at launch", Game.menu.current_screen() == "main")
	# Start through the real click path, then release the cursor for the scripted part.
	await _click_button(Game.menu.start_button)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_check("click starts the game", Game.state == "play")
	_check("starting click does not swing", p.state == "move")
	var yaw_before := p.cam_yaw
	p.add_look(Vector2(120, 0))
	_check("mouse look turns the camera", p.cam_yaw != yaw_before)
	p.cam_yaw = yaw_before
	await _wait(1.0)
	_check("floor contact", p.is_on_floor())
	_check("spawn above ground", p.global_position.y > Game.terrain.get_height(p.global_position.x, p.global_position.z) - 0.3)
	await _wait(3.5)
	print("FPS meadow %d" % Engine.get_frames_per_second())
	await _shot("02_gameplay")

	var start := p.global_position
	Input.action_press("move_forward")
	Input.action_press("run")
	await _wait(1.6)
	await _shot("03_running")
	await _wait(0.6)
	Input.action_release("run")
	Input.action_release("move_forward")
	_check("moved forward (-Z)", p.global_position.z < start.z - 8.0)
	_check("sprint spends stamina", p.stamina < p.max_stamina)
	await _wait(2.0)
	_check("stamina recovers", p.stamina > p.max_stamina * 0.9)

	var soldier: Enemy = Game.enemies[0]
	_place_near(soldier, 2.2)
	soldier.state = "idle"
	await _wait(0.15)
	var soldier_hp := soldier.hp
	var hits_before := soldier_hp
	for i in 5:
		await _tap("attack")
		await _wait(0.3)
		if i == 0:
			await _shot("04_attack")
		await _wait(0.45)
		_place_near(soldier, 2.2)
	_check("sword damages soldier", soldier.hp < hits_before)
	await _shot("05_soldier_fight")

	# Slash effects, one frame per stage, viewed from the side.
	soldier.reset()
	soldier.hp = 99999.0
	soldier.state = "stagger"
	soldier._state_time = 0.0
	soldier._state_length = 30.0
	_place_near(soldier, 2.4)
	p.cam_yaw = 0.8
	p.stamina = p.max_stamina
	await _wait(0.4)
	if not p.rig.is_armed:
		await _tap("weapon")
		await _wait(1.0)
	await _tap("attack")
	await _shot_at("light1", 0.3, "fx_1_windup")
	await _shot_at("light1", 0.5, "fx_2_cut")
	Input.action_press("attack")
	await _shot_at("light2", 0.42, "fx_3_cut2", true)
	await _shot_at("light3", 0.5, "fx_4_finisher", true)
	Input.action_release("attack")
	while p.state != "move":
		await get_tree().physics_frame
	p.stamina = p.max_stamina
	_place_near(soldier, 2.4)
	p.cam_yaw = 0.8
	await _wait(0.4)
	await _tap("heavy")
	await _shot_at("heavy", 0.54, "fx_5_heavy")
	await _shot_at("heavy", 0.66, "fx_6_heavy_after")
	_check("blade lights up during a swing", p.rig._blade_power > 0.3)
	await _wait(1.0)
	_check("blade settles after the swing", p.rig._blade_power < 0.3)
	soldier.hp = soldier.max_hp
	p.cam_yaw = 0.0

	p.hp = p.max_hp
	await _tap("lock_on")
	await _wait(0.2)
	_check("lock-on acquires target", p.target != null)
	await _shot("06_lock_on")
	await _tap("lock_on")

	var stamina_before := p.stamina
	await _tap("roll")
	await _wait(0.1)
	_check("roll starts", p.state == "roll")
	_check("roll spends stamina", p.stamina < stamina_before)
	await _shot("07_roll")
	await _wait(0.7)
	_check("roll ends", p.state != "roll")

	p.hp = p.max_hp
	var fp_before := p.fp
	soldier.hp = soldier.max_hp
	_place_near(soldier, 7.0)
	soldier.state = "stagger"
	soldier._state_length = 3.0
	soldier._state_time = 0.0
	var soldier_full := soldier.hp
	await _wait(0.1)
	await _tap("bolt")
	await _wait(0.42)
	await _shot("08_cast")
	_check("bolt spends focus", p.fp < fp_before)
	await _wait(0.8)
	_check("bolt damages soldier", soldier.hp < soldier_full)

	p.hp = p.max_hp * 0.3
	var flasks_before := p.flasks
	var hp_before := p.hp
	await _tap("vial")
	await _wait(1.1)
	_check("vial heals", p.hp > hp_before and p.flasks == flasks_before - 1)

	soldier.take_hit(99999.0, 0.0, p.global_position, false)
	_check("soldier dies", not soldier.is_alive())
	_check("kill awards stardust", Game.stardust > 0)
	await _wait(1.2)
	await _shot("09_soldier_dead")

	var shrine: Shrine = Game.shrines[1]
	p.global_position = shrine.global_position + Vector3(0, 0.4, 3.0)
	p.velocity = Vector3.ZERO
	p.cam_yaw = 0.0
	p._cam_root.global_position = p.global_position + Vector3(0, 2.05, 0)
	await _wait(0.3)
	await _shot("10_shrine")
	p.hp = 50.0
	await _tap("interact")
	await _wait(0.4)
	await _shot("11_resting")
	await _wait(2.0)
	_check("shrine heals", p.hp == p.max_hp)
	_check("shrine sets checkpoint", Game.checkpoint == shrine)
	_check("shrine revives soldiers", soldier.is_alive())

	var boss: Enemy = Game.boss
	p.global_position = boss.home + Vector3(0, 0.3, 16)
	p.velocity = Vector3.ZERO
	p.cam_yaw = 0.0
	p.rig.rotation.y = PI
	p._cam_root.global_position = p.global_position + Vector3(0, 2.05, 0)
	await _wait(0.4)
	_check("boss wakes", Game.boss_active)
	_check("the boss is the System Overlord", boss.rig is OverlordModel)
	await _shot("12_boss")
	p.hp = 99999.0
	await _wait(6.0)
	print("FPS arena %d" % Engine.get_frames_per_second())
	await _shot("13_boss_fight")
	_check("boss hurts the player", p.hp < 99999.0)
	p.hp = p.max_hp
	p.stamina = p.max_stamina

	# A held guard must soak a frontal blow.
	await _wait(1.0)
	var guard_hp := p.hp
	p.state = "move"
	p.blocking = true
	p.rig.rotation.y = atan2(boss.global_position.x - p.global_position.x, boss.global_position.z - p.global_position.z)
	p.take_damage(100.0, boss.global_position)
	_check("guard reduces damage", guard_hp - p.hp <= 12.0)
	p.blocking = false
	p.hp = p.max_hp

	p.take_damage(p.hp + 10.0, boss.global_position)
	_check("player can die", p.state == "dead" and Game.state == "dead")
	await _wait(1.4)
	await _shot("14_death")
	await _wait(2.6)
	_check("respawns at checkpoint", Game.state == "play" and p.state == "move" and p.global_position.distance_to(shrine.global_position) < 8.0)
	_check("boss resets", boss.hp == boss.max_hp and not Game.boss_active)

	boss.take_hit(99999.0, 0.0, p.global_position, false)
	_check("boss dies and game is won", Game.boss_defeated)
	await _wait(1.0)
	await _shot("15_victory")

	await _test_blade_summon(p)
	await _test_supreme(p)
	await _test_boss_skills(p)
	await _test_menus(p)
	print("FPS %d" % Engine.get_frames_per_second())
	print("AUTOTEST DONE failures=%d" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)
