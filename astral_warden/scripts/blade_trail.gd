class_name BladeTrail
extends MeshInstance3D
## Curved ribbon swept by the blade. Samples are smoothed, so a fast swing stays round.

const SHADER := preload("res://shaders/slash_trail.gdshader")
const LIFETIME := 0.24
const SUBDIVISIONS := 5
const MIN_STEP := 0.012

var active := false
var tint := Color(0.62, 0.46, 1.0)
var strength := 1.0

var _base: Node3D
var _tip: Node3D
var _mesh := ImmediateMesh.new()
var _material := ShaderMaterial.new()
var _samples: Array = [] ## Each is [base position, tip position, age, tint, strength].


func _init() -> void:
	top_level = true
	mesh = _mesh
	_material.shader = SHADER
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 50.0
	process_priority = 100 # Runs after the body has been posed this frame.


func follow(base: Node3D, tip: Node3D) -> void:
	_base = base
	_tip = tip


## Draws one ribbon so the shader is compiled before the first real swing.
func warm(at: Vector3) -> void:
	for i in 4:
		_samples.append([at + Vector3(i * 0.5, 0, 0), at + Vector3(i * 0.5, 1, 0), 0.0, tint, strength])
	_rebuild()


func clear() -> void:
	active = false
	_samples.clear()
	_mesh.clear_surfaces()


func _process(delta: float) -> void:
	for sample: Array in _samples:
		sample[2] += delta
	while not _samples.is_empty() and _samples[0][2] > LIFETIME:
		_samples.pop_front()

	if active and _tip != null:
		var tip_position := _tip.global_position
		var moved: bool = _samples.is_empty() or (_samples[-1][1] as Vector3).distance_to(tip_position) > MIN_STEP
		if moved:
			_samples.append([_base.global_position, tip_position, 0.0, tint, strength])
	_rebuild()


func _at(i: int) -> Array:
	return _samples[clampi(i, 0, _samples.size() - 1)]


func _rebuild() -> void:
	_mesh.clear_surfaces()
	if _samples.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _material)
	var travelled := 0.0
	var previous: Vector3 = _samples[0][1]
	for i in _samples.size() - 1:
		var a := _at(i - 1)
		var b := _at(i)
		var c := _at(i + 1)
		var d := _at(i + 2)
		var steps := SUBDIVISIONS if i < _samples.size() - 2 else SUBDIVISIONS + 1
		for s in steps:
			var f := float(s) / SUBDIVISIONS
			var base_point: Vector3 = (b[0] as Vector3).cubic_interpolate(c[0], a[0], d[0], f)
			var tip_point: Vector3 = (b[1] as Vector3).cubic_interpolate(c[1], a[1], d[1], f)
			travelled += previous.distance_to(tip_point)
			previous = tip_point
			var age := lerpf(b[2], c[2], f)
			var life := clampf(1.0 - age / LIFETIME, 0.0, 1.0)
			var shade: Color = (b[3] as Color).lerp(c[3], f)
			shade.a = lerpf(b[4], c[4], f)
			_mesh.surface_set_color(shade)
			_mesh.surface_set_uv(Vector2(life, 0.0))
			_mesh.surface_set_uv2(Vector2(travelled, 0.0))
			_mesh.surface_add_vertex(base_point)
			_mesh.surface_set_color(shade)
			_mesh.surface_set_uv(Vector2(life, 1.0))
			_mesh.surface_set_uv2(Vector2(travelled, 1.0))
			_mesh.surface_add_vertex(tip_point)
	_mesh.surface_end()
