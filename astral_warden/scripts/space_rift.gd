class_name SpaceRift
extends MeshInstance3D
## A star-shaped tear in the air. `follow` makes it ride a moving point.

const SHADER := preload("res://shaders/space_rift.gdshader")

var follow: Node3D

var _material := ShaderMaterial.new()
var _open := 0.0
var _goal := 0.0


func _init(nebula: Texture2D) -> void:
	top_level = true
	var quad := QuadMesh.new()
	quad.material = _material
	mesh = quad
	_material.shader = SHADER
	_material.set_shader_parameter("nebula", nebula)
	_material.render_priority = 1
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = 10.0
	visible = false
	process_priority = 100


func tear_open(at: Vector3, size: float) -> void:
	follow = null
	global_position = at
	scale = Vector3.ONE * size
	_goal = 1.0
	visible = true


func seal() -> void:
	_goal = 0.0


func vanish() -> void:
	_goal = 0.0
	_open = 0.0
	visible = false


func _process(delta: float) -> void:
	_open = move_toward(_open, _goal, delta * (6.0 if _goal > _open else 7.5))
	_material.set_shader_parameter("open", ease(_open, 0.5))
	if follow != null:
		global_position = follow.global_position
	if _open <= 0.0 and _goal <= 0.0:
		visible = false
