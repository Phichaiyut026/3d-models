class_name Hud
extends Control
## In-game overlay, drawn directly so it needs no art assets.

const WHITE := Color(0.95, 0.94, 1.0)
const MUTED := Color(0.72, 0.7, 0.86)
const GOLD := Color(0.96, 0.8, 0.46)
const LAVENDER := Color(0.7, 0.6, 1.0)
const SKEW := 0.65
const ARENA := Vector3(22, 0, -112)

var font: Font
var show_fps := false
var screen_flash: ColorRect
var screen_shatter: ColorRect
var _panel := StyleBoxFlat.new()
var _panel_lit := StyleBoxFlat.new()
var _key := StyleBoxFlat.new()
var _banner_title := ""
var _banner_sub := ""
var _banner_color := WHITE
var _banner_left := 0.0
var _banner_length := 1.0
var _shown_hp := 1.0
var _boss_shown := 1.0
var _last_hp := -1.0
var _hurt := 0.0
var _clock := 0.0


func _ready() -> void:
	font = ThemeDB.fallback_font
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modulate.a = 0.0
	_panel.bg_color = Color(0.05, 0.04, 0.13, 0.74)
	_panel.border_color = Color(0.7, 0.6, 1.0, 0.32)
	_panel.set_border_width_all(1)
	_panel.set_corner_radius_all(9)
	_panel_lit.bg_color = Color(0.2, 0.14, 0.42, 0.85)
	_panel_lit.border_color = GOLD
	_panel_lit.set_border_width_all(2)
	_panel_lit.set_corner_radius_all(9)
	_key.bg_color = Color(0.93, 0.91, 1.0, 0.94)
	_key.set_corner_radius_all(4)
	screen_flash = _overlay()
	screen_shatter = _overlay()
	var shatter_material := ShaderMaterial.new()
	shatter_material.shader = preload("res://shaders/screen_shatter.gdshader")
	screen_shatter.material = shatter_material


func _overlay() -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.visible = false
	add_child(rect)
	return rect


func banner(title: String, sub: String, color: Color, seconds := 3.0) -> void:
	_banner_title = title
	_banner_sub = sub
	_banner_color = color
	_banner_left = seconds
	_banner_length = seconds


func clear() -> void:
	_banner_left = 0.0
	_hurt = 0.0
	_last_hp = -1.0


func _process(delta: float) -> void:
	_clock += delta
	_banner_left = maxf(0.0, _banner_left - delta)
	modulate.a = move_toward(modulate.a, 0.0 if Game.state == "title" else 1.0, delta * 3.0)
	if Game.player != null:
		if _last_hp >= 0.0 and Game.player.hp < _last_hp - 1.0:
			_hurt = 1.0
		_last_hp = Game.player.hp
	_hurt = maxf(0.0, _hurt - delta * 2.2)
	queue_redraw()


func _draw() -> void:
	if Game.player == null or Game.camera == null or modulate.a <= 0.0:
		return
	_draw_vignette()
	_draw_enemy_bars()
	_draw_lock_on()
	_draw_vitals()
	_draw_compass()
	_draw_objective()
	_draw_slots()
	_draw_skills()
	_draw_stardust()
	_draw_boss()
	_draw_prompt()
	if Game.state == "dead":
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.0, 0.03, 0.5))
	_draw_banner()


# ----------------------------------------------------------------- primitives

