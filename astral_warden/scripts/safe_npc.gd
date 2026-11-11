class_name SafeNpc
extends Node3D
## A survivor sheltering in Safe Mode, in the state OBLIVION left them: slumped, scorched and sparking.

const WEB := 0.36 ## Metres per unit of the model pages.
const SCORCH := Color(0.5, 0.45, 0.42)

var display_name := ""
var tint := Color.WHITE
var height := 3.0
var lines: Array = []

var _scene: Node3D
var _spine: Node3D
var _spine_rest := Vector3.ZERO
var _head: Node3D
var _head_rest := Vector3.ZERO
var _clock := 0.0
var _talk_index := 0
var _light: OmniLight3D
var _damage_at := Vector3.ZERO


## `pose` maps joint names to rotations; `broken` lists parts that are simply gone.
func setup(id: String, who: String, color: Color, say: Array, facing: float, pose: Dictionary, broken: Array, lift := 0.0) -> SafeNpc:
	display_name = who
	tint = color
	lines = say
	rotation.y = facing
	_clock = randf() * 10.0
	_scene = (load("res://models/npc/%s.glb" % id) as PackedScene).instantiate()
	_scene.scale = Vector3.ONE * WEB
	add_child(_scene)
	var player := _find_player(_scene)
	if player != null:
		player.stop()
		player.active = false
	for joint_name: String in pose:
		var joint: Node3D = _scene.find_child(joint_name, true, false)
		if joint != null:
			joint.rotation = pose[joint_name]
	for part_name: String in broken:
		var part: Node3D = _scene.find_child(part_name, true, false)
		if part != null:
			part.visible = false
	_spine = _scene.find_child("Spine", true, false)
	_head = _scene.find_child("Head", true, false)
	if _spine != null:
		_spine_rest = _spine.rotation
	if _head != null:
		_head_rest = _head.rotation
	_scorch(_scene, {})
	_settle()
	_scene.position.y += lift
	_add_damage(lift)
	return self


## Where the repair arms should work: the middle of the body, as it lies.
func damage_point() -> Vector3:
	return _damage_at


func _find_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null


## Burnt-looking armour, and every light on the body turned down.
func _scorch(node: Node, done: Dictionary) -> void:
	if node is MeshInstance3D:
		var instance: MeshInstance3D = node
		for i in instance.mesh.get_surface_count():
			var old := instance.mesh.surface_get_material(i)
			if not old is StandardMaterial3D:
				continue
			if not done.has(old):
				var burnt: StandardMaterial3D = old.duplicate()
				burnt.albedo_color = Color(old.albedo_color * SCORCH, old.albedo_color.a)
				burnt.emission_energy_multiplier = old.emission_energy_multiplier * 0.25
				done[old] = burnt
			instance.set_surface_override_material(i, done[old])
	if node is Light3D:
		(node as Light3D).light_energy *= 0.15
	for child in node.get_children():
		_scorch(child, done)


func _bounds(node: Node, box: Array) -> void:
	if node is Node3D and not (node as Node3D).visible:
		return
	if node is MeshInstance3D:
		var instance: MeshInstance3D = node
		var world := instance.global_transform * instance.get_aabb()
		box[0] = minf(box[0], world.position.y)
		box[1] = maxf(box[1], world.end.y)
	for child in node.get_children():
		_bounds(child, box)


## However a body has fallen, its lowest point rests on the floor.
func _settle() -> void:
	var box := [INF, -INF]
	_bounds(_scene, box)
	if box[0] == INF:
		return
	_scene.position.y -= box[0] - global_position.y
	height = box[1] - box[0]


func _add_damage(lift: float) -> void:
	var mid := Vector3(0, lift + height * 0.55, 0)
	_damage_at = mid
	var dot := BoxMesh.new()
	dot.size = Vector3.ONE * 0.05
	dot.material = Fx.flat_material(Color(1.0, 0.6, 0.2), 4.0)
	var sparks := CPUParticles3D.new()
	sparks.mesh = dot
	sparks.amount = 8 # Welding sparks now as much as damage.
	sparks.lifetime = 0.7
	sparks.explosiveness = 0.85
	sparks.randomness = 1.0
	sparks.local_coords = false
	sparks.position = mid
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 0.5
	sparks.spread = 70.0
	sparks.direction = Vector3.UP
	sparks.initial_velocity_min = 1.0
	sparks.initial_velocity_max = 3.2
	sparks.gravity = Vector3(0, -9, 0)
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sparks)

	var puff := QuadMesh.new()
	puff.size = Vector2.ONE * 0.9
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = _soft_dot()
	material.disable_fog = true
	puff.material = material
	var fade := Gradient.new()
	fade.set_color(0, Color(0.1, 0.1, 0.1, 0.5))
	fade.set_color(1, Color(0.1, 0.1, 0.1, 0.0))
	var smoke := CPUParticles3D.new()
	smoke.mesh = puff
	smoke.amount = 5
	smoke.lifetime = 3.2
	smoke.local_coords = false
	smoke.position = mid
	smoke.direction = Vector3.UP
	smoke.spread = 12.0
	smoke.gravity = Vector3.ZERO
	smoke.initial_velocity_min = 0.5
	smoke.initial_velocity_max = 1.1
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 1.7
	smoke.color_ramp = fade
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(smoke)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.45, 0.2)
	_light.omni_range = 5.0
	_light.position = mid
	add_child(_light)


func _soft_dot() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 32
	texture.height = 32
	return texture


## The next thing it has to say, in turn.
func next_line() -> String:
	var line: String = lines[_talk_index % lines.size()]
	_talk_index += 1
	return line


## Shallow, uneven breathing; now and then the weld at the wound flares.
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_clock += delta
	var breath := sin(_clock * 1.1) * 0.02 + sin(_clock * 2.7) * 0.006
	if _spine != null:
		_spine.rotation = _spine_rest + Vector3(breath, 0, 0)
	if _head != null:
		_head.rotation = _head_rest + Vector3(-breath * 1.5, sin(_clock * 0.37) * 0.03, 0)
	if _light != null:
		_light.light_energy = 1.6 if sin(_clock * 23.0) * sin(_clock * 7.1) > 0.55 else 0.35
