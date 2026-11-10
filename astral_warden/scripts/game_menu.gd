class_name GameMenu
extends Control
## Main menu, pause menu, controls, settings and the loading cover.

const WHITE := Color(0.95, 0.94, 1.0)
const MUTED := Color(0.72, 0.7, 0.86)
const GOLD := Color(0.96, 0.8, 0.46)
const LAVENDER := Color(0.7, 0.6, 1.0)

const CONTROLS := [
	["W A S D", "เดิน"], ["เมาส์", "หมุนกล้อง"],
	["Shift", "วิ่ง"], ["Space", "กลิ้งหลบ"],
	["คลิกซ้าย", "ฟันต่อเนื่อง"], ["C", "ฟันหนัก"],
	["คลิกขวา", "ป้องกัน"], ["F", "ยิงดาว"],
	["X", "เสก / เก็บดาบ"], ["R", "ดื่มยาฟื้นพลัง"],
	["Q", "ล็อกเป้า"], ["E", "พักที่แท่นดาว"],
	["U", "เสริมพลังที่แท่นดาว"], ["Esc", "หยุดเกม"],
	["T", "แปลงร่าง / กลับร่าง"], ["1 - 7", "ใช้สกิล"],
	["V", "บิน / ลงพื้น (ร่างใหม่)"], ["Space / Ctrl", "บินขึ้น / บินลง"],
]

var start_button: Button
var resume_button: Button
var settings_widgets := {} ## Setting key -> slider or toggle, for refreshing.

var _screens := {}
var _first_focus := {}
var _current := ""
var _parent_screen := "main"
var _backdrop: TextureRect
var _dim: ColorRect
var _cover: ColorRect
var _confirm_label: Label
var _confirm_action: Callable
var _button_normal := StyleBoxEmpty.new()
var _button_active := StyleBoxFlat.new()
var _pill := StyleBoxFlat.new()
var _pill_active := StyleBoxFlat.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_styles()

	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.03, 0.02, 0.1, 0.9))
	gradient.set_color(1, Color(0.03, 0.02, 0.1, 0.0))
	var fade := GradientTexture2D.new()
	fade.gradient = gradient
	fade.width = 512
	fade.height = 4
	_backdrop = TextureRect.new()
	_backdrop.texture = fade
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(_backdrop, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2(0.62, 1.0))
	add_child(_backdrop)

	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.01, 0.07, 0.62)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	_build_main()
	_build_pause()
	_build_controls()
	_build_settings()
	_build_confirm()
	_hide_screens()

	_cover = ColorRect.new()
	_cover.color = Color(0.03, 0.02, 0.09)
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var loading := _label("กำลังโหลด...", 30, WHITE)
	loading.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cover.add_child(loading)
	add_child(_cover)


func _build_styles() -> void:
	_button_active.bg_color = Color(0.46, 0.32, 0.95, 0.42)
	_button_active.border_color = GOLD
	_button_active.border_width_left = 4
	_button_active.set_corner_radius_all(4)
	_button_active.content_margin_left = 24
	_button_normal.content_margin_left = 24
	_pill.bg_color = Color(0.1, 0.08, 0.24, 0.95)
	_pill.border_color = Color(0.7, 0.6, 1.0, 0.45)
	_pill.set_border_width_all(1)
	_pill.set_corner_radius_all(6)
	_pill_active.bg_color = Color(0.4, 0.28, 0.85, 0.95)
	_pill_active.border_color = GOLD
	_pill_active.set_border_width_all(2)
	_pill_active.set_corner_radius_all(6)


func _place(node: Control, anchor: Vector2, offset: Vector2, box: Vector2, anchor_end := Vector2(-1, -1)) -> void:
	var end := anchor if anchor_end.x < 0.0 else anchor_end
	node.anchor_left = anchor.x
	node.anchor_top = anchor.y
	node.anchor_right = end.x
	node.anchor_bottom = end.y
	node.offset_left = offset.x
	node.offset_top = offset.y
	node.offset_right = offset.x + box.x
	node.offset_bottom = offset.y + box.y


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.07, 0.8))
	label.add_theme_constant_override("outline_size", 5)
	return label


