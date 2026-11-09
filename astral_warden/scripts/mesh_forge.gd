class_name MeshForge
extends RefCounted
## Procedural solids, ported from the web viewer's geometry helpers.
## Parts are transformed into their joint's space and merged per material,
## so a whole character costs a handful of draw calls.

const TILE := 4.0

class Geo:
	var points := PackedVector3Array()
	var indices := PackedInt32Array() ## Empty means `points` is a raw triangle list.

class Soup:
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	var uv := PackedVector2Array()
	var smo := PackedVector3Array()

var materials: Dictionary
var _seed := 11
var _buckets := {} ## Node3D -> { material key -> Soup }


func _init(p_materials := {}) -> void:
	materials = p_materials


func rnd() -> float:
	_seed = (_seed * 16807) % 2147483647
	return float(_seed) / 2147483647.0


static func xform(pos := Vector3.ZERO, rot := Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(rot, EULER_ORDER_XYZ), pos)


static func orient(normal: Vector3, up := Vector3.UP) -> Basis:
	var z := normal.normalized()
	var x := up.cross(z).normalized()
	return Basis(x, z.cross(x), z)


# --------------------------------------------------------------------- solids

## Lofted solid. Rings are [height, halfWidth, halfDepth, depthOffset].
static func loft_geo(rings: Array, n := 14, p := 0.8) -> Geo:
	var geo := Geo.new()
	for ring: Array in rings:
		var offset: float = ring[3] if ring.size() > 3 else 0.0
		for i in n:
			var a := float(i) / n * TAU
			var c := cos(a)
			var s := sin(a)
			geo.points.append(Vector3(ring[1] * sign(c) * pow(abs(c), p), ring[0], ring[2] * sign(s) * pow(abs(s), p) + offset))
	var count := rings.size()
	var bottom := geo.points.size()
	geo.points.append(Vector3(0, rings[0][0], rings[0][3] if rings[0].size() > 3 else 0.0))
	var top := geo.points.size()
	var last: Array = rings[count - 1]
	geo.points.append(Vector3(0, last[0], last[3] if last.size() > 3 else 0.0))
	for j in count - 1:
		for i in n:
			var a := j * n + i
			var b := j * n + (i + 1) % n
			var c := a + n
			var d := b + n
			geo.indices.append_array([a, c, d, a, d, b])
	for i in n:
		geo.indices.append_array([bottom, i, (i + 1) % n])
		geo.indices.append_array([top, (count - 1) * n + (i + 1) % n, (count - 1) * n + i])
	return geo


## Extruded polygon centred on z = 0, with an optional one-step bevel.
static func shape_geo(points: Array, depth: float, bevel := 0.0) -> Geo:
	var poly := PackedVector2Array()
	for q: Array in points:
		poly.append(Vector2(q[0], q[1]))
	var area := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		area += a.x * b.y - b.x * a.y
	if area < 0.0:
		poly.reverse()

	var n := poly.size()
	var wide := PackedVector2Array()
	for i in n:
		if bevel <= 0.0:
			wide.append(poly[i])
			continue
		var before := (poly[i] - poly[(i - 1 + n) % n]).normalized()
		var after := (poly[(i + 1) % n] - poly[i]).normalized()
		var n1 := Vector2(before.y, -before.x)
		var n2 := Vector2(after.y, -after.x)
		var miter := (n1 + n2).normalized()
		wide.append(poly[i] + miter * bevel / max(0.45, miter.dot(n1)))

	var geo := Geo.new()
	var half := depth * 0.5
	var layers: Array = []
	if bevel > 0.0:
		layers = [[poly, -half - bevel], [wide, -half], [wide, half], [poly, half + bevel]]
	else:
		layers = [[poly, -half], [poly, half]]
	for layer: Array in layers:
		var contour: PackedVector2Array = layer[0]
		for v in contour:
			geo.points.append(Vector3(v.x, v.y, layer[1]))
	for j in layers.size() - 1:
		for i in n:
			var a := j * n + i
			var b := j * n + (i + 1) % n
			var c := a + n
			var d := b + n
			geo.indices.append_array([a, b, d, a, d, c])

	var caps := Geometry2D.triangulate_polygon(poly)
	var front := (layers.size() - 1) * n
	for t in range(0, caps.size(), 3):
		var i0 := caps[t]
		var i1 := caps[t + 1]
		var i2 := caps[t + 2]
		if (poly[i1] - poly[i0]).cross(poly[i2] - poly[i0]) < 0.0:
			var swap := i1
			i1 = i2
			i2 = swap
		geo.indices.append_array([front + i0, front + i1, front + i2])
		geo.indices.append_array([i0, i2, i1])
	return geo


