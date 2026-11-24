class_name AbyssShow
extends CosmicShow
## The eight powers of อั้ม · ABYSS, as in aum.html, played out in the valley.
## It stands in for CosmicShow while อั้ม is the one being played, so the player drives it the same way:
## start() when a power begins, update() with how far through it is, finish() or stop() at the end.
## Nobody can stand against this form, so every number here is meant to be absurd.

const RED := Color(1.0, 0.1, 0.16)
const VIOLET := Color(0.62, 0.17, 1.0)
const PALE := Color(0.86, 0.7, 1.0)
const ERASE := 999999.0 ## What the last power does to anything it touches.
## The poses each power plays on the rig, in PoseRig's format. "lift" is in fractions of the rig's unit.
const POSES := {
	"a_raise": [
		[0.0, {}],
		[0.15, {"armR": Vector3(-2.6, 0, -0.2), "foreR": Vector3(-0.15, 0, 0), "armL": Vector3(-0.2, 0, 0.25), "foreL": Vector3(-0.5, 0, 0), "upper": Vector3(-0.1, 0, 0)}],
		[0.38, {"armR": Vector3(-2.6, 0, -0.2), "foreR": Vector3(-0.15, 0, 0), "armL": Vector3(-2.4, 0, 0.2), "foreL": Vector3(-0.15, 0, 0), "upper": Vector3(-0.12, 0, 0), "lift": Vector3(0, 0.45, 0)}],
		[0.86, {"armR": Vector3(-2.6, 0, -0.2), "foreR": Vector3(-0.15, 0, 0), "armL": Vector3(-2.4, 0, 0.2), "foreL": Vector3(-0.15, 0, 0), "upper": Vector3(-0.2, 0, 0), "lift": Vector3(0, 0.45, 0)}],
		[1.0, {}],
	],
	"a_slam": [
		[0.0, {}],
		[0.13, {"armR": Vector3(-2.6, 0, -0.3), "armL": Vector3(-2.6, 0, 0.3), "upper": Vector3(-0.1, 0, 0), "lift": Vector3(0, 0.9, 0)}],
		[0.2, {"armR": Vector3(-0.3, 0, -0.75), "armL": Vector3(-0.3, 0, 0.75), "upper": Vector3(0.32, 0, 0), "legR": Vector3(-0.5, 0, 0), "shinR": Vector3(0.9, 0, 0), "legL": Vector3(-0.5, 0, 0), "shinL": Vector3(0.9, 0, 0)}, "snap"],
		[0.4, {"armR": Vector3(-0.9, 0, -0.9), "armL": Vector3(-0.9, 0, 0.9), "upper": Vector3(-0.2, 0, 0)}],
		[0.82, {"armR": Vector3(-0.9, 0, -0.9), "armL": Vector3(-0.9, 0, 0.9), "upper": Vector3(-0.2, 0, 0)}],
		[1.0, {}],
	],
	"a_thrust": [
		[0.0, {}],
		[0.22, {"armR": Vector3(-1.0, 0, 0.35), "foreR": Vector3(-1.2, 0, 0), "armL": Vector3(-1.0, 0, -0.35), "foreL": Vector3(-1.2, 0, 0), "upper": Vector3(0.1, 0, 0)}],
		[0.3, {"armR": Vector3(-1.55, 0, 0.3), "foreR": Vector3(-0.1, 0, 0), "armL": Vector3(-1.55, 0, -0.3), "foreL": Vector3(-0.1, 0, 0), "upper": Vector3(0.18, 0, 0)}, "snap"],
		[0.8, {"armR": Vector3(-1.55, 0, 0.3), "foreR": Vector3(-0.1, 0, 0), "armL": Vector3(-1.55, 0, -0.3), "foreL": Vector3(-0.1, 0, 0), "upper": Vector3(0.18, 0, 0)}],
		[1.0, {}],
	],
	"a_legion": [
		[0.0, {}],
		[0.12, {"armR": Vector3(-1.2, 0, 0.55), "foreR": Vector3(-1.3, 0, 0), "armL": Vector3(-1.2, 0, -0.55), "foreL": Vector3(-1.3, 0, 0), "upper": Vector3(0.25, 0, 0)}],
		[0.22, {"armR": Vector3(-0.5, 0, -1.2), "armL": Vector3(-0.5, 0, 1.2), "upper": Vector3(-0.15, 0, 0), "lift": Vector3(0, 0.4, 0)}, "snap"],
		[0.5, {"armR": Vector3(-2.7, 0, -0.3), "armL": Vector3(-2.7, 0, 0.3), "lift": Vector3(0, 1.2, 0)}],
		[0.6, {"armR": Vector3(-0.6, 0, -0.5), "armL": Vector3(-0.6, 0, 0.5), "upper": Vector3(0.35, 0, 0)}, "snap"],
		[0.86, {"armR": Vector3(-0.6, 0, -0.5), "armL": Vector3(-0.6, 0, 0.5), "upper": Vector3(0.2, 0, 0)}],
		[1.0, {}],
	],
	"a_call": [
		[0.0, {}],
		[0.12, {"armR": Vector3(-2.7, 0, -0.2), "foreR": Vector3(-0.1, 0, 0), "armL": Vector3(-0.5, 0, 0.3), "foreL": Vector3(-0.6, 0, 0), "upper": Vector3(-0.1, 0, 0), "lift": Vector3(0, 0.6, 0)}],
		[0.66, {"armR": Vector3(-2.7, 0, -0.2), "foreR": Vector3(-0.1, 0, 0), "armL": Vector3(-0.5, 0, 0.3), "foreL": Vector3(-0.6, 0, 0), "upper": Vector3(-0.1, 0, 0), "lift": Vector3(0, 0.6, 0)}],
		[0.72, {"armR": Vector3(-1.0, 0, -0.6), "armL": Vector3(-1.0, 0, 0.6), "upper": Vector3(0.28, 0, 0)}, "snap"],
		[0.9, {"armR": Vector3(-1.0, 0, -0.6), "armL": Vector3(-1.0, 0, 0.6), "upper": Vector3(0.2, 0, 0)}],
		[1.0, {}],
	],
	"a_command": [
		[0.0, {}],
		[0.16, {"armR": Vector3(-0.8, 0, -1.3), "armL": Vector3(-0.8, 0, 1.3), "upper": Vector3(-0.1, 0, 0), "lift": Vector3(0, 0.8, 0)}],
		[0.42, {"armR": Vector3(-0.8, 0, -1.3), "armL": Vector3(-0.8, 0, 1.3), "lift": Vector3(0, 0.8, 0)}],
		[0.48, {"armR": Vector3(-2.2, 0, -0.9), "armL": Vector3(-2.2, 0, 0.9), "upper": Vector3(0.15, 0, 0), "lift": Vector3(0, 0.8, 0)}, "snap"],
		[0.84, {"armR": Vector3(-2.2, 0, -0.9), "armL": Vector3(-2.2, 0, 0.9), "upper": Vector3(0.15, 0, 0), "lift": Vector3(0, 0.8, 0)}],
		[1.0, {}],
	],
	"a_grip": [
		[0.0, {}],
		[0.18, {"armR": Vector3(-1.5, 0, 0.1), "foreR": Vector3(-0.1, 0, 0), "armL": Vector3(-0.4, 0, 0.3), "foreL": Vector3(-0.8, 0, 0), "upper": Vector3(0.05, 0, 0)}],
		[0.46, {"armR": Vector3(-1.5, 0, 0.1), "foreR": Vector3(-0.1, 0, 0), "armL": Vector3(-0.4, 0, 0.3), "foreL": Vector3(-0.8, 0, 0)}],
		[0.54, {"armR": Vector3(-0.8, 0, 0.1), "foreR": Vector3(-0.4, 0, 0), "armL": Vector3(-0.4, 0, 0.3), "foreL": Vector3(-0.8, 0, 0), "upper": Vector3(-0.2, 0, 0)}],
		[0.7, {"armR": Vector3(-0.8, 0, 0.1), "foreR": Vector3(-0.4, 0, 0), "upper": Vector3(-0.2, 0, 0)}],
		[0.73, {"armR": Vector3(-1.7, 0, 0.1), "foreR": Vector3(-0.2, 0, 0), "upper": Vector3(0.18, 0, 0)}, "snap"],
		[0.9, {"armR": Vector3(-1.7, 0, 0.1), "foreR": Vector3(-0.2, 0, 0), "upper": Vector3(0.18, 0, 0)}],
		[1.0, {}],
	],
	"a_end": [
		[0.0, {}],
		[0.28, {"armR": Vector3(-0.4, 0, -0.6), "armL": Vector3(-0.4, 0, 0.6), "upper": Vector3(-0.1, 0, 0), "lift": Vector3(0, 2.6, 0)}],
		[0.42, {"armR": Vector3(-1.2, 0, 0.55), "foreR": Vector3(-1.3, 0, 0), "armL": Vector3(-1.2, 0, -0.55), "foreL": Vector3(-1.3, 0, 0), "upper": Vector3(0.22, 0, 0), "lift": Vector3(0, 2.6, 0)}],
		[0.5, {"armR": Vector3(-0.9, 0, -1.7), "armL": Vector3(-0.9, 0, 1.7), "upper": Vector3(-0.12, 0, 0), "lift": Vector3(0, 2.8, 0)}, "snap"],
		[0.88, {"armR": Vector3(-0.9, 0, -1.7), "armL": Vector3(-0.9, 0, 1.7), "upper": Vector3(-0.12, 0, 0), "lift": Vector3(0, 2.8, 0)}],
		[1.0, {}],
	],
}

