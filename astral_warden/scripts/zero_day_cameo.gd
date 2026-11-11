class_name ZeroDayCameo
extends Node3D
## Zero Day's rescue: its body, chains, padlocks and backdoor. Frees with the scene.

const GREEN := Color("b8ff2e")
const PORTAL := preload("res://shaders/keyhole_portal.gdshader")

var _rig: ZeroDayRig
var _chains: Array[MultiMeshInstance3D] = []
var _locks: Array[Node3D] = []
var _portal: MeshInstance3D
var _door := Vector3.ZERO


func _ready() -> void:
	_rig = ZeroDayRig.new()
	_rig.visible = false
	add_child(_rig)
	var light := OmniLight3D.new()
	light.light_color = GREEN
	light.light_energy = 5.0
	light.omni_range = 24.0
	light.position = Vector3(0, 6, 1.5)
	_rig.add_child(light)


## Steps out of a keyhole, between the boss and whoever it was about to delete.
func appear(at: Vector3, facing: Vector3) -> void:
	_portal_at(at, facing, 15.0)
	var to := facing - at
	_rig.global_position = at
	_rig.rotation.y = atan2(to.x, to.z)
	_rig.visible = true
	_rig.fight_goal = 1.0
	var chest := at + Vector3(0, 5.0, 0)
	CosmicFx.flash(GREEN, 0.75, 0.5)
	CosmicFx.shock(chest, 16.0, 2.4, 0.7, GREEN)
	CosmicFx.shock(at, 22.0, 2.2, 0.9, GREEN, true)
	Fx.burst(chest, GREEN, 70, 16.0, 0.09)
	Game.shake(1.0)
	_close_portal(0.9)


## LOCKDOWN: the arm comes forward, chains close on the target and padlocks slam shut.
func lockdown(boss: Enemy) -> void:
	_rig.play("lockdown", true)
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(boss):
		return
	var body := boss.chest_position()
	var center := boss.global_position
	var from := _rig.global_position + Vector3(0, 6.0, 0)
	_chain(from, body)
	_chain(from + Vector3(0, -1.5, 0), body + Vector3(0, 3.0, 0))
	for i in 6:
		var a := i * TAU / 6.0
		var ground := center + Vector3(cos(a), 0, sin(a)) * 16.0
		ground.y = Game.terrain.get_height(ground.x, ground.z)
		_chain(ground, body + Vector3(cos(a) * 2.0, randf_range(-2.0, 3.0), sin(a) * 2.0))
		Fx.burst(ground + Vector3(0, 0.3, 0), GREEN, 22, 10.0, 0.08)
	var spots := [Vector3(-3.4, 2.0, 2.2), Vector3(3.4, 2.0, 2.2), Vector3(-2.2, -3.0, 2.8), Vector3(2.2, -3.0, 2.8)]
	var turn := Basis(Vector3.UP, boss.rig.rotation.y)
	for i in spots.size():
		_slam_lock(body + turn * (spots[i] as Vector3), boss.rig.rotation.y, 0.1 + i * 0.12)
	CosmicFx.flash(GREEN, 0.5, 0.35)
	CosmicFx.shock(body, 30.0, 2.4, 0.8, GREEN)
	Game.shake(1.4)


func _slam_lock(at: Vector3, yaw: float, delay: float) -> void:
	var lock := _padlock()
	lock.global_position = at
	lock.rotation.y = yaw
	lock.scale = Vector3.ONE * 6.0
	lock.visible = false
	_locks.append(lock)
	var tween := lock.create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(lock.show)
	tween.tween_property(lock, "scale", Vector3.ONE * 1.5, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		CosmicFx.shock(at, 6.0, 2.0, 0.4, GREEN)
		Fx.burst(at, GREEN, 24, 9.0, 0.08)
		Game.shake(0.5))


func _padlock() -> Node3D:
	var lock := Node3D.new()
	add_child(lock)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.1, 0.11, 0.14)
	dark.metallic = 0.5
	dark.roughness = 0.5
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.36, 0.4, 0.46)
	steel.metallic = 0.7
	steel.roughness = 0.35
	var box := BoxMesh.new()
	box.size = Vector3(2.2, 2.0, 1.05)
	box.material = dark
	var body := MeshInstance3D.new()
	body.mesh = box
	lock.add_child(body)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.5
	torus.outer_radius = 0.84
	torus.material = steel
	var shackle := MeshInstance3D.new()
	shackle.mesh = torus
	shackle.position = Vector3(0, 1.2, 0)
	shackle.rotation.x = PI * 0.5
	lock.add_child(shackle)
	var hole := keyhole(1.5)
	lock.add_child(hole)
	hole.position = Vector3(0, -0.04, 0.56)
	return lock


