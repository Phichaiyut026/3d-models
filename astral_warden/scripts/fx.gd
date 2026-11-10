class_name Fx
extends RefCounted
## Short-lived effects. Every node frees itself.

const FLAT := preload("res://shaders/flat.gdshader")
const STAR := preload("res://shaders/star_spark.gdshader")
const CRESCENT := preload("res://shaders/crescent.gdshader")


static func flat_material(color: Color, boost := 2.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FLAT
	m.set_shader_parameter("color", color)
	m.set_shader_parameter("boost", boost)
	return m


static func burst(pos: Vector3, color: Color, amount := 18, speed := 6.0, size := 0.06) -> void:
	var p := CPUParticles3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.material = flat_material(color, 3.0)
	p.mesh = mesh
	p.amount = amount
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -7, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.finished.connect(p.queue_free)
	Game.world.add_child(p)
	p.global_position = pos
	p.emitting = true


static func ring(pos: Vector3, radius: float, color: Color, duration := 0.45) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.92
	mesh.outer_radius = 1.0
	mesh.rings = 48
	mesh.material = flat_material(color, 3.0)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Game.world.add_child(instance)
	instance.global_position = pos + Vector3(0, 0.15, 0)
	instance.scale = Vector3(0.3, 0.3, 0.3)
	var tween := instance.create_tween()
	tween.tween_property(instance, "scale", Vector3(radius, 1.0, radius), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(instance.queue_free)


static func _star(pos: Vector3, size: Vector2, tint: Color, spin: float, duration: float, grow: float) -> void:
	var quad := QuadMesh.new()
	var material := ShaderMaterial.new()
	material.shader = STAR
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("spin", spin)
	quad.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.extra_cull_margin = 10.0
	Game.world.add_child(instance)
	instance.global_position = pos
	instance.scale = Vector3(size.x, size.y, 1.0)
	# Flashes keep playing through the hit-stop, which is when they are seen.
	var tween := instance.create_tween().set_ignore_time_scale(true).set_parallel(true)
	tween.tween_property(instance, "scale", Vector3(size.x * grow, size.y * grow, 1.0), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(v: float) -> void: material.set_shader_parameter("fade", v), 1.0, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(instance.queue_free)


## Blade striking flesh or armour. Strength runs from 0 (glancing) to 1 (full heavy blow).
static func impact(pos: Vector3, tint: Color, strength: float) -> void:
	var spin := randf() * PI
	_star(pos, Vector2.ONE * lerpf(1.0, 2.6, strength), tint, spin, 0.18, 1.5)
	_star(pos, Vector2.ONE * lerpf(1.9, 4.6, strength), tint, spin + PI * 0.25, 0.13, 1.25)
	burst(pos, tint, int(lerpf(14.0, 34.0, strength)), lerpf(5.0, 10.0, strength), 0.05)
	if strength > 0.55:
		ring(pos - Vector3(0, 1.0, 0), lerpf(2.0, 4.5, strength), tint, 0.3)


## A crescent of light flying forward from a finishing blow.
static func crescent(pos: Vector3, forward: Vector3, roll: float, tint: Color, width: float, travel := 10.0) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(width, width * 0.72)
	var material := ShaderMaterial.new()
	material.shader = CRESCENT
	material.set_shader_parameter("tint", tint)
	quad.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Game.world.add_child(instance)
	var facing := Basis.looking_at(-forward, Vector3.UP).rotated(forward, roll)
	instance.global_transform = Transform3D(facing, pos)
	var tween := instance.create_tween().set_parallel(true)
	tween.tween_property(instance, "global_position", pos + forward * travel, 0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(instance, "scale", Vector3.ONE * 1.5, 0.34)
	tween.tween_method(func(v: float) -> void: material.set_shader_parameter("fade", v), 1.0, 0.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(instance.queue_free)


## Cracking light and dust where a downward blow meets the ground.
static func ground_strike(pos: Vector3, tint: Color) -> void:
	ring(pos, 4.2, tint, 0.35)
	burst(pos + Vector3(0, 0.2, 0), tint, 26, 8.0, 0.05)
	burst(pos + Vector3(0, 0.1, 0), Color(0.72, 0.62, 0.42), 18, 4.0, 0.09)