var _id := ""
var _qq := 0.0
var _len := 1.0
var _nodes: Array[Node] = [] ## Everything the power built, freed when it ends.
var _d := {} ## What the power in play remembers between frames.
var _hit := {} ## Enemy -> true, for blows that land once per enemy.
var _vig: ColorRect
var _vig_mat: ShaderMaterial
var _vig_goal := 0.0
var _vig_now := 0.0
var _clones: Array[AbyssBody] = []
var _giant: AbyssBody
var _rock_mesh: Mesh
var _void_mat: ShaderMaterial
var _spike_mat: ShaderMaterial


func _ready() -> void:
	super()
	# The dark closes in from the edges of the screen while these powers play.
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_vig = ColorRect.new()
	_vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float amount = 0.0;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p * vec2(1.0, 0.8));
	COLOR = vec4(0.02, 0.0, 0.05, smoothstep(0.45, 1.35, d) * amount);
}
"""
	_vig_mat = ShaderMaterial.new()
	_vig_mat.shader = shader
	_vig.material = _vig_mat
	layer.add_child(_vig)
	_void_mat = _rim_material(Color(0.55, 0.18, 1.0), false)
	_spike_mat = _rim_material(Color(0.66, 0.25, 1.0), true)
	var rock := SphereMesh.new()
	rock.radius = 1.0
	rock.height = 2.0
	rock.radial_segments = 6
	rock.rings = 3
	_rock_mesh = rock


## Black matter with a violet rim, and if asked, a glow at its foot.
func _rim_material(rim: Color, base_glow: bool) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, fog_disabled;
uniform vec3 rim = vec3(0.6, 0.2, 1.0);
uniform bool base_glow = false;
varying float h;
void vertex() { h = UV.y; }
void fragment() {
	float r = pow(1.0 - abs(dot(NORMAL, VIEW)), 2.0);
	vec3 c = vec3(0.01, 0.0, 0.02) + rim * r * 0.55;
	if (base_glow) c += rim * smoothstep(0.75, 1.0, h) * 0.6;
	ALBEDO = c;
}
"""
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("rim", Vector3(rim.r, rim.g, rim.b))
	m.set_shader_parameter("base_glow", base_glow)
	return m


# ------------------------------------------------------------------ the show's own life

func start(p: Player, id: String) -> void:
	_end()
	_p = p
	_id = id
	_qq = 0.0
	_len = p.skill_info(p._skill_key)["length"]
	_hit.clear()
	_d = {"from": p.global_position, "ahead": p.forward(), "right": p.forward().cross(Vector3.UP).normalized(), "fired": {}}
	call("_begin_" + id.trim_prefix("a_"))


func update(q: float) -> void:
	if _id == "":
		return
	q = minf(q, 1.0)
	var delta := get_process_delta_time()
	call("_play_" + _id.trim_prefix("a_"), q, delta)
	_qq = q


func channel(_key: String) -> float:
	return 0.0


func finish() -> void:
	_end()


func stop() -> void:
	_end()


func firewall_blocks(_at: Vector3, _from: Vector3) -> bool:
	return false


func warm(at: Vector3) -> void:
	# The shadows are built the first time a power needs them.
	for node: Node3D in _clones:
		node.global_position = at


func _end() -> void:
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()
	_nodes.clear()
	for clone in _clones:
		clone.visible = false
	if _giant != null:
		_giant.visible = false
	_id = ""
	_d = {}
	wide = 0.0
	turn = 0.0
	_vig_goal = 0.0


func _process(delta: float) -> void:
	if _vig_mat != null:
		_vig_now = lerpf(_vig_now, _vig_goal, 1.0 - exp(-4.0 * delta))
		_vig_mat.set_shader_parameter("amount", _vig_now)


# ------------------------------------------------------------------ helpers

static func _seg(q: float, a: float, b: float) -> float:
	return clampf((q - a) / (b - a), 0.0, 1.0)


static func _ease(k: float) -> float:
	return k * k * (3.0 - 2.0 * k)


static func _env(q: float, a: float, b: float, c: float, d: float) -> float:
	return _ease(_seg(q, a, b)) * (1.0 - _ease(_seg(q, c, d)))


## Fires `action` once, the first time the power passes `at`.
func _once(key: String, q: float, at: float) -> bool:
	if q < at or _d["fired"].has(key):
		return false
	_d["fired"][key] = true
	return true


func _add(node: Node3D) -> Node3D:
	Game.world.add_child(node)
	_nodes.append(node)
	return node


func _mesh(mesh: Mesh, material: Material, at: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = material
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(m)
	m.global_position = at
	return m


func _glow(tint: Color, strength := 1.0, additive := true) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_fog = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(tint.r * strength, tint.g * strength, tint.b * strength, tint.a)
	return m


func _black() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_fog = true
	m.albedo_color = Color(0, 0, 0)
	return m


func _sphere(radius: float, material: Material, at: Vector3) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	return _mesh(s, material, at)


## A soft glowing dot that always faces the camera.
func _billboard(size: float, tint: Color, at: Vector3, texture: Texture2D = null) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var m := _glow(tint)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = texture if texture != null else AbyssBody._soft_dot()
	return _mesh(quad, m, at)


static var _ring_tex: Texture2D
static func _ring_texture() -> Texture2D:
	if _ring_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.38, 0.46, 0.56, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0)])
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_ring_tex = t
	return _ring_tex


func _ground(at: Vector3) -> Vector3:
	return Vector3(at.x, Game.ground_height(at.x, at.z), at.z)


## Lightning, from the body's own lightning maker.
func _bolt(a: Vector3, b: Vector3, tint := VIOLET, life := 0.3, width := 0.12) -> void:
	if _p != null and _p.abyss != null:
		_p.abyss.spark(a, b, tint, life, width)
		Fx.burst(b, tint, 6, 5.0, 0.05)


## A one-off billow of black smoke with a violet fringe.
func _smoke(at: Vector3, amount: int, size: float, speed := 3.0, life := 1.8) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.85
	p.amount = maxi(amount, 1)
	p.lifetime = life
	p.local_coords = false
	p.direction = Vector3.UP
	p.spread = 70.0
	p.gravity = Vector3(0, 1.0, 0)
	p.initial_velocity_min = speed * 0.3
	p.initial_velocity_max = speed
	p.damping_min = 1.0
	p.damping_max = 2.0
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size * 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.4))
	p.scale_amount_curve = curve
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.12, 1.0])
	fade.colors = PackedColorArray([Color(0.05, 0.0, 0.08, 0.0), Color(0.05, 0.0, 0.08, 0.85), Color(0.05, 0.0, 0.08, 0.0)])
	p.color_ramp = fade
	var quad := QuadMesh.new()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_fog = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = AbyssBody._soft_dot()
	quad.material = m
	p.mesh = quad
	Game.world.add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(life + 0.2).timeout.connect(p.queue_free)