func _text(pos: Vector2, value: String, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string_outline(font, pos, value, align, width, font_size, 4, Color(0.02, 0.01, 0.07, color.a * 0.75))
	draw_string(font, pos, value, align, width, font_size, color)


func _text_width(value: String, font_size: int) -> float:
	return font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _centered(y: float, value: String, font_size: int, color: Color) -> void:
	_text(Vector2(0, y), value, font_size, color, HORIZONTAL_ALIGNMENT_CENTER, size.x)


func _star_points(center: Vector2, r: float, waist := 0.24, spin := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 8:
		var a := i * PI * 0.25 - PI * 0.5 + spin
		pts.append(center + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * waist))
	return pts


func _slant(pos: Vector2, width: float, height: float) -> PackedVector2Array:
	var lean := height * SKEW
	return PackedVector2Array([pos + Vector2(lean, 0), pos + Vector2(width + lean, 0), pos + Vector2(width, height), pos + Vector2(0, height)])


## A slanted meter. `trail` is the pale segment showing damage just taken.
func _bar(pos: Vector2, width: float, height: float, ratio: float, top: Color, bottom: Color, trail := -1.0) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	var back := _slant(pos, width, height)
	draw_colored_polygon(back, Color(0.03, 0.02, 0.09, 0.82))
	if trail > ratio:
		draw_colored_polygon(_slant(pos, width * minf(trail, 1.0), height), Color(1.0, 0.86, 0.62, 0.8))
	if ratio > 0.001:
		draw_polygon(_slant(pos, width * ratio, height), PackedColorArray([top, top, bottom, bottom]))
	var outline := back.duplicate()
	outline.append(back[0])
	draw_polyline(outline, Color(0.8, 0.74, 1.0, 0.42), 1.0, true)


func _keycap(pos: Vector2, value: String, font_size := 13) -> float:
	var width := maxf(_text_width(value, font_size) + 12.0, 22.0)
	var height := font_size + 9.0
	draw_style_box(_key, Rect2(pos, Vector2(width, height)))
	draw_string(font, pos + Vector2(0, font_size + 2.5), value, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, Color(0.08, 0.05, 0.2))
	return width


# ------------------------------------------------------------------- elements

func _draw_vignette() -> void:
	var p := Game.player
	var low := 1.0 - smoothstep(0.12, 0.3, p.hp / p.max_hp)
	var strength := maxf(_hurt * 0.55, low * (0.26 + 0.12 * sin(_clock * 5.0)))
	if strength <= 0.01 or Game.state == "dead":
		return
	var edge := Color(0.75, 0.06, 0.14, strength)
	var clear_edge := Color(edge, 0.0)
	var depth := 190.0
	var w := size.x
	var h := size.y
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(depth, 0), Vector2(depth, h), Vector2(0, h)]), PackedColorArray([edge, clear_edge, clear_edge, edge]))
	draw_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w - depth, 0), Vector2(w - depth, h), Vector2(w, h)]), PackedColorArray([edge, clear_edge, clear_edge, edge]))
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(w, 0), Vector2(w, depth * 0.7), Vector2(0, depth * 0.7)]), PackedColorArray([edge, edge, clear_edge, clear_edge]))
	draw_polygon(PackedVector2Array([Vector2(0, h), Vector2(w, h), Vector2(w, h - depth * 0.7), Vector2(0, h - depth * 0.7)]), PackedColorArray([edge, edge, clear_edge, clear_edge]))


func _draw_vitals() -> void:
	var p := Game.player
	var ratio := clampf(p.hp / p.max_hp, 0.0, 1.0)
	_shown_hp = move_toward(_shown_hp, ratio, get_process_delta_time() * 0.45) if _shown_hp > ratio else ratio

	var emblem := Vector2(66, 62)
	var ring := PackedVector2Array()
	for i in 8:
		var a := i * TAU / 8.0 + PI / 8.0
		ring.append(emblem + Vector2(cos(a), sin(a)) * 38.0)
	draw_colored_polygon(ring, Color(0.06, 0.04, 0.16, 0.9))
	ring.append(ring[0])
	draw_polyline(ring, GOLD, 2.0, true)
	draw_colored_polygon(_star_points(emblem, 27.0, 0.22, sin(_clock * 0.6) * 0.08), GOLD if p.rig.is_supreme else LAVENDER)
	draw_colored_polygon(_star_points(emblem, 15.0, 0.18, sin(_clock * 0.6) * 0.08), Color.WHITE)
	if p.upgrades > 0:
		var badge := emblem + Vector2(27, 26)
		draw_circle(badge, 12.0, GOLD)
		draw_string(font, badge + Vector2(-12, 5), str(p.upgrades), HORIZONTAL_ALIGNMENT_CENTER, 24, 14, Color(0.1, 0.06, 0.2))

	var left := 112.0
	var hp_width := minf(310.0 + (p.max_hp - 420.0) * 0.3, 460.0)
	_bar(Vector2(left, 34), hp_width, 18, ratio, Color(1.0, 0.34, 0.42), Color(0.68, 0.08, 0.26), _shown_hp)
	_text(Vector2(left + 12, 49), "%d / %d" % [ceili(p.hp), roundi(p.max_hp)], 14, WHITE)
	_bar(Vector2(left - 6, 58), 236, 9, p.fp / p.max_fp, Color(0.5, 0.74, 1.0), Color(0.2, 0.36, 0.9))
	var winded := p.stamina < p.max_stamina * 0.15 and fmod(_clock, 0.4) < 0.2
	var top := Color(1.0, 0.8, 0.5) if winded else Color(0.66, 0.96, 0.72)
	var bottom := Color(0.86, 0.5, 0.2) if winded else Color(0.2, 0.68, 0.5)
	_bar(Vector2(left - 11, 72), 270, 9, p.stamina / p.max_stamina, top, bottom)


