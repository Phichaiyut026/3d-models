class_name TownMap
extends Node3D
## เมืองดาวรุ่ง and the farm village round it: a cobbled square with a fountain and a market, town houses
## along two crossing streets, cottages, fields and a windmill beyond the ring road, and people living there.
## It sits off the valley's terrain like Safe Mode and WORMS' system; a golden gate by the first shrine leads in.

const CENTER := Vector3(-1000, 400, 1000)
const RADIUS := 130.0
const ENTRY := Vector3(0, 0, 108) ## Where the gate puts the warrior, on the south road.
const EXIT := Vector3(0, 0, 120)
const START := Vector3(0, 0, 32) ## Where a new journey begins: the south street, the fountain ahead.
const REACH := 7.0
const NPC_REACH := 3.4
const GROUND := preload("res://shaders/town_ground.gdshader")
const GOLD := Color(1.0, 0.8, 0.35)
const WALLS := [Color("fffaf0"), Color("ffe9a8"), Color("ffcfd6"), Color("c6e8ff"), Color("cff5d9"), Color("ffd9b3"), Color("ffffff"), Color("e8dcff")]
const ROOFS := [Color("f0553d"), Color("ff8f3d"), Color("3d8fe0"), Color("2fbfa0"), Color("e04a6a"), Color("8a63e0")]
const AWNINGS := [Color("ff4f45"), Color("ffc23a"), Color("3d9cff"), Color("4fcf6a"), Color("b46cff"), Color("ff7a3d")]
const SKIN := [Color("f1c9a5"), Color("e0ac83"), Color("c68a62"), Color("9c6644"), Color("f5d6bc")]
const HAIR := [Color("2b1d14"), Color("4a3020"), Color("8a5a2b"), Color("161210"), Color("b8873f"), Color("6b6b6b")]
const CLOTH := [Color("3f6fb0"), Color("b0413e"), Color("4f8a4a"), Color("d0a03c"), Color("7a4fa0"), Color("e4e0d6"), Color("2f4a5e"), Color("a86a3c"), Color("c75a8a")]
const PANTS := [Color("3a3a44"), Color("5a4632"), Color("2c3e55"), Color("6b5a44")]