func _menu_button(value: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(360, 56)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_color_override("font_hover_pressed_color", GOLD)
	button.add_theme_stylebox_override("normal", _button_normal)
	button.add_theme_stylebox_override("hover", _button_active)
	button.add_theme_stylebox_override("pressed", _button_active)
	button.add_theme_stylebox_override("focus", _button_active)
	# Mouse and keyboard share one highlight.
	button.mouse_entered.connect(button.grab_focus)
	button.pressed.connect(action)
	return button


func _screen(screen_name: String) -> Control:
	var screen := Control.new()
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	_screens[screen_name] = screen
	return screen


func _column(parent: Control, y: float, buttons: Array) -> Button:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_place(column, Vector2(0, 0.5), Vector2(110, y), Vector2(360, buttons.size() * 62))
	parent.add_child(column)
	var first: Button = null
	for entry: Array in buttons:
		var button := _menu_button(entry[0], entry[1])
		column.add_child(button)
		if first == null:
			first = button
	return first


func _build_main() -> void:
	var screen := _screen("main")
	var title := _label("ASTRAL WARDEN", 76, GOLD)
	_place(title, Vector2(0, 0.5), Vector2(104, -290), Vector2(760, 100))
	screen.add_child(title)
	var subtitle := _label("ผู้พิทักษ์ดวงดาวแห่งหุบเขาอำพัน", 27, WHITE)
	_place(subtitle, Vector2(0, 0.5), Vector2(110, -190), Vector2(760, 44))
	screen.add_child(subtitle)
	start_button = _column(screen, -90, [
		["เริ่มเกม", Game.start_game],
		["วิธีเล่น", _open.bind("controls", "main")],
		["ตั้งค่า", _open.bind("settings", "main")],
		["ออกจากเกม", _quit],
	])
	_first_focus["main"] = start_button


func _build_pause() -> void:
	var screen := _screen("pause")
	var title := _label("หยุดเกมชั่วคราว", 58, GOLD)
	_place(title, Vector2(0, 0.5), Vector2(104, -250), Vector2(760, 90))
	screen.add_child(title)
	resume_button = _column(screen, -130, [
		["เล่นต่อ", Game.set_paused.bind(false)],
		["วิธีเล่น", _open.bind("controls", "pause")],
		["ตั้งค่า", _open.bind("settings", "pause")],
		["กลับเมนูหลัก", _ask.bind("กลับเมนูหลักใช่ไหม ความคืบหน้าในรอบนี้จะหายไป", Game.return_to_title)],
		["ออกจากเกม", _ask.bind("ออกจากเกมใช่ไหม ความคืบหน้าในรอบนี้จะหายไป", _quit)],
	])
	_first_focus["pause"] = resume_button


func _dialog(screen: Control, title_text: String, box: Vector2) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.13, 0.96)
	style.border_color = Color(0.7, 0.6, 1.0, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(38)
	panel.add_theme_stylebox_override("panel", style)
	_place(panel, Vector2(0.5, 0.5), -box * 0.5, box)
	screen.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)
	content.add_child(_label(title_text, 36, GOLD))
	return content


func _build_controls() -> void:
	var screen := _screen("controls")
	var content := _dialog(screen, "วิธีเล่น", Vector2(900, 640))
	var note := _label("เดินทางไปยังหอดาวทางเหนือแล้วโค่นผู้พิทักษ์ พักที่แท่นดาวเพื่อฟื้นพลัง", 19, MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 11)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(grid)
	for entry: Array in CONTROLS:
		var cap := Label.new()
		cap.text = entry[0]
		cap.custom_minimum_size = Vector2(106, 38)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cap.add_theme_font_size_override("font_size", 17)
		cap.add_theme_stylebox_override("normal", _pill)
		grid.add_child(cap)
		var text := _label(entry[1], 20, WHITE)
		text.custom_minimum_size = Vector2(250, 38)
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		grid.add_child(text)
	var back := _menu_button("กลับ", _back)
	content.add_child(back)
	_first_focus["controls"] = back


func _build_settings() -> void:
	var screen := _screen("settings")
	var content := _dialog(screen, "ตั้งค่า", Vector2(820, 660))
	_slider_row(content, "ความไวเมาส์", "mouse", 0.3, 2.0, 0.05)
	_toggle_row(content, "กลับทิศเมาส์แนวตั้ง", "invert_y")
	_slider_row(content, "ความละเอียดภาพ 3D", "render", 0.6, 1.0, 0.05)
	_quality_row(content)
	_toggle_row(content, "เต็มจอ", "fullscreen")
	_toggle_row(content, "VSync", "vsync")
	_toggle_row(content, "แสดงค่า FPS", "show_fps")
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	var back := _menu_button("กลับ", _back)
	content.add_child(back)
	_first_focus["settings"] = back


