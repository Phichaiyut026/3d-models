class_name Shrine
extends Node3D
## Rest point: a small captive star over a stone plinth.

const COSMIC := preload("res://shaders/cosmic.gdshader")
const STONE := preload("res://shaders/stone.gdshader")

var _star: MeshInstance3D
var _light: OmniLight3D
var _clock := 0.0
var _kindle := 0.0


func _ready() -> void:
	var stone := ShaderMaterial.new()
	stone.shader = STONE
	var plinth := MeshInstance3D.new()
	var plinth_mesh := CylinderMesh.new()
	plinth_mesh.top_radius = 0.85
	plinth_mesh.bottom_radius = 1.25
	plinth_mesh.height = 0.8
	plinth_mesh.radial_segments = 8
	plinth_mesh.material = stone
	plinth.mesh = plinth_mesh
	plinth.position.y = 0.3
	add_child(plinth)

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 1.1
	cylinder.height = 1.6
	shape.shape = cylinder
	body.add_child(shape)
	add_child(body)

	var forge := MeshForge.new({"star": Fx.flat_material(Color(0.78, 0.7, 1.0), 2.6)})
	var holder := Node3D.new()
	add_child(holder)
	forge.plate(holder, Transform3D.IDENTITY, MeshForge.star4(0.62, 0.13, 0.9), 0.14, "star", 0.04)
	_star = MeshInstance3D.new()
	_star.mesh = forge.bake(holder)
	_star.position.y = 2.1
	add_child(_star)
	holder.queue_free()

	_light = OmniLight3D.new()
	_light.light_color = Color(0.62, 0.5, 1.0)
	_light.omni_range = 11.0
	_light.position.y = 2.1
	add_child(_light)


func kindle() -> void:
	_kindle = 1.0
	Fx.ring(global_position, 9.0, Color(0.7, 0.6, 1.0), 0.8)
	Fx.burst(_star.global_position, Color(0.8, 0.72, 1.0), 40, 7.0)


func _process(delta: float) -> void:
	_clock += delta
	_kindle = maxf(0.0, _kindle - delta * 0.8)
	_star.rotation.y = _clock * 0.9
	_star.position.y = 2.1 + sin(_clock * 1.6) * 0.08
	_light.light_energy = 2.2 + sin(_clock * 2.4) * 0.3 + _kindle * 7.0