## [name, lines while the valley is dark, lines once WORMS is gone]
const PEOPLE := [
	["ป้าแม่ค้าผลไม้", ["มาม่ะ แอปเปิลเพิ่งเก็บเมื่อเช้า หวานกรอบเลยนะ", "ช่วงนี้คนออกไปหุบเขาน้อยลงเยอะ ลูกค้าก็หายไปด้วย"], ["วันนี้ลดราคาให้ฮีโร่ของเมืองเลย เอาไปเท่าไหร่ก็ได้!", "ฟ้าสว่างแบบนี้ ผลไม้ก็สุกงามตามไปด้วย"]],
	["ลุงช่างตีเหล็ก", ["ดาบเล่มนั้นของเจ้า... ไม่ได้ทำจากเหล็กธรรมดาแน่ ๆ", "ถ้าจะไปหอดาว ระวังตัวด้วย ฟ้าทางนั้นแดงมาหลายวันแล้ว"], ["ข้าจะตีระฆังให้ดังที่สุดเลย ฉลองให้เจ้า!", "ดาบที่ฟันระบบทั้งระบบได้... ข้าคงตีแบบนั้นไม่ได้ทั้งชีวิต"]],
	["เด็กน้อย", ["พี่คือนักรบดวงดาวใช่ไหม! บินได้ด้วยหรือเปล่า", "แม่บอกว่าห้ามออกไปนอกเมืองตอนฟ้าเป็นสีแดง"], ["เย้! ฟ้ากลับมาเป็นสีฟ้าแล้ว!", "โตขึ้นหนูจะเป็นนักรบดวงดาวเหมือนพี่!"]],
	["ทหารยามประตู", ["ทางใต้คือทางกลับหุบเขา ถ้าจะออกไปก็เดินผ่านประตูทองได้เลย", "ข้าเฝ้าประตูนี้มาสิบปี ไม่เคยเห็นฟ้าแดงขนาดนี้มาก่อน"], ["ไม่มีอะไรให้เฝ้าแล้ว... แต่ข้าก็จะยืนตรงนี้ต่อไปแหละ", "ขอบคุณที่ปกป้องเมืองนี้ไว้นะ"]],
	["ชาวนา", ["ข้าวปีนี้ออกรวงช้า แสงแดดมันจางลงทุกวัน", "เห็นกังหันลมทางตะวันตกไหม ปู่ของข้าเป็นคนสร้างเอง"], ["แดดกลับมาแล้ว ข้าวคงเหลืองทั้งทุ่งภายในอาทิตย์นี้", "ขอบใจนะ ปีนี้ไม่ต้องอดแล้ว"]],
	["นักเดินทาง", ["ข้าเดินทางมาไกล ได้ยินว่ามีโปรแกรมชื่อ OBLIVION ยึดหอดาวไว้", "เมืองนี้เงียบดีนะ แต่ทุกคนดูกังวลกันหมด"], ["ได้ยินข่าวแล้ว! WORMS ถูกลบออกจากระบบจริง ๆ เหรอ", "ข้าจะเอาเรื่องของเจ้าไปเล่าให้ทุกเมืองที่ข้าผ่านฟังเลย"]],
	["คุณยายใจดี", ["นั่งพักก่อนไหมหลาน เดินทางมาเหนื่อยแล้วใช่ไหม", "สมัยยายยังสาว ดาวบนฟ้าเยอะกว่านี้มากเลยนะ"], ["คืนนี้ดาวคงเต็มฟ้าเหมือนสมัยก่อนแล้วล่ะ", "ยายจะทำขนมไว้ให้นะ แวะมากินด้วยล่ะ"]],
	["คนขายขนมปัง", ["ขนมปังอบใหม่ ๆ ร้อน ๆ จ้า!", "แป้งเริ่มขาดแล้ว ชาวนาบอกว่าข้าวไม่ค่อยงาม"], ["วันนี้แจกฟรี! ฉลองให้วีรบุรุษของเรา", "ได้กลิ่นไหม นี่คือกลิ่นของวันที่สงบสุข"]],
	["นักดนตรี", ["ข้าแต่งเพลงไว้เพลงหนึ่ง ชื่อเพลงว่า 'ดาวที่หายไป'", "เพลงเศร้าขายไม่ค่อยดีหรอก แต่ช่วงนี้ใครก็อยากฟัง"], ["ข้าแต่งเพลงใหม่แล้ว ชื่อ 'Gemini ผู้คืนแสง' อยากฟังไหม", "คืนนี้จะมีงานฉลองที่ลานน้ำพุ อย่าลืมมานะ!"]],
	["ชาวเมือง", ["สวัสดี ไม่ค่อยเห็นหน้าแปลก ๆ ในเมืองนี้เลยนะ", "ระวังตัวด้วยนะ ได้ยินว่าทางเหนือมีแต่ทหารของระบบ"], ["บรรยากาศดีขึ้นเยอะเลยนะ ว่าไหม", "ทุกคนพูดถึงเจ้ากันทั้งเมืองเลย"]],
	["แม่บ้าน", ["ลูก ๆ ข้าไม่ยอมออกจากบ้านเลยตั้งแต่ฟ้าเป็นสีแดง", "ตลาดวันนี้คนน้อยจัง ของก็แพงขึ้นทุกวัน"], ["วันนี้พาลูก ๆ ออกมาเล่นที่ลานได้แล้ว", "ขอบคุณจริง ๆ นะ ทุกบ้านกลับมายิ้มได้อีกครั้ง"]],
	["นายกเทศมนตรี", ["ข้าเป็นนายกเมืองนี้ ถ้าเจ้าจะไปสู้กับมัน... เมืองนี้ฝากความหวังไว้กับเจ้านะ", "หอนาฬิกานั่นเดินช้าไปตั้งแต่ฟ้าเปลี่ยนสี แปลกจริง ๆ"], ["ในนามของเมืองดาวรุ่ง ขอบคุณเจ้าจากใจ", "ข้าจะสร้างรูปปั้นของเจ้าไว้กลางลานน้ำพุเลย!"]],
]


static func contains(x: float, z: float) -> bool:
	return Vector2(x - CENTER.x, z - CENTER.z).length() < 300.0


var exit_gate: Node3D
var people: Array[Villager] = []
var aum: AumNpc ## อั้ม, putting the system back in order in front of the town hall.
var _mats := {}
var _body: StaticBody3D
var _rng := RandomNumberGenerator.new()
var _blades: Node3D
var _water: CPUParticles3D
var _taken: Array = [] ## [Vector2 centre, radius] of everything already standing, so nothing overlaps.
var _clock := 0.0