func _draw_compass() -> void:
	var center := Vector2(size.x * 0.5, 40)
	var width := 440.0
	draw_style_box(_panel, Rect2(center - Vector2(width * 0.5 + 16, 24), Vector2(width + 32, 48)))
	var forward := -Game.camera.global_transform.basis.z
	var heading := rad_to_deg(atan2(forward.x, -forward.z))
	var labels := {0: "N", 90: "E", 180: "S", 270: "W"}
	for degree in range(0, 360, 15):
		var x: float = center.x + wrapf(degree - heading, -180.0, 180.0) * 2.0
		if absf(x - center.x) > width * 0.5:
			continue
		var alpha: float = clampf((1.0 - absf(x - center.x) / (width * 0.5)) * 2.2, 0.0, 1.0)
		if labels.has(degree):
			draw_string(font, Vector2(x - 20, center.y + 7), labels[degree], HORIZONTAL_ALIGNMENT_CENTER, 40, 18, Color(GOLD if degree == 0 else WHITE, alpha))
		else:
			var tall := degree % 45 == 0
			draw_line(Vector2(x, center.y - (8 if tall else 4)), Vector2(x, center.y + (8 if tall else 4)), Color(MUTED, alpha * 0.8), 1.5 if tall else 1.0)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-7, -24), center + Vector2(7, -24), center + Vector2(0, -14)]), GOLD)
	var from := Game.player.global_position
	if Game.checkpoint != null:
		_compass_marker(Game.checkpoint.global_position - from, heading, center, width, LAVENDER)
	if not Game.boss_defeated:
		_compass_marker(ARENA - from, heading, center, width, GOLD)


func _compass_marker(to: Vector3, heading: float, center: Vector2, width: float, color: Color) -> void:
	var offset := wrapf(rad_to_deg(atan2(to.x, -to.z)) - heading, -180.0, 180.0) * 2.0
	draw_colored_polygon(_star_points(Vector2(center.x + clampf(offset, -width * 0.5, width * 0.5), center.y - 12.0), 8.0, 0.3), color)


func _draw_objective() -> void:
	var right := size.x - 30.0
	var title := "เป้าหมาย"
	var goal := "ไปยังหอดาวทางเหนือ"
	var detail := "%d ม." % roundi(Game.player.global_position.distance_to(ARENA))
	if Game.boss_defeated:
		goal = "หุบเขาอำพันกลับคืนสู่ความสงบ"
		detail = ""
	elif Game.boss_active:
		goal = "โค่น " + Game.BOSS_NAME
		detail = ""
	var box_width := _text_width(goal, 20) + 36.0
	var box_height := 86.0 if detail != "" else 66.0
	draw_style_box(_panel, Rect2(Vector2(right + 2.0 - box_width, 16), Vector2(box_width + 12.0, box_height)))
	right -= 8.0
	_text(Vector2(0, 40), title, 15, GOLD, HORIZONTAL_ALIGNMENT_RIGHT, right)
	_text(Vector2(0, 66), goal, 20, WHITE, HORIZONTAL_ALIGNMENT_RIGHT, right)
	if detail != "":
		_text(Vector2(0, 90), detail, 15, MUTED, HORIZONTAL_ALIGNMENT_RIGHT, right)
	if show_fps:
		_text(Vector2(0, 126), "%d FPS" % Engine.get_frames_per_second(), 15, WHITE, HORIZONTAL_ALIGNMENT_RIGHT, right)


