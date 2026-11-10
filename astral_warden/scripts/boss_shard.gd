class_name BossShard
extends Node3D
## A crystal fired from the Overlord's wings.

const SPEED := 38.0
const LIFE := 2.2
const DAMAGE := 30.0

var direction := Vector3.FORWARD
var _age := 0.0
static var _mesh: CylinderMesh


func _ready() -> void:
	if _mesh == null:
		_mesh = CylinderMesh.new()
		_mesh.top_radius = 0.0
		_mesh.bottom_radius = 0.24
		_mesh.height = 2.2
		_mesh.radial_segments = 5
		_mesh.rings = 1
		_mesh.material = Fx.flat_material(Color(1.0, 0.16, 0.22), 3.2)
	var body := MeshInstance3D.new()
	body.mesh = _mesh
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(body)
	basis = Basis(Quaternion(Vector3.UP, direction))


func _physics_process(delta: float) -> void:
	_age += delta
	var pos := global_position + direction * SPEED * delta
	global_position = pos
	if _age > LIFE or pos.y < Game.terrain.get_height(pos.x, pos.z):
		Fx.burst(pos, Color(1.0, 0.16, 0.22), 10, 6.0)
		queue_free()
		return
	if Game.player.is_alive() and Game.player.chest().distance_to(pos) < 1.3:
		Game.player.take_damage(DAMAGE, pos - direction * 2.0)
		Fx.burst(pos, Color(1.0, 0.16, 0.22), 14, 7.0)
		queue_free()