func _ready() -> void:
	global_position = CENTER
	_rng.seed = 7741
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	_body.collision_mask = 0
	add_child(_body)
	_build_ground()
	_build_hills()
	_build_square()
	_build_landmarks()
	_build_farms()
	_build_houses()
	_build_trees()
	_build_lamps()
	exit_gate = WormsDomain.gate(GOLD)
	add_child(exit_gate)
	exit_gate.position = EXIT
	_spawn_people()
	aum = AumNpc.new()
	aum.position = Vector3(-21.0, 0, 21.0)
	aum.rotation.y = atan2(21.0, -21.0) # facing the fountain
	add_child(aum)
	_taken.append([Vector2(-21, 21), 3.0])


# ---------- helpers ----------

func _mat(color: Color, emit := 0.0, rough := 0.85) -> StandardMaterial3D:
	var key := "%s/%s" % [color.to_html(), emit]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = rough
		if emit > 0.0:
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = emit
		_mats[key] = m
	return _mats[key]


func _mesh(parent: Node3D, mesh: Mesh, color: Color, at: Vector3, rot := Vector3.ZERO, emit := 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = _mat(color, emit)
	m.position = at
	m.rotation = rot
	parent.add_child(m)
	return m


func _box(parent: Node3D, size: Vector3, color: Color, at: Vector3, rot := Vector3.ZERO, emit := 0.0) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mesh(parent, b, color, at, rot, emit)


func _cyl(parent: Node3D, top: float, bottom: float, h: float, color: Color, at: Vector3, sides := 16) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = sides
	return _mesh(parent, c, color, at)


## A solid block for the player to bump into, in the town's own space.
func _solid(at: Vector3, size: Vector3, yaw := 0.0) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	shape.rotation.y = yaw
	_body.add_child(shape)


func _free(p: Vector2, r: float) -> bool:
	for t: Array in _taken:
		if (t[0] as Vector2).distance_to(p) < r + float(t[1]):
			return false
	return true


func _on_road(p: Vector2, margin: float) -> bool:
	var d := p.length()
	if absf(p.x) < 3.8 + margin or absf(p.y) < 3.8 + margin:
		return true
	if absf(d - 60.0) < 3.1 + margin or d < 19.6 + margin:
		return true
	for i in 6:
		var a := i * 1.047 + 0.52
		var dir := Vector2(cos(a), sin(a))
		var along := p.dot(dir)
		if along > 60.0 and along < 120.0 and absf(p.dot(Vector2(-dir.y, dir.x))) < 2.2 + margin:
			return true
	return false


# ---------- the land ----------

func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * RADIUS * 2.4
	var material := ShaderMaterial.new()
	material.shader = GROUND
	material.set_shader_parameter("radius", RADIUS)
	plane.material = material
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	add_child(ground)
	var meadow := PlaneMesh.new() # Fields run on past the edge to the hills.
	meadow.size = Vector2.ONE * 900.0
	var outer := _mesh(self, meadow, Color(0.36, 0.62, 0.2), Vector3(0, -0.05, 0))
	outer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_solid(Vector3(0, -1.0, 0), Vector3(RADIUS * 2.6, 2.0, RADIUS * 2.6))
	# Unseen fence at the edge of town: the hills beyond are only scenery.
	for i in 40:
		var a := i * TAU / 40.0
		_solid(Vector3(sin(a) * RADIUS, 100.0, cos(a) * RADIUS), Vector3(22.0, 200.0, 2.0), a)


func _build_hills() -> void:
	for i in 26:
		var a := i / 26.0 * TAU + _rng.randf() * 0.1
		var r := _rng.randf_range(230.0, 320.0)
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		var hill := _mesh(self, s, Color(0.38, 0.66, 0.26).lerp(Color(0.5, 0.76, 0.32), _rng.randf()), Vector3(cos(a) * r, -6.0, sin(a) * r))
		hill.scale = Vector3(_rng.randf_range(50, 90), _rng.randf_range(18, 40), _rng.randf_range(40, 70))
		hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 9: # Blue mountains far behind
		var a := i / 9.0 * TAU + 0.3
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = _rng.randf_range(70, 110)
		c.height = _rng.randf_range(90, 150)
		c.radial_segments = 7
		var m := _mesh(self, c, Color(0.5, 0.64, 0.84), Vector3(cos(a) * 470.0, c.height * 0.5 - 20.0, sin(a) * 470.0))
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ---------- the square ----------

func _build_square() -> void:
	# The fountain, with a golden star on top
	_cyl(self, 6.2, 6.4, 1.0, Color("f2ece0"), Vector3(0, 0.5, 0), 28)
	_cyl(self, 5.6, 5.6, 0.12, Color(0.3, 0.6, 0.85), Vector3(0, 0.9, 0), 28).material_override = _mat(Color(0.32, 0.62, 0.9), 0.35, 0.1)
	_cyl(self, 1.0, 1.4, 3.6, Color("ffffff"), Vector3(0, 2.4, 0), 12)
	_cyl(self, 2.4, 2.2, 0.4, Color("f2ece0"), Vector3(0, 3.0, 0), 20)
	var star := SphereMesh.new()
	star.radius = 0.7
	star.height = 1.4
	_mesh(self, star, GOLD, Vector3(0, 5.0, 0), Vector3.ZERO, 2.5)
	_solid(Vector3(0, 1.0, 0), Vector3(12.0, 2.0, 12.0))
	_taken.append([Vector2.ZERO, 7.0])
	_water = CPUParticles3D.new()
	var drop := SphereMesh.new()
	drop.radius = 0.08
	drop.height = 0.16
	drop.material = _mat(Color(0.7, 0.88, 1.0), 0.6, 0.1)
	_water.mesh = drop
	_water.amount = 120
	_water.lifetime = 1.4
	_water.position = Vector3(0, 3.4, 0)
	_water.direction = Vector3.UP
	_water.spread = 35.0
	_water.initial_velocity_min = 3.5
	_water.initial_velocity_max = 5.0
	_water.gravity = Vector3(0, -9.0, 0)
	add_child(_water)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.6)
	light.light_energy = 1.4
	light.omni_range = 16.0
	light.position = Vector3(0, 6.0, 0)
	add_child(light)
	# Market stalls round the square, between the streets
	for i in 8:
		var a := deg_to_rad(22.5 + i * 45.0) + (0.12 if i % 2 == 0 else -0.12)
		var at := Vector3(cos(a), 0, sin(a)) * 15.0
		_stall(at, atan2(-at.x, -at.z), AWNINGS[i % AWNINGS.size()], i)
	# Benches and flower beds on the square's edge
	for i in 12:
		var a := deg_to_rad(i * 30.0 + 15.0)
		var at := Vector3(cos(a), 0, sin(a)) * 9.0
		var g := Node3D.new()
		g.position = at
		g.rotation.y = atan2(-at.x, -at.z)
		add_child(g)
		if i % 2 == 0:
			_box(g, Vector3(2.2, 0.15, 0.6), Color("7a5232"), Vector3(0, 0.55, 0))
			_box(g, Vector3(2.2, 0.6, 0.12), Color("7a5232"), Vector3(0, 0.85, -0.28))
			for x: float in [-0.9, 0.9]:
				_box(g, Vector3(0.12, 0.5, 0.5), Color("3a3a3a"), Vector3(x, 0.25, 0))
		else:
			_box(g, Vector3(1.6, 0.5, 1.6), Color("9b8f7d"), Vector3(0, 0.25, 0))
			for k in 6:
				var f := SphereMesh.new()
				f.radius = 0.22
				f.height = 0.44
				_mesh(g, f, [Color("e14b5a"), Color("f2c14e"), Color("f7f3e8"), Color("b65cd1")][k % 4], Vector3(_rng.randf_range(-0.55, 0.55), 0.62, _rng.randf_range(-0.55, 0.55)))