## Broken ground: a web of glowing red and violet fissures spreading out from `center`.
func _cracks_at(center: Vector3, radius: float, alpha: float) -> MeshInstance3D:
	var node: MeshInstance3D = _d.get("cracks")
	if node == null or not is_instance_valid(node):
		var quad := QuadMesh.new()
		quad.size = Vector2(1, 1)
		quad.orientation = PlaneMesh.FACE_Y
		var shader := Shader.new()
		shader.code = """
shader_type spatial;
render_mode unshaded, fog_disabled, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform float reach = 0.0;
uniform float alpha = 1.0;
vec2 h22(vec2 p) { return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453); }
void fragment() {
	vec2 w = (UV - 0.5) * 2.0;
	float dist = length(w);
	if (dist > reach + 0.02) discard;
	vec2 p = w * 9.0;
	p += vec2(sin(p.y * 1.3 + sin(p.x * 0.7)), sin(p.x * 1.1 + sin(p.y * 0.9))) * 0.22;
	vec2 i = floor(p), f = fract(p);
	float d1 = 8.0, d2 = 8.0;
	for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
		vec2 g = vec2(float(x), float(y));
		vec2 r = g + h22(i + g) - f;
		float d = dot(r, r);
		if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
	}
	float e = sqrt(d2) - sqrt(d1);
	float line = smoothstep(0.05, 0.0, e) * step(0.25, h22(i * 1.7 + 3.0).y + h22(i).x * 0.5);
	float halo = smoothstep(0.25, 0.0, e) * 0.15;
	float reveal = smoothstep(reach, reach - 0.08, dist) + exp(-pow((dist - reach) / 0.05, 2.0)) * 0.8;
	vec3 col = mix(vec3(1.0, 0.15, 0.3), vec3(0.6, 0.15, 1.0), h22(i).x) * (0.9 + 0.4 * sin(TIME * 4.0 - dist * 20.0));
	ALBEDO = col * (line + halo) * reveal * alpha * 1.6;
}
"""
		var m := ShaderMaterial.new()
		m.shader = shader
		node = _mesh(quad, m, center)
		_d["cracks"] = node
	node.global_position = Vector3(center.x, Game.ground_height(center.x, center.z) + 0.06, center.z)
	node.scale = Vector3(radius * 2.0, 1, radius * 2.0) if radius > 0.01 else Vector3.ONE * 0.01
	var mat := node.material_override as ShaderMaterial
	mat.set_shader_parameter("reach", 1.0 if radius > 0.01 else 0.0)
	mat.set_shader_parameter("alpha", alpha)
	return node


func _strike(enemy: Enemy, damage: float, tint := RED, force := 1.0) -> void:
	enemy.take_hit(damage * _p.damage_scale, 999.0, _p.global_position, false, tint, force)


## Every enemy within `radius` of `center` takes `damage`; with `key`, each only once per power.
func _blast(center: Vector3, radius: float, damage: float, key := "", tint := RED) -> void:
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var to := enemy.global_position - center
		to.y = 0.0
		if to.length() > radius + enemy.radius:
			continue
		if key != "":
			var mark := key + str(enemy.get_instance_id())
			if _hit.has(mark):
				continue
			_hit[mark] = true
		_strike(enemy, damage, tint)


func _make_shadows(p: Player) -> void:
	for i in 6:
		var clone := AbyssBody.new()
		clone.rig = p.rig
		Game.world.add_child(clone)
		clone.visible = false
		_clones.append(clone)
	_giant = AbyssBody.new()
	_giant.rig = p.rig
	Game.world.add_child(_giant)
	_giant.set_rim(Color(0.55, 0.14, 0.95))
	_giant.visible = false


# ------------------------------------------------------------------ 1 · BLACK HOLE
# A black sun tears open above him, lightning lashes from its disk, the ground breaks,
# everything near is dragged in, and it detonates.

func _begin_hole() -> void:
	var p := _p
	var h: Vector3 = p.global_position + _d["ahead"] * 30.0 + Vector3.UP * 7.5
	_d["H"] = h
	_d["core"] = _sphere(1.0, _black(), h)
	var disc := QuadMesh.new()
	disc.size = Vector2(1, 1)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, fog_disabled, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform float alpha = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y); }
