extends Node
## Global game state, input map and the rest/death/victory flow.

const BOSS_NAME := "SYSTEM OVERLORD"
const SETTINGS_PATH := "user://settings.cfg"

var world: Node3D
var terrain: AstralTerrain
var player: Player
var camera: Camera3D
var hud: Hud
var menu: GameMenu
var cutscene: Cutscene
var powers: CosmicShow ## The powers of whoever is being played.
var gemini_show: CosmicShow
var abyss_show: AbyssShow
var hero := "gemini" ## Chosen on the menu: "gemini" or "aum".
var haven: SafeHaven
var domain: WormsDomain
var town: TownMap ## เมืองดาวรุ่ง, through the golden gate by the first shrine.
var town_gate: Node3D
var gate: Node3D ## The red gate in the tower's arena, open once OBLIVION has fallen.
var haven_seen := false
var supreme_unlocked := false ## Form 2: Zero Day restores it in Safe Mode, before the rematch with OBLIVION.
var argon_unlocked := false ## Form 3: wakes when OBLIVION falls, kept for WORMS.
var enemies: Array[Enemy] = []
var shrines: Array[Shrine] = []
var boss: Enemy ## Whichever boss the fight is with.
var overlord: Enemy
var worms: WormsBoss
var boss_active := false
var boss_defeated := false ## OBLIVION has fallen.
var worms_defeated := false ## And so has WORMS: the game is won.
var checkpoint: Shrine
var boss_intro_seen := false
var state := "title" ## title, play, cutscene, dead
var stardust := 0
var autotest := false
var cutscenes_on := true ## The scripted tests turn these off, except the one that tests them.
var warming := false
var run_id := 0 ## Bumped on a new run so pending respawn timers can tell they are stale.
var settings := {"mouse": 1.0, "invert_y": false, "render": 0.8, "quality": 1, "fullscreen": false, "vsync": true, "show_fps": false}

var _shake := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Thonburi", "Sukhumvit Set", "Noto Sans Thai", "Leelawadee UI", "Tahoma", "Arial"])
	ThemeDB.fallback_font = font
	_define_inputs()
	autotest = "--autotest" in OS.get_cmdline_user_args()
	cutscenes_on = not autotest
	_load_settings()


func oblivion_fighting() -> bool:
	return boss_active and boss != null and boss.oblivion


## The ground under (x, z): the valley's terrain, or the floor of WORMS' system out where it hangs.
func ground_height(x: float, z: float) -> float:
	if WormsDomain.contains(x, z):
		return WormsDomain.CENTER.y
	if TownMap.contains(x, z):
		return TownMap.CENTER.y
	return terrain.get_height(x, z)


func in_town() -> bool:
	return player != null and town != null and TownMap.contains(player.global_position.x, player.global_position.z)


func near_town_gate(at: Vector3) -> bool:
	return town_gate != null and town_gate.global_position.distance_to(at) < TownMap.REACH


## Through the golden gate to the town. Nothing there will fight.
func enter_town() -> void:
	cutscene.fade = 1.0
	town.visible = true
	player.global_position = TownMap.CENTER + TownMap.ENTRY + Vector3(0, 0.3, 0)
	player.velocity = Vector3.ZERO
	player.set_flying(false)
	player.cam_yaw = 0.0
	player.rig.rotation.y = PI
	player.reset_camera()
	player.lock_input(0.6)
	hud.banner("เมืองดาวรุ่ง", "เมืองแห่งผู้คน ตลาด และหมู่บ้านทุ่งทอง", Color(1.0, 0.8, 0.35), 3.0)


## Back through the gate to the valley, beside the first shrine.
func leave_town() -> void:
	cutscene.fade = 1.0
	var at := town_gate.global_position + Vector3(0, 0.3, 4.0)
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.set_flying(false)
	player.reset_camera()
	player.lock_input(0.6)
	town.visible = false
	hud.banner("หุบเขาอำพัน", "", Color(1.0, 0.85, 0.4), 2.0)


func in_domain() -> bool:
	return player != null and player.global_position.y > WormsDomain.CENTER.y - 100.0


func worms_fighting() -> bool:
	return boss_active and boss != null and boss is WormsBoss and boss.is_alive()


## The fights whose blows are measured against the whole of the warrior, in any form.
func harsh_boss_fighting() -> bool:
	return oblivion_fighting() or worms_fighting()