func _draw_slots() -> void:
	var p := Game.player
	var y := size.y - 94.0
	var armed := p.rig.is_armed
	_slot(Vector2(30, y), "blade", "LMB", armed, p.state == "attack", "")
	_slot(Vector2(108, y), "kite", "RMB", true, p.blocking, "")
	_slot(Vector2(186, y), "star", "F", p.fp >= 22.0, p.state == "cast", "")
	_slot(Vector2(264, y), "vial", "R", p.flasks > 0, p.state == "drink", str(p.flasks))
	var hint := "เก็บดาบ" if armed else "เสกดาบ"
	draw_style_box(_panel, Rect2(Vector2(30, y - 42), Vector2(_text_width(hint, 15) + 50.0, 28)))
	var hint_x := 37.0 + _keycap(Vector2(37, y - 38), "X") + 7.0
	_text(Vector2(hint_x, y - 23), hint, 15, WHITE)
	var form := "กลับร่างเดิม" if p.rig.is_supreme else "แปลงร่าง"
	var ready := p._transform_cooldown <= 0.0
	draw_style_box(_panel_lit if p.state == "transform" else _panel, Rect2(Vector2(30, y - 76), Vector2(_text_width(form, 15) + 50.0, 28)))
	var form_x := 37.0 + _keycap(Vector2(37, y - 72), "T") + 7.0
	_text(Vector2(form_x, y - 57), form, 15, (GOLD if not p.rig.is_supreme else WHITE) if ready else Color(MUTED, 0.6))
	if p.rig.is_supreme:
		var flight := "ลงพื้น · Space ขึ้น · Ctrl ลง" if p.flying else "บิน"
		draw_style_box(_panel_lit if p.flying else _panel, Rect2(Vector2(30, y - 110), Vector2(_text_width(flight, 15) + 50.0, 28)))
		var flight_x := 37.0 + _keycap(Vector2(37, y - 106), "V") + 7.0
		_text(Vector2(flight_x, y - 91), flight, 15, WHITE)


## The powers of whichever form the warrior is in.
func _draw_skills() -> void:
	var p := Game.player
	var keys := p.skill_keys()
	var box := Vector2(92, 66)
	var gap := 8.0
	var x := size.x - 30.0 - (box.x + gap) * keys.size() + gap
	var y := size.y - 148.0
	for i in keys.size():
		var key: String = keys[i]
		var skill: Dictionary = p.skill_info(key)
		var rect := Rect2(Vector2(x + i * (box.x + gap), y), box)
		var lit: bool = p.state == "skill" and p._skill_key == key
		var usable := p.skill_ready(key)
		var tint: Color = skill["tint"]
		draw_style_box(_panel_lit if lit else _panel, rect)
		var center := rect.position + Vector2(box.x * 0.5, 25)
		draw_colored_polygon(_star_points(center, 18.0, 0.28, i * 0.4), Color(tint, 1.0 if usable else 0.3))
		draw_colored_polygon(_star_points(center, 8.0, 0.3, i * 0.4), Color(1, 1, 1, 1.0 if usable else 0.3))
		_text(rect.position + Vector2(0, 60), skill["name"], 13, WHITE if usable else Color(MUTED, 0.75), HORIZONTAL_ALIGNMENT_CENTER, box.x)
		var wait := p.skill_cooldown(key)
		if wait > 0.0:
			var share: float = clampf(wait / skill["cooldown"], 0.0, 1.0)
			draw_rect(Rect2(rect.position, Vector2(box.x, box.y * share)), Color(0.02, 0.01, 0.07, 0.55))
			_text(rect.position + Vector2(0, 33), str(ceili(wait)), 22, WHITE, HORIZONTAL_ALIGNMENT_CENTER, box.x)
		_keycap(rect.position + Vector2(-5, -7), str(i + 1), 11)