static func box_geo(w: float, h: float, d: float) -> Geo:
	var x := w * 0.5
	var y := h * 0.5
	var z := d * 0.5
	var geo := Geo.new()
	var faces := [
		[Vector3(-x, -y, z), Vector3(x, -y, z), Vector3(x, y, z), Vector3(-x, y, z)],
		[Vector3(x, -y, -z), Vector3(-x, -y, -z), Vector3(-x, y, -z), Vector3(x, y, -z)],
		[Vector3(x, -y, z), Vector3(x, -y, -z), Vector3(x, y, -z), Vector3(x, y, z)],
		[Vector3(-x, -y, -z), Vector3(-x, -y, z), Vector3(-x, y, z), Vector3(-x, y, -z)],
		[Vector3(-x, y, z), Vector3(x, y, z), Vector3(x, y, -z), Vector3(-x, y, -z)],
		[Vector3(-x, -y, -z), Vector3(x, -y, -z), Vector3(x, -y, z), Vector3(-x, -y, z)],
	]
	for f: Array in faces:
		geo.points.append_array([f[0], f[1], f[2], f[0], f[2], f[3]])
	return geo


static func sphere_geo(r: float, w := 12, h := 10) -> Geo:
	var geo := Geo.new()
	for j in h + 1:
		var theta := float(j) / h * PI
		for i in w + 1:
			var phi := float(i) / w * TAU
			geo.points.append(Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi)) * r)
	for j in h:
		for i in w:
			var a := j * (w + 1) + i
			var b := a + 1
			var c := a + w + 1
			var d := c + 1
			geo.indices.append_array([a, b, c, b, d, c])
	return geo


static func torus_geo(radius: float, tube: float, radial := 8, tubular := 18) -> Geo:
	var geo := Geo.new()
	for j in radial + 1:
		var v := float(j) / radial * TAU
		for i in tubular + 1:
			var u := float(i) / tubular * TAU
			geo.points.append(Vector3((radius + tube * cos(v)) * cos(u), (radius + tube * cos(v)) * sin(u), tube * sin(v)))
	for j in radial:
		for i in tubular:
			var a := j * (tubular + 1) + i
			var b := a + 1
			var c := a + tubular + 1
			var d := c + 1
			geo.indices.append_array([a, b, c, b, d, c])
	return geo


static func cylinder_geo(top: float, bottom: float, height: float, n := 16) -> Geo:
	var geo := Geo.new()
	for i in n:
		var a := float(i) / n * TAU
		geo.points.append(Vector3(top * cos(a), height * 0.5, top * sin(a)))
	for i in n:
		var a := float(i) / n * TAU
		geo.points.append(Vector3(bottom * cos(a), -height * 0.5, bottom * sin(a)))
	var c_top := geo.points.size()
	geo.points.append(Vector3(0, height * 0.5, 0))
	var c_bottom := geo.points.size()
	geo.points.append(Vector3(0, -height * 0.5, 0))
	for i in n:
		var next := (i + 1) % n
		geo.indices.append_array([i, next, n + i, next, n + next, n + i])
		geo.indices.append_array([c_top, next, i, c_bottom, n + i, n + next])
	return geo


static func star4(r: float, w := -1.0, h := -1.0) -> Array:
	if w < 0.0:
		w = r * 0.24
	if h < 0.0:
		h = r
	return [[r, 0.0], [w, w], [0.0, h], [-w, w], [-r, 0.0], [-w, -w], [0.0, -h], [w, -w]]


# ------------------------------------------------------------------ surfaces