func _row(content: Control, title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var label := _label(title, 21, WHITE)
	label.custom_minimum_size = Vector2(320, 40)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	content.add_child(row)
	return row


func _circle_texture(diameter: int, color: Color) -> ImageTexture:
	var image := Image.create_empty(diameter, diameter, false, Image.FORMAT_RGBA8)
	var c := (diameter - 1) * 0.5
	for y in diameter:
		for x in diameter:
			var alpha := clampf(c + 0.5 - Vector2(x - c, y - c).length(), 0.0, 1.0)
			image.set_pixel(x, y, Color(color, alpha))
	return ImageTexture.create_from_image(image)


func _slider_row(content: Control, title: String, key: String, low: float, high: float, step: float) -> void:
	var row := _row(content, title)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.custom_minimum_size = Vector2(250, 40)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.16, 0.13, 0.32)
	track.set_corner_radius_all(4)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	var filled := StyleBoxFlat.new()
	filled.bg_color = LAVENDER
	filled.set_corner_radius_all(4)
	filled.content_margin_top = 4
	filled.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	slider.add_theme_icon_override("grabber", _circle_texture(22, WHITE))
	slider.add_theme_icon_override("grabber_highlight", _circle_texture(22, GOLD))
	row.add_child(slider)
	var value := _label("", 20, MUTED)
	value.custom_minimum_size = Vector2(70, 40)
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value)
	var show_value := func(v: float) -> void: value.text = "%d%%" % roundi(v * 100.0)
	slider.value = Game.settings[key]
	show_value.call(slider.value)
	slider.value_changed.connect(func(v: float) -> void:
		show_value.call(v)
		Game.set_setting(key, v))
	slider.mouse_entered.connect(slider.grab_focus)
	settings_widgets[key] = slider


func _pill_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(150, 40)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _pill)
	button.add_theme_stylebox_override("hover", _pill_active)
	button.add_theme_stylebox_override("pressed", _pill_active)
	button.add_theme_stylebox_override("focus", _pill_active)
	button.mouse_entered.connect(button.grab_focus)
	return button


func _toggle_row(content: Control, title: String, key: String) -> void:
	var button := _pill_button()
	_row(content, title).add_child(button)
	button.text = "เปิด" if Game.settings[key] else "ปิด"
	button.pressed.connect(func() -> void:
		var on: bool = not Game.settings[key]
		button.text = "เปิด" if on else "ปิด"
		Game.set_setting(key, on))
	settings_widgets[key] = button


func _quality_row(content: Control) -> void:
	var names := ["ต่ำ", "กลาง", "สูง"]
	var button := _pill_button()
	_row(content, "คุณภาพกราฟิก").add_child(button)
	button.text = names[Game.settings["quality"]]
	button.pressed.connect(func() -> void:
		var level: int = (int(Game.settings["quality"]) + 1) % 3
		button.text = names[level]
		Game.set_setting("quality", level))
	settings_widgets["quality"] = button


func _build_confirm() -> void:
	var screen := _screen("confirm")
	var content := _dialog(screen, "ยืนยัน", Vector2(640, 320))
	_confirm_label = _label("", 22, WHITE)
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_confirm_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	var no := _menu_button("ยกเลิก", _back)
	no.custom_minimum_size.x = 260
	row.add_child(no)
	var yes := _menu_button("ตกลง", func() -> void: _confirm_action.call())
	yes.custom_minimum_size.x = 260
	row.add_child(yes)
	_first_focus["confirm"] = no


# ------------------------------------------------------------------ navigation

func _hide_screens() -> void:
	for screen: Control in _screens.values():
		screen.visible = false
	_current = ""
	_backdrop.visible = false
	_dim.visible = false


func _show(screen_name: String) -> void:
	_hide_screens()
	_current = screen_name
	var screen: Control = _screens[screen_name]
	screen.visible = true
	_backdrop.visible = screen_name == "main" or screen_name == "pause"
	_dim.visible = screen_name != "main"
	(_first_focus[screen_name] as Control).grab_focus()
	screen.modulate.a = 0.0
	create_tween().tween_property(screen, "modulate:a", 1.0, 0.14)


func _open(screen_name: String, parent: String) -> void:
	_parent_screen = parent
	_show(screen_name)


func _ask(message: String, action: Callable) -> void:
	_confirm_label.text = message
	_confirm_action = action
	_parent_screen = "pause"
	_show("confirm")


func _back() -> void:
	_show(_parent_screen)


func _quit() -> void:
	get_tree().quit()


func finish_loading() -> void:
	open_main()
	create_tween().tween_property(_cover, "modulate:a", 0.0, 0.35)
	await get_tree().create_timer(0.36).timeout
	_cover.visible = false


func open_main() -> void:
	_show("main")


func close() -> void:
	_hide_screens()


func show_pause(paused: bool) -> void:
	if paused:
		_show("pause")
	else:
		_hide_screens()


func current_screen() -> String:
	return _current


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		return
	match _current:
		"controls", "settings", "confirm":
			_back()
		"pause":
			Game.set_paused(false)
		"":
			if Game.state == "play":
				Game.set_paused(true)