func _stall(at: Vector3, yaw: float, awning: Color, seed_index: int) -> void:
	var g := Node3D.new()
	g.position = at
	g.rotation.y = yaw
	add_child(g)
	var wood := Color("7a5232")
	_box(g, Vector3(3.4, 1.0, 1.4), wood, Vector3(0, 0.5, 0))
	for x: float in [-1.6, 1.6]:
		for z: float in [-0.65, 0.65]:
			_box(g, Vector3(0.12, 2.6, 0.12), wood, Vector3(x, 1.3, z))
	# A striped awning
	for k in 6:
		_box(g, Vector3(0.6, 0.08, 2.0), awning if k % 2 == 0 else Color("f4ecdf"), Vector3(-1.5 + k * 0.6, 2.7, 0.15), Vector3(0.25, 0, 0))
	var goods := [Color("d9412b"), Color("f2b33d"), Color("6cae3f"), Color("8b5a2b"), Color("f4e4b0")]
	for k in 9:
		var s := SphereMesh.new()
		s.radius = 0.17
		s.height = 0.34
		_mesh(g, s, goods[(k + seed_index) % goods.size()], Vector3(-1.3 + (k % 5) * 0.62, 1.15, -0.25 + (k / 5) * 0.4))
	_solid(Vector3(at.x, 0.6, at.z), Vector3(3.4, 1.2, 1.4), yaw)
	_taken.append([Vector2(at.x, at.z), 2.2])