void fragment() {
	vec2 v = (UV - 0.5) * 2.0;
	float r = length(v), k = (r - 0.23) / 0.77;
	float a2 = atan(v.y, v.x) - TIME * 2.0 / max(r, 0.05) + r * 3.0;
	float n = noise(vec2(cos(a2), sin(a2)) * 3.0 + r * 6.0) * 0.6 + noise(vec2(cos(a2), sin(a2)) * 7.0 - r * 9.0) * 0.4;
	vec3 col = mix(vec3(1.0, 0.95, 1.0), mix(vec3(0.75, 0.2, 1.0), vec3(0.8, 0.05, 0.18), smoothstep(0.15, 0.7, k)), smoothstep(0.0, 0.25, k));
	ALBEDO = col * smoothstep(0.0, 0.06, k) * smoothstep(1.0, 0.5, k) * (0.35 + n * 1.3) * alpha * 1.6;
}
"""
	var dm := ShaderMaterial.new()
	dm.shader = shader
	var d1 := _mesh(disc, dm, h)
	d1.rotation = Vector3(-1.25, atan2(_d["ahead"].x, _d["ahead"].z), 0.25)
	_d["disc"] = d1
	_d["disc_mat"] = dm
	_d["halo"] = _billboard(1.0, Color(0.85, 0.55, 1.0), h, _ring_texture())
	_d["glow"] = _billboard(1.0, Color(0.42, 0.1, 0.7), h)
	var rocks: Array = []
	for i in 40:
		var a := randf() * TAU
		var r := randf_range(8.0, 34.0)
		var at := _ground(p.global_position + Vector3(cos(a) * r, 0, sin(a) * r))
		var rock := _mesh(_rock_mesh, _void_mat, at)
		rock.scale = Vector3.ONE * randf_range(0.4, 1.5)
		rocks.append([rock, at, randf_range(1.0, 7.0), randf_range(0.2, 0.7)])
	_d["rocks"] = rocks
	Game.shake(0.4)


func _play_hole(q: float, delta: float) -> void:
	var h: Vector3 = _d["H"]
	var grow := _ease(_seg(q, 0.06, 0.3))
	var gone := _ease(_seg(q, 0.84, 0.88))
	var r := maxf(0.01, 4.0 * grow * (1.0 - gone))
	(_d["core"] as Node3D).scale = Vector3.ONE * r
	(_d["disc"] as Node3D).scale = Vector3.ONE * r * 7.0
	(_d["disc_mat"] as ShaderMaterial).set_shader_parameter("alpha", grow * (1.0 - gone))
	(_d["halo"] as Node3D).scale = Vector3.ONE * (r * 4.8 + 0.01)
	(_d["glow"] as Node3D).scale = Vector3.ONE * (r * 10.0 + 0.01)
	wide = 0.7 * grow
	_vig_goal = 0.75 * grow
	_cracks_at(_d["from"], 34.0 * _ease(_seg(q, 0.12, 0.55)), 1.0 - _ease(_seg(q, 0.9, 1.0)))
	if q > 0.08 and q < 0.86:
		CosmicFx.inflow(h, 4, 30.0, 0.8, VIOLET if randf() < 0.5 else RED)
		CosmicSkills.hole_pull(_p, h, 1.6)
		Game.shake(0.05 + 0.1 * grow)
		if randf() < 0.14 * grow:
			var a := randf() * TAU
			var from := h + Vector3(cos(a) * r * 2.2, randf_range(-0.5, 0.5) * r, sin(a) * r * 2.2)
			var to := _ground(_d["from"] + Vector3(randf_range(-30, 30), 0, randf_range(-30, 30)))
			_bolt(from, to, VIOLET if randf() < 0.7 else RED, 0.3, 0.2)
		if randf() < 0.1:
			_blast(h, 40.0, 1800.0)
	for rock: Array in _d["rocks"]:
		var node: Node3D = rock[0]
		if not is_instance_valid(node) or not node.visible:
			continue
		node.rotate_x(delta * 2.0)
		node.rotate_y(delta * 3.0)
		var loose := _ease(_seg(q, 0.15, 0.4))
		var k := _seg(q, 0.2 + rock[3] * 0.5, 0.45 + rock[3] * 0.5)
		var at: Vector3 = rock[1] + Vector3.UP * rock[2] * loose
		if k > 0.0:
			var e := k * k
			at = h + ((at - h) * (1.0 - e)).rotated(Vector3.UP, e * 6.0)
			if k >= 1.0:
				node.visible = false
				Fx.burst(h, VIOLET, 8, 4.0)
		node.global_position = at
	if _once("boom", q, 0.88):
		CosmicFx.flash(Color(0.3, 0.05, 0.5), 0.8, 0.6)
		CosmicFx.shock(h, 90.0, 2.0, 1.0, VIOLET)
		Fx.ring(_ground(_d["from"]), 50.0, VIOLET, 1.0)
		Fx.burst(h, Color(0.8, 0.4, 1.0), 120, 30.0, 0.12)
		_smoke(h, 60, 8.0, 14.0, 2.4)
		Game.shake(1.6)
		for i in 10:
			_bolt(h, h + Vector3(randf_range(-1, 1), randf_range(-1.2, 0.3), randf_range(-1, 1)).normalized() * randf_range(20.0, 40.0), Color(0.85, 0.5, 1.0), 0.5, 0.3)
		CosmicSkills.hole_blast(_p, h)
		_blast(_d["from"], 60.0, 60000.0, "boom", VIOLET)


# ------------------------------------------------------------------ 2 · ABYSS SPIKES
# He drops out of the air, the floor splits, a crown of giant spikes erupts round him,
# and seven rings of black spikes race outwards.

func _begin_spikes() -> void:
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.5
	cone.height = 1.0
	cone.radial_segments = 6
	cone.rings = 1
	var spikes: Array = []
	var origin: Vector3 = _d["from"]
	var add := func(at: Vector3, a: float, lean: float, wd: float, h: float, start_at: float, crown: bool) -> void:
		var pivot := Node3D.new()
		_add(pivot)
		pivot.global_position = _ground(at) - Vector3(0, 0.1, 0)
		pivot.rotation = Vector3(0, -a, 0)
		pivot.rotate_object_local(Vector3.FORWARD, lean)
		var mesh := MeshInstance3D.new()
		mesh.mesh = cone
		mesh.material_override = _spike_mat
		mesh.position.y = 0.5
		pivot.add_child(mesh)
		pivot.scale = Vector3(wd, 0.01, wd)
		spikes.append([pivot, h, start_at, false, crown])
	for i in 7:
		var a := float(i) / 7.0 * TAU + 0.2
		add.call(origin + Vector3(cos(a), 0, sin(a)) * 3.6, a, 0.3, 1.9, randf_range(6.5, 9.0), 0.2 + i * 0.006, true)
	var rings := [[7.0, 12], [10.5, 17], [14.0, 23], [18.0, 29], [22.0, 35], [26.5, 41], [31.0, 47]]
	for w in rings.size():
		var r: float = rings[w][0]
		var n: int = rings[w][1]
		for i in n:
			var a := float(i) / n * TAU + w * 0.3 + randf_range(-0.08, 0.08)
			var rr := r + randf_range(-0.6, 0.6)
			add.call(origin + Vector3(cos(a), 0, sin(a)) * rr, a, randf_range(0.15, 0.55), randf_range(0.7, 1.4), randf_range(2.4, 5.0) * (1.25 - w * 0.08), 0.26 + w * 0.065 + randf() * 0.02, false)
	_d["spikes"] = spikes
	_d["rings"] = rings


func _play_spikes(q: float, _delta: float) -> void:
	var origin: Vector3 = _d["from"]
	if _once("slam", q, 0.19):
		CosmicFx.flash(Color(0.25, 0.0, 0.4), 0.7, 0.5)
		Fx.ring(_ground(origin), 22.0, VIOLET, 0.8)
		Fx.ring(_ground(origin), 36.0, RED, 1.1)
		Fx.burst(origin + Vector3.UP, Color(0.75, 0.3, 1.0), 90, 18.0, 0.1)
		for i in 16:
			var a := float(i) / 16.0 * TAU
			_smoke(origin + Vector3(cos(a), 0.3, sin(a)) * 2.0, 3, 3.5, 9.0, 1.6)
		Game.shake(1.4)
		_blast(origin, 9.0, 40000.0, "slam")
	_cracks_at(origin, 36.0 * _ease(_seg(q, 0.19, 0.7)), 1.0 - _ease(_seg(q, 0.88, 1.0)))
	var rings: Array = _d["rings"]
	for w in rings.size():
		if _once("wave" + str(w), q, 0.26 + w * 0.065):
			Game.shake(0.45)
			var r: float = rings[w][0]
			for enemy in Game.enemies:
				if enemy.is_alive():
					var d := Vector2(enemy.global_position.x - origin.x, enemy.global_position.z - origin.z).length()
					if absf(d - r) < 3.5 + enemy.radius:
						_strike(enemy, 30000.0, VIOLET, 1.0)
						enemy.pull(Vector3.UP * 12.0)
	var sink := _ease(_seg(q, 0.82, 0.97))
	var up_list: Array = []
	for s: Array in _d["spikes"]:
		var node: Node3D = s[0]
		var k := _seg(q, s[2], s[2] + 0.05)
		var pop := _ease(k) * 1.15 if k < 1.0 else 1.15 - 0.15 * _ease(_seg(q, s[2] + 0.05, s[2] + 0.1))
		node.scale.y = maxf(0.01, s[1] * pop * (1.0 - sink))
		if k > 0.0 and not s[3]:
			s[3] = true
			Fx.burst(node.global_position + Vector3.UP * 0.3, VIOLET if randf() < 0.5 else RED, 10 if s[4] else 4, 6.0 if s[4] else 3.5)
			if s[4] or randf() < 0.2:
				_smoke(node.global_position + Vector3.UP * 0.4, 6 if s[4] else 2, 2.6, 3.0, 1.5)
		if s[3]:
			up_list.append(s)
	# Lightning jumps between the crown and the outer spikes.
	if q > 0.3 and q < 0.82 and randf() < 0.35 and up_list.size() > 8:
		var crown: Array = up_list.filter(func(e: Array) -> bool: return e[4])
		var outer: Array = up_list.filter(func(e: Array) -> bool: return not e[4])
		if not crown.is_empty() and not outer.is_empty():
			var a: Node3D = crown[randi() % crown.size()][0]
			var b: Node3D = outer[randi() % outer.size()][0]
			_bolt(a.to_global(Vector3(0, 0.95, 0)), b.to_global(Vector3(0, 0.95, 0)), VIOLET if randf() < 0.6 else RED, 0.25, 0.14)
	if _once("crumble", q, 0.82):
		Game.shake(0.6)
		for s: Array in _d["spikes"]:
			if s[4] or randi() % 4 == 0:
				_smoke((s[0] as Node3D).global_position + Vector3.UP, 2, 3.0, 2.0, 1.6)
	_vig_goal = 0.6 * _ease(_seg(q, 0.15, 0.25)) * (1.0 - sink)
	wide = 0.9 * _ease(_seg(q, 0.15, 0.3)) * (1.0 - sink)


# ------------------------------------------------------------------ 3 · OBLITERATE
# Dark gathers into a crackling ball between his hands, then a black beam sweeps the land ahead away.

func _begin_beam() -> void:
	_d["orb"] = _sphere(1.0, _black(), _p.abyss.hands_point())
	_d["orb_halo"] = _billboard(1.0, Color(0.7, 0.3, 1.0), _p.abyss.hands_point(), _ring_texture())
	var core := CylinderMesh.new()
	core.top_radius = 1.4
	core.bottom_radius = 1.4
	core.height = 1.0
	core.radial_segments = 24
	var beam := _mesh(core, _black(), _d["from"])
	beam.visible = false
	_d["beam"] = beam
	var sheath_mesh := CylinderMesh.new()
	sheath_mesh.top_radius = 2.4
	sheath_mesh.bottom_radius = 2.4
	sheath_mesh.height = 1.0
	sheath_mesh.radial_segments = 24
	var sheath := _mesh(sheath_mesh, _glow(Color(0.55, 0.17, 0.9, 0.16)), _d["from"])
	sheath.visible = false
	_d["sheath"] = sheath


func _play_beam(q: float, _delta: float) -> void:
	var hands: Vector3 = _p.abyss.hands_point()
	var charge := _ease(_seg(q, 0.02, 0.26))
	var fire := q > 0.3 and q < 0.8
	var orb_r := maxf(0.01, charge * 1.6 * (1.0 - _ease(_seg(q, 0.8, 0.86))))
	(_d["orb"] as Node3D).global_position = hands
	(_d["orb"] as Node3D).scale = Vector3.ONE * orb_r
	(_d["orb_halo"] as Node3D).global_position = hands
	(_d["orb_halo"] as Node3D).scale = Vector3.ONE * (orb_r * 4.8 + 0.01)
	if q < 0.3:
		CosmicFx.inflow(hands, 4, 6.0, 0.4, VIOLET if randf() < 0.6 else RED)
		if randf() < 0.25:
			_bolt(hands + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * orb_r, hands + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * 5.0, VIOLET, 0.15, 0.06)
		Game.shake(charge * 0.08)
	var beam: Node3D = _d["beam"]
	var sheath: Node3D = _d["sheath"]
	beam.visible = fire
	sheath.visible = fire
	_vig_goal = 0.65 * charge * (1.0 - _ease(_seg(q, 0.86, 1.0)))
	wide = 0.6 * charge
	_cracks_at(_d["from"], 40.0 * _ease(_seg(q, 0.3, 0.75)), 1.0 - _ease(_seg(q, 0.88, 1.0)))
	if not fire:
		return
	var ahead: Vector3 = _d["ahead"]
	var ang := -1.15 + _seg(q, 0.32, 0.78) * 2.3
	var dir := ahead.rotated(Vector3.UP, -ang)
	var tgt := _ground(_d["from"] + dir * 140.0)
	var length := hands.distance_to(tgt)
	var j := 1.0 + sin(Time.get_ticks_msec() * 0.04) * 0.12
	for b: Node3D in [beam, sheath]:
		b.global_position = hands.lerp(tgt, 0.5)
		b.look_at(tgt, Vector3.UP)
		b.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		b.scale = Vector3(j, length, j)
	Game.shake(0.18)
	# Along the beam the land explodes, and anything in its path is gone.
	var along := _ground(hands.lerp(tgt, randf()))
	Fx.burst(along + Vector3.UP, VIOLET if randf() < 0.5 else RED, 10, 9.0, 0.1)
	if randf() < 0.4:
		_smoke(along + Vector3.UP, 2, 4.0, 4.0, 1.6)
	if randf() < 0.3:
		_bolt(hands, hands.lerp(tgt, randf()) + Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2)), Color(0.8, 0.5, 1.0), 0.12, 0.1)
	for enemy in Game.enemies:
		if not enemy.is_alive():
			continue
		var to: Vector3 = enemy.global_position - _d["from"]
		to.y = 0.0
		if to.length() < 145.0 and absf(dir.signed_angle_to(to.normalized(), Vector3.UP)) < 0.1 + 2.5 / maxf(to.length(), 1.0):
			var mark := "beam" + str(enemy.get_instance_id())
			if not _hit.has(mark):
				_hit[mark] = true
				_strike(enemy, 50000.0, VIOLET)
				Fx.ring(enemy.global_position, 6.0, VIOLET, 0.5)
				_smoke(enemy.global_position + Vector3.UP, 10, 4.0, 5.0, 2.2)
				_bolt(enemy.global_position + Vector3(0, 60, 0), enemy.chest_position(), Color(0.85, 0.5, 1.0), 0.35, 0.3)
				Game.shake(0.5)
	if _once("end", q, 0.79):
		CosmicFx.flash(Color(0.3, 0.05, 0.5), 0.6, 0.5)
		Game.shake(0.9)


# ------------------------------------------------------------------ 4 · SHADOW LEGION
# Six copies of him tear out of his body, race outwards, leap, and come down like lightning.

func _begin_legion() -> void:
	if _clones.is_empty():
		_make_shadows(_p)
	_d["angles"] = []
	var face := atan2(_d["ahead"].x, _d["ahead"].z)
	for i in 6:
		_d["angles"].append(face + float(i) / 6.0 * TAU + 0.3)


func _play_legion(q: float, _delta: float) -> void:
	var origin: Vector3 = _d["from"]
	var out := _ease(_seg(q, 0.16, 0.32))
	var leap := _seg(q, 0.42, 0.6)
	var fade := _ease(_seg(q, 0.8, 0.95))
	if _once("out", q, 0.16):
		CosmicFx.flash(Color(0.25, 0.0, 0.4), 0.6, 0.4)
		_smoke(origin + Vector3.UP * 2.0, 30, 4.0, 10.0, 1.6)
		Fx.ring(_ground(origin), 14.0, VIOLET, 0.6)
		Game.shake(0.9)
	for i in _clones.size():
		var clone := _clones[i]
		var a: float = _d["angles"][i]
		clone.visible = q > 0.16 and fade < 1.0
		var r := 14.0 * out
		var at := origin + Vector3(sin(a), 0, cos(a)) * r
		at.y = Game.ground_height(at.x, at.z) + sin(leap * PI) * 8.0
		clone.global_position = at
		clone.rotation.y = a
		clone.scale = Vector3.ONE * maxf(0.01, 1.0 - fade)
		if q > 0.16 and q < 0.34 and randf() < 0.4:
			_smoke(at + Vector3.UP, 1, 2.0, 1.0, 1.0)
		if _once("land" + str(i), q, 0.6):
			var ground := _ground(at)
			Fx.ring(ground, 10.0, VIOLET, 0.6)
			Fx.burst(ground + Vector3.UP * 0.5, Color(0.8, 0.3, 1.0), 40, 12.0, 0.1)
			_smoke(ground + Vector3.UP * 0.6, 12, 4.0, 6.0, 2.0)
			_bolt(ground + Vector3(0, 50, 0), ground + Vector3(0, 2.5, 0), Color(0.85, 0.5, 1.0), 0.35, 0.3)
			Game.shake(0.7)
			_blast(ground, 11.0, 40000.0, "land" + str(i), VIOLET)
		if fade > 0.0 and fade < 1.0 and randf() < 0.3:
			_smoke(at + Vector3.UP * randf_range(0.5, 2.5), 1, 2.4, 1.2, 1.4)
	_cracks_at(origin, 22.0 * _ease(_seg(q, 0.6, 0.75)), 1.0 - _ease(_seg(q, 0.88, 1.0)))
	_vig_goal = 0.65 * _ease(_seg(q, 0.05, 0.2)) * (1.0 - fade)
	wide = 0.7 * out * (1.0 - fade)


# ------------------------------------------------------------------ 5 · DARK METEOR
# A rift opens in the sky and black stars fall out of it, ending with one the size of a hill.

func _begin_meteor() -> void:
	var center := CosmicSkills.aim_point(_p, 30.0)
	_d["center"] = center
	var ahead: Vector3 = _d["ahead"]
	var right: Vector3 = _d["right"]
	var rift_at := center + ahead * 30.0 + Vector3.UP * 42.0
	_d["rift"] = _billboard(1.0, Color(0.75, 0.3, 1.0), rift_at, _ring_texture())
	_d["rift_glow"] = _billboard(1.0, Color(0.35, 0.06, 0.6), rift_at)
	var meteors: Array = []
	for i in 26:
		var big := i == 25
		var size := 7.0 if big else randf_range(0.8, 1.8)
		var a := randf() * TAU
		var to := center if big else _ground(center + Vector3(cos(a), 0, sin(a)) * randf_range(4.0, 34.0))
		var from := to + right * 45.0 + ahead * 35.0 + Vector3(randf_range(-8, 8), 60.0, randf_range(-8, 8))
		var rock := _mesh(_rock_mesh, _void_mat, from)
		rock.scale = Vector3.ONE * size
		rock.visible = false
		var glow := _billboard(size * 5.0, Color(1.0, 0.3, 0.75), from)
		glow.visible = false
		var tail_mesh := CylinderMesh.new()
		tail_mesh.top_radius = size * 1.0
		tail_mesh.bottom_radius = size * 0.15
		tail_mesh.height = 1.0
		tail_mesh.radial_segments = 12
		var tail := _mesh(tail_mesh, _glow(Color(0.75, 0.3, 1.0, 0.55)), from)
		tail.visible = false
		meteors.append({"rock": rock, "glow": glow, "tail": tail, "from": from, "to": to, "size": size, "big": big,
			"at": 0.66 if big else 0.14 + float(i) / 25.0 * 0.48, "dur": 0.12 if big else 0.07, "hit": false})
	_d["meteors"] = meteors


func _play_meteor(q: float, _delta: float) -> void:
	var center: Vector3 = _d["center"]
	var rift := _ease(_seg(q, 0.04, 0.16)) * (1.0 - _ease(_seg(q, 0.82, 0.92)))
	(_d["rift"] as Node3D).scale = Vector3.ONE * (50.0 * rift + 0.01)
	(_d["rift_glow"] as Node3D).scale = Vector3.ONE * (80.0 * rift + 0.01)
	_vig_goal = 0.7 * _ease(_seg(q, 0.02, 0.14)) * (1.0 - _ease(_seg(q, 0.9, 1.0)))
	wide = 0.9 * rift
	_cracks_at(center, 44.0 * _ease(_seg(q, 0.16, 0.8)), 1.0 - _ease(_seg(q, 0.9, 1.0)))
	for m: Dictionary in _d["meteors"]:
		if m["hit"]:
			continue
		var k := _seg(q, m["at"], m["at"] + m["dur"])
		if k <= 0.0:
			continue
		var at: Vector3 = (m["from"] as Vector3).lerp(m["to"], k)
		for key: String in ["rock", "glow"]:
			var node: Node3D = m[key]
			node.visible = true
			node.global_position = at
		var tail: Node3D = m["tail"]
		tail.visible = true
		var back: Vector3 = (m["from"] as Vector3 - at)
		var tail_len := minf(back.length(), 40.0 if m["big"] else 22.0)
		if tail_len > 0.5:
			tail.global_position = at + back.normalized() * tail_len * 0.5
			tail.look_at(at, Vector3.UP if absf(back.normalized().y) < 0.99 else Vector3.RIGHT)
			tail.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
			tail.scale = Vector3(1, tail_len, 1)
		(m["rock"] as Node3D).rotate_x(0.1)
		if randf() < (1.0 if m["big"] else 0.3):
			_smoke(at, 1, m["size"] * 1.6, 0.5, 1.2)
		if k >= 1.0:
			m["hit"] = true
			for key: String in ["rock", "glow", "tail"]:
				(m[key] as Node3D).visible = false
			var ground := _ground(m["to"])
			var s: float = m["size"]
			Fx.ring(ground, 4.0 + s * 4.0, VIOLET, 0.7)
			Fx.burst(ground + Vector3.UP, Color(0.85, 0.3, 1.0), 120 if m["big"] else 24, 30.0 if m["big"] else 10.0, 0.12)
			_smoke(ground + Vector3.UP, 70 if m["big"] else 6, 10.0 if m["big"] else 3.0, 16.0 if m["big"] else 5.0, 2.6 if m["big"] else 1.8)
			Game.shake(2.0 if m["big"] else 0.35 + s * 0.15)
			if m["big"]:
				CosmicFx.flash(Color(0.4, 0.05, 0.6), 0.9, 0.7)
				CosmicFx.shock(ground, 110.0, 2.4, 1.1, VIOLET, true)
				for r: float in [20.0, 45.0, 80.0]:
					Fx.ring(ground, r, VIOLET, 1.3)
				for i in 12:
					_bolt(ground + Vector3.UP * 3.0, ground + Vector3(randf_range(-40, 40), randf_range(0, 20), randf_range(-40, 40)), Color(0.85, 0.5, 1.0), 0.5, 0.3)
				_blast(ground, 50.0, 200000.0, "", VIOLET)
			else:
				_blast(ground, 7.0, 25000.0, "", VIOLET)


# ------------------------------------------------------------------ 6 · ABYSS GATE
# A gate into the dark opens behind him and its tentacles come through, crash down around him,
# and thrash the ground apart.

func _begin_gate() -> void:
	var ahead: Vector3 = _d["ahead"]
	var c: Vector3 = _d["from"] + ahead * 30.0 + Vector3.UP * 13.0
	var portal := Node3D.new()
	_add(portal)
	portal.global_position = c
	portal.look_at(c - ahead, Vector3.UP)
	_d["portal"] = portal
	var disc := QuadMesh.new()
	disc.size = Vector2(1, 1)
	var hole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 0.05
	hole.mesh = cm
	hole.material_override = _black()
	hole.rotation.x = PI * 0.5
	portal.add_child(hole)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, fog_disabled, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
uniform float alpha = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y); }
void fragment() {
	vec2 v = (UV - 0.5) * 2.0;
	float r = length(v), k = (r - 0.62) / 0.38;
	float a2 = atan(v.y, v.x) + TIME * 0.8 + r * 2.0;
	float n = noise(vec2(cos(a2), sin(a2)) * 3.0 + r * 4.0 - TIME * 0.5);
	vec3 col = mix(vec3(1.0, 0.85, 1.0), mix(vec3(0.7, 0.15, 1.0), vec3(0.8, 0.05, 0.25), clamp(k, 0.0, 1.0)), smoothstep(0.0, 0.3, k));
	ALBEDO = col * smoothstep(-0.04, 0.06, k) * smoothstep(1.0, 0.3, k) * (0.3 + n * 1.2) * alpha * 1.5;
}
"""
	var rim_mat := ShaderMaterial.new()
	rim_mat.shader = shader
	var rim := MeshInstance3D.new()
	rim.mesh = disc
	rim.material_override = rim_mat
	portal.add_child(rim)
	_d["hole"] = hole
	_d["rim"] = rim
	_d["rim_mat"] = rim_mat
	var ball := SphereMesh.new()
	ball.radius = 1.0
	ball.height = 2.0
	ball.radial_segments = 10
	ball.rings = 6
	var tents: Array = []
	for j in 7:
		var a := float(j) / 7.0 * TAU
		var side := (float(j) / 6.0 - 0.5) * 2.4
		var dist := randf_range(8.0, 22.0)
		var target: Vector3 = _d["from"] + ahead.rotated(Vector3.UP, side) * dist
		var segs: Array = []
		for i in 30:
			var m := _mesh(ball, _void_mat, c)
			m.visible = false
			segs.append(m)
		tents.append({"base": Vector3(cos(a) * 4.0, sin(a) * 4.0, 0.3), "target": target, "segs": segs, "at": 0.18 + j * 0.03, "hit": false, "ph": randf() * 6.0})
	_d["tents"] = tents


