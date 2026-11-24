class_name Cutscene
extends Node3D
## Scripted shots that take over the camera: Gemini's change of form and the meeting with the boss.
## A step is a dictionary: seconds, from, to, look, look_to, fov, and optionally who, text, do, must.
## `do` runs when the step starts; a `must` step still runs it when the scene is skipped.

const GEMINI := "GEMINI"
const OVERLORD := "SYSTEM OVERLORD"
const ZERO := "ZERO DAY"
const ARGON := "GEMINI ARGON"
const WORMS := "WORMS"
const ARGON_TINT := Color(0.25, 0.91, 1.0)
const WORMS_TINT := Color(1.0, 0.06, 0.19)
const GEMINI_TINT := Color(0.8, 0.64, 1.0)
const OVERLORD_TINT := Color(1.0, 0.36, 0.32)
const LETTERS_PER_SECOND := 34.0
const READ_TIME := 2.2 ## Seconds a finished line stays up before moving on by itself.
const INPUT_DELAY := 0.3 ## A press this soon after a line appears was meant for the fight.
const REVEAL_AT := 4.0
const ASCEND_SNAP := 0.66 ## Where the "ascend" action reaches its burst, as a share of its length.
const BOSS_DISTANCE := 15.0
const REBIRTH_DISTANCE := 32.0
const RESCUE_DISTANCE := 26.0
const OPENING_FALL := 2.2

var bars := 0.0 ## Letterbox, 0 to 1.
var fade := 0.0 ## Black cover, 0 to 1.
var speaker := ""
var line := ""
var tint := Color.WHITE
var letters := 0.0
var index := -1

var _camera: Camera3D
var _active := false
var _steps: Array[Dictionary] = []
var _clock := 0.0
var _length := 1.0
var _on_done := Callable()
var _on_abort := Callable()
var _frozen: Array[Enemy] = []


func _ready() -> void:
	_camera = Camera3D.new()
	_camera.top_level = true
	_camera.near = 0.08
	_camera.far = 2200.0
	add_child(_camera)


func is_playing() -> bool:
	return _active


func waiting_for_press() -> bool:
	return _active and line != ""


## Returns false when a scene cannot start, so the caller can carry on without one.
func transformation(p: Player) -> bool:
	if not _begin():
		return false
	var foot := p.global_position
	var ahead := p.forward()
	var side := Vector3.UP.cross(ahead)
	var chest := foot + Vector3(0, 1.25, 0)
	var face := foot + Vector3(0, 1.75, 0)
	var tall := foot + Vector3(0, 3.3, 0)
	var charge := Color(0.7, 0.55, 1.0)
	_start([
		{"seconds": 1.4, "from": _clear(chest, foot + ahead * 6.0 + side * 1.6 + Vector3(0, 0.6, 0)), "to": _clear(chest, foot + ahead * 4.2 + side * 1.0 + Vector3(0, 0.9, 0)), "look": chest, "look_to": chest, "fov": 42.0,
			"who": GEMINI, "text": "ดวงดาวทั้งหลาย... ขอยืมพลังหน่อยนะ", "tint": GEMINI_TINT,
			"do": func() -> void:
				p.rig.set_energy(1.0)
				p.rig.play("ascend", REVEAL_AT / ASCEND_SNAP, true)
				Fx.ring(foot, 5.0, charge, 0.6)
				Game.shake(0.2)},
		{"seconds": 1.3, "from": _clear(face, foot + ahead * 1.9 + side * 1.0 + Vector3(0, 1.7, 0)), "to": _clear(face, foot + ahead * 1.6 - side * 0.8 + Vector3(0, 1.55, 0)), "look": face, "look_to": face, "fov": 36.0,
			"do": func() -> void:
				Fx.burst(chest, charge, 34, 4.0)
				Game.shake(0.3)},
		{"seconds": 1.3, "from": _clear(chest, foot - ahead * 5.0 + side * 3.0 + Vector3(0, 0.8, 0)), "to": _clear(chest, foot - ahead * 6.5 + side * 2.0 + Vector3(0, 6.0, 0)), "look": chest, "look_to": chest, "fov": 50.0, "text": "",
			"do": func() -> void:
				Fx.ring(foot, 12.0, CosmicFx.GOLD, 1.0)
				Fx.burst(chest, CosmicFx.GOLD, 50, 7.0)
				Game.shake(0.6)},
		{"seconds": 1.0, "from": _clear(tall, foot + ahead * 24.0 + side * 3.0 + Vector3(0, 0.6, 0)), "to": _clear(tall, foot + ahead * 20.0 + side * 2.0 + Vector3(0, 0.9, 0)), "look": tall, "look_to": foot + Vector3(0, 7.0, 0), "fov": 60.0, "must": true,
			"do": p.apply_form},
		{"seconds": 2.6, "from": _clear(tall, foot + ahead * 7.5 + side * 4.0 + Vector3(0, 0.7, 0)), "to": _clear(tall, foot + ahead * 7.0 - side * 4.0 + Vector3(0, 1.6, 0)), "look": tall, "look_to": tall, "fov": 44.0,
			"who": GEMINI, "text": "เอาล่ะ... ทีนี้ของจริงแล้ว", "tint": CosmicFx.GOLD},
	], p.end_transform)
	return true