# ---------- town landmarks ----------

func _build_landmarks() -> void:
	# Clock tower on the north-east corner of the square
	var t := Node3D.new()
	t.position = Vector3(26, 0, -26)
	add_child(t)
	_box(t, Vector3(6, 18, 6), Color("fff4dc"), Vector3(0, 9, 0))
	_box(t, Vector3(6.6, 1.0, 6.6), Color("a89676"), Vector3(0, 18.4, 0))
	var roof := CylinderMesh.new()
	roof.top_radius = 0.0
	roof.bottom_radius = 4.8
	roof.height = 7.0
	roof.radial_segments = 4
	_mesh(t, roof, Color("3d8fe0"), Vector3(0, 22.4, 0), Vector3(0, PI / 4.0, 0))
	for k in 4:
		var face := Node3D.new()
		face.rotation.y = k * PI * 0.5
		t.add_child(face)
		_cyl(face, 1.6, 1.6, 0.2, Color("f4ecdf"), Vector3(0, 14.5, 3.05)).rotation.x = PI / 2.0
		_box(face, Vector3(0.12, 1.2, 0.1), Color("222222"), Vector3(0, 14.9, 3.2))
		_box(face, Vector3(0.9, 0.12, 0.1), Color("222222"), Vector3(0.35, 14.5, 3.2))
		_box(face, Vector3(1.4, 2.6, 0.2), Color("3d2a1c"), Vector3(0, 1.3, 3.0))
	_solid(Vector3(26, 9, -26), Vector3(6, 18, 6))
	_taken.append([Vector2(26, -26), 6.0])
	# Town hall on the south-west corner: wide, columned, with a dome
	var h := Node3D.new()
	h.position = Vector3(-28, 0, 28)
	h.rotation.y = atan2(28.0, -28.0)
	add_child(h)
	_box(h, Vector3(16, 8, 10), Color("ffffff"), Vector3(0, 4, 0))
	_box(h, Vector3(17, 0.8, 11), Color("bfae8f"), Vector3(0, 8.4, 0))
	_cyl(h, 3.6, 3.6, 2.0, Color("bfae8f"), Vector3(0, 9.8, 0), 20)
	var dome := SphereMesh.new()
	dome.radius = 3.6
	dome.height = 7.2
	_mesh(h, dome, Color("ffc94a"), Vector3(0, 10.8, 0))
	for k in 6:
		_cyl(h, 0.4, 0.45, 7.0, Color("f4ecdf"), Vector3(-6.0 + k * 2.4, 3.5, 6.0), 10)
	_box(h, Vector3(16.5, 0.6, 2.6), Color("cfc2a8"), Vector3(0, 0.3, 6.0))
	_box(h, Vector3(2.4, 4.0, 0.2), Color("5a3a22"), Vector3(0, 2.0, 5.05))
	_solid(Vector3(-28, 4, 28), Vector3(16, 8, 10), h.rotation.y)
	_taken.append([Vector2(-28, 28), 10.0])


# ---------- houses ----------

func _build_houses() -> void:
	for gx in range(-8, 9):
		for gz in range(-8, 9):
			var p := Vector2(gx * 14.0 + _rng.randf_range(-2.0, 2.0), gz * 14.0 + _rng.randf_range(-2.0, 2.0))
			var r := p.length()
			if r > 112.0 or r < 25.0:
				continue
			var city := r < 54.0
			if not city and _rng.randf() < 0.35:
				continue
			var w := _rng.randf_range(8.0, 11.0) if city else _rng.randf_range(6.0, 8.0)
			var d := _rng.randf_range(7.5, 10.0) if city else _rng.randf_range(5.5, 7.0)
			var reach := maxf(w, d) * 0.62
			if _on_road(p, reach) or not _free(p, reach):
				continue
			if p.x > 66.0 and absf(p.y) < 42.0: # the fields
				continue
			var hgt := _rng.randf_range(7.0, 12.5) if city else _rng.randf_range(3.6, 4.6)
			_house(Vector3(p.x, 0, p.y), w, d, hgt, atan2(-p.x, -p.y), city)
			_taken.append([p, reach])