func _play_gate(q: float, _delta: float) -> void:
	var portal: Node3D = _d["portal"]
	var open := _ease(_seg(q, 0.04, 0.2)) * (1.0 - _ease(_seg(q, 0.9, 1.0)))
	(_d["hole"] as Node3D).scale = Vector3(9.0, 1, 9.0) * maxf(open, 0.01)
	(_d["rim"] as Node3D).scale = Vector3.ONE * 32.0 * maxf(open, 0.01)
	(_d["rim_mat"] as ShaderMaterial).set_shader_parameter("alpha", open)
	if open > 0.3 and randf() < 0.15:
		var a := randf() * TAU
		_bolt(portal.to_global(Vector3(cos(a), sin(a), 0) * 10.0), portal.to_global(Vector3(cos(a + 1.0), sin(a + 1.0), 0) * 14.0), VIOLET, 0.2, 0.2)
	var thrash := _ease(_seg(q, 0.48, 0.55)) * (1.0 - _ease(_seg(q, 0.78, 0.84)))
	var t := Time.get_ticks_msec() * 0.001
	for o: Dictionary in _d["tents"]:
		var e := _ease(_seg(q, o["at"], o["at"] + 0.2)) * (1.0 - _ease(_seg(q, 0.82, 0.94)))
		var p0: Vector3 = portal.to_global(o["base"])
		var target: Vector3 = (o["target"] as Vector3 - _d["from"]).rotated(Vector3.UP, sin(t * 2.2 + o["ph"]) * 0.6 * thrash) + _d["from"]
		target = _ground(target)
		var p1 := p0.lerp(target, 0.45) + Vector3.UP * 10.0
		var segs: Array = o["segs"]
		for i in segs.size():
			var m: MeshInstance3D = segs[i]
			var s := float(i) / (segs.size() - 1) * e
			m.visible = e > 0.01
			if not m.visible:
				continue
			var b := p0 * (1.0 - s) * (1.0 - s) + p1 * 2.0 * (1.0 - s) * s + target * s * s
			var w := sin(s * 9.0 - t * 5.0 + o["ph"]) * 2.4 * s * (1.0 - s) * 2.0
			b += Vector3(sin(o["ph"]) * w, cos(t * 3.0 + s * 6.0) * w * 0.6, cos(o["ph"]) * w)
			b.y = maxf(b.y, Game.ground_height(b.x, b.z) + 0.5)
			m.global_position = b
			m.scale = Vector3.ONE * (2.0 * pow(1.0 - float(i) / segs.size(), 0.6) + 0.25)
		var tip: Vector3 = (segs[segs.size() - 1] as Node3D).global_position
		if e >= 0.99 and not o["hit"]:
			o["hit"] = true
			Game.shake(0.8)
			Fx.ring(target, 9.0, VIOLET, 0.6)
			Fx.burst(target + Vector3.UP, Color(0.8, 0.3, 1.0), 50, 14.0, 0.1)
			_smoke(target + Vector3.UP, 14, 4.0, 6.0, 2.0)
			_blast(target, 10.0, 40000.0, "slam" + str(o["ph"]), VIOLET)
		if thrash > 0.2 and randf() < 0.08:
			_smoke(tip, 3, 3.0, 4.0, 1.4)
			Fx.burst(tip, VIOLET, 10, 6.0)
			Game.shake(0.25)
			_blast(tip, 8.0, 12000.0)
		if thrash > 0.2 and randf() < 0.05:
			_bolt(p0, tip, Color(0.85, 0.5, 1.0), 0.2, 0.15)
	Game.shake(0.04 + open * 0.06)
	_vig_goal = 0.7 * open
	wide = 0.9 * open
	_cracks_at(_d["from"], 30.0 * _ease(_seg(q, 0.3, 0.6)), 1.0 - _ease(_seg(q, 0.88, 1.0)))