## The change into the third form: the system's administrator logs in.
func argon_transformation(p: Player) -> bool:
	if not _begin():
		return false
	var foot := p.global_position
	var ahead := p.forward()
	var side := Vector3.UP.cross(ahead)
	var k := 1.9 if p.rig.is_supreme else 1.0 # The supreme body is already tall.
	var chest := foot + Vector3(0, 1.25 * k, 0)
	var face := foot + Vector3(0, 1.75 * k, 0)
	var tall := foot + Vector3(0, 3.6, 0)
	var mint := Color(0.49, 1.0, 0.78)
	_start([
		{"seconds": 1.5, "from": _clear(chest, foot + ahead * 6.0 * k + side * 1.6 + Vector3(0, 0.6, 0)), "to": _clear(chest, foot + ahead * 4.2 * k + side * 1.0 + Vector3(0, 0.9, 0)), "look": chest, "look_to": chest, "fov": 42.0,
			"who": GEMINI, "text": "ขอสิทธิ์ผู้ดูแลระบบ... ตอนนี้เลย", "tint": GEMINI_TINT,
			"do": func() -> void:
				p.rig.set_energy(1.0)
				p.rig.play("ascend", REVEAL_AT / ASCEND_SNAP, true)
				CosmicFx.shock(foot, 14.0, 2.0, 0.8, ARGON_TINT, true)
				Fx.ring(foot, 5.0, ARGON_TINT, 0.6)
				Game.shake(0.2)},
		{"seconds": 1.3, "from": _clear(face, foot + ahead * 1.9 * k + side * 1.0 + Vector3(0, 1.7 * k, 0)), "to": _clear(face, foot + ahead * 1.6 * k - side * 0.8 + Vector3(0, 1.55 * k, 0)), "look": face, "look_to": face, "fov": 36.0,
			"who": "SYSTEM", "text": "ACCESS LEVEL: ROOT · ยืนยันตัวตนสำเร็จ", "tint": mint,
			"do": func() -> void:
				for i in 4:
					CosmicFx.shock(chest + Vector3(0, i * 0.5, 0), 2.0 + i, 1.6, 0.5, mint)
				Fx.burst(chest, ARGON_TINT, 34, 4.0)
				Game.shake(0.3)},
		{"seconds": 1.3, "from": _clear(chest, foot - ahead * 5.0 + side * 3.0 + Vector3(0, 0.8, 0)), "to": _clear(chest, foot - ahead * 6.5 + side * 2.0 + Vector3(0, 6.0, 0)), "look": chest, "look_to": chest, "fov": 50.0, "text": "",
			"do": func() -> void:
				Fx.ring(foot, 12.0, ARGON_TINT, 1.0)
				CosmicFx.inflow(chest, 40, 9.0, 0.8, ARGON_TINT)
				Fx.burst(chest, mint, 50, 7.0)
				Game.shake(0.6)},
		{"seconds": 1.0, "from": _clear(tall, foot + ahead * 24.0 + side * 3.0 + Vector3(0, 0.6, 0)), "to": _clear(tall, foot + ahead * 20.0 + side * 2.0 + Vector3(0, 0.9, 0)), "look": tall, "look_to": foot + Vector3(0, 7.5, 0), "fov": 60.0, "must": true,
			"do": p.apply_form},
		{"seconds": 2.6, "from": _clear(tall, foot + ahead * 8.0 + side * 4.0 + Vector3(0, 0.7, 0)), "to": _clear(tall, foot + ahead * 7.5 - side * 4.0 + Vector3(0, 1.8, 0)), "look": tall, "look_to": tall, "fov": 44.0,
			"who": ARGON, "text": "ระบบนี้อยู่ในมือฉันแล้ว ไวรัสตัวไหนก็หนีไม่พ้น", "tint": ARGON_TINT},
	], p.end_transform)
	return true