func _house(at: Vector3, w: float, d: float, h: float, yaw: float, city: bool) -> void:
	var g := Node3D.new()
	g.position = at
	g.rotation.y = yaw
	add_child(g)
	var wall: Color = WALLS[_rng.randi() % WALLS.size()]
	var roof_col: Color = ROOFS[_rng.randi() % ROOFS.size()]
	var trim := Color("ffffff") if wall.get_luminance() < 0.9 else Color("c9b49a")
	_box(g, Vector3(w, h, d), wall, Vector3(0, h * 0.5, 0))
	_box(g, Vector3(w + 0.3, 0.5, d + 0.3), trim, Vector3(0, 0.25, 0)) # plinth
	# A pitched roof: two slabs meeting at the ridge, gable ends filled
	var pitch := 0.6
	var half := d * 0.5 + 0.5
	var rise := tan(pitch) * half
	for side: float in [-1.0, 1.0]:
		_box(g, Vector3(w + 0.9, 0.25, half / cos(pitch) + 0.1), roof_col, Vector3(0, h + rise * 0.5, side * half * 0.5), Vector3(side * pitch, 0, 0))
	var gable := PrismMesh.new()
	gable.size = Vector3(d + 0.2, rise, w - 0.05)
	var end := _mesh(g, gable, wall, Vector3(0, h + rise * 0.5, 0), Vector3(0, PI * 0.5, 0))
	end.scale = Vector3(1, 1, 1)
	if _rng.randf() < 0.6:
		_box(g, Vector3(0.8, rise + 1.6, 0.8), Color("7d6a5a"), Vector3(w * 0.28, h + rise * 0.6 + 0.4, -d * 0.18))
	# Door and windows on the front (+Z), windows on the back, lit warm
	_box(g, Vector3(1.4, 2.4, 0.16), Color("5a3a22"), Vector3(0, 1.2, d * 0.5 + 0.05))
	_box(g, Vector3(1.8, 0.2, 0.5), trim, Vector3(0, 2.55, d * 0.5 + 0.2))
	var floors := maxi(1, int(h / 3.6))
	var across := maxi(2, int(w / 3.0))
	for f in floors:
		var y := 1.8 + f * 3.4 + (0.0 if f > 0 else 0.2)
		if y + 0.8 > h:
			continue
		for k in across:
			var x := -w * 0.5 + (k + 0.5) * w / across
			if f == 0 and absf(x) < 1.3:
				continue
			for z: float in [d * 0.5 + 0.05, -d * 0.5 - 0.05]:
				_box(g, Vector3(1.0, 1.3, 0.12), Color(1.0, 0.82, 0.5), Vector3(x, y, z), Vector3.ZERO, 0.6)
				_box(g, Vector3(1.3, 0.14, 0.3), trim, Vector3(x, y - 0.75, z))
	if city and _rng.randf() < 0.5: # a shop sign
		_box(g, Vector3(2.6, 0.7, 0.12), AWNINGS[_rng.randi() % AWNINGS.size()], Vector3(0, 3.3, d * 0.5 + 0.12))
	elif not city: # a little fence and a garden
		for k in 7:
			_box(g, Vector3(0.1, 0.9, 0.1), Color("8a6a46"), Vector3(-w * 0.5 + k * w / 6.0, 0.45, d * 0.5 + 2.2))
		_box(g, Vector3(w, 0.08, 0.08), Color("8a6a46"), Vector3(0, 0.75, d * 0.5 + 2.2))
	for node in g.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_solid(Vector3(at.x, h * 0.5, at.z), Vector3(w, h, d), yaw)


# ---------- farms ----------