func _slot(pos: Vector2, icon: String, key: String, enabled: bool, lit: bool, count: String) -> void:
	var box := Vector2(68, 68)
	var center := pos + box * 0.5
	draw_style_box(_panel_lit if lit else _panel, Rect2(pos, box))
	var a := 1.0 if enabled else 0.32
	match icon:
		"blade":
			draw_colored_polygon(PackedVector2Array([center + Vector2(19, -23), center + Vector2(23, -19), center + Vector2(-6, 10), center + Vector2(-11, 5)]), Color(0.7, 0.58, 1.0, a))
			draw_line(center + Vector2(-16, 2), center + Vector2(-2, 16), Color(GOLD, a), 3.5)
			draw_line(center + Vector2(-10, 10), center + Vector2(-20, 20), Color(0.6, 0.48, 0.42, a), 3.5)
		"kite":
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -24), center + Vector2(16, -8), center + Vector2(13, 12), center + Vector2(0, 25), center + Vector2(-13, 12), center + Vector2(-16, -8)]), Color(0.42, 0.28, 0.88, a))
			draw_colored_polygon(_star_points(center, 11.0, 0.3), Color(0.82, 0.92, 1.0, a))
		"star":
			draw_colored_polygon(_star_points(center, 24.0, 0.24), Color(LAVENDER, a))
			draw_colored_polygon(_star_points(center, 12.0, 0.2), Color(1, 1, 1, a))
		"vial":
			draw_circle(center + Vector2(0, 7), 16.0, Color(0.32, 0.54, 1.0, a))
			draw_rect(Rect2(center + Vector2(-5, -22), Vector2(10, 16)), Color(0.72, 0.82, 0.98, a))
			draw_rect(Rect2(center + Vector2(-7, -25), Vector2(14, 5)), Color(GOLD, a))
			draw_circle(center + Vector2(-6, 2), 4.0, Color(1, 1, 1, 0.65 * a))
	_keycap(pos + Vector2(-5, -7), key, 11)
	if count != "":
		_text(pos + Vector2(0, 62), count, 18, WHITE, HORIZONTAL_ALIGNMENT_RIGHT, box.x - 6.0)


func _draw_stardust() -> void:
	var value := str(Game.stardust)
	var width := maxf(_text_width(value, 20) + 66.0, 120.0)
	var rect := Rect2(size - Vector2(width + 30, 62), Vector2(width, 40))
	draw_style_box(_panel, rect)
	draw_colored_polygon(_star_points(rect.position + Vector2(24, 20), 12.0, 0.26), GOLD)
	_text(rect.position + Vector2(0, 27), value, 20, WHITE, HORIZONTAL_ALIGNMENT_RIGHT, width - 14.0)


func _draw_enemy_bars() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for enemy in Game.enemies:
		if enemy.is_boss or not enemy.is_alive():
			continue
		if not enemy.is_engaged() and now - enemy.last_hit_time > 4.0:
			continue
		var world_pos := enemy.head_position()
		if Game.camera.is_position_behind(world_pos) or world_pos.distance_to(Game.camera.global_position) > 42.0:
			continue
		var at := Game.camera.unproject_position(world_pos)
		_bar(at - Vector2(45, 3), 90, 6, enemy.hp / enemy.max_hp, Color(1.0, 0.36, 0.4), Color(0.7, 0.1, 0.24))


