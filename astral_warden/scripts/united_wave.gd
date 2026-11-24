class_name UnitedWave
extends Node3D
## UNITED WAVE, GEMINI ARGON's last resort, from gemini_aegis.html. The other heroes' shadows stand up
## in the sky behind Gemini, push their power into its back, and it leaves the hands as one wave.
## Positions are in the page's units on CosmicShow's stage (+Z is where Gemini faces, one unit is K metres).

const K := CosmicShow.K
const GHOST := preload("res://shaders/hero_ghost.gdshader")
const PALE := Color("e8fffb")
const CYAN := Color("3fe8ff")
const MINT := Color("7dffc8")
## y is where the feet hang: they float in the sky, huge and faint. The page has them straight behind
## Gemini, but the game's camera stands there, so they flank it, a little behind, where the camera sees them.
const HEROES := [
	{"name": "CLAWD", "sub": "COSMIC GUARDIAN", "color": Color("ff8a2a"), "at": Vector2(-24, -4), "y": 16.0, "height": 22.0, "file": "res://models/npc/clawd0.glb"},
	{"name": "CHATGPT", "sub": "GOD OF TECHNOLOGY", "color": Color("3dffc8"), "at": Vector2(24, -4), "y": 10.0, "height": 38.0, "file": "res://models/npc/gpt0.glb"},
	{"name": "GROK", "sub": "GOD OF DESTRUCTION", "color": Color("c45cff"), "at": Vector2(-44, -12), "y": 14.0, "height": 42.0, "file": "res://models/npc/grok0.glb"},
	{"name": "อั้ม", "sub": "THE ARCHITECT", "color": Color("ffd08a"), "at": Vector2(44, -12), "y": 14.0, "height": 42.0, "file": "res://models/npc/aum.glb"},
]
const WAVE_LEN := 260.0
const WAVE_R := 4.6
const ORB_AHEAD := 1.3 ## Metres in front of the chest where the charge gathers.

var _built := false
var _stage: Node3D
var _p: Player
var _ghosts: Array = [] ## [holder, material, hands (local points), size]
var _ties: Array = [] ## Per hero, two [node, material].
var _wave: Array
var _strands: Array = []
var _orb: MeshInstance3D
var _orb_mat: ShaderMaterial
var _star: MeshInstance3D
var _star_mat: ShaderMaterial
var _ring_clock := 0.0
var _ring_next := 0
var _charge_clock := 0.0
var _beat := 0.0
var _wave_power := 0.0
var _wave_r := 1.0


func _build() -> void:
	if _built:
		return
	_built = true
	for h: Dictionary in HEROES:
		var holder := Node3D.new()
		add_child(holder)
		var material := ShaderMaterial.new()
		material.shader = GHOST
		material.set_shader_parameter("tint", h["color"])
		var model: Node3D = (load(h["file"]) as PackedScene).instantiate()
		holder.add_child(model)
		var box := AABB()
		var first := true
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			mesh.material_override = material
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mesh.extra_cull_margin = 60.0
			var part: AABB = _relative_transform(model, mesh) * mesh.get_aabb()
			box = part if first else box.merge(part)
			first = false
		var size := box.size
		# Stand the model on its feet at the middle of the holder.
		model.position = Vector3(-(box.position.x + size.x * 0.5), -box.position.y, -(box.position.z + size.z * 0.5))
		var hands := [Vector3(-size.x * 0.32, size.y * 0.6, size.z * 0.5), Vector3(size.x * 0.32, size.y * 0.6, size.z * 0.5)]
		_ghosts.append([holder, material, hands, size])
		var pair := []
		for j in 2:
			var tie := CosmicFx.flame(90.0, 0.9, h["color"], self)
			(tie[0] as Node3D).visible = false
			pair.append(tie)
		_ties.append(pair)
	_wave = CosmicFx.flame(WAVE_LEN, 13.0, PALE, self)
	for h: Dictionary in HEROES:
		_strands.append(CosmicFx.flame(WAVE_LEN, 8.0, h["color"], self))
	var core := CosmicFx._instance(QuadMesh.new(), CosmicFx.STAR)
	_orb = core[0]
	_orb_mat = core[1]
	_orb.reparent(self)
	var star := CosmicFx._instance(QuadMesh.new(), CosmicFx.STAR)
	_star = star[0]
	_star_mat = star[1]
	_star.reparent(self)
	_orb_mat.set_shader_parameter("tint", Color.WHITE)
	hide_all()