## WORMS comes down into its own system and has its say. The fight starts when the talking is over.
func worms_intro(worms: Enemy, on_landed: Callable) -> bool:
	if not _begin(worms):
		return false
	var p := Game.player
	var away := p.global_position - worms.global_position
	away.y = 0.0
	var dir := away.normalized() if away.length() > 0.1 else Vector3.BACK
	var at := worms.global_position + dir * 24.0
	at.y = Game.ground_height(at.x, at.z) + 0.2
	p.halt_for_scene()
	p.place_for_scene(at, worms.global_position)
	worms.rig.rotation.y = atan2(dir.x, dir.z)
	var side := Vector3.UP.cross(dir)
	var base := worms.global_position
	var height := 3.2 if p.rig.is_supreme else 1.75
	var hero := at + Vector3(0, height, 0)
	var face: Vector3 = worms.head_position()
	var body: Vector3 = worms.chest_position()
	var sky := base + Vector3(0, 40.0, 0)
	var argon := p.rig.is_argon
	_start([
		{"seconds": 3.4, "from": _clear(hero, at + dir * 5.0 + side * 3.0 + Vector3(0, 1.0, 0)), "to": _clear(hero, at + dir * 4.0 + side * 2.0 + Vector3(0, 0.6, 0)), "look": sky, "look_to": body, "fov": 52.0,
			"who": WORMS, "text": "ในที่สุด... ไวรัสตัวเล็ก ๆ ก็คลานมาถึงแกนกลางจนได้", "tint": WORMS_TINT,
			"do": func() -> void:
				var tween := worms.rig.create_tween()
				tween.tween_property(worms.rig, "position:y", 0.0, 3.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
				CosmicFx.flash(Color(1.0, 0.06, 0.15), 0.6, 1.0)
				Game.shake(0.5)},
		{"seconds": 2.6, "must": true, "from": _clear(body, base + dir * 12.0 - side * 4.0 + Vector3(0, 0.5, 0)), "to": _clear(body, base + dir * 10.0 - side * 3.0 + Vector3(0, 1.0, 0)), "look": body, "look_to": face, "fov": 50.0,
			"who": GEMINI, "text": "แกสินะ ตัวการที่อยู่เบื้องหลัง OBLIVION", "tint": ARGON_TINT if argon else GEMINI_TINT,
			"do": func() -> void:
				worms.rig.position.y = 0.0
				on_landed.call()},
		{"seconds": 3.4, "from": _clear(face, base + dir * 9.0 + side * 2.0 + Vector3(0, -1.0, 0)), "to": _clear(face, base + dir * 7.5 + side * 1.2 + Vector3(0, -0.4, 0)), "look": face, "look_to": face, "fov": 40.0,
			"who": WORMS, "text": "OBLIVION เป็นแค่โปรแกรมที่ข้าเขียนเล่น ๆ... ส่วนแก ก็แค่โค้ดบรรทัดเดียวที่ข้าลบทิ้งได้", "tint": WORMS_TINT,
			"do": func() -> void:
				worms.rig.play("raise", 3.4, true)},
		{"seconds": 2.8, "from": _clear(hero, at - dir * 3.4 + side * 1.2 + Vector3(0, height, 0)), "to": _clear(hero, at - dir * 2.8 + side * 0.7 + Vector3(0, height - 0.1, 0)), "look": hero, "look_to": hero, "fov": 38.0,
			"who": ARGON if argon else GEMINI,
			"text": "ฉันไม่ใช่ไวรัส ฉันคือผู้ดูแลระบบ... และแกคือภัยคุกคามตัวสุดท้าย" if argon else "งั้นฉันจะเป็นบรรทัดที่แกลบไม่ออก",
			"tint": ARGON_TINT if argon else GEMINI_TINT,
			"do": func() -> void:
				if not p.rig.is_armed:
					p.rig.begin_summon(0.8)},
		{"seconds": 2.4, "from": _clear(face, base + dir * 6.0 + Vector3(0, 1.5, 0)), "to": _clear(face, base + dir * 5.0 + Vector3(0, 2.2, 0)), "look": face, "look_to": face, "fov": 42.0,
			"who": WORMS, "text": "ทุกอย่างในระบบนี้ต้องฟังข้า WORMS... คำสั่ง: ลบทุกอย่าง", "tint": WORMS_TINT,
			"do": func() -> void:
				worms.rig.play("sky", 2.4, true)
				(worms.rig as WormsModel).power = 1.0
				Game.shake(0.4)},
		{"seconds": 1.8, "from": _clear(body, base + dir * 26.0 + side * 6.0 + Vector3(0, 1.0, 0)), "to": _clear(body, base + dir * 22.0 + side * 4.0 + Vector3(0, 2.0, 0)), "look": body, "look_to": body, "fov": 60.0, "text": "",
			"do": func() -> void:
				CosmicFx.shock(base, 30.0, 2.6, 1.0, WORMS_TINT, true)
				CosmicFx.pillar(base, 200.0, 1.0, WORMS_TINT, 8.0)
				Game.shake(1.2)
				Game.hud.banner(WORMS, "ผู้ควบคุมทุกสิ่งในระบบ · มีแค่ร่าง ARGON ที่ทำร้ายมันได้", WORMS_TINT, 3.0)},
	], func() -> void:
		worms.rig.stop_action()
		(worms.rig as WormsModel).power = 0.0
		worms._wake()
		p.lock_input(0.35))
	return true


## The boss stays idle until the talking is over; `_wake` then starts the fight.
func boss_intro(boss: Enemy) -> void:
	if not _begin(boss):
		return
	Game.boss_intro_seen = true
	var p := Game.player
	var away := p.global_position - boss.global_position
	away.y = 0.0
	var dir := away.normalized() if away.length() > 0.1 else Vector3.BACK
	var at := boss.global_position + dir * BOSS_DISTANCE
	at.y = Game.ground_height(at.x, at.z) + 0.2
	p.halt_for_scene()
	p.place_for_scene(at, boss.global_position)
	boss.rig.rotation.y = atan2(dir.x, dir.z)
	boss.rig.stop_action()
	fade = 1.0

	var side := Vector3.UP.cross(dir)
	var base := boss.global_position
	var height := 3.2 if p.rig.is_supreme else 1.75
	var hero := at + Vector3(0, height, 0)
	var boss_face := base + Vector3(0, 4.9, 0)
	var boss_body := base + Vector3(0, 3.6, 0)
	var middle := at.lerp(base, 0.5) + Vector3(0, 2.6, 0)
	var talk := _boss_lines(p.rig.is_supreme)
	_start([
		{"seconds": 3.0, "from": _clear(hero, at + dir * 4.5 + side * 2.6 + Vector3(0, height + 1.4, 0)), "to": _clear(hero, at + dir * 3.2 + side * 1.8 + Vector3(0, height + 0.4, 0)), "look": boss_body, "look_to": boss_body, "fov": 48.0,
			"who": OVERLORD, "text": talk[0], "tint": OVERLORD_TINT},
		{"seconds": 3.0, "from": _clear(hero, at - dir * 3.4 + side * 1.2 + Vector3(0, height, 0)), "to": _clear(hero, at - dir * 2.8 + side * 0.7 + Vector3(0, height - 0.1, 0)), "look": hero, "look_to": hero, "fov": 38.0,
			"who": GEMINI, "text": talk[1], "tint": GEMINI_TINT},
		{"seconds": 3.0, "from": _clear(boss_face, base + dir * 7.0 - side * 2.6 + Vector3(0, 1.0, 0)), "to": _clear(boss_face, base + dir * 6.0 - side * 1.6 + Vector3(0, 1.3, 0)), "look": boss_face, "look_to": boss_face, "fov": 44.0,
			"who": OVERLORD, "text": talk[2], "tint": OVERLORD_TINT},
		{"seconds": 3.0, "from": _clear(middle, middle + side * 18.0 + Vector3(0, 0.6, 0)), "to": _clear(middle, middle + side * 15.0 + Vector3(0, 0.2, 0)), "look": middle, "look_to": middle, "fov": 46.0,
			"who": GEMINI, "text": talk[3], "tint": GEMINI_TINT, "do": func() -> void:
				if not p.rig.is_armed:
					p.rig.begin_summon(0.8)},
		{"seconds": 2.0, "from": _clear(boss_face, base + dir * 5.0 + Vector3(0, 3.4, 0)), "to": _clear(boss_face, base + dir * 3.8 + Vector3(0, 4.0, 0)), "look": boss_face, "look_to": boss_face, "fov": 40.0,
			"who": OVERLORD, "text": talk[4], "tint": OVERLORD_TINT, "do": func() -> void:
				boss.rig.play("boss_beam", 2.0, true)
				Game.shake(0.3)},
		{"seconds": 1.8, "from": _clear(boss_body, base + dir * 13.0 + side * 3.0 + Vector3(0, 0.6, 0)), "to": _clear(boss_body, base + dir * 11.0 + side * 2.0 + Vector3(0, 1.0, 0)), "look": boss_body, "look_to": boss_body, "fov": 58.0, "text": "",
			"do": func() -> void:
				Fx.ring(base, 14.0, Color(1.0, 0.16, 0.22), 0.8)
				Fx.burst(boss_body, Color(1.0, 0.16, 0.22), 50, 12.0, 0.09)
				Game.shake(0.8)
				Game.hud.banner(OVERLORD, "ผู้คุมระบบ", OVERLORD_TINT, 1.8)},
	], func() -> void:
		boss.rig.stop_action()
		boss._wake()
		p.lock_input(0.35))


## The first form falls, and OBLIVION climbs out of it. Returns false if a scene cannot start yet.
func boss_rebirth(boss: Enemy) -> bool:
	if not _begin(boss):
		return false
	var p := Game.player
	var away := p.global_position - boss.global_position
	away.y = 0.0
	var dir := away.normalized() if away.length() > 0.1 else Vector3.BACK
	var at := boss.global_position + dir * REBIRTH_DISTANCE
	at.y = Game.ground_height(at.x, at.z) + 0.2
	p.halt_for_scene()
	p.place_for_scene(at, boss.global_position)
	boss.rig.rotation.y = atan2(dir.x, dir.z)
	fade = 1.0

	var side := Vector3.UP.cross(dir)
	var base := boss.global_position
	var red := Color(1.0, 0.13, 0.2)
	var height := 3.2 if p.rig.is_supreme else 1.75
	var hero := at + Vector3(0, height, 0)
	var fallen := base + Vector3(0, 2.0, 0)
	var sky := base + Vector3(0, 14.0, 0) - dir * 16.0
	var body := base + Vector3(0, 9.0, 0)
	var face := base + Vector3(0, 13.0, 0)
	_start([
		{"seconds": 3.0, "from": _clear(fallen, base + dir * 9.0 + side * 3.0 + Vector3(0, 1.2, 0)), "to": _clear(fallen, base + dir * 7.5 + side * 2.0 + Vector3(0, 1.6, 0)), "look": fallen, "look_to": fallen, "fov": 42.0,
			"who": OVERLORD, "text": "ร่างนั้น... เป็นแค่ด่านแรกเท่านั้น", "tint": OVERLORD_TINT},
		{"seconds": 3.2, "from": _clear(sky, base + dir * 30.0 + side * 8.0 + Vector3(0, 2.0, 0)), "to": _clear(sky, base + dir * 26.0 + side * 5.0 + Vector3(0, 2.5, 0)), "look": sky, "look_to": sky, "fov": 56.0,
			"who": OVERLORD, "text": "รีบูตระบบ... ปลดล็อกสิทธิ์ทั้งหมด", "tint": OVERLORD_TINT,
			"do": func() -> void:
				(boss.rig as OverlordModel).open_hole()
				Fx.ring(base, 18.0, red, 1.0)
				Game.shake(0.8)},
		{"seconds": 1.7, "from": _clear(body, base + dir * 44.0 + side * 10.0 + Vector3(0, 0.8, 0)), "to": _clear(body, base + dir * 38.0 + side * 7.0 + Vector3(0, 1.2, 0)), "look": body, "look_to": body, "fov": 62.0, "text": "", "must": true,
			"do": func() -> void:
				boss.become_oblivion()
				CosmicFx.nova(body, 60.0, 1.2, red)
				CosmicFx.pillar(base, 300.0, 1.3, red, 26.0)
				CosmicFx.flash(Color(1.0, 0.2, 0.22), 0.95, 0.9)
				CosmicFx.shock(base, 60.0, 2.6, 1.2, red, true)
				CosmicFx.sparks(body, 700, 60.0)
				Game.shake(2.2)
				Game.hud.banner("OBLIVION", "SYSTEM OVERLORD · ร่างสุดท้าย", OVERLORD_TINT, 2.4)},
		{"seconds": 3.0, "from": _clear(hero, at - dir * 3.4 + side * 1.2 + Vector3(0, height, 0)), "to": _clear(hero, at - dir * 2.8 + side * 0.7 + Vector3(0, height - 0.1, 0)), "look": hero, "look_to": hero, "fov": 38.0,
			"who": GEMINI, "text": "เดี๋ยวนะ... พลังนี่มันคนละเรื่องเลย", "tint": GEMINI_TINT},
		{"seconds": 3.0, "from": _clear(face, at + dir * 3.0 + side * 3.0 + Vector3(0, 1.0, 0)), "to": _clear(face, at + side * 3.0 + Vector3(0, 0.8, 0)), "look": face, "look_to": face, "fov": 52.0,
			"who": OVERLORD, "text": "สิ่งที่แกทำลายได้ มีแค่เปลือกนอกของข้า", "tint": OVERLORD_TINT},
		{"seconds": 3.0, "from": _clear(face, base + dir * 16.0 + Vector3(0, 11.0, 0)), "to": _clear(face, base + dir * 13.0 + Vector3(0, 12.0, 0)), "look": face, "look_to": face, "fov": 44.0,
			"who": OVERLORD, "text": "จากนี้ไป พลังของแกไม่มีความหมายอะไรอีกแล้ว", "tint": OVERLORD_TINT,
			"do": func() -> void:
				boss.rig.play("boss_beam", 3.0, true)
				Game.shake(0.5)},
	], func() -> void:
		boss.rig.stop_action()
		boss._wake()
		p.lock_input(0.35))
	return true


## Gemini falls to OBLIVION; Zero Day locks the boss down and takes them through a backdoor.
## Returns false if a scene cannot start, so the caller can fall back to an ordinary death.
func rescue(boss: Enemy) -> bool:
	if not _begin(boss):
		return false
	var p := Game.player
	var away := p.global_position - boss.global_position
	away.y = 0.0
	var dir := away.normalized() if away.length() > 0.1 else Vector3.BACK
	var at := boss.global_position + dir * RESCUE_DISTANCE
	at.y = Game.ground_height(at.x, at.z) + 0.2
	boss.halt_for_scene()
	Game.boss_active = false
	p.defeat_for_scene()
	p.place_for_scene(at, boss.global_position)
	boss.rig.rotation.y = atan2(dir.x, dir.z)
	fade = 0.7

	var cameo := ZeroDayCameo.new()
	add_child(cameo)
	_on_abort = cameo.queue_free
	var side := Vector3.UP.cross(dir)
	var base := boss.global_position
	var hero := at + Vector3(0, 1.0, 0)
	var body := base + Vector3(0, 9.0, 0)
	var face := base + Vector3(0, 13.0, 0)
	var spot := at - dir * 8.0
	spot.y = Game.ground_height(spot.x, spot.z)
	var zero_face := spot + Vector3(0, 7.5, 0)
	var zero_body := spot + Vector3(0, 5.0, 0)
	var middle := at.lerp(base, 0.5) + Vector3(0, 6.0, 0)
	var walk_look := at.lerp(spot, 0.5) + Vector3(0, 3.0, 0)
	var door_look := at + dir * 5.0 + Vector3(0, 5.5, 0)
	_start([
		{"seconds": 3.0, "from": _clear(body, at + dir * 3.0 + side * 2.0 + Vector3(0, 0.7, 0)), "to": _clear(body, at + dir * 2.2 + side * 1.4 + Vector3(0, 0.6, 0)), "look": body, "look_to": face, "fov": 54.0,
			"who": OVERLORD, "text": "จบแล้ว... ตัวแปรสุดท้ายกำลังจะหายไป", "tint": OVERLORD_TINT},
		{"seconds": 2.8, "from": _clear(hero, at - dir * 2.6 + side * 1.4 + Vector3(0, 1.0, 0)), "to": _clear(hero, at - dir * 2.0 + side * 0.9 + Vector3(0, 0.9, 0)), "look": hero, "look_to": hero, "fov": 36.0,
			"who": GEMINI, "text": "ยัง... ยังไม่จบ...", "tint": GEMINI_TINT},
		{"seconds": 2.6, "from": _clear(face, base + dir * 16.0 + Vector3(0, 10.0, 0)), "to": _clear(face, base + dir * 13.0 + Vector3(0, 11.0, 0)), "look": face, "look_to": face, "fov": 44.0,
			"who": OVERLORD, "text": "ลาก่อน... ลบทิ้ง", "tint": OVERLORD_TINT,
			"do": func() -> void:
				boss.rig.play("o_cleave", 6.5, true)
				Game.shake(0.5)},
		{"seconds": 3.2, "from": _clear(zero_body, spot - dir * 12.0 + side * 6.0 + Vector3(0, 1.5, 0)), "to": _clear(zero_body, spot - dir * 10.0 + side * 4.0 + Vector3(0, 1.2, 0)), "look": zero_body, "look_to": zero_face, "fov": 50.0,
			"who": ZERO, "text": "00:00:00... ช่องโหว่ที่แกลืมปิดไงล่ะ", "tint": ZeroDayCameo.GREEN,
			"do": func() -> void:
				cameo.appear(spot, base)
				Game.hud.banner("ZERO DAY", "UNPATCHED", ZeroDayCameo.GREEN, 2.4)},
		{"seconds": 3.0, "from": _clear(middle, middle + side * 30.0 + Vector3(0, 1.0, 0)), "to": _clear(middle, middle + side * 26.0 + Vector3(0, 1.5, 0)), "look": middle, "look_to": middle, "fov": 52.0,
			"who": OVERLORD, "text": "ตรวจไม่พบ... นี่มันตัวอะไร", "tint": OVERLORD_TINT,
			"do": func() -> void:
				boss.rig.play("stagger", 8.0, true)
				cameo.lockdown(boss)},
		{"seconds": 3.0, "from": _clear(zero_face, spot + dir * 7.0 + side * 3.0 + Vector3(0, 6.0, 0)), "to": _clear(zero_face, spot + dir * 6.0 + side * 2.0 + Vector3(0, 6.6, 0)), "look": zero_face, "look_to": zero_face, "fov": 40.0,
			"who": ZERO, "text": "ล็อกมันไว้ได้ไม่นานหรอก ลุกเร็ว ไปกัน", "tint": ZeroDayCameo.GREEN},
		{"seconds": 3.2, "from": _clear(walk_look, walk_look + side * 24.0 + Vector3(0, 1.0, 0)), "to": _clear(walk_look, walk_look + side * 20.0 + Vector3(0, 0.6, 0)), "look": walk_look, "look_to": walk_look + dir * 3.0, "fov": 44.0,
			"who": GEMINI, "text": "นาย... เป็นใคร", "tint": GEMINI_TINT,
			"do": func() -> void: cameo.walk_to(p)},
		{"seconds": 2.8, "from": _clear(door_look, at - dir * 15.0 + side * 3.0 + Vector3(0, 2.2, 0)), "to": _clear(door_look, at - dir * 13.0 + side * 2.0 + Vector3(0, 2.4, 0)), "look": door_look, "look_to": door_look, "fov": 52.0,
			"who": ZERO, "text": "แค่บั๊กที่ระบบลืมลบน่ะ จับไว้แน่น ๆ ล่ะ", "tint": ZeroDayCameo.GREEN,
			"do": func() -> void: cameo.open_door(p, base)},
		{"seconds": 3.0, "from": _clear(door_look, at - dir * 13.0 + side * 2.0 + Vector3(0, 2.4, 0)), "to": _clear(door_look, at - dir * 8.0 + side * 0.5 + Vector3(0, 2.8, 0)), "look": door_look, "look_to": door_look, "fov": 52.0, "text": "",
			"do": func() -> void: cameo.go_through(p)},
		{"seconds": 3.4, "from": _clear(face, base + dir * 15.0 + side * 2.0 + Vector3(0, 11.0, 0)), "to": _clear(face, base + dir * 12.0 + side * 1.0 + Vector3(0, 12.0, 0)), "look": face, "look_to": face, "fov": 42.0,
			"who": OVERLORD, "text": "หนีไปก็ไม่พ้นหรอก... แล้วเจอกัน", "tint": OVERLORD_TINT,
			"do": func() -> void:
				boss.rig.play("boss_beam", 3.4, true)
				cameo.break_free(boss)},
	], func() -> void:
		cameo.queue_free()
		boss.rig.stop_action()
		fade = 1.0
		Game.after_rescue())
	return true


## Pressing start: Gemini comes down out of the sky and lands in the valley.
func opening() -> bool:
	if not _begin():
		return false
	var p := Game.player
	var foot := p.global_position
	var ahead := p.forward()
	var side := Vector3.UP.cross(ahead)
	var low := foot + Vector3(0, 1.0, 0)
	var top := foot + Vector3(0, 1.8, 0)
	var sky := foot + Vector3(0, 70, 0)
	p.halt_for_scene()
	p.drop_from_sky(foot, 120.0, OPENING_FALL)
	fade = 1.0
	_start([
		{"seconds": OPENING_FALL, "from": _clear(low, foot + ahead * 17.0 + side * 6.0 + Vector3(0, 1.0, 0)), "to": _clear(low, foot + ahead * 15.0 + side * 4.5 + Vector3(0, 0.9, 0)), "look": sky, "look_to": low, "fov": 64.0},
		{"seconds": 1.5, "from": _clear(low, foot + ahead * 4.6 + side * 1.8 + Vector3(0, 0.35, 0)), "to": _clear(low, foot + ahead * 3.8 + side * 1.2 + Vector3(0, 0.4, 0)), "look": low, "look_to": low, "fov": 42.0, "must": true,
			"do": func() -> void: p.land_for_scene(foot)},
		{"seconds": 1.6, "from": _clear(top, foot + ahead * 5.0 - side * 2.4 + Vector3(0, 0.5, 0)), "to": _clear(top, foot + ahead * 4.0 - side * 1.6 + Vector3(0, 0.8, 0)), "look": top, "look_to": top, "fov": 40.0},
	], func() -> void:
		p.halt_for_scene()
		p.lock_input(0.35)
		Game.hud.banner("เมืองดาวรุ่ง", "ออกทางประตูทองทางใต้ เพื่อไปหุบเขาอำพัน", TownMap.GOLD))
	return true


## Waking up in Safe Mode for the first time.
func haven_arrival() -> void:
	if not _begin():
		return
	var h := Game.haven
	var c := SafeHaven.CENTER
	var p := Game.player
	p.halt_for_scene()
	p.rig.play("rest", 2.0, true)
	fade = 1.0
	h.place_zero()
	h.hide_world_view()
	var zero_face := h.zero.global_position + Vector3(0, 7.5, 0)
	var hero := p.global_position + Vector3(0, 1.0, 0)
	var stand := p.global_position + Vector3(0, 1.75, 0)
	var view := h.world_view_position()
	var behind := p.global_position - (view - p.global_position).normalized() * 6.0 + Vector3(1.6, 1.4, 0)
	behind.y = p.global_position.y + 2.2
	var room := c + Vector3(0, 8, 0)
	h.zero.play("talk")
	_start([
		{"seconds": 4.0, "from": c + Vector3(30, 14, 30), "to": c + Vector3(-22, 10, 34), "look": room, "look_to": room, "fov": 58.0,
			"who": ZERO, "text": "ที่นี่คือ Safe Mode มุมเล็ก ๆ ที่ระบบสร้างไว้แล้วลืมลบ", "tint": ZeroDayCameo.GREEN},
		{"seconds": 3.0, "from": hero + p.forward() * 3.2 + Vector3(1.0, 0.1, 0), "to": hero + p.forward() * 2.6 + Vector3(0.6, 0, 0), "look": hero, "look_to": hero, "fov": 38.0,
			"who": GEMINI, "text": "ฉัน... ยังไม่ตายเหรอ", "tint": GEMINI_TINT},
		{"seconds": 3.6, "from": zero_face + Vector3(-5, -1.5, 8), "to": zero_face + Vector3(-3, -1, 7), "look": zero_face, "look_to": zero_face, "fov": 42.0,
			"who": ZERO, "text": "ยังหรอก ตราบใดที่อยู่ในนี้ OBLIVION ก็หาเราไม่เจอ", "tint": ZeroDayCameo.GREEN,
			"do": func() -> void: h.zero.play("talk")},
		{"seconds": 4.0, "from": c + Vector3(-30, 3.5, 16), "to": c + Vector3(30, 3.5, 16), "look": c + Vector3(0, 1.5, 12), "look_to": c + Vector3(0, 1.5, 12), "fov": 56.0,
			"who": ZERO, "text": "ทุกคนในห้องนี้เคยแพ้มันมาแล้ว นายไม่ใช่คนแรกหรอก", "tint": ZeroDayCameo.GREEN},
		{"seconds": 3.6, "from": zero_face + Vector3(-5, -1.5, 8), "to": zero_face + Vector3(-3, -1, 7), "look": zero_face, "look_to": zero_face, "fov": 42.0,
			"who": ZERO, "text": "แต่นายยังสู้ได้... เอานี่ไป พลังของนายที่ระบบล็อกไว้ ฉันแฮ็กคืนมาให้แล้ว", "tint": ZeroDayCameo.GREEN,
			"do": func() -> void:
				h.zero.play("talk")
				CosmicFx.inflow(hero, 40, 9.0, 0.9, CosmicFx.GOLD)},
		{"seconds": 3.4, "must": true, "from": hero + p.forward() * 3.4 + Vector3(1.4, 0.4, 0), "to": hero + p.forward() * 2.4 + Vector3(0.8, 0.2, 0), "look": hero, "look_to": hero, "fov": 40.0,
			"who": "SYSTEM", "text": "RESTORE COMPLETE · ปลดล็อกร่างที่ 2: ร่างสูงสุด", "tint": CosmicFx.GOLD,
			"do": func() -> void:
				Game.unlock_supreme(true)
				CosmicFx.shock(p.global_position, 10.0, 1.6, 0.8, CosmicFx.GOLD, true)
				Fx.burst(hero, CosmicFx.GOLD, 50, 6.0)
				Game.shake(0.4)},
		{"seconds": 3.0, "from": hero + p.forward() * 3.2 + Vector3(1.0, 0.1, 0), "to": hero + p.forward() * 2.6 + Vector3(0.6, 0, 0), "look": hero, "look_to": hero, "fov": 38.0,
			"who": GEMINI, "text": "รู้สึกได้เลย... พลังของดวงดาวกลับมาแล้ว", "tint": CosmicFx.GOLD},
		{"seconds": 3.4, "from": c + Vector3(6, 7, -22), "to": c + Vector3(3, 7.5, -28), "look": c + Vector3(0, 7, -44), "look_to": c + Vector3(0, 7, -44), "fov": 50.0,
			"who": ZERO, "text": "รอบนี้นายสู้มันได้แน่ พักให้หายก่อน แล้วประตูนั้นจะพานายกลับไป", "tint": ZeroDayCameo.GREEN},
		{"seconds": 6.2, "from": c + Vector3(14, 5, -8), "to": c + Vector3(8, 6, -24), "look": c + Vector3(3, 5, -18), "look_to": c + Vector3(0, 7, -44), "fov": 50.0, "text": "",
			"do": func() -> void: h.zero_walks_out(5.6)},
		{"seconds": 3.4, "from": stand + p.forward() * 3.4 + Vector3(1.2, 0.2, 0), "to": stand + p.forward() * 2.6 + Vector3(0.7, 0, 0), "look": stand, "look_to": stand, "fov": 36.0,
			"who": GEMINI, "text": "รอบนี้... ฉันไม่แพ้แน่", "tint": GEMINI_TINT,
			"do": func() -> void: p.rig.stop_action()},
		{"seconds": 6.0, "from": behind + Vector3(0, 1.0, 0), "to": behind + Vector3(0, 2.2, -3.0), "look": stand, "look_to": view, "fov": 54.0, "text": "",
			"do": func() -> void:
				p.turn_for_scene(view)
				h.show_world_view(2.4)},
	], func() -> void:
		h.zero_gone()
		h.show_world_view(0.2)
		p.rig.stop_action()
		p.place_for_scene(p.global_position, view)
		p.lock_input(0.35)
		Game.hud.banner("ปลดล็อกร่างที่ 2 แล้ว", "SAFE MODE · กด T เพื่อแปลงเป็นร่างสูงสุด", CosmicFx.GOLD, 4.0))


## OBLIVION falls, names the one behind it, and Gemini's third form wakes to answer. `on_done` runs after.
func oblivion_last_words(on_done: Callable) -> bool:
	if not _begin():
		return false
	var p := Game.player
	p.halt_for_scene()
	var wreck: Vector3 = Game.overlord.global_position
	var away := p.global_position - wreck
	away.y = 0.0
	var dir := away.normalized() if away.length() > 0.1 else Vector3.BACK
	var side := Vector3.UP.cross(dir)
	var foot := p.global_position
	var height := 3.2 if p.rig.is_supreme else 1.75
	var hero := foot + Vector3(0, height, 0)
	var low := wreck + Vector3(0, 3.0, 0)
	var red := Color(1.0, 0.13, 0.2)
	_start([
		{"seconds": 3.4, "from": _clear(low, wreck + dir * 12.0 + side * 5.0 + Vector3(0, 2.0, 0)), "to": _clear(low, wreck + dir * 9.0 + side * 3.5 + Vector3(0, 1.6, 0)), "look": low, "look_to": low, "fov": 46.0,
			"who": OVERLORD, "text": "แกคิดว่าชนะแล้วเหรอ... ข้าเป็นแค่โปรแกรมหนึ่งของเขาเท่านั้น", "tint": OVERLORD_TINT,
			"do": func() -> void:
				Fx.burst(low, red, 40, 6.0)
				Game.shake(0.3)},
		{"seconds": 3.6, "from": _clear(low, wreck + dir * 7.0 - side * 3.0 + Vector3(0, 1.0, 0)), "to": _clear(low, wreck + dir * 6.0 - side * 2.0 + Vector3(0, 1.4, 0)), "look": low, "look_to": low, "fov": 40.0,
			"who": OVERLORD, "text": "ยังมีอีกตัว... WORMS ผู้ควบคุมทุกสิ่ง แกไม่มีทางสู้เขาได้หรอก", "tint": OVERLORD_TINT,
			"do": func() -> void:
				CosmicFx.flash(Color(1.0, 0.06, 0.15), 0.4, 0.8)
				Game.shake(0.5)},
		{"seconds": 3.0, "from": _clear(hero, foot - dir * 3.4 + side * 1.2 + Vector3(0, height, 0)), "to": _clear(hero, foot - dir * 2.8 + side * 0.7 + Vector3(0, height - 0.1, 0)), "look": hero, "look_to": hero, "fov": 38.0,
			"who": GEMINI, "text": "ไม่ว่าจะเป็นใคร... ฉันจะไปหยุดมันเอง", "tint": GEMINI_TINT,
			"do": func() -> void: Fx.burst(low, red, 80, 9.0)},
		{"seconds": 3.4, "must": true, "from": _clear(hero, foot + dir * 6.0 + side * 3.0 + Vector3(0, 1.0, 0)), "to": _clear(hero, foot + dir * 4.5 + side * 2.0 + Vector3(0, 1.4, 0)), "look": hero, "look_to": hero + Vector3(0, 2.0, 0), "fov": 46.0,
			"who": "SYSTEM", "text": "ตรวจพบภัยคุกคามระดับสูงสุด · ปลดล็อกร่างที่ 3: GEMINI ARGON", "tint": Color(0.49, 1.0, 0.78),
			"do": func() -> void:
				Game.unlock_argon(true)
				CosmicFx.shock(foot, 16.0, 2.0, 0.9, ARGON_TINT, true)
				CosmicFx.inflow(hero, 50, 10.0, 0.9, ARGON_TINT)
				Fx.burst(hero, ARGON_TINT, 60, 7.0)
				Game.shake(0.6)},
		{"seconds": 2.8, "from": _clear(hero, foot - dir * 3.0 - side * 1.4 + Vector3(0, height + 0.2, 0)), "to": _clear(hero, foot - dir * 2.6 - side * 1.0 + Vector3(0, height, 0)), "look": hero, "look_to": hero, "fov": 36.0,
			"who": GEMINI, "text": "พลังนี้... เก็บไว้ใช้กับเจ้านั่นคนเดียวพอ", "tint": ARGON_TINT},
	], func() -> void:
		p.lock_input(0.35)
		Game.hud.banner("ปลดล็อกร่างที่ 3 · ARGON", "กด G เพื่อแปลงร่าง · ใช้สู้กับ WORMS", ARGON_TINT, 4.0)
		on_done.call())
	return true


## A word with one of the survivors in Safe Mode.
func npc_talk(npc: Node3D) -> void:
	if not _begin():
		return
	var p := Game.player
	p.halt_for_scene()
	var to := npc.global_position - p.global_position
	to.y = 0.0
	p.rig.rotation.y = atan2(to.x, to.z)
	var near := -to.normalized()
	var side := Vector3.UP.cross(near)
	var tall: float = npc.get("height")
	var face := npc.global_position + Vector3(0, tall * 0.75, 0)
	var back := near * maxf(tall * 1.4, 3.2) + Vector3(0, 0.5, 0)
	_start([
		{"seconds": 3.4, "from": face + back + side * 1.4, "to": face + back * 0.85 + side * 0.9, "look": face, "look_to": face, "fov": 40.0,
			"who": npc.get("display_name"), "text": npc.call("next_line"), "tint": npc.get("tint")},
	], func() -> void: p.lock_input(0.35))


func _boss_lines(supreme: bool) -> Array:
	if supreme:
		return [
			"พลังระดับนี้... ไม่อยู่ในการคำนวณของข้าเลย",
			"แกขังดวงดาวไว้นานพอแล้ว",
			"ไม่มีอะไรอยู่เหนือระบบ ต่อให้เป็นพระเจ้าก็ตาม",
			"งั้นรีบคำนวณใหม่ซะ ก่อนจะไม่ทัน",
			"รับทราบ... เริ่มลบ",
		]
	return [
		"หยุดตรงนั้น เขตนี้ห้ามบุคคลภายนอกเข้า",
		"ฉันชื่อ Gemini มาเอาแสงดาวของหุบเขานี้คืน",
		"แสงดาวไม่มีอยู่ในระบบของข้า และจะไม่มีวันมี",
		"งั้นคงต้องแก้ระบบของแก ด้วยดาบเล่มนี้แล้วล่ะ",
		"รับทราบ... เริ่มลบ",
	]


## Time stops for everyone but the cast. `actor` is the one enemy that keeps moving.
func _begin(actor: Enemy = null) -> bool:
	if _active or not Game.cutscenes_on or Game.state != "play":
		return false
	_active = true
	Engine.time_scale = 1.0
	Game.state = "cutscene"
	_frozen.clear()
	for enemy in Game.enemies:
		if enemy != actor:
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			_frozen.append(enemy)
	return true


func _start(steps: Array[Dictionary], on_done: Callable) -> void:
	_steps = steps
	_on_done = on_done
	index = -1
	_camera.current = true
	Game.camera = _camera
	_next()
	_aim()


func _next() -> void:
	index += 1
	if index >= _steps.size():
		_finish()
		return
	var step := _steps[index]
	_clock = 0.0
	if step.has("text"):
		line = step["text"]
		speaker = step.get("who", "")
		tint = step.get("tint", Color.WHITE)
		letters = 0.0
	_length = step["seconds"]
	if step.has("text") and line != "":
		_length = maxf(_length, line.length() / LETTERS_PER_SECOND + READ_TIME)
	if step.has("do"):
		(step["do"] as Callable).call()


func _skip() -> void:
	for i in range(index + 1, _steps.size()):
		if _steps[i].get("must", false):
			(_steps[i]["do"] as Callable).call()
	_finish()


func _finish() -> void:
	_release()
	_on_abort = Callable()
	Game.state = "play"
	_on_done.call()


## Gives everything back without playing the ending. Used when leaving for the menu.
func abort() -> void:
	if _active:
		_release()
		if _on_abort.is_valid():
			_on_abort.call()
		_on_abort = Callable()
	bars = 0.0
	fade = 0.0


func _release() -> void:
	_active = false
	line = ""
	speaker = ""
	for enemy in _frozen:
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
	_frozen.clear()
	var view := Game.player.view_camera()
	view.current = true
	Game.camera = view


## Pulls a shot in front of anything solid between it and its subject.
func _clear(subject: Vector3, wanted: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(subject, wanted, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var at := wanted if hit.is_empty() else subject.lerp(hit["position"], 0.88)
	at.y = maxf(at.y, Game.ground_height(at.x, at.z) + 0.4)
	return at


func _aim() -> void:
	var step := _steps[index]
	var t := smoothstep(0.0, 1.0, clampf(_clock / _length, 0.0, 1.0))
	var from: Vector3 = step["from"]
	var look: Vector3 = step["look"]
	_camera.global_position = from.lerp(step["to"], t)
	_camera.fov = step["fov"]
	var aim := look.lerp(step["look_to"], t)
	if not aim.is_equal_approx(_camera.global_position):
		_camera.look_at(aim, Vector3.UP)
	var view := Game.player.view_camera() # It takes the shake; a scene borrows the result.
	_camera.h_offset = view.h_offset
	_camera.v_offset = view.v_offset


func _pressed_next() -> bool:
	return Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("roll") or Input.is_action_just_pressed("interact")


func _process(delta: float) -> void:
	bars = move_toward(bars, 1.0 if _active else 0.0, delta * 3.5)
	fade = move_toward(fade, 0.0, delta * 2.2)
	if not _active:
		return
	_clock += delta
	letters = minf(letters + delta * LETTERS_PER_SECOND, line.length())
	if Input.is_action_just_pressed("cutscene_skip"):
		_skip()
		return
	if line != "" and _clock > INPUT_DELAY and _pressed_next():
		if letters < line.length():
			letters = line.length()
		else:
			_next()
			if not _active:
				return
	if _clock >= _length:
		_next()
		if not _active:
			return
	_aim()