func _draw_boss() -> void:
	if not Game.boss_active or Game.boss == null or not Game.boss.is_alive():
		return
	var ratio := Game.boss.hp / Game.boss.max_hp
	_boss_shown = move_toward(_boss_shown, ratio, get_process_delta_time() * 0.35) if _boss_shown > ratio else ratio
	var width := minf(size.x * 0.46, 760.0)
	var left := (size.x - width) * 0.5
	var y := size.y - 58.0
	_centered(y - 12.0, Game.BOSS_NAME, 22, WHITE)
	_bar(Vector2(left, y), width, 15, ratio, Color(1.0, 0.56, 0.3), Color(0.74, 0.12, 0.2), _boss_shown)
	# Below this mark the warden fights harder.
	draw_line(Vector2(left + width * 0.5 + 5, y), Vector2(left + width * 0.5, y + 15), GOLD, 2.0)
	var name_half := _text_width(Game.BOSS_NAME, 22) * 0.5 + 24.0
	draw_colored_polygon(_star_points(Vector2(size.x * 0.5 - name_half, y - 19.0), 9.0, 0.28), GOLD)
	draw_colored_polygon(_star_points(Vector2(size.x * 0.5 + name_half, y - 19.0), 9.0, 0.28), GOLD)


func _draw_lock_on() -> void:
	var target := Game.player.target
	if target == null or Game.camera.is_position_behind(target.chest_position()):
		return
	var at := Game.camera.unproject_position(target.chest_position())
	var pts := _star_points(at, 24.0, 0.42, _clock * 1.3)
	pts.append(pts[0])
	draw_polyline(pts, Color(GOLD, 0.95), 2.0, true)
	draw_circle(at, 3.0, Color.WHITE)


func _draw_prompt() -> void:
	if Game.state != "play" or Game.player.state != "move":
		return
	if Game.nearest_shrine(Game.player.global_position, 3.6) == null:
		return
	var cost := Game.player.upgrade_cost()
	var rest := "พักผ่อน"
	var boost := "เสริมพลัง  %d" % cost
	var total := _text_width(rest, 19) + _text_width(boost, 19) + 118.0
	var box := Rect2(Vector2((size.x - total) * 0.5, size.y * 0.74), Vector2(total, 48))
	draw_style_box(_panel, box)
	var x := box.position.x + 20.0
	x += _keycap(Vector2(x, box.position.y + 13), "E") + 8.0
	_text(Vector2(x, box.position.y + 31), rest, 19, WHITE)
	x += _text_width(rest, 19) + 30.0
	var can_pay := Game.stardust >= cost
	x += _keycap(Vector2(x, box.position.y + 13), "U") + 8.0
	_text(Vector2(x, box.position.y + 31), boost, 19, GOLD if can_pay else Color(MUTED, 0.7))


func _draw_banner() -> void:
	if _banner_left <= 0.0:
		return
	var elapsed := _banner_length - _banner_left
	var alpha := minf(smoothstep(0.0, 0.45, elapsed), smoothstep(0.0, 0.7, _banner_left))
	var y := size.y * 0.4
	var mid := size.x * 0.5
	var shade := Color(0.02, 0.01, 0.08, 0.62 * alpha)
	var none := Color(shade, 0.0)
	var band_top := y - 74.0
	var band_bottom := y + 58.0
	draw_polygon(PackedVector2Array([Vector2(0, band_top), Vector2(mid, band_top), Vector2(mid, band_bottom), Vector2(0, band_bottom)]), PackedColorArray([none, shade, shade, none]))
	draw_polygon(PackedVector2Array([Vector2(mid, band_top), Vector2(size.x, band_top), Vector2(size.x, band_bottom), Vector2(mid, band_bottom)]), PackedColorArray([shade, none, none, shade]))
	_centered(y, _banner_title, 58, Color(_banner_color, alpha))
	var line_y := y + 16.0
	draw_line(Vector2(mid - 210, line_y), Vector2(mid - 18, line_y), Color(_banner_color, alpha * 0.7), 1.5)
	draw_line(Vector2(mid + 18, line_y), Vector2(mid + 210, line_y), Color(_banner_color, alpha * 0.7), 1.5)
	draw_colored_polygon(_star_points(Vector2(mid, line_y), 11.0, 0.26), Color(_banner_color, alpha))
	if _banner_sub != "":
		_centered(y + 47.0, _banner_sub, 20, Color(WHITE, alpha))
