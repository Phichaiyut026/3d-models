class_name Villager
extends Node3D
## One of the town's people: a simple body built from rounded shapes, walking a lane of its own
## (a street, the ring road or round the square), stopping now and then, and turning to talk.

var display_name := ""
var tint := Color.WHITE
var height := 1.75
var lines_before: Array = [] ## While the darkness holds the valley.
var lines_after: Array = [] ## Once WORMS is gone.

var _lane := "" ## "x" or "z": along a main street; "ring": round the ring road; "square": round the square.
var _lane_value := 0.0 ## The street's offset, or the circle's radius.
var _span := Vector2.ZERO ## How far along the lane it wanders.
var _goal := Vector3.ZERO
var _speed := 1.4
var _wait := 0.0
var _talking := 0.0
var _phase := 0.0
var _talk_index := 0
var _hips: Node3D
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _head: Node3D
var _mats := {}


## `look` holds skin, shirt, trousers, hair and an optional hat colour.
func setup(who: String, before: Array, after: Array, look: Dictionary, size: float, lane: String, lane_value: float, span: Vector2, start: float) -> Villager:
	display_name = who
	lines_before = before
	lines_after = after
	height = 1.75 * size
	tint = look["shirt"]
	_lane = lane
	_lane_value = lane_value
	_span = span
	_speed = (1.2 + randf() * 0.6) * (1.25 if size < 0.8 else 1.0)
	_phase = randf() * TAU
	_build(look, size)
	position = _lane_point(start)
	_pick_goal()
	return self


func _mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.85
		_mats[key] = m
	return _mats[key]


func _part(parent: Node3D, mesh: Mesh, color: Color, at: Vector3, scale_by := Vector3.ONE) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = _mat(color)
	m.position = at
	m.scale = scale_by
	parent.add_child(m)
	return m


func _capsule(radius: float, length: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = radius
	c.height = length
	c.radial_segments = 10
	c.rings = 4
	return c


func _build(look: Dictionary, s: float) -> void:
	var body := Node3D.new()
	body.scale = Vector3.ONE * s
	add_child(body)
	_hips = Node3D.new()
	_hips.position.y = 0.9
	body.add_child(_hips)
	for side: float in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.13, 0, 0)
		_hips.add_child(leg)
		_part(leg, _capsule(0.1, 0.9), look["pants"], Vector3(0, -0.43, 0))
		_part(leg, BoxMesh.new(), Color(0.18, 0.12, 0.08), Vector3(0, -0.86, 0.06), Vector3(0.16, 0.1, 0.28))
		_legs.append(leg)
	var torso := _part(_hips, _capsule(0.24, 0.75), look["shirt"], Vector3(0, 0.36, 0), Vector3(1.0, 1.0, 0.75))
	if look.get("dress", false):
		var skirt := CylinderMesh.new()
		skirt.top_radius = 0.24
		skirt.bottom_radius = 0.36
		skirt.height = 0.55
		_part(_hips, skirt, look["shirt"], Vector3(0, -0.18, 0))
	_part(_hips, _capsule(0.07, 0.5), (look["shirt"] as Color).darkened(0.25), Vector3(0, 0.02, 0), Vector3(3.6, 0.25, 2.6)) # belt
	for side: float in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.31, 0.64, 0)
		_hips.add_child(arm)
		_part(arm, _capsule(0.075, 0.68), look["shirt"], Vector3(0, -0.3, 0))
		_part(arm, SphereMesh.new(), look["skin"], Vector3(0, -0.66, 0), Vector3.ONE * 0.15)
		_arms.append(arm)
	_head = Node3D.new()
	_head.position.y = 0.9
	_hips.add_child(_head)
	_part(_head, SphereMesh.new(), look["skin"], Vector3(0, 0.12, 0), Vector3(0.38, 0.44, 0.38))
	_part(_head, SphereMesh.new(), look["hair"], Vector3(0, 0.2, -0.03), Vector3(0.41, 0.34, 0.41))
	for side: float in [-1.0, 1.0]:
		_part(_head, SphereMesh.new(), Color(0.08, 0.06, 0.06), Vector3(side * 0.07, 0.14, 0.17), Vector3.ONE * 0.045)
	if look.has("hat"):
		var brim := CylinderMesh.new()
		brim.top_radius = 0.34
		brim.bottom_radius = 0.34
		brim.height = 0.03
		_part(_head, brim, look["hat"], Vector3(0, 0.32, 0))
		var crown := CylinderMesh.new()
		crown.top_radius = 0.13
		crown.bottom_radius = 0.2
		crown.height = 0.2
		_part(_head, crown, look["hat"], Vector3(0, 0.42, 0))
	for node in find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	torso.name = "Torso"


## A point on this villager's lane, `k` from 0 to 1 along its span.
func _lane_point(k: float) -> Vector3:
	var t := lerpf(_span.x, _span.y, k)
	match _lane:
		"x":
			return Vector3(t, 0, _lane_value)
		"z":
			return Vector3(_lane_value, 0, t)
		_:
			return Vector3(cos(t), 0, sin(t)) * _lane_value


func _pick_goal() -> void:
	_goal = _lane_point(randf())


func next_line() -> String:
	_talking = 4.0
	var pool: Array = lines_after if Game.worms_defeated and not lines_after.is_empty() else lines_before
	var line: String = pool[_talk_index % pool.size()]
	_talk_index += 1
	return line


func _process(delta: float) -> void:
	if not is_visible_in_tree() or not Game.in_town():
		return
	var moving := false
	if _talking > 0.0:
		_talking -= delta
		var to := Game.player.global_position - global_position
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 1.0 - exp(-delta * 8.0))
	elif _wait > 0.0:
		_wait -= delta
	else:
		var to := _goal - position
		to.y = 0.0
		var step := _speed * delta
		if to.length() <= step:
			position = _goal
			_wait = randf_range(0.5, 4.0)
			_pick_goal()
		else:
			# Round the ring and the square it follows the curve rather than cutting across.
			var dir := to.normalized()
			if _lane == "ring" or _lane == "square":
				var tangent := Vector3(-position.z, 0, position.x).normalized()
				dir = (tangent * (1.0 if tangent.dot(to) >= 0.0 else -1.0) + (Vector3(position.x, 0, position.z).normalized() * (_lane_value - Vector2(position.x, position.z).length()) * 0.4)).normalized()
			position += dir * step
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-delta * 6.0))
			moving = true
	_phase += delta * (_speed * 4.2 if moving else 1.2)
	var swing := sin(_phase) * (0.55 if moving else 0.0)
	_legs[0].rotation.x = swing
	_legs[1].rotation.x = -swing
	_arms[0].rotation.x = -swing * 0.8
	_arms[1].rotation.x = swing * 0.8
	_hips.position.y = 0.9 + (absf(sin(_phase)) * 0.04 if moving else sin(_phase) * 0.01)
	_head.rotation.y = 0.0 if moving else sin(_phase * 0.4) * 0.3
	if _talking > 0.0:
		_arms[1].rotation = Vector3(-0.6 + sin(_phase * 3.0) * 0.25, 0, 0.2)