static func _relative_transform(root: Node3D, node: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != root:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


func hide_all() -> void:
	if not _built:
		return
	for g: Array in _ghosts:
		(g[0] as Node3D).visible = false
	for pair: Array in _ties:
		for tie: Array in pair:
			(tie[0] as Node3D).visible = false
	(_wave[0] as Node3D).visible = false
	for s: Array in _strands:
		(s[0] as Node3D).visible = false
	_orb.visible = false
	_star.visible = false
	_wave_power = 0.0


## Shows every piece once behind the loading screen, so the first real use cannot hitch.
func warm(stage: Node3D, at: Vector3) -> void:
	_build()
	_stage = stage
	for g: Array in _ghosts:
		(g[0] as Node3D).visible = true
		(g[0] as Node3D).global_position = at
	(_wave[0] as Node3D).visible = true
	_orb.visible = true


func begin(p: Player, stage: Node3D) -> void:
	_build()
	_p = p
	_stage = stage
	_ring_clock = 0.0
	_ring_next = 0
	_beat = 0.0


func _hero_center(i: int) -> Vector3:
	var h: Dictionary = HEROES[i]
	return _stage.to_global(Vector3(h["at"].x, h["y"] + h["height"] * 0.5, h["at"].y))


func _back() -> Vector3:
	return _p.chest() - _p.forward() * 0.6 + Vector3(0, 0.3, 0)


func orb_point() -> Vector3:
	return _p.chest() + _p.forward() * ORB_AHEAD + Vector3(0, 0.2, 0)


func _hand_points(i: int) -> Array:
	var g: Array = _ghosts[i]
	var holder: Node3D = g[0]
	var out := []
	for hand: Vector3 in g[2]:
		out.append(holder.global_transform * hand)
	return out


## Every frame of the move: `show` hands over its channels.
func apply(show: CosmicShow, time: float) -> void:
	if _p == null:
		return
	var gh := show.channel("gh")
	var tie := show.channel("tie")
	var ball := show.channel("ball")
	var grow := show.channel("kw")
	var wp := show.channel("kwP")
	var flare := show.channel("flare")
	var r := show.channel("kwR")
	if r <= 0.0:
		r = 1.0
	var back := _back()
	var orb := orb_point()
	var face := _stage.to_global(Vector3.ZERO)
	for i in HEROES.size():
		var h: Dictionary = HEROES[i]
		var g: Array = _ghosts[i]
		var holder: Node3D = g[0]
		var material: ShaderMaterial = g[1]
		var size: Vector3 = g[3]
		var k := clampf(gh * 1.8 - i * 0.22, 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)
		holder.visible = e > 0.005
		var local := Vector3(h["at"].x * (1.0 - flare * 0.15), h["y"] + (1.0 - e) * -10.0 + sin(time * 1.1 + i) * 1.2, h["at"].y * (1.0 - flare * 0.15))
		var at := _stage.to_global(local)
		var look := face + Vector3(0, at.y - face.y, 0)
		var basis := Basis.looking_at(at - look, Vector3.UP) if at.distance_to(look) > 0.01 else Basis.IDENTITY
		var scale_k := float(h["height"]) * K / maxf(size.y, 0.001)
		holder.global_transform = Transform3D(basis.scaled(Vector3.ONE * scale_k), at)
		material.set_shader_parameter("a", e * (0.42 + 0.08 * sin(time * 9.0 + i * 2.0) + flare * 0.3 + _beat * 0.2))
		var tie_power := tie * e * (0.75 + 0.25 * sin(time * 23.0 + i))
		var hands := _hand_points(i)
		for j in 2:
			var piece: Array = _ties[i][j]
			var node: Node3D = piece[0]
			node.visible = holder.visible and tie_power > 0.01
			if not node.visible:
				continue
			var from: Vector3 = hands[j]
			var d := back - from
			node.global_transform = Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), from)
			(piece[1] as ShaderMaterial).set_shader_parameter("len", d.length() / K)
			(piece[1] as ShaderMaterial).set_shader_parameter("power", tie_power)
	# The charge between the hands.
	var throb := 1.0 + sin(time * 26.0) * 0.08
	var beat_k := 1.0 + _beat * 0.45
	_orb.visible = ball > 0.01
	_star.visible = _orb.visible
	_orb.global_position = orb
	_star.global_position = orb
	_orb.scale = Vector3.ONE * maxf(ball * 7.0 * K * throb * beat_k, 0.01)
	_star.scale = Vector3.ONE * maxf(ball * 11.0 * K * throb * beat_k, 0.01)
	_star_mat.set_shader_parameter("spin", time * 3.0)
	_star_mat.set_shader_parameter("tint", HEROES[int(time * 6.0) % HEROES.size()]["color"])
	# The wave: a white core with a strand of every hero's colour wound round it.
	var ahead := _p.forward()
	var wave_basis := Basis(Quaternion(Vector3.UP, ahead))
	var wave_node: Node3D = _wave[0]
	var wave_mat: ShaderMaterial = _wave[1]
	wave_node.visible = wp > 0.01
	wave_node.global_transform = Transform3D(wave_basis, orb)
	wave_mat.set_shader_parameter("len", WAVE_LEN * grow)
	wave_mat.set_shader_parameter("rad", WAVE_R * r)
	wave_mat.set_shader_parameter("power", wp * 0.6 * (1.0 + sin(time * 40.0) * 0.12))
	var side := ahead.cross(Vector3.UP).normalized()
	for i in _strands.size():
		var strand: Array = _strands[i]
		var a := time * 5.0 + i * PI * 0.5
		var node: Node3D = strand[0]
		node.visible = wave_node.visible
		node.global_transform = Transform3D(wave_basis, orb + (side * cos(a) + Vector3.UP * sin(a)) * 2.6 * r * K)
		(strand[1] as ShaderMaterial).set_shader_parameter("len", WAVE_LEN * grow)
		(strand[1] as ShaderMaterial).set_shader_parameter("rad", 3.0 * r)
		(strand[1] as ShaderMaterial).set_shader_parameter("power", wp * 0.6)
	_wave_power = wp
	_wave_r = r