## Triangle soup with flat or smooth normals, box-projected UVs and welded hull normals.
func prepare(geo: Geo, smooth := false) -> Soup:
	var soup := Soup.new()
	var points := geo.points
	var tris := geo.indices
	if tris.is_empty():
		tris.resize(points.size())
		for i in points.size():
			tris[i] = i

	var vertex_normals := PackedVector3Array()
	if smooth:
		vertex_normals.resize(points.size())
		for t in range(0, tris.size(), 3):
			var a := points[tris[t]]
			var face := (points[tris[t + 1]] - a).cross(points[tris[t + 2]] - a)
			vertex_normals[tris[t]] += face
			vertex_normals[tris[t + 1]] += face
			vertex_normals[tris[t + 2]] += face
		for i in vertex_normals.size():
			vertex_normals[i] = vertex_normals[i].normalized()

	var count := tris.size()
	soup.pos.resize(count)
	soup.nor.resize(count)
	soup.uv.resize(count)
	soup.smo.resize(count)
	var offset := Vector2(rnd(), rnd())
	var k := 1.0 / TILE
	var welded := {}
	var keys: Array[Vector3i] = []
	keys.resize(count)

	for t in range(0, count, 3):
		var a := points[tris[t]]
		var b := points[tris[t + 1]]
		var c := points[tris[t + 2]]
		var flat := (b - a).cross(c - a).normalized()
		for corner in 3:
			var index := t + corner
			var p := points[tris[index]]
			var n: Vector3 = vertex_normals[tris[index]] if smooth else flat
			soup.pos[index] = p
			soup.nor[index] = n
			var ax := absf(n.x)
			var ay := absf(n.y)
			var az := absf(n.z)
			var flat_uv := Vector2(p.x, p.y)
			if ax >= ay and ax >= az:
				flat_uv = Vector2(p.z, p.y)
			elif ay >= az:
				flat_uv = Vector2(p.x, p.z)
			soup.uv[index] = flat_uv * k + offset
			var key := Vector3i((p * 1000.0).round())
			keys[index] = key
			welded[key] = welded.get(key, Vector3.ZERO) + n

	for i in count:
		soup.smo[i] = (welded[keys[i]] as Vector3).normalized()
	return soup


func add_soup(joint: Node3D, xf: Transform3D, soup: Soup, mat: String) -> void:
	if not _buckets.has(joint):
		_buckets[joint] = {}
	var bucket: Dictionary = _buckets[joint]
	if not bucket.has(mat):
		bucket[mat] = Soup.new()
	var target: Soup = bucket[mat]
	var normal_basis := xf.basis.inverse().transposed()
	for i in soup.pos.size():
		target.pos.append(xf * soup.pos[i])
		target.nor.append((normal_basis * soup.nor[i]).normalized())
		target.uv.append(soup.uv[i])
		target.smo.append((normal_basis * soup.smo[i]).normalized())


func add(joint: Node3D, xf: Transform3D, geo: Geo, mat: String, smooth := false) -> void:
	add_soup(joint, xf, prepare(geo, smooth), mat)


func loft(joint: Node3D, xf: Transform3D, rings: Array, mat: String, p := 0.8, n := 14) -> void:
	add(joint, xf, loft_geo(rings, n, p), mat, true)


## Solid from a to b. Rings are [fraction, halfWidth, halfDepth, depthOffset].
func limb(joint: Node3D, xf: Transform3D, a: Vector3, b: Vector3, rings: Array, mat: String, p := 1.0, n := 12) -> void:
	var delta := b - a
	var length := delta.length()
	var scaled: Array = []
	for ring: Array in rings:
		var h: float = ring[2] if ring.size() > 2 else ring[1]
		var o: float = ring[3] if ring.size() > 3 else 0.0
		scaled.append([ring[0] * length, ring[1], h, o])
	var local := Transform3D(Basis(Quaternion(Vector3.UP, delta.normalized())), a)
	loft(joint, xf * local, scaled, mat, p, n)


func plate(joint: Node3D, xf: Transform3D, pts: Array, depth: float, mat: String, bevel := 0.0) -> void:
	add(joint, xf, shape_geo(pts, depth, bevel), mat)


## Builds a mesh for everything added to `joint` and parents it there.
func commit() -> void:
	for joint: Node3D in _buckets:
		var instance := MeshInstance3D.new()
		instance.mesh = bake(joint)
		joint.add_child(instance)
	_buckets.clear()


func bake(joint: Node3D) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var bucket: Dictionary = _buckets[joint]
	for key: String in bucket:
		var soup: Soup = bucket[key]
		var count := soup.pos.size()
		var indices := PackedInt32Array()
		indices.resize(count)
		for t in range(0, count, 3):
			# Godot's front faces are clockwise.
			indices[t] = t
			indices[t + 1] = t + 2
			indices[t + 2] = t + 1
		var custom := PackedFloat32Array()
		custom.resize(count * 3)
		for i in count:
			custom[i * 3] = soup.smo[i].x
			custom[i * 3 + 1] = soup.smo[i].y
			custom[i * 3 + 2] = soup.smo[i].z
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = soup.pos
		arrays[Mesh.ARRAY_NORMAL] = soup.nor
		arrays[Mesh.ARRAY_TEX_UV] = soup.uv
		arrays[Mesh.ARRAY_CUSTOM0] = custom
		arrays[Mesh.ARRAY_INDEX] = indices
		var flags := Mesh.ARRAY_CUSTOM_RGB_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
		if materials.has(key):
			mesh.surface_set_material(mesh.get_surface_count() - 1, materials[key])
	return mesh