func boss_title() -> String:
	if boss is WormsBoss:
		return "WORMS"
	return BOSS_NAME + " · OBLIVION" if boss != null and boss.oblivion else BOSS_NAME


func _define_inputs() -> void:
	var keys := {
		"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D,
		"run": KEY_SHIFT, "roll": KEY_SPACE, "lock_on": KEY_Q, "interact": KEY_E,
		"vial": KEY_R, "bolt": KEY_F, "heavy": KEY_C, "upgrade": KEY_U, "weapon": KEY_X,
		"transform": KEY_T, "argon": KEY_G, "skill_1": KEY_1, "skill_2": KEY_2, "skill_3": KEY_3, "skill_4": KEY_4, "skill_5": KEY_5, "skill_6": KEY_6, "skill_7": KEY_7, "skill_8": KEY_8,
		"fly": KEY_V, "fly_down": KEY_CTRL, "cutscene_skip": KEY_TAB,
	}
	for action: String in keys:
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	var buttons := {"attack": MOUSE_BUTTON_LEFT, "block": MOUSE_BUTTON_RIGHT}
	for action: String in buttons:
		InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = buttons[action]
		InputMap.action_add_event(action, event)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and (state == "play" or state == "cutscene") and not autotest and not get_tree().paused:
		set_paused(true)


func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	if not autotest:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED
	menu.show_pause(paused)
	player.lock_input(0.25) # The click that resumes must not also swing the sword.


func _load_settings() -> void:
	if autotest:
		return
	var file := ConfigFile.new()
	if file.load(SETTINGS_PATH) != OK:
		return
	for key: String in settings:
		settings[key] = file.get_value("settings", key, settings[key])


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	apply_settings()
	if autotest:
		return
	var file := ConfigFile.new()
	for k: String in settings:
		file.set_value("settings", k, settings[k])
	file.save(SETTINGS_PATH)


