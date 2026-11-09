class_name StarBolt
extends Node3D
## Homing-free star shard fired from the left hand.

const SPEED := 26.0
const LIFE := 1.6
const DAMAGE := 62.0

var direction := Vector3.FORWARD
var _age := 0.0


func _ready() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.4
	mesh.material = Fx.flat_material(Color(0.72, 0.62, 1.0), 4.0)
	var core := MeshInstance3D.new()
	core.mesh = mesh
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(core)

	var light := OmniLight3D.new()
	light.light_color = Color(0.65, 0.5, 1.0)
	light.light_energy = 3.0
	light.omni_range = 7.0
	add_child(light)

	var trail := CPUParticles3D.new()
	var dot := SphereMesh.new()
	dot.radius = 0.07
	dot.height = 0.14
	dot.radial_segments = 6
	dot.rings = 3
	dot.material = Fx.flat_material(Color(0.55, 0.45, 1.0), 3.0)
	trail.mesh = dot
	trail.amount = 40
	trail.lifetime = 0.4
	trail.local_coords = false
	trail.gravity = Vector3.ZERO
	trail.spread = 180.0
	trail.initial_velocity_max = 0.8
	add_child(trail)


func _physics_process(delta: float) -> void:
	_age += delta
	var pos := global_position + direction * SPEED * delta
	global_position = pos
	if _age > LIFE or pos.y < Game.terrain.get_height(pos.x, pos.z):
		_explode()
		return
	for enemy in Game.enemies:
		if enemy.is_alive() and enemy.chest_position().distance_to(pos) < enemy.radius + 0.5:
			enemy.take_hit(DAMAGE, 22.0, Game.player.global_position, false)
			_explode()
			return


func _explode() -> void:
	Fx.burst(global_position, Color(0.72, 0.6, 1.0), 26, 8.0)
	queue_free()
