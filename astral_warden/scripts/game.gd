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
var enemies: Array[Enemy] = []
var shrines: Array[Shrine] = []
var boss: Enemy
var boss_active := false
var boss_defeated := false
var checkpoint: Shrine
var state := "title" ## title, play, dead
var stardust := 0
var autotest := false
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
	_load_settings()


func _define_inputs() -> void:
	var keys := {
		"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D,
		"run": KEY_SHIFT, "roll": KEY_SPACE, "lock_on": KEY_Q, "interact": KEY_E,
		"vial": KEY_R, "bolt": KEY_F, "heavy": KEY_C, "upgrade": KEY_U, "weapon": KEY_X,
		"transform": KEY_T, "skill_1": KEY_1, "skill_2": KEY_2, "skill_3": KEY_3, "skill_4": KEY_4, "skill_5": KEY_5, "skill_6": KEY_6, "skill_7": KEY_7,
		"fly": KEY_V, "fly_down": KEY_CTRL,
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
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "play" and not autotest and not get_tree().paused:
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
	OverlordSkills.warm(at)
	player.rig.warm_effects(at)
	player.warm_trail(at)
	Fx.impact(at, tint, 1.0)
	Fx.crescent(at, Vector3.FORWARD, 0.0, tint, 5.0)
	Fx.ground_strike(at, tint)
	var bolt := StarBolt.new()
	world.add_child(bolt)
	bolt.global_position = at
	for i in 8:
		await RenderingServer.frame_post_draw
	player.rig.set_energy(0.0)
	player.rig.set_blade_sparks(false)
	player.rig.set_form(false, true)
	player.rig.set_armed_instant(false)
	warming = false
	menu.finish_loading()


## Abandons the run and puts everything back as it was at launch.
func return_to_title() -> void:
	run_id += 1
	get_tree().paused = false
	Engine.time_scale = 1.0
	state = "title"
	boss_active = false
	boss_defeated = false
	stardust = 0
	checkpoint = shrines[0]
	player.new_game()
	reset_enemies()
	hud.clear()
	menu.open_main()
	if not autotest:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


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
	hud.banner("หุบเขาอำพัน", "จงไปยังหอดาวทางเหนือ", Color(1.0, 0.85, 0.5))


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
	for enemy in enemies:
		if enemy.is_boss and boss_defeated:
			continue
		enemy.reset()


func on_player_died() -> void:
	state = "dead"
	boss_active = false
	hud.banner("แสงดาวดับลง", "", Color(0.85, 0.2, 0.2), 3.0)
	var run := run_id
	await get_tree().create_timer(3.2).timeout
	if run != run_id:
		return
	player.respawn(checkpoint)
	reset_enemies()
	state = "play"


func on_boss_defeated() -> void:
	boss_defeated = true
	boss_active = false
	add_stardust(5000)
	hud.banner("ชัยชนะ", "ดวงดาวกลับคืนสู่ฟากฟ้า", Color(1.0, 0.85, 0.4), 6.0)