# ------------------------------------------------------------------ 7 · VOID CHAINS
# Six gates open in the ground round his prey; chains of the abyss shoot out, bind it, and crush it to nothing.

func _begin_chains() -> void:
	var prey: Enemy = _p.target if _p.target != null and _p.target.is_alive() else null
	if prey == null:
		var best := 90.0
		for enemy in Game.enemies:
			if enemy.is_alive():
				var d := enemy.global_position.distance_to(_p.global_position)
				if d < best:
					best = d
					prey = enemy
	_d["prey"] = prey
	var at: Vector3 = prey.chest_position() if prey != null else CosmicSkills.aim_point(_p, 18.0) + Vector3.UP * 6.0
	_d["T"] = at
	if prey == null:
		# Nothing to bind: a titan of light rises to show what happens to one.
		var ico := SphereMesh.new()
		ico.radius = 4.0
		ico.height = 8.0
		ico.radial_segments = 8
		ico.rings = 5
		var titan := _mesh(ico, _glow(Color(0.75, 1.0, 0.97, 0.35)), at)
		_d["titan"] = titan
		_d["heart"] = _billboard(6.0, Color(0.8, 1.0, 1.0), at)
	else:
		prey.freeze(4.5)
	var link := TorusMesh.new()
	link.inner_radius = 0.28
	link.outer_radius = 0.5
	link.rings = 10
	link.ring_segments = 6
	var chains: Array = []
	for i in 6:
		var a := float(i) / 6.0 * TAU
		var base := _ground(Vector3(at.x, 0, at.z) + Vector3(cos(a), 0, sin(a)) * 10.0)
		var hole := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 1.8
		cyl.bottom_radius = 1.8
		cyl.height = 0.05
		hole.mesh = cyl
		hole.material_override = _black()
		_add(hole)
		hole.global_position = base + Vector3.UP * 0.05
		var rim := TorusMesh.new()
		rim.inner_radius = 1.8
		rim.outer_radius = 2.3
		var ring_node := _mesh(rim, _glow(Color(0.7, 0.3, 1.0)), base + Vector3.UP * 0.1)
		var off := Vector3(cos(a + 0.5) * 3.0, 1.4 if i % 2 else -1.4, sin(a + 0.5) * 3.0)
		var n := int(ceil(base.distance_to(at + off) / 0.85))
		var links: Array = []
		for k in n:
			var m := _mesh(link, _spike_mat, base)
			m.visible = false
			links.append(m)
		chains.append({"base": base, "off": off, "links": links, "hole": hole, "rim": ring_node, "at": 0.18 + i * 0.035, "locked": false})
	_d["chains"] = chains