func apply_settings() -> void:
	get_viewport().scaling_3d_scale = settings["render"]
	hud.show_fps = settings["show_fps"]
	world.call("apply_quality", settings["quality"])
	if autotest:
		return
	var windowed := DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN
	if windowed == settings["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings["vsync"] else DisplayServer.VSYNC_DISABLED)


## Draws every effect once behind the loading screen, so its first real use cannot hitch.
func warmup() -> void:
	warming = true
	await get_tree().process_frame
	await get_tree().process_frame
	var at := camera.global_position - camera.global_transform.basis.z * 6.0
	var tint := Color(0.7, 0.55, 1.0)
	player.rig.set_armed_instant(true)
	player.rig.set_form(true, true)
	CosmicFx.warm(at)
	powers.warm(at)
	OverlordSkills.warm(at)
	WormsSkills.warm(at)
	for i in 4:
		await RenderingServer.frame_post_draw
	player.rig.set_form_level(2, true)
	player.rig.warm_effects(at)
	player.set_hero("aum") # Builds อั้ม's body once behind the loading screen.
	player.abyss.global_position = at
	player.warm_trail(at)
	Fx.impact(at, tint, 1.0)
	Fx.crescent(at, Vector3.FORWARD, 0.0, tint, 5.0)
	Fx.ground_strike(at, tint)
	var bolt := StarBolt.new()
	world.add_child(bolt)
	bolt.global_position = at
	for i in 8:
		await RenderingServer.frame_post_draw
	powers.stop()
	player.rig.set_energy(0.0)
	player.rig.set_blade_sparks(false)
	player.rig.set_form(false, true)
	player.rig.set_armed_instant(false)
	player.set_hero(hero)
	warming = false
	menu.finish_loading()


## Abandons the run and puts everything back as it was at launch.
func return_to_title() -> void:
	run_id += 1
	get_tree().paused = false
	Engine.time_scale = 1.0
	cutscene.abort()
	state = "title"
	boss_active = false
	boss_defeated = false
	worms_defeated = false
	boss_intro_seen = false
	haven_seen = false
	supreme_unlocked = false
	argon_unlocked = false
	stardust = 0
	checkpoint = shrines[0]
	player.new_game()
	boss = overlord
	overlord.restore_first_form()
	gate.visible = false
	domain.exit_gate.visible = false
	reset_enemies()
	hud.clear()
	menu.open_main()
	if not autotest:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


## Who is played. The menu calls this as the cursor moves over each hero, so the one on screen changes with it.
func set_hero(new_hero: String) -> void:
	if state != "title" and state != "":
		return
	hero = new_hero
	if powers != null:
		powers.stop()
	powers = abyss_show if hero == "aum" else gemini_show
	player.set_hero(hero)


func start_game_as(new_hero: String) -> void:
	set_hero(new_hero)
	start_game()


func start_game() -> void:
	if state != "title":
		return
	state = "play"
	player.cam_yaw = 0.0
	player.cam_pitch = -0.17
	player.lock_input(0.3)
	if not autotest:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	menu.close()
	if not cutscene.opening():
		hud.banner("เมืองดาวรุ่ง", "ออกทางประตูทองทางใต้ เพื่อไปหุบเขาอำพัน", TownMap.GOLD)


func add_stardust(amount: int) -> void:
	stardust += amount


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func take_shake(delta: float) -> float:
	_shake = maxf(0.0, _shake - delta * 2.4)
	return _shake


func hit_stop(duration: float) -> void:
	Engine.time_scale = 0.06
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0


func nearest_shrine(from: Vector3, reach: float) -> Shrine:
	var best: Shrine = null
	var best_distance := reach
	for shrine in shrines:
		var d := shrine.global_position.distance_to(from)
		if d < best_distance:
			best = shrine
			best_distance = d
	return best


## Resting refills the player and brings the valley's soldiers back, as a checkpoint.
func rest_at(shrine: Shrine) -> void:
	checkpoint = shrine
	shrine.kindle()
	player.refill()
	reset_enemies()
	hud.banner("จุดประกายดารา", "ฟื้นฟูพลัง ศัตรูกลับคืนสู่หุบเขา", Color(0.72, 0.62, 1.0))


func reset_enemies() -> void:
	boss_active = false
	for enemy in enemies.duplicate():
		if enemy.summoned:
			enemies.erase(enemy)
			enemy.queue_free()
			continue
		if enemy is WormsBoss:
			enemy.reset()
			continue
		if enemy.is_boss and boss_defeated:
			continue
		enemy.reset()


func on_player_died() -> void:
	state = "dead"
	boss_active = false
	hud.banner("แสงดาวดับลง", "ลองใหม่อีกครั้ง" if haven_seen else "", Color(0.85, 0.2, 0.2), 3.0)
	var run := run_id
	await get_tree().create_timer(3.2).timeout
	if run != run_id:
		return
	player.respawn(checkpoint)
	reset_enemies()
	state = "play"


## Zero Day has carried Gemini out. The run goes on from the last shrine.
func after_rescue() -> void:
	haven.prepare()
	checkpoint = haven.shrine
	player.respawn(checkpoint)
	reset_enemies()
	player.reset_camera()
	player.lock_input(0.4)
	if not haven_seen:
		haven_seen = true
		cutscene.haven_arrival()
	else:
		hud.banner("SAFE MODE", "รอดมาได้หวุดหวิด", Color("b8ff2e"), 3.0)


func in_haven() -> bool:
	return player != null and player.global_position.y > SafeHaven.CENTER.y - 60.0 and not in_domain()


## Through the red gate into WORMS' system. It comes down the first time.
func enter_domain() -> void:
	cutscene.fade = 1.0
	var at := WormsDomain.CENTER + WormsDomain.ENTRY
	player.global_position = at + Vector3(0, 0.3, 0)
	player.velocity = Vector3.ZERO
	player.set_flying(false)
	player.cam_yaw = 0.0
	player.rig.rotation.y = PI
	player.reset_camera()
	player.lock_input(0.6)
	hud.banner("ระบบของ WORMS", "ทุกสิ่งในนี้อยู่ใต้คำสั่งของมัน", Color(1.0, 0.06, 0.19), 3.0)
	if worms.state == "dormant":
		await get_tree().create_timer(1.6).timeout
		if in_domain() and state == "play":
			worms.appear()


## Back through the gate to the valley, by the shrine nearest the tower.
func leave_domain() -> void:
	cutscene.fade = 1.0
	player.respawn(shrines[1])
	player.reset_camera()
	player.lock_input(0.4)
	hud.banner("หุบเขาอำพัน", "", Color(1.0, 0.85, 0.4), 2.0)


func near_gate(at: Vector3) -> bool:
	return gate != null and gate.visible and gate.global_position.distance_to(at) < WormsDomain.REACH


## Through the door, back to the valley near the tower.
func leave_haven() -> void:
	cutscene.fade = 1.0
	player.respawn(shrines[1])
	player.reset_camera()
	player.lock_input(0.4)
	hud.banner("หุบเขาอำพัน", "OBLIVION ยังรออยู่ที่หอดาว", Color(1.0, 0.42, 0.4), 3.0)


func on_boss_defeated() -> void:
	boss_defeated = true
	boss_active = false
	add_stardust(5000)
	hud.banner("OBLIVION ถูกลบแล้ว", "แต่ดูเหมือนยังมีใครบางคนคุมระบบนี้อยู่...", Color(1.0, 0.85, 0.4), 4.0)
	# The one behind it all opens a way into its own system.
	var run := run_id
	await get_tree().create_timer(4.5).timeout
	if run != run_id or worms_defeated:
		return
	# OBLIVION's last words name the one behind it, and the third form wakes to answer.
	supreme_unlocked = true
	if cutscene.oblivion_last_words(func() -> void:
			if run == run_id and not worms_defeated:
				open_gate()):
		return
	unlock_argon()
	await get_tree().create_timer(4.0).timeout
	if run != run_id or worms_defeated:
		return
	open_gate()


## Opens the second form for good.
func unlock_supreme(quiet := false) -> void:
	if supreme_unlocked:
		return
	supreme_unlocked = true
	CosmicFx.pillar(player.global_position, 200.0, 1.0, CosmicFx.GOLD, 10.0)
	CosmicFx.flash(Color(1.0, 0.92, 0.7), 0.5, 0.6)
	Fx.ring(player.global_position, 12.0, CosmicFx.GOLD, 0.9)
	if not quiet:
		hud.banner("ปลดล็อกร่างที่ 2 · ร่างสูงสุด", "กด T เพื่อแปลงร่าง", CosmicFx.GOLD, 4.0)


## Opens the third form for good. `quiet` leaves the announcement to a cutscene that is already saying it.
func unlock_argon(quiet := false) -> void:
	if argon_unlocked:
		return
	argon_unlocked = true
	CosmicFx.pillar(player.global_position, 200.0, 1.0, Color(0.25, 0.91, 1.0), 10.0)
	CosmicFx.flash(Color(0.85, 1.0, 0.98), 0.5, 0.6)
	Fx.ring(player.global_position, 12.0, Color(0.25, 0.91, 1.0), 0.9)
	if not quiet:
		hud.banner("ปลดล็อกร่างที่ 3 · ARGON", "ได้สิทธิ์ผู้ดูแลระบบแล้ว · กด G เพื่อแปลงร่าง", Color(0.25, 0.91, 1.0), 4.0)


func open_gate() -> void:
	gate.visible = true
	CosmicFx.pillar(gate.global_position, 200.0, 1.2, Color(1.0, 0.06, 0.19), 8.0)
	CosmicFx.flash(Color(1.0, 0.06, 0.15), 0.6, 0.8)
	shake(0.8)
	hud.banner("ประตูแดงเปิดแล้ว", "เข้าสู่ระบบของ WORMS ที่ลานหอดาว (E)", Color(1.0, 0.06, 0.19), 4.0)


## TESTING: P (or F9) jumps straight to the end of the game, to check what winning changes.
## Read by physical key, so it works with a Thai keyboard layout too.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and (key.physical_keycode == KEY_P or key.physical_keycode == KEY_F9 or key.keycode == KEY_F9):
		debug_skip_to_victory()


func debug_skip_to_victory() -> void:
	if state != "play" or worms_defeated:
		return
	cutscene.abort()
	boss_defeated = true
	supreme_unlocked = true
	argon_unlocked = true
	haven_seen = true
	# OBLIVION is simply gone, without its last-words scene.
	overlord.hp = 0.0
	overlord.state = "dead"
	overlord.visible = false
	overlord.collision_layer = 0
	overlord.collision_mask = 0
	if in_domain():
		leave_domain()
	hud.banner("TEST · ข้ามไปตอนชนะ", "", Color(1.0, 0.85, 0.4), 1.5)
	on_worms_defeated()


func on_worms_defeated() -> void:
	worms_defeated = true
	boss_active = false
	add_stardust(10000)
	gate.visible = false
	hud.banner("ชัยชนะ", "WORMS ถูกลบออกจากระบบ · ดวงดาวกลับคืนสู่ฟากฟ้า", Color(1.0, 0.85, 0.4), 7.0)
	var run := run_id
	await get_tree().create_timer(5.0).timeout
	if run == run_id:
		domain.exit_gate.visible = true