static func keyhole(size: float) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	var material := ShaderMaterial.new()
	material.shader = PORTAL
	var node := MeshInstance3D.new()
	node.mesh = quad
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.extra_cull_margin = 20.0
	return node


func _portal_at(at: Vector3, facing: Vector3, size: float) -> void:
	if _portal != null:
		_portal.queue_free()
	_portal = keyhole(size)
	add_child(_portal)
	var to := facing - at
	to.y = 0.0
	_portal.global_position = at + Vector3(0, size * 0.42, 0)
	_portal.rotation.y = atan2(to.x, to.z)
	_portal.scale = Vector3(0.02, 0.02, 1.0)
	_portal.create_tween().tween_property(_portal, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_portal(delay: float) -> void:
	var door := _portal
	var tween := door.create_tween()
	tween.tween_interval(delay)
	tween.tween_property(door, "scale", Vector3(0.02, 0.02, 1.0), 0.3)
	tween.tween_callback(door.queue_free)
	_portal = null


## A chain thrown from `a` to `b`, link by link.
func _chain(a: Vector3, b: Vector3) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.16
	torus.outer_radius = 0.3
	torus.rings = 12
	torus.ring_segments = 6
	torus.material = Fx.flat_material(Color("2bc53c"), 3.0)
	var along := b - a
	var dir := along.normalized()
	var count := clampi(int(along.length() / 0.62), 2, 160)
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = torus
	multi.instance_count = count
	var up := Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT
	var face := Basis.looking_at(dir, up)
	for i in count:
		var u := (i + 0.5) / count
		var turned := face.rotated(dir, PI * 0.5) if i % 2 == 1 else face
		multi.set_instance_transform(i, Transform3D(turned.scaled_local(Vector3(1.0, 1.0, 1.45)), a + along * u))
	multi.visible_instance_count = 0
	var node := MultiMeshInstance3D.new()
	node.multimesh = multi
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.extra_cull_margin = 80.0
	add_child(node)
	node.global_position = Vector3.ZERO
	_chains.append(node)
	var reveal := func(v: float) -> void: multi.visible_instance_count = int(v)
	node.create_tween().tween_method(reveal, 0.0, float(count), 0.35)


## Crosses to Gemini and reaches down.
func walk_to(p: Player) -> void:
	_rig.stop_act()
	_rig.fight_goal = 0.0
	var side := Vector3.UP.cross(p.global_position - _rig.global_position).normalized()
	var goal := p.global_position + side * 3.2
	goal.y = Game.terrain.get_height(goal.x, goal.z)
	var to := goal - _rig.global_position
	_rig.rotation.y = atan2(to.x, to.z)
	_rig.walking = true
	var tween := create_tween()
	tween.tween_property(_rig, "global_position", goal, 2.2)
	tween.tween_callback(func() -> void:
		_rig.walking = false
		var look := p.global_position - _rig.global_position
		_rig.rotation.y = atan2(look.x, look.z)
		_rig.play("beckon"))


## BACKDOOR: a keyhole opens behind Gemini, facing the way they came.
func open_door(p: Player, facing: Vector3) -> void:
	var away := p.global_position - facing
	away.y = 0.0
	_door = p.global_position + away.normalized() * 7.0
	_door.y = Game.terrain.get_height(_door.x, _door.z)
	_portal_at(_door, facing, 18.0)
	CosmicFx.shock(_door + Vector3(0, 7, 0), 14.0, 2.2, 0.7, GREEN)
	Fx.burst(_door + Vector3(0, 6, 0), GREEN, 60, 12.0, 0.09)
	Game.shake(0.7)
	p.stand_for_scene()


## Both walk through, and the door shuts behind them.
func go_through(p: Player) -> void:
	var goal := _door
	var to := goal - _rig.global_position
	_rig.rotation.y = atan2(to.x, to.z)
	_rig.walking = true
	p.walk_for_scene(goal, 2.1)
	var tween := create_tween()
	tween.tween_property(_rig, "global_position", goal, 2.1)
	tween.tween_callback(func() -> void:
		_rig.visible = false
		p.rig.visible = false
		CosmicFx.flash(GREEN, 0.8, 0.5)
		CosmicFx.shock(goal + Vector3(0, 7, 0), 22.0, 2.6, 0.7, GREEN)
		Game.shake(0.9)
		if _portal != null:
			_close_portal(0.15))


## The boss flexes and the locks shatter, too late.
func break_free(boss: Enemy) -> void:
	for node in _chains:
		node.queue_free()
	_chains.clear()
	for lock in _locks:
		Fx.burst(lock.global_position, GREEN, 30, 14.0, 0.09)
		lock.queue_free()
	_locks.clear()
	CosmicFx.shock(boss.chest_position(), 34.0, 2.6, 0.9, Color(1.0, 0.13, 0.2))
	Game.shake(1.6)