func _play_chains(q: float, delta: float) -> void:
	var prey: Enemy = _d["prey"]
	var alive := prey != null and is_instance_valid(prey) and prey.is_alive()
	var center: Vector3 = prey.chest_position() if alive else _d["T"]
	var open := _ease(_seg(q, 0.05, 0.16)) * (1.0 - _ease(_seg(q, 0.88, 0.98)))
	var squeeze := _ease(_seg(q, 0.48, 0.7))
	var broke := q >= 0.7
	if _d.has("titan"):
		var titan: Node3D = _d["titan"]
		titan.visible = not broke
		titan.scale = Vector3.ONE * maxf(0.01, _ease(_seg(q, 0.0, 0.14)) * (1.0 - squeeze * 0.7))
		titan.rotate_y(delta * (1.0 - squeeze))
		var struggle := _seg(q, 0.32, 0.7)
		titan.global_position = center + Vector3(sin(q * 160.0), sin(q * 120.0), cos(q * 140.0)) * 0.3 * struggle
		(_d["heart"] as Node3D).visible = not broke
	if alive and q > 0.3 and q < 0.7:
		prey.freeze(0.5)
	if q > 0.58 and q < 0.7:
		CosmicFx.inflow(center, 6, 10.0, 0.4, Color(0.8, 0.6, 1.0))
	var cs := 1.0 - squeeze * 0.7
	for c: Dictionary in _d["chains"]:
		(c["hole"] as Node3D).scale = Vector3(maxf(open, 0.01), 1, maxf(open, 0.01))
		(c["rim"] as Node3D).scale = Vector3.ONE * maxf(open, 0.01)
		var e := _ease(_seg(q, c["at"], c["at"] + 0.12)) * ((1.0 - _ease(_seg(q, 0.72, 0.86))) if broke else 1.0)
		var taut := _ease(_seg(q, c["at"] + 0.12, 0.36))
		var anchor: Vector3 = center + (c["off"] as Vector3) * cs
		var links: Array = c["links"]
		var n := links.size()
		var shown := int(floor(e * n))
		var base: Vector3 = c["base"]
		for k in n:
			var m: MeshInstance3D = links[k]
			m.visible = k < shown
			if not m.visible:
				continue
			var u := (k + 0.5) / n
			var u2 := (k + 1.5) / n
			var pt := base.lerp(anchor, u) - Vector3.UP * sin(u * PI) * 2.0 * (1.0 - taut)
			var nx := base.lerp(anchor, u2) - Vector3.UP * sin(u2 * PI) * 2.0 * (1.0 - taut)
			m.global_position = pt
			if pt.distance_to(nx) > 0.01:
				m.look_at(nx, Vector3.UP if absf((nx - pt).normalized().y) < 0.99 else Vector3.RIGHT)
				m.rotate_object_local(Vector3.FORWARD, PI * 0.5 if k % 2 else 0.0)
				m.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		if e >= 1.0 and not c["locked"]:
			c["locked"] = true
			Game.shake(0.5)
			Fx.burst(anchor, VIOLET, 20, 6.0)
			_bolt(base + Vector3.UP * 0.5, anchor, VIOLET, 0.25, 0.15)
	if q > 0.32 and q < 0.7 and randf() < 0.1:
		var ch: Dictionary = _d["chains"][randi() % 6]
		_bolt(ch["base"] + Vector3.UP * 0.5, center, Color(0.85, 0.5, 1.0), 0.18, 0.12)
		Game.shake(0.2)
	if _once("crush", q, 0.7):
		CosmicFx.flash(Color(0.4, 0.05, 0.6), 0.8, 0.6)
		CosmicFx.shock(center, 50.0, 2.0, 0.9, VIOLET)
		Fx.burst(center, Color(0.85, 0.4, 1.0), 120, 24.0, 0.12)
		Fx.burst(center, Color(0.9, 1.0, 1.0), 60, 16.0, 0.08)
		_smoke(center, 40, 7.0, 10.0, 2.4)
		for r: float in [14.0, 28.0]:
			Fx.ring(_ground(center), r, VIOLET, 1.2)
		for i in 10:
			_bolt(center, center + Vector3(randf_range(-1, 1), randf_range(-0.5, 1), randf_range(-1, 1)).normalized() * 25.0, Color(0.85, 0.5, 1.0), 0.5, 0.25)
		Game.shake(1.8)
		if alive:
			_strike(prey, ERASE, VIOLET)
		_blast(center, 16.0, 40000.0, "", VIOLET)
	_vig_goal = 0.65 * open
	wide = 0.5 * open
	_cracks_at(_ground(center), 20.0 * _ease(_seg(q, 0.1, 0.4)), 1.0 - _ease(_seg(q, 0.88, 1.0)))