func _build_farms() -> void:
	# Wheat and greens to the east, either side of the east road
	for side: float in [-1.0, 1.0]:
		for row in 14:
			var z := side * (7.0 + row * 2.4)
			var ripe := Color("ffd24a") if row % 3 != 0 else Color("7fcf45")
			_box(self, Vector3(38.0, 0.7, 1.2), ripe, Vector3(91.0, 0.35, z))
		for k in 10:
			_box(self, Vector3(0.14, 1.1, 0.14), Color("8a6a46"), Vector3(72.0 + k * 4.2, 0.55, side * 41.0))
		_box(self, Vector3(40.0, 0.1, 0.1), Color("8a6a46"), Vector3(91.0, 0.9, side * 41.0))
	_taken.append([Vector2(91, 0), 30.0])
	# A scarecrow
	var s := Node3D.new()
	s.position = Vector3(92, 0, 20)
	add_child(s)
	_box(s, Vector3(0.18, 2.6, 0.18), Color("8a6a46"), Vector3(0, 1.3, 0))
	_box(s, Vector3(2.0, 0.16, 0.16), Color("8a6a46"), Vector3(0, 2.0, 0))
	_box(s, Vector3(0.9, 1.0, 0.5), Color("b0413e"), Vector3(0, 1.9, 0))
	var head := SphereMesh.new()
	head.radius = 0.32
	head.height = 0.64
	_mesh(s, head, Color("e8d39a"), Vector3(0, 2.75, 0))
	_cyl(s, 0.1, 0.55, 0.45, Color("c9a24a"), Vector3(0, 3.1, 0))
	# The windmill to the west
	var m := Node3D.new()
	m.position = Vector3(-94, 0, -30)
	add_child(m)
	_cyl(m, 2.4, 3.8, 14.0, Color("fffaf0"), Vector3(0, 7, 0), 8)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.0
	cap.bottom_radius = 3.0
	cap.height = 3.4
	cap.radial_segments = 8
	_mesh(m, cap, Color("f0553d"), Vector3(0, 15.7, 0))
	_box(m, Vector3(1.4, 2.4, 0.2), Color("5a3a22"), Vector3(0, 1.2, 3.75))
	_blades = Node3D.new()
	_blades.position = Vector3(0, 12.5, 3.2)
	m.add_child(_blades)
	_cyl(_blades, 0.5, 0.5, 0.8, Color("5a3a22"), Vector3.ZERO).rotation.x = PI / 2.0
	for k in 4:
		var arm := Node3D.new()
		arm.rotation.z = k * PI * 0.5
		_blades.add_child(arm)
		_box(arm, Vector3(0.25, 7.5, 0.15), Color("6f4a32"), Vector3(0, 3.9, 0.3))
		_box(arm, Vector3(1.6, 6.0, 0.05), Color("f4ecdf"), Vector3(0.9, 4.4, 0.35))
	m.rotation.y = atan2(94.0, 30.0)
	_solid(Vector3(-94, 7, -30), Vector3(7, 14, 7))
	_taken.append([Vector2(-94, -30), 8.0])


# ---------- trees and lamps ----------

func _build_trees() -> void:
	var placed := 0
	var tries := 0
	while placed < 90 and tries < 2000:
		tries += 1
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(30.0, 124.0)
		var p := Vector2(cos(a), sin(a)) * r
		if _on_road(p, 2.0) or not _free(p, 2.6):
			continue
		_tree(Vector3(p.x, 0, p.y))
		_taken.append([p, 2.2])
		placed += 1


func _tree(at: Vector3) -> void:
	var g := Node3D.new()
	g.position = at
	g.scale = Vector3.ONE * _rng.randf_range(0.8, 1.4)
	add_child(g)
	_cyl(g, 0.25, 0.4, 3.0, Color("6b4a2f"), Vector3(0, 1.5, 0), 8)
	var leaf := Color("4caf3e").lerp(Color("8fd650"), _rng.randf())
	if _rng.randf() < 0.4:
		for k in 3:
			var c := CylinderMesh.new()
			c.top_radius = 0.0
			c.bottom_radius = 2.4 - k * 0.5
			c.height = 2.6
			c.radial_segments = 9
			_mesh(g, c, leaf.darkened(0.15), Vector3(0, 3.6 + k * 1.3, 0))
	else:
		for k in 3:
			var s := SphereMesh.new()
			s.radius = 1.6 - k * 0.2
			s.height = (1.6 - k * 0.2) * 2.0
			_mesh(g, s, leaf, Vector3(_rng.randf_range(-0.7, 0.7), 4.0 + k * 0.7, _rng.randf_range(-0.7, 0.7)))
	for node in g.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_solid(Vector3(at.x, 1.5, at.z), Vector3(0.8, 3.0, 0.8))