func _process(delta: float) -> void:
	if _p == null or not _built:
		return
	_beat *= exp(-delta * 6.0)
	if _wave_power >= 0.05:
		# Rings ride out along the wave, and sparks of every colour spiral round it.
		var orb := orb_point()
		var ahead := _p.forward()
		var side := ahead.cross(Vector3.UP).normalized()
		var radius := WAVE_R * _wave_r * K * 1.25
		for i in HEROES.size():
			var a := Time.get_ticks_msec() * 0.009 + i * PI * 0.5
			var at := orb + (side * cos(a) + Vector3.UP * sin(a)) * radius
			CosmicFx.shoot(at, ahead * 55.0 + (Vector3.UP * cos(a) - side * sin(a)) * 2.0, 0.9, 1.7 * K * _wave_r * 1.5, HEROES[i]["color"])
		Game.shake(0.25 * _wave_r * delta * 8.0)
	_charge_clock -= delta
	if _orb.visible and _charge_clock <= 0.0:
		_charge_clock = 0.07
		var hue: Color = HEROES[randi() % HEROES.size()]["color"]
		CosmicFx.inflow(_orb.global_position, 3, 5.0, 0.4, hue)


## The page's events, played at the moment the move reaches them.
func fire(effect: String, arg: float) -> void:
	var p := _p
	match effect:
		"linkStart":
			CosmicFx.shock(p.global_position, 9.0, 1.2, 0.6, PALE, true)
			Game.hud.banner("HERO LINK", "ขอยืมพลังจากฮีโร่ทุกคน", PALE, 1.4)
		"ghostIn":
			var i := int(arg)
			var h: Dictionary = HEROES[i]
			var q := _hero_center(i)
			CosmicFx.shock(q, float(h["height"]) * 0.6 * K, 1.4, 0.7, h["color"])
			CosmicFx.sparks(q, 120, 26.0)
			Game.hud.banner(h["name"], "%s · ส่งพลังให้ GEMINI" % h["sub"], h["color"], 0.9)
			Game.shake(0.3)
		"linked":
			Game.hud.banner("ALL HEROES · LINKED", "CLAWD · CHATGPT · GROK · อั้ม → GEMINI", MINT, 2.2)
			CosmicFx.shock(_back(), 18.0 * K, 2.2, 0.5, MINT)
		"feed":
			var back := _back()
			for i in HEROES.size():
				for from: Vector3 in _hand_points(i):
					CosmicFx.shoot(from, (back - from) / 0.35, 0.35, 1.8 * K * 1.6, HEROES[i]["color"])
			CosmicFx.inflow(orb_point(), 12, 7.0 * K, 0.4)
			Game.shake(0.12)
		"pulse":
			var k := int(arg)
			CosmicFx.shock(p.global_position, 5.0 + k * 1.2, 0.9 + k * 0.06, 0.55, CYAN if k % 2 == 1 else PALE, true)
			CosmicFx.shock(orb_point(), 1.6 + k * 0.4, 1.2, 0.35, HEROES[k % HEROES.size()]["color"])
			CosmicFx.sparks(p.global_position + Vector3(0, 0.4, 0), 40 + k * 10, 20.0 + k * 4.0)
			_beat = 1.0
			Game.shake(0.2 + k * 0.08)
			if k == 8:
				Game.hud.banner("MAX POWER", "พลังของทุกคนเต็มเปี่ยม!", PALE, 1.2)
		"unite":
			var orb := orb_point()
			Game.hud.banner("UNITED WAVE", "คลื่นพลังรวมใจ · พลังของทุกคนในการโจมตีเดียว", PALE, 2.6)
			for i in HEROES.size():
				CosmicFx.shock(orb + p.forward() * (6.0 + i * 4.0), (16.0 + i * 6.0) * K, 1.8, 0.5 + i * 0.08, HEROES[i]["color"])
			CosmicFx.sparks(orb + p.forward() * 6.0, 240, 60.0)
			Game.shake(1.6)
			CosmicSkills.united_wave(p, p.global_position, p.forward(), 1.0)
		"surge":
			var orb := orb_point()
			Game.hud.banner("FULL POWER", "ทุกคนปล่อยพลังสุดตัว · ×4", PALE, 2.2)
			for i in HEROES.size():
				var h: Dictionary = HEROES[i]
				var q := _hero_center(i)
				CosmicFx.shock(orb + p.forward() * (8.0 + i * 4.0), (24.0 + i * 8.0) * K, 1.8, 0.6 + i * 0.1, h["color"])
				CosmicFx.shock(q, float(h["height"]) * 0.8 * K, 1.4, 0.6, h["color"])
				CosmicFx.sparks(q, 120, 40.0)
			CosmicFx.shock(p.global_position, 18.0, 1.0, 1.2, PALE, true)
			CosmicFx.sparks(orb + p.forward() * 6.0, 300, 90.0)
			for i in 60:
				var a := i * 2.39996
				var e := i / 60.0 * 2.0 - 1.0
				var c := sqrt(1.0 - e * e)
				CosmicFx.shoot(orb, Vector3(cos(a) * c, e, sin(a) * c) * 80.0 * K, 0.9, 5.0 * K, HEROES[i % HEROES.size()]["color"])
			Game.shake(2.0)
			CosmicSkills.united_wave(p, p.global_position, p.forward(), 1.9)
		"waveRing":
			var i := int(arg)
			var h: Dictionary = HEROES[i % HEROES.size()]
			if i % 2 == 1:
				return
			var q := orb_point() + p.forward() * (14.0 + (i % 10) * 9.0)
			CosmicFx.shock(q, 3.5 + i * 0.15, 1.2, 0.5, PALE if i % 4 == 0 else h["color"])
			var floor_at := Vector3(q.x, Game.ground_height(q.x, q.z) + 0.1, q.z)
			CosmicFx.shock(floor_at, 4.0 + i * 0.3, 1.0, 0.6, h["color"], true)
			Game.shake(0.2)
		"unityDone":
			Game.hud.banner("UNITED WAVE", "ฮีโร่ทุกคนคือพลังเดียวกัน", MINT, 2.4)