# ------------------------------------------------------------------ 8 · END OF ALL
# He rises under a black eclipse; his colossal shadow climbs out of the dark behind him; lightning tears the sky,
# the ground breaks loose, and a sphere of darkness swallows the whole world but him.

func _begin_end() -> void:
	if _giant == null:
		_make_shadows(_p)
	var ahead: Vector3 = _d["ahead"]
	var sky := SphereMesh.new()
	sky.radius = 1.0
	sky.height = 2.0
	var night := StandardMaterial3D.new()
	night.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	night.disable_fog = true
	night.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	night.cull_mode = BaseMaterial3D.CULL_FRONT
	night.albedo_color = Color(0, 0, 0, 0)
	night.no_depth_test = false
	var dome := _mesh(sky, night, _p.global_position)
	dome.scale = Vector3.ONE * 900.0
	_d["night"] = night
	_d["sky"] = dome
	# The eclipse: a black disc in a white corona.
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.34, 0.36, 0.42, 0.62, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 1), Color(0, 0, 0, 1), Color(1, 1, 1, 1), Color(0.88, 0.8, 1, 0.75), Color(0.55, 0.27, 1, 0.22), Color(0, 0, 0, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	var em := StandardMaterial3D.new()
	em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	em.disable_fog = true
	em.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	em.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	em.albedo_texture = tex
	em.albedo_color = Color(1, 1, 1, 0)
	var eclipse := _mesh(quad, em, _p.global_position + ahead * 320.0 + Vector3.UP * 95.0)
	eclipse.scale = Vector3.ONE * 170.0
	_d["eclipse"] = em
	# The wave of nothing: black inside, a thin violet skin.
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, shadows_disabled;
uniform float alpha = 0.0;
void fragment() {
	float rim = pow(1.0 - abs(dot(NORMAL, VIEW)), 3.0);
	ALBEDO = vec3(0.55, 0.15, 1.0) * rim * 1.5;
	ALPHA = (0.92 * (1.0 - rim) + rim) * alpha;
}
"""
	var wm := ShaderMaterial.new()
	wm.shader = shader
	var wave := _mesh(sky, wm, _p.global_position + Vector3.UP * 4.0)
	wave.scale = Vector3.ONE * 0.01
	_d["wave"] = wave
	_d["wave_mat"] = wm
	var rocks: Array = []
	for i in 70:
		var at := _ground(_p.global_position + ahead.rotated(Vector3.UP, randf_range(-1.3, 1.3)) * randf_range(12.0, 70.0))
		var rock := _mesh(_rock_mesh, _void_mat, at)
		rock.scale = Vector3.ONE * randf_range(0.4, 1.6)
		rocks.append([rock, at, randf_range(4.0, 26.0), randf() * 0.25])
	_d["rocks"] = rocks


func _play_end(q: float, delta: float) -> void:
	var origin: Vector3 = _d["from"]
	var ahead: Vector3 = _d["ahead"]
	var dark := _ease(_seg(q, 0.02, 0.18)) * (1.0 - _ease(_seg(q, 0.92, 1.0)))
	(_d["night"] as StandardMaterial3D).albedo_color = Color(0.01, 0.0, 0.02, 0.93 * dark)
	(_d["sky"] as Node3D).global_position = Game.camera.global_position if Game.camera != null else origin
	(_d["eclipse"] as StandardMaterial3D).albedo_color = Color(1, 1, 1, _ease(_seg(q, 0.06, 0.22)) * (1.0 - _ease(_seg(q, 0.9, 0.98))))
	_vig_goal = 0.8 * dark
	wide = 1.2 * dark
	# The shadow rises behind him, many times his size, moving as he moves.
	var rise := _ease(_seg(q, 0.08, 0.34))
	var sink := _ease(_seg(q, 0.88, 1.0))
	_giant.visible = rise > 0.0 and sink < 1.0
	var back := origin + ahead * 55.0
	_giant.global_position = Vector3(back.x, Game.ground_height(back.x, back.z) - 40.0 + rise * 32.0 - sink * 40.0, back.z)
	_giant.rotation.y = _p.rig.rotation.y + PI
	_giant.scale = Vector3.ONE * 11.0
	if rise > 0.0 and rise < 1.0:
		Game.shake(0.15)
		if randf() < 0.4:
			_smoke(back + Vector3(randf_range(-15, 15), 0.5, randf_range(-8, 8)), 2, 8.0, 3.0, 2.2)
	_cracks_at(origin, 90.0 * _ease(_seg(q, 0.08, 0.45)), 1.0 - _ease(_seg(q, 0.9, 1.0)))
	# The sky splits with lightning.
	if q > 0.12 and q < 0.5 and randf() < 0.2:
		var at := _ground(origin + Vector3(randf_range(-80, 80), 0, randf_range(-80, 80)))
		_bolt(at + Vector3(randf_range(-15, 15), 90.0, randf_range(-15, 15)), at, VIOLET if randf() < 0.7 else RED, 0.35, 0.45)
		Fx.ring(at, 6.0, VIOLET, 0.5)
		_smoke(at + Vector3.UP, 4, 5.0, 3.0, 1.8)
		Game.shake(0.3)
	for rock: Array in _d["rocks"]:
		var node: Node3D = rock[0]
		if not node.visible:
			continue
		node.global_position = rock[1] + Vector3.UP * (_seg(q, rock[3], 1.0) * rock[2])
		node.rotate_x(delta * 0.6)
		node.rotate_y(delta * 0.4)
	var reach := _ease(_seg(q, 0.5, 0.72)) * 260.0
	var wave: Node3D = _d["wave"]
	wave.scale = Vector3.ONE * maxf(0.01, reach)
	(_d["wave_mat"] as ShaderMaterial).set_shader_parameter("alpha", 0.0 if q < 0.5 else 1.0 - _ease(_seg(q, 0.86, 1.0)))
	if q > 0.5:
		for rock: Array in _d["rocks"]:
			var node: Node3D = rock[0]
			if node.visible and node.global_position.distance_to(wave.global_position) < reach:
				node.visible = false
				Fx.burst(node.global_position, VIOLET, 8, 5.0)
		# Everything the darkness reaches is erased.
		_blast(origin, reach, ERASE, "wave", VIOLET)
	if _once("wave", q, 0.5):
		CosmicFx.flash(Color(0.3, 0.02, 0.5), 1.0, 0.8)
		for r: float in [30.0, 60.0, 100.0, 150.0]:
			Fx.ring(_ground(origin), r, VIOLET, 1.6)
		Fx.burst(origin + Vector3.UP * 5.0, Color(0.85, 0.4, 1.0), 200, 40.0, 0.14)
		_smoke(origin + Vector3.UP * 3.0, 80, 10.0, 20.0, 2.4)
		for i in 14:
			var a := float(i) / 14.0 * TAU
			_bolt(origin + Vector3.UP * 8.0, origin + Vector3(cos(a) * 60.0, randf_range(0, 20), sin(a) * 60.0), Color(0.85, 0.5, 1.0), 0.6, 0.4)
		Game.shake(2.0)
	if q > 0.5 and q < 0.72:
		Game.shake(0.35)
	if _once("calm", q, 0.9):
		Fx.ring(_ground(origin), 20.0, Color(1, 1, 1), 1.0)