func _build_lamps() -> void:
	for axis in 4:
		var dir := Vector3(cos(axis * PI * 0.5), 0, sin(axis * PI * 0.5))
		var side := Vector3(-dir.z, 0, dir.x)
		for k in 8:
			var at := dir * (24.0 + k * 12.0) + side * (4.6 if k % 2 == 0 else -4.6)
			var g := Node3D.new()
			g.position = at
			add_child(g)
			_cyl(g, 0.09, 0.14, 4.2, Color("2e2e33"), Vector3(0, 2.1, 0), 8)
			var bulb := SphereMesh.new()
			bulb.radius = 0.32
			bulb.height = 0.64
			_mesh(g, bulb, Color(1.0, 0.85, 0.55), Vector3(0, 4.35, 0), Vector3.ZERO, 3.0)
			_cyl(g, 0.0, 0.42, 0.35, Color("2e2e33"), Vector3(0, 4.75, 0), 8)


# ---------- people ----------

func _look(child: bool) -> Dictionary:
	var look := {
		"skin": SKIN[_rng.randi() % SKIN.size()],
		"hair": HAIR[_rng.randi() % HAIR.size()],
		"shirt": CLOTH[_rng.randi() % CLOTH.size()],
		"pants": PANTS[_rng.randi() % PANTS.size()],
		"dress": _rng.randf() < 0.35,
	}
	if not child and _rng.randf() < 0.3:
		look["hat"] = [Color("c9a24a"), Color("5a3a22"), Color("2f2f36")][_rng.randi() % 3]
	return look


func _spawn_people() -> void:
	var lanes := [
		# [lane, value, span start, span end, how many]
		["square", 12.0, 0.0, TAU, 6], ["square", 17.5, 0.0, TAU, 4],
		["x", 2.0, 22.0, 105.0, 2], ["x", -2.0, -105.0, -22.0, 2], ["x", 2.0, -105.0, -22.0, 2],
		["z", 2.0, 22.0, 100.0, 2], ["z", -2.0, -105.0, -22.0, 2], ["z", -2.0, 22.0, 100.0, 2],
		["ring", 60.0, 0.0, TAU, 8],
	]
	var named := 0
	for spec: Array in lanes:
		for i in int(spec[4]):
			var child := _rng.randf() < 0.18
			var who: Array = PEOPLE[named % PEOPLE.size()]
			named += 1
			var who_name: String = who[0]
			if child:
				who = PEOPLE[2]
				who_name = "เด็กน้อย"
			var v := Villager.new().setup(who_name, who[1], who[2], _look(child), 0.62 if child else _rng.randf_range(0.92, 1.08), spec[0], spec[1], Vector2(spec[2], spec[3]), _rng.randf())
			add_child(v)
			people.append(v)
	# Two guards at the gate, a vendor at each stall
	for x: float in [-6.0, 6.0]:
		var guard := Villager.new().setup("ทหารยามประตู", PEOPLE[3][1], PEOPLE[3][2], {"skin": SKIN[1], "hair": HAIR[0], "shirt": Color("2f4a5e"), "pants": Color("3a3a44"), "hat": Color("2f2f36")}, 1.05, "z", x, Vector2(100.0, 104.0), 0.5)
		add_child(guard)
		people.append(guard)
	for i in 8:
		var a := deg_to_rad(22.5 + i * 45.0) + (0.12 if i % 2 == 0 else -0.12)
		var who: Array = PEOPLE[[0, 7, 1, 0, 7, 8, 1, 7][i]]
		var vendor := Villager.new().setup(who[0], who[1], who[2], _look(false), 1.0, "square", 16.4, Vector2(a, a), 0.0)
		add_child(vendor)
		people.append(vendor)


func nearest_person(from: Vector3) -> Node3D:
	var best: Node3D = null
	var best_distance := NPC_REACH
	if aum != null and aum.global_position.distance_to(from) < NPC_REACH + 1.2:
		return aum
	for v in people:
		var d := v.global_position.distance_to(from)
		if d < best_distance:
			best = v
			best_distance = d
	return best


func near_exit(at: Vector3) -> bool:
	return to_global(EXIT).distance_to(at) < REACH


func _process(delta: float) -> void:
	if not Game.in_town():
		return
	_clock += delta
	if _blades != null:
		_blades.rotation.z = _clock * 0.6
	(exit_gate.get_node("Cube") as Node3D).rotation = Vector3(_clock * 0.5, _clock * 0.8, 0)
